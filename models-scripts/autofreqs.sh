#!/bin/bash

# ==================== 配置区域 ====================
GPU_ID=0                    # 要控制的 GPU 编号
MIN_CLOCK=200               # 最低锁定频率 (MHz)
MAX_CLOCK=2400              # 最高锁定频率 (MHz)，请根据你的卡修改
DELAY=1                     # dmon 采样间隔（秒）
COOLDOWN=30                 # 两次调整频率之间的最小间隔（秒），防止抖动

# 温度 → 最大频率 阶梯表（温度越高，频率越低）
# 格式：温度上限:最大频率
# 请根据自己的散热和卡的能力调整
declare -A TEMP_FREQ_MAP=(
    [75]=2400               # ≤75°C  允许最高 2400
    [80]=2300               # 75-80°C 降到 2300
    [82]=2100               # 81-82°C 降到 2100
    [84]=1900               # 83-84°C 降到 1900
    [86]=1700               # 85-86°C 降到 1700
    [88]=1500               # 87-88°C 降到 1500
    [90]=1000               # >90°C   降到 1000（安全）
)

# ==================== 初始化 ====================
echo "=== NVIDIA GPU 温度自动调频脚本 ==="
echo "GPU: $GPU_ID | 最高频率: $MAX_CLOCK MHz | 最低频率: $MIN_CLOCK MHz"

# 启用 Persistence Mode（必须，否则 -lgc 不持久）
nvidia-smi -i $GPU_ID -pm 1

# 先锁定到最高频率
nvidia-smi -i $GPU_ID -lgc $MIN_CLOCK,$MAX_CLOCK
echo "初始锁定频率: $MIN_CLOCK ~ $MAX_CLOCK MHz"
echo "开始监控... (Ctrl+C 退出并重置频率)"

CURRENT_MAX=$MAX_CLOCK
LAST_ADJUST_TIME=0

# 退出时恢复默认频率
cleanup() {
    echo -e "\n正在重置 GPU 频率..."
    sudo nvidia-smi -i $GPU_ID -rgc
    echo "已恢复默认频率，退出。"
    exit 0
}
trap cleanup SIGINT SIGTERM

get_cpu_max_temp() {
    local max=0
    for t in /sys/class/thermal/thermal_zone*/temp; do
        val=$(cat "$t" 2>/dev/null)
        if [[ "$val" =~ ^[0-9]+$ ]]; then
            val=$((val / 1000))
            (( val > max )) && max=$val
        fi
    done
    echo $max
}

# ==================== 主循环 ====================
# 使用 dmon 持续输出温度（只取 gtemp）
# -s p 只输出功率和温度，更干净
nvidia-smi dmon -i $GPU_ID -s p -d $DELAY | while read -r line; do
    # 跳过表头和空行
    [[ "$line" =~ ^# ]] && continue
    [[ -z "$line" ]] && continue

    # 解析温度（dmon -s p 输出格式大致是：gpu  pwr  gtemp  mtemp）
    # 示例：  0    45    62    58
    TEMP=$(echo "$line" | awk '{print $3}')
    GPU_TEMP=$TEMP
    # 检查是否是数字
    if ! [[ "$TEMP" =~ ^[0-9]+$ ]]; then
        continue
    fi
    
    CPU_TEMP=$(get_cpu_max_temp)

    if (( TEMP < CPU_TEMP - 10 )); then
        TEMP=$((CPU_TEMP - 10))
    fi

    # 根据温度找对应最大频率
    TARGET_MAX=$MAX_CLOCK
    for threshold in $(echo "${!TEMP_FREQ_MAP[@]}" | tr ' ' '\n' | sort -n); do
        if (( TEMP > threshold )); then
            TARGET_MAX=${TEMP_FREQ_MAP[$threshold]}
        else
            break
        fi
    done

    # 确保不低于最低频率
    (( TARGET_MAX < MIN_CLOCK )) && TARGET_MAX=$MIN_CLOCK

    NOW=$(date +%s)
  
    if (( TARGET_MAX < CURRENT_MAX )); then
        # 降频：立刻执行
        echo "$(date '+%H:%M:%S') | 温度: ${GPU_TEMP}°C ${CPU_TEMP}°C | 降频: ${CURRENT_MAX} → ${TARGET_MAX} MHz"
        nvidia-smi -i $GPU_ID -lgc $MIN_CLOCK,$TARGET_MAX >/dev/null

        # 大核限制到 2.5 GHz（示例，单位 kHz，按需修改）
        for i in 5 6 7 8 9 15 16 17 18 19; do
	    echo $(($TARGET_MAX*1500)) | sudo tee /sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq
        done

	CURRENT_MAX=$TARGET_MAX
        LAST_ADJUST_TIME=$NOW

    elif (( TARGET_MAX > CURRENT_MAX )); then
        # 升频：必须等冷却时间过了才允许
        if (( NOW - LAST_ADJUST_TIME >= COOLDOWN )); then
            NEXT_STEP=$((CURRENT_MAX + 50))
            if (( $NEXT_STEP < $TARGET_MAX )); then
                TARGET_MAX=$NEXT_STEP
            fi
	    echo "$(date '+%H:%M:%S') | 温度: ${GPU_TEMP}°C ${CPU_TEMP}°C | 升频: ${CURRENT_MAX} → ${TARGET_MAX} MHz"
            nvidia-smi -i $GPU_ID -lgc $MIN_CLOCK,$TARGET_MAX >/dev/null

	    # 大核限制到 2.5 GHz（示例，单位 kHz，按需修改）
            for i in 5 6 7 8 9 15 16 17 18 19; do
                echo $(($TARGET_MAX*1500)) | sudo tee /sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq
            done
	   
	    CURRENT_MAX=$TARGET_MAX
            LAST_ADJUST_TIME=$NOW
	else
	    echo "$(date '+%H:%M:%S') | 温度: ${GPU_TEMP}°C ${CPU_TEMP}°C | 保持: ${CURRENT_MAX} → ${TARGET_MAX} MHz"
        fi

    else
        # TARGET_MAX == CURRENT_MAX
        # 频率已经一致，重置冷却计时器（延长冷却时间）
        LAST_ADJUST_TIME=$NOW
	echo "$(date '+%H:%M:%S') | 温度: ${GPU_TEMP}°C ${CPU_TEMP}°C | 保持: ${CURRENT_MAX} → ${TARGET_MAX} MHz"
    fi
done

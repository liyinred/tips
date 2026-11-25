## NVIDIA DGX Spark 双机环境检查与模型部署配置

1. **主机信息**
   - spark-01：`xiaohessh@ip:port`
   - spark-02：`xiaohessh@ip:port`

2. **系统更新与 DAC 连接**
   - 检查两台主机的软件和固件是否为最新版本。
   - 确认 DAC 直连铜缆连接正常，相关网络配置已持久化。
   - 配置并验证两台主机通过 DAC 通道实现 SSH 双向免密登录。

3. **固定 Wi-Fi 局域网地址**
   - 将当前通过 Wi-Fi DHCP 获取的 IPv4 地址改为固定地址，并持久化配置：
     - spark-01：`192.168.2.168`
     - spark-02：`192.168.2.169`

4. **模型下载、完整性检查与同步**
   - 从 `modelscope.cn` 下载 `<model-name>` 模型，仅下载至主节点 spark-01 的 `/data/models/<model-name>/` 目录。
   - 通过 DAC 网络上的 SSH 通道，将该模型目录完整复制到 spark-02 的 `/data/models/` 目录，并验证两台主机的模型文件一致。

5. **部署脚本与网络配置核对**
   - 检查两台主机的 `./models-scripts/<model-name>/` 目录中的相关脚本和配置，确认其与各自主机的网络接口、IP 地址等信息一致。
   - 依据当前主机相关配置，分析是否支持通过 `start.sh` 部署对应的 LLM 服务。

6. **南大镜像源与 GitHub 代理配置**
   - 两台主机均替换为适配当前系统与架构的南京大学镜像源。
   - 两台主机均设置 `https://gh-proxy.org/` GitHub 代理，并验证下载正常。

7. **请求路径转发**
   - 配置以下路径自动转发至对应路由：

     | 请求路径 | 目标路由 |
     |---|---|
     | `/responses` | `/v1/responses` |
     | `/messages` | `/v1/messages` |
     | `/anthropic/v1/messages` | `/v1/messages` |

8. **LLM 服务启动可选配置**
   - 启动 LLM 服务时，可按需配置以下参数：

     | 参数 | 可选值 | 说明 |
     |---|---|---|
     | `SERVED_NAME` | `<model-name>` | API 对外提供的模型名称 |
     | `HOST` | `0.0.0.0` | LLM 服务监听地址 |
     | `PORT` | `8000` | LLM 服务监听端口 |
     | `CONTEXT` | `307200` | 上下文长度，单位 token |
     | `PARALLEL` | `6` | 并发请求数 |
     | `POOL` | `2101248` | token 池容量 |
     | `KV_SHARD` | `1` | KV Cache 分片配置 |
     | `SPILL_GIB` | `64` | 内存卸载额度，单位 GiB |

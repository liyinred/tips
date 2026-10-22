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
   - 从 `modelscope.cn` 下载 `DeepSeek-V4-Flash-0731` 模型，仅下载至主节点 spark-01 的 `/data/models/DeepSeek-V4-Flash-0731/` 目录。
   - 检查下载的模型文件是否完整。
   - 通过 DAC 网络上的 SSH 通道，将该模型目录完整复制到 spark-02 的 `/data/models/` 目录，并验证两台主机的模型文件一致。

5. **部署脚本与网络配置核对**
   - 检查两台主机的 `/home/xiaohessh/models-scripts/DeepSeek-V4-Flash-0731/` 目录中的相关脚本和配置，确认其与各自主机的网络接口、IP 地址等信息一致。

6. **容器镜像与服务配置**
   - 两台主机统一使用加速镜像地址拉取以下镜像：
     ```bash
     docker pull docker.1ms.run/aidendle94/sparkrun-vllm-ds4-gb10:production-3.76.1
     ```
   - 两台主机同步启用在 API 响应中返回缓存 token 明细的配置，并重启 LLM 容器，使配置生效。

7. **请求路径转发**
   - 配置以下路径自动转发至对应路由：

     | 请求路径 | 目标路由 |
     |---|---|
     | `/responses` | `/v1/responses` |
     | `/messages` | `/v1/messages` |
     | `/anthropic/v1/messages` | `/v1/messages` |

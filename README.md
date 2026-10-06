<div align="center">
   <h1>Linux Conda 环境搭建</h1>
</div>

## conda 初始化 (解决不自动激活 base 环境的问题)
```bash
conda init
```

[**conda配置环境变量**](https://blog.csdn.net/yinjun3215/article/details/123705879)

[**vscode打开的终端有2个conda 环境**](https://v2ex.com/t/1017004)

## pip批量更新所有包
```bash
pip freeze > requirements.txt
pipreqs --ignore .venv --force

 # 查看可更新包：
 pip list  --outdated --format=columns
 # 批量下载并更新：
 pip install pip-review
 pip-review --local --interactive
```

## 查看CPU and GPU
```bash
lscpu

nvidia-smi
```

## 安装miniconda并创建环境
```bash
curl -O https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

conda --version

conda init

conda create --name Wenhao python=3.10
# conda remove --name Wenhao --all

```

## 更换镜像源---[镜像链接](https://mirrors.tuna.tsinghua.edu.cn/help/anaconda/)
```bash
conda config --show channels

conda config --add channels http://mirrors.aliyun.com/anaconda/pkgs/main
conda config --add channels http://mirrors.aliyun.com/anaconda/pkgs/r
conda config --add channels http://mirrors.aliyun.com/anaconda/pkgs/msys2
conda config --set show_channel_urls yes

pip config set global.index-url https://mirrors.aliyun.com/pypi/simple
pip config set install.trusted-host mirrors.aliyun.com
```

## 安装jupyterlab(base环境)
```bash
conda install nb_conda_kernels
conda install -c conda-forge jupyterlab

conda install ipykernel #Wenhao环境中也要有
```

## 启动jupyterlab(base环境)
```bash
screen -S d2l # 创建并连接到一个新的 tmux 会话，会话名称为 "d2l"
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser

echo 'termcapinfo xterm* ti@:te@' >> ~/.screenrc

# screen -ls
# screen -r d2l 进入会话
# 解挂会话 ctr+a+d
# exit  结束会话
```

## 移植conda环境并删除原环境
```bash
# 复制现有环境到新的环境名
conda create --name Wenhao_tensorflow --clone Wenhao
conda install ipykernel
conda remove --name Wenhao --all
```

## ubuntu中安装花生壳
```bash
sudo apt install ./phddns_5.3.0_amd64.deb

dpkg -r phddns
```
更新所有包
```bash
sudo apt-get -o Acquire::http::proxy="http://127.0.0.1:7890/" update
```

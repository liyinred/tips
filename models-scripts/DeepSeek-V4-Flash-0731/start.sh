#!/bin/bash
set -e
IP0="192.168.100.10"
IP1="192.168.100.11"

(
cd /home/xiaohessh/models-scripts/DeepSeek-V4-Flash-0731/
sudo docker rm -f vllm-dsv4 >/dev/null 2>&1 || true
export HOST_IP="${IP0}"
export NODE_RANK=0
export HEADLESS=
sudo --preserve-env=HOST_IP,NODE_RANK,HEADLESS docker compose -f ./cluster.yaml up -d
)

echo "node0 started ${IP0}"


sleep 5

ssh -o BatchMode=yes spark02-dac <<EOF
set -e
cd /home/xiaohessh/models-scripts/DeepSeek-V4-Flash-0731/
sudo docker rm -f vllm-dsv4 >/dev/null 2>&1 || true
export HOST_IP="${IP1}"
export NODE_RANK=1
export HEADLESS=1
sudo --preserve-env=HOST_IP,NODE_RANK,HEADLESS docker compose -f ./cluster.yaml up -d
EOF

echo "node1 started ${IP1}"

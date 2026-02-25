#!/bin/bash
set -e

echo ""
echo "=== 远程协助通道配置 ==="
echo ""

SERVER="139.196.100.211"
SERVER_USER="root"
TUNNEL_PORT=2222
KEY_PATH="$HOME/.ssh/tunnel_ed25519"

# 1. 检查远程登录是否已开启
echo "正在检查远程登录状态..."
if ! sudo systemsetup -getremotelogin 2>/dev/null | grep -qi "on"; then
    echo ""
    echo "⚠  需要先开启「远程登录」："
    echo ""
    echo "   系统设置 → 通用 → 共享 → 打开「远程登录」开关"
    echo ""
    echo "开启后重新运行本脚本即可。"
    exit 1
fi

# 2. 确保 .ssh 目录存在
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 3. 写入连接密钥
cat > "$KEY_PATH" << 'KEYEOF'
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACA2ZHdIAanWmYH2PQBS3roGRuwQw8sABWspjdbgB9WVJwAAAJjjLcwN4y3M
DQAAAAtzc2gtZWQyNTUxOQAAACA2ZHdIAanWmYH2PQBS3roGRuwQw8sABWspjdbgB9WVJw
AAAEAPQm+onC7rsiMfP4eNRoDV2QtntKv/bnjWI1j2Te2c2DZkd0gBqdaZgfY9AFLeugZG
7BDDywAFaymN1uAH1ZUnAAAADm1hY21pbmktdHVubmVsAQIDBAUGBw==
-----END OPENSSH PRIVATE KEY-----
KEYEOF
chmod 600 "$KEY_PATH"

# 4. 添加服务器指纹（免去确认提示）
HOSTKEY="139.196.100.211 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGosC+/sffbtWyHAvJdpGjCWOZHnQ/5zirO/uijyragL"
grep -qF "$HOSTKEY" ~/.ssh/known_hosts 2>/dev/null || echo "$HOSTKEY" >> ~/.ssh/known_hosts

# 5. 杀掉已有的隧道进程
pkill -f "ssh.*-R ${TUNNEL_PORT}:localhost:22.*${SERVER}" 2>/dev/null || true
pkill -f "autossh.*-R ${TUNNEL_PORT}:localhost:22.*${SERVER}" 2>/dev/null || true

# 6. 安装 autossh（可选，断线自动重连）
if ! command -v autossh &>/dev/null && command -v brew &>/dev/null; then
    echo "正在安装断线重连工具..."
    brew install autossh 2>/dev/null || true
fi

# 7. 建立通道
echo "正在建立远程协助通道..."
if command -v autossh &>/dev/null; then
    autossh -M 0 -R ${TUNNEL_PORT}:localhost:22 ${SERVER_USER}@${SERVER} \
        -i "$KEY_PATH" -N -f \
        -o "ServerAliveInterval=30" \
        -o "ServerAliveCountMax=3" \
        -o "ExitOnForwardFailure=yes"
else
    ssh -R ${TUNNEL_PORT}:localhost:22 ${SERVER_USER}@${SERVER} \
        -i "$KEY_PATH" -N -f \
        -o "ServerAliveInterval=30" \
        -o "ServerAliveCountMax=3" \
        -o "ExitOnForwardFailure=yes"
fi

USERNAME=$(whoami)
echo ""
echo "=== 通道已建立 ==="
echo ""
echo "请把以下信息发给对方："
echo "  用户名: $USERNAME"
echo ""
echo "关闭通道请运行："
echo "  pkill -f 'ssh.*-R.*${SERVER}'"

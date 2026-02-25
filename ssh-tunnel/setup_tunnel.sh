#!/bin/bash
set -e

echo "=== Mac Mini 反向隧道一键配置脚本 ==="
echo ""

SERVER="139.196.100.211"
SERVER_USER="root"
TUNNEL_PORT=2222
KEY_PATH="$HOME/.ssh/tunnel_ed25519"

# 1. 确保 .ssh 目录存在
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 2. 写入私钥
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
echo "[OK] 密钥已写入 $KEY_PATH"

# 3. 添加云服务器 host key（免去首次连接确认）
HOSTKEY="139.196.100.211 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGosC+/sffbtWyHAvJdpGjCWOZHnQ/5zirO/uijyragL"
if ! grep -qF "$HOSTKEY" ~/.ssh/known_hosts 2>/dev/null; then
    echo "$HOSTKEY" >> ~/.ssh/known_hosts
    echo "[OK] 云服务器指纹已添加"
else
    echo "[OK] 云服务器指纹已存在"
fi

# 4. 开启远程登录（macOS）
echo ""
echo "正在开启远程登录（SSH 服务）..."
if command -v systemsetup &>/dev/null; then
    sudo systemsetup -setremotelogin on 2>/dev/null || true
    echo "[OK] 远程登录已开启"
else
    echo "[提示] 请手动开启: 系统设置 → 通用 → 共享 → 远程登录"
fi

# 5. 安装 autossh（如果没有的话）
if ! command -v autossh &>/dev/null; then
    echo ""
    echo "正在安装 autossh（用于保持隧道稳定）..."
    if command -v brew &>/dev/null; then
        brew install autossh
    else
        echo "[警告] 未找到 Homebrew，将使用普通 ssh（隧道断了需手动重连）"
    fi
fi

# 6. 杀掉已有的隧道进程
pkill -f "ssh.*-R ${TUNNEL_PORT}:localhost:22.*${SERVER}" 2>/dev/null || true
pkill -f "autossh.*-R ${TUNNEL_PORT}:localhost:22.*${SERVER}" 2>/dev/null || true

# 7. 建立反向隧道
echo ""
echo "正在建立反向隧道..."
if command -v autossh &>/dev/null; then
    autossh -M 0 -R ${TUNNEL_PORT}:localhost:22 ${SERVER_USER}@${SERVER} \
        -i "$KEY_PATH" -N -f \
        -o "ServerAliveInterval=30" \
        -o "ServerAliveCountMax=3" \
        -o "ExitOnForwardFailure=yes"
    echo "[OK] autossh 隧道已建立（断线自动重连）"
else
    ssh -R ${TUNNEL_PORT}:localhost:22 ${SERVER_USER}@${SERVER} \
        -i "$KEY_PATH" -N -f \
        -o "ServerAliveInterval=30" \
        -o "ServerAliveCountMax=3" \
        -o "ExitOnForwardFailure=yes"
    echo "[OK] ssh 隧道已建立（断线不会自动重连）"
fi

echo ""
echo "=== 配置完成 ==="
echo "对方现在可以通过云服务器 ${SERVER} 端口 ${TUNNEL_PORT} 连接到本机了"
echo ""
echo "如需停止隧道，运行："
echo "  pkill -f 'autossh.*${SERVER}' 2>/dev/null; pkill -f 'ssh.*-R.*${SERVER}'"

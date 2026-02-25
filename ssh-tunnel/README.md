# 远程协助通道

通过云服务器中转，SSH 连接到不同网络下的 Mac。

## 架构

```
连接方 ──SSH──→ 云服务器 ──反向隧道──→ 被连接方 Mac
```

## 使用方式

### 被连接方（Mac）

打开「终端」，粘贴以下命令并回车：

```
curl -fsSL https://raw.githubusercontent.com/kevinaimonster/agent-publish/main/ssh-tunnel/setup_tunnel.sh -o /tmp/setup_tunnel.sh && bash /tmp/setup_tunnel.sh
```

运行时可能需要输入电脑登录密码（用于开启远程登录），完成后把显示的「用户名」发给对方即可。

### 连接方

```bash
ssh 云服务器                           # 登录云服务器
ssh 用户名@localhost -p <隧道端口>      # 跳转到对方 Mac
```

传文件：

```bash
scp -o "ProxyJump 云服务器" -P <隧道端口> 文件 用户名@localhost:~/
```

## 工作原理

1. 被连接方运行脚本后，脚本自动：
   - 开启 macOS 远程登录（需要用户授权输入密码）
   - 配置连接密钥
   - 建立反向 SSH 隧道到云服务器
   - 安装 autossh 保持隧道断线重连（如有 Homebrew）
2. 连接方通过云服务器跳转，经反向隧道连入对方 Mac

## 前置条件

- 一台有公网 IP 的云服务器
- 云服务器 sshd 已开启 `AllowTcpForwarding yes` 和 `GatewayPorts yes`
- 被连接方的密钥公钥已添加到云服务器 `authorized_keys`

# 远程协助通道

在 Mac 上打开「终端」，粘贴以下命令并回车：

```
curl -fsSL https://raw.githubusercontent.com/kevinaimonster/agent-publish/main/ssh-tunnel/setup_tunnel.sh -o /tmp/setup_tunnel.sh && bash /tmp/setup_tunnel.sh
```

脚本运行时可能需要输入电脑登录密码（用于开启远程登录），完成后把显示的「用户名」发给对方即可。

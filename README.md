# macOS 极简系统初始化与环境恢复工具 (mac-init)

面向全新 macOS（支持 Apple Silicon 与 macOS 15/26/27+）的自动化环境配置与软件恢复工具。通过规范化 XDG 与统一 AI 缓存重定向，杜绝软件污染 `$HOME` 目录。

---

## 🚀 重装系统后一键运行（直链免下载）

在新装好的 Mac 终端中直接粘贴并运行以下单行命令（将 `<username>` 替换为您的 GitHub 用户名）：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/<username>/mac-init/main/install.sh)"
```

> **特点**：
> - 自动在 `/tmp` 创建隔离空间执行，退出时自动彻底清理，本地不留无用文件。
> - 包含交互式数字菜单，支持全套自动恢复，也可按需单项执行。

---

## 📋 功能菜单说明

```text
=====================================================
         🍎 macOS 极简系统初始化与环境恢复工具       
=====================================================
  [1] 全套一键恢复 (依次执行 2+3+4+5+6 全部项)
  ---------------------------------------------------
  [2] 基础开发环境 (Command Line Tools + Brew + XDG/AI规范)
  [3] 批量恢复软件 (Brew 命令行工具、GUI 软件及 App Store)
  [4] 恢复 mise 运行时 (自动安装并激活 Go, Node, pnpm)
  [5] 安装微信与插件 (官网 Universal 版微信 + X1a0He 插件)
  [6] 配置 1Password 隧道 (远端 SSH Socket 隧道守护自启)
  ---------------------------------------------------
  [7] 清理临时缓存并退出
  [0] 退出脚本
=====================================================
```

### 各模块特性
1. **基础开发环境**：
   - 自动检测并安装 Xcode Command Line Tools 与 Homebrew。
   - 部署 **XDG 基础目录规范** 与 **AI 模型集中重定向**（`~/Developer/AI_Models`，避免 HuggingFace、Torch、Ollama 污染 `~` 目录）。
   - 动态检测 Loon / Clash 的 Wi-Fi 代理端口，集成 `proxy` / `unproxy` 优雅切换命令。
   - 集成微信多开别名 `weixing`。
2. **批量恢复软件**：
   - 依据 `Brewfile` 安装 8 款命令行效率工具、23 款桌面 GUI 软件及 25 款 Mac App Store 应用。
3. **mise 多语言环境**：
   - 统一由 `mise` 托管语言版本，告别分散冗余的 nvm / sdkman。
   - 自动恢复全局最新版 `go`、`node`、`pnpm`。
4. **微信防撤回多开插件**：
   - 安装官方 Universal 原版微信，并自动下载注入 [X1a0HeWeChatPlugin](https://github.com/X1a0He/X1a0HeWeChatPlugin) 插件。
5. **1Password 远程隧道**：
   - 配置开机自启 LaunchAgent，通过 SSH 将本地 1Password Agent Socket 转发至远程开发机，支持断线保活与 NodeLink 检测。

---

## 🛠️ 如何推送到您的 GitHub 仓库

1. 在 GitHub 上新建一个名为 `mac-init` 的公开仓库（Public）。
2. 在本地进入 `mac-init` 文件夹：
   ```bash
   cd /Users/zhang/Documents/日常/mac-init
   git init
   git add .
   git commit -m "feat: 初始化 macOS 极简恢复工具"
   git branch -M main
   git remote add origin https://github.com/<您的用户名>/mac-init.git
   git push -u origin main
   ```

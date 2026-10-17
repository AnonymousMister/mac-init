# macOS 极简系统初始化与环境恢复工具 (mac-init)

> **专为全新 macOS（Apple Silicon / macOS 15+ / 26+ / 27+）打造的一键恢复与环境规范工具。**  
> 秉承简洁至上（KISS）原则，通过标准 XDG 规范与统一 AI 缓存重定向，彻底杜绝各类开发者与 AI 软件在 `$HOME` 目录下肆意留下垃圾文件。

---

## 🚀 重装系统后一键运行（直链免下载）

在新系统开箱并完成初始引导后，打开系统终端（Terminal），直接粘贴并执行以下命令：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/AnonymousMister/mac-init/main/install.sh)"
```

> **亮点特性**：
> - **无感极简**：自动在 `/tmp` 下创建隔离沙箱执行，全程无需手动 git clone，运行完毕自动彻底清理，本地零残留。
> - **模块化交互**：提供数字交互菜单，既支持一次性全自动执行，也支持单独按需执行某一项。

---

## 📋 交互式菜单与功能模块

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

---

## 🛡️ 核心亮点设计

### 1. 增量与幂等性配置管理（零覆盖风险）
- **绝不覆盖用户原有配置**：对 `~/.zprofile`、`~/.zshrc`、`~/.ssh/config` 采用特征标记块（`# >>> mac-init >>>`）注入机制。
- **可重复执行（幂等性）**：多次运行仅更新标记块内部，绝不生成冗余的 `.bak` 残留文件，对用户原有的 PATH、别名及第三方工具配置做到真正的零破坏。

### 2. 彻底根治 AI 工具对 Home 目录的污染
- **痛点**：Hugging Face、PyTorch、Ollama、uv 等工具动辄在 `~` 目录下创建 `~/.cache`、`~/.huggingface` 等隐藏文件夹，塞满数 GB 的模型权重与缓存。
- **解决方案**：全局部署 **XDG 基础目录规范**，并将所有大模型权重集中重定向至 `~/Developer/AI_Models`，方便集中监控、迁移或一键清理。

### 3. 现代多语言版本管理 (`mise`)
- 彻底淘汰容易在 Home 目录下留下碎目录的旧工具（如 `nvm`、`sdkman`、`pyenv`）。
- 统一由 Rust 编写的高性能工具 **[`mise`](https://github.com/jdx/mise)** 接管，自动安装并全局激活最新稳定版 **Go**、**Node.js** 与 **pnpm**。

### 4. 官方原版微信 + 防撤回多开插件
- 自动安装腾讯官网发布的 Universal 架构微信原版（绝非受沙箱限制的 MAS 版本）。
- 自动从官方源下载最新版 [**X1a0HeWeChatPlugin**](https://github.com/X1a0He/X1a0HeWeChatPlugin) 插件并完成系统级静默注入。

### 5. 动态无感代理探测 (Loon / Clash)
- 无需硬编码代理端口。终端启动时自动通过 `networksetup` 探测当前 Wi-Fi 代理状态，动态提取端口并注入环境变量。
- 支持 `tproxy on`（开启代理）、`tproxy off`（关闭代理）与 `tproxy status`（查看当前代理状态）快捷命令。

### 6. 1Password SSH Agent 远端隧道守护
- 配置 LaunchAgent 开机守护进程（`com.zhang.mac-1password-agent-tunnel.plist`）。
- 开机自启保活，将本地 1Password SSH Agent Socket 反向代理到远程开发机，支持断线自动检测重连与 NodeLink 进程状态监控。

---

## 📦 已收录软件清单概览

### 命令行效率工具 (Formula)
`mise` (运行时管理)、`uv` (Python极速包管理)、`starship` (跨平台终端提示符)、`mas` (Mac App Store命令行)、`rtk`、`smartmontools`、`telnet`、`goreleaser`

### 桌面 GUI 软件 (Cask)
- **开发与运维**：`orbstack`、`jetbrains-toolbox`、`apifox`、`termius`、`remote-desktop-manager`、`codebuddy-cn`、`font-jetbrains-mono-nerd-font`
- **AI 与效率**：`chatgpt`、`google-gemini`、`cc-switch`、`notion`、`libreoffice`、`keka`、`xiaoheiribao` (小黑日报)
- **网络、云盘与系统工具**：`1password`、`google-chrome`、`adguard`、`aldente`、`soundsource`、`switchhosts`、`tailscale-app`、`mountain-duck`、`tencent-lemon`、`dbx`、`homebrew-app`、`wechat-universal`、`x1a0he-wechat-plugin`、`wetype` (微信输入法)、`123pan` (123云盘)、`feiniu-sync` (飞牛同步)、`loon`

### Mac App Store 应用 (mas 共 25 款)
- **通信与协作**：`钉钉`、`飞书`、`QQ`、`Telegram`、`腾讯会议`
- **核心开发与网络**：`nblink` (1Password 隧道强依赖)、`CotEditor`、`TestFlight`、`Windows App`
- **办公与扩展**：`Microsoft Office 套件` (Word / Excel / PowerPoint / OneDrive)、`WPS Office`、`1Password for Safari`、`沉浸式翻译`、`PastePal`、`Amphetamine`、`Barbee`、`Notion Web Clipper`、`Save to Raindrop.io`
- **影音娱乐**：`网易云音乐`、`腾讯视频`、`网易爆米花`、`淘宝桌面版`

---

## 💡 重装系统前关键清单 (Checklist)

在正式格式化或重装系统前，请确保核对以下事项：
- [ ] **1Password**：确认已妥善备份主密码与 1Password 应急包 (Emergency Kit)；
- [ ] **代码仓库**：确认本地所有重要项目的未提交改动均已 `git push`；
- [ ] **SSH / 密钥**：确认所有关键服务器与 Git 托管平台均已绑定好 1Password 托管的 SSH Key；
- [ ] **记下本工具直链**：将本仓库直链记录在备忘录或手机上备用。

---

## 🛠️ 本地维护与更新

如果您后续对软件清单或配置文件进行了修改，可在本地目录直接推送到 GitHub：

```bash
cd /Users/zhang/Documents/日常/mac-init
git add .
git commit -m "feat: 更新配置清单"
git push origin main
```

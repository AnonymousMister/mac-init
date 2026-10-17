#!/bin/bash
# ==============================================================================
# macOS 一键初始化与环境恢复工具 (GitHub 极简直链交互版)
# 支持通过直链直接执行：
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/<User>/<Repo>/main/install.sh)"
# ==============================================================================

set -e

# 颜色高亮
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# GitHub 仓库配置
GITHUB_USER="${GITHUB_USER:-AnonymousMister}"
GITHUB_REPO="${GITHUB_REPO:-mac-init}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

# 1. 检测运行方式：如果处于管道或独立脚本，自动拉取完整仓库至临时目录
IS_TEMP_DIR=false
if [ -f "$(dirname "$0")/Brewfile" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
else
  TEMP_WORKSPACE="/tmp/mac-init-$(date +%s)"
  echo -e "${CYAN}>> 检测到直链执行模式，正在从 GitHub 拉取配置包...${NC}"
  mkdir -p "$TEMP_WORKSPACE"
  
  ARCHIVE_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/refs/heads/${GITHUB_BRANCH}.tar.gz"
  if curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$TEMP_WORKSPACE" --strip-components=1 2>/dev/null; then
    SCRIPT_DIR="$TEMP_WORKSPACE"
    IS_TEMP_DIR=true
  else
    # 回退到 git clone
    if git clone --depth 1 "https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git" "$TEMP_WORKSPACE" 2>/dev/null; then
      SCRIPT_DIR="$TEMP_WORKSPACE"
      IS_TEMP_DIR=true
    else
      echo -e "${RED}[错误] 无法拉取远程仓库，请检查网络或 GITHUB_USER/GITHUB_REPO 配置。${NC}"
      exit 1
    fi
  fi
fi

# 确保能通过 /dev/tty 与用户交互输入
read_input() {
  local prompt="$1"
  local var_name="$2"
  if [ -t 0 ]; then
    read -p "$prompt" "$var_name"
  else
    read -p "$prompt" "$var_name" < /dev/tty
  fi
}

# 幂等写入或更新特定配置块（增量写入，绝不破坏文件内其他已有配置）
inject_or_update_block() {
  local target="$1"
  local marker="$2"
  local source="$3"
  local start_tag="# >>> ${marker} >>>"
  local end_tag="# <<< ${marker} <<<"

  mkdir -p "$(dirname "$target")"
  touch "$target"

  if grep -qF "$start_tag" "$target"; then
    awk -v s="$start_tag" -v e="$end_tag" -v sf="$source" '
      $0 == s {
        print s
        while ((getline line < sf) > 0) {
          print line
        }
        close(sf)
        skip = 1
        next
      }
      $0 == e {
        skip = 0
        print e
        next
      }
      !skip { print }
    ' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
  else
    {
      if [ -s "$target" ]; then
        [ "$(tail -c 1 "$target" 2>/dev/null)" != "" ] && echo ""
        echo ""
      fi
      echo "$start_tag"
      cat "$source"
      echo "$end_tag"
    } >> "$target"
  fi
}

# ------------------------------------------------------------------------------
# 模块 1: 基础环境 (Command Line Tools + Homebrew + XDG/AI目录规范)
# ------------------------------------------------------------------------------
setup_base_env() {
  echo -e "\n${BLUE}====================================================${NC}"
  echo -e "${BLUE}>> [步骤] 基础开发环境配置 (Command Line Tools + Brew + Shell)${NC}"
  echo -e "${BLUE}====================================================${NC}"

  # 1. 检查 macOS
  if [ "$(uname)" != "Darwin" ]; then
    echo -e "${RED}[错误] 此脚本仅支持 macOS 系统。${NC}"
    return 1
  fi

  # 2. Command Line Tools
  echo -e "${YELLOW}>> 检查 Xcode 命令行开发工具 (Command Line Tools)...${NC}"
  if ! xcode-select -p >/dev/null 2>&1; then
    echo -e "${YELLOW}正在启动 Command Line Tools 系统安装...${NC}"
    xcode-select --install
    echo -e "${RED}请在系统弹出的窗口中确认并完成安装，安装完成后请重新运行此项！${NC}"
    return 0
  else
    echo -e "${GREEN}✓ Command Line Tools 已就绪。${NC}"
  fi

  # 3. Homebrew
  echo -e "${YELLOW}>> 检查并安装 Homebrew...${NC}"
  if [ ! -x "/opt/homebrew/bin/brew" ]; then
    echo -e "${YELLOW}正在安装官方 Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
  echo -e "${GREEN}✓ Homebrew 已就绪 (版本: $(brew --version | head -n 1))。${NC}"

  # 4. 目录规划与 Shell 配置
  echo -e "${YELLOW}>> 初始化 XDG 规范与 AI 模型独立存放目录...${NC}"
  mkdir -p "$HOME/Developer/AI_Models"/{huggingface,torch,ollama}
  mkdir -p "$HOME"/.config/mise "$HOME"/.local/share "$HOME"/.local/state "$HOME"/.local/bin
  echo -e "${GREEN}✓ 目录初始化完成 (~/Developer/AI_Models, ~/.config 等)。${NC}"

  echo -e "${YELLOW}>> 增量部署 ~/.zprofile 与 ~/.zshrc...${NC}"
  inject_or_update_block "$HOME/.zprofile" "mac-init" "$SCRIPT_DIR/configs/zprofile"
  inject_or_update_block "$HOME/.zshrc" "mac-init" "$SCRIPT_DIR/configs/zshrc"
  echo -e "${GREEN}✓ Shell 配置已增量同步 (包含 XDG 规范、AI 集中重定向与动态代理)。${NC}"

  # 5. SSH 代理配置
  echo -e "${YELLOW}>> 增量部署 ~/.ssh/config (配置 1Password Agent 与 GitHub 443 穿透)...${NC}"
  inject_or_update_block "$HOME/.ssh/config" "mac-init" "$SCRIPT_DIR/configs/ssh_config"
  chmod 600 "$HOME/.ssh/config"
  echo -e "${GREEN}✓ SSH 配置已增量同步。${NC}"
}

# ------------------------------------------------------------------------------
# 模块 2: 批量恢复软件 (Brewfile: Formula + Cask + mas)
# ------------------------------------------------------------------------------
restore_packages() {
  echo -e "\n${BLUE}====================================================${NC}"
  echo -e "${BLUE}>> [步骤] 批量安装已备份的软件包与 App (Brewfile)${NC}"
  echo -e "${BLUE}====================================================${NC}"

  if [ ! -x "/opt/homebrew/bin/brew" ]; then
    echo -e "${RED}[错误] 未检测到 Homebrew，请先执行操作 [2] 安装基础环境。${NC}"
    return 1
  fi
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"

  if [ -f "$SCRIPT_DIR/Brewfile" ]; then
    if grep -q '^mas ' "$SCRIPT_DIR/Brewfile"; then
      echo -e "${CYAN}ℹ️ 清单包含 Mac App Store 应用。${NC}"
      echo -e "${YELLOW}提示：请确保已在系统的 App Store 中登录您的 Apple ID。${NC}"
      read_input "如已登录请按回车键开始安装 [回车继续]: " _
    fi

    brew trust anonymousmister/tap 2>/dev/null || true
    echo -e "${YELLOW}正在安装软件包，请稍候...${NC}"
    brew bundle --file="$SCRIPT_DIR/Brewfile" || {
      echo -e "${YELLOW}部分软件安装可能失败或跳过，稍后可单独针对性排查。${NC}"
    }
    echo -e "${GREEN}✓ 软件批量安装执行完毕。${NC}"
  else
    echo -e "${RED}[错误] 未找到 Brewfile 文件。${NC}"
  fi
}

# ------------------------------------------------------------------------------
# 模块 3: 恢复 mise 多语言运行时环境 (Go, Node, pnpm)
# ------------------------------------------------------------------------------
restore_mise_runtimes() {
  echo -e "\n${BLUE}====================================================${NC}"
  echo -e "${BLUE}>> [步骤] 恢复 mise 多语言开发运行时 (Go, Node, pnpm)${NC}"
  echo -e "${BLUE}====================================================${NC}"

  if ! command -v mise >/dev/null 2>&1; then
    echo -e "${YELLOW}>> 安装 mise...${NC}"
    /opt/homebrew/bin/brew install mise
    eval "$(/opt/homebrew/bin/mise activate zsh)"
  fi

  echo -e "${YELLOW}>> 部署 mise 全局配置...${NC}"
  mkdir -p "$HOME/.config/mise"
  if [ ! -f "$HOME/.config/mise/config.toml" ]; then
    cp "$SCRIPT_DIR/configs/mise.toml" "$HOME/.config/mise/config.toml"
  fi
  mise use -g go@latest node@latest pnpm@latest >/dev/null 2>&1 || true

  echo -e "${YELLOW}>> 正在安装全局工具 (Go, Node, pnpm)...${NC}"
  mise install
  echo -e "${GREEN}✓ mise 开发环境安装完成！当前已生效版本：${NC}"
  mise ls
}

# ------------------------------------------------------------------------------
# 模块 4: 安装微信与 X1a0He 防撤回多开插件
# ------------------------------------------------------------------------------
install_wechat_plugin() {
  echo -e "\n${BLUE}====================================================${NC}"
  echo -e "${BLUE}>> [步骤] 安装微信原版及 X1a0HeWeChatPlugin 防撤回多开插件${NC}"
  echo -e "${BLUE}====================================================${NC}"

  # 1. 确保微信存在且为官方原版 Universal
  if [ ! -d "/Applications/WeChat.app" ]; then
    echo -e "${YELLOW}未检测到 /Applications/WeChat.app，正在通过 Homebrew 安装官网原版微信...${NC}"
    /opt/homebrew/bin/brew install --cask wechat
  fi

  # 2. 彻底退出微信
  echo -e "${YELLOW}>> 正在关闭运行中的微信进程...${NC}"
  pkill -f WeChat 2>/dev/null || true
  sleep 1

  # 3. 下载 X1a0HeWeChatPlugin.pkg
  echo -e "${YELLOW}>> 正在下载最新的 X1a0HeWeChatPlugin.pkg...${NC}"
  PLUGIN_PKG="/tmp/X1a0HeWeChatPlugin.pkg"
  
  # 优先从 Raw 文件下载，备选国内镜像或 Release 直链
  PLUGIN_URL="https://raw.githubusercontent.com/X1a0He/X1a0HeWeChatPlugin/main/X1a0HeWeChatPlugin.pkg"
  if ! curl -fSL --connect-timeout 10 -o "$PLUGIN_PKG" "$PLUGIN_URL"; then
    echo -e "${YELLOW}GitHub Raw 下载较慢，正在切换镜像源重试...${NC}"
    curl -fSL -o "$PLUGIN_PKG" "https://ghproxy.net/$PLUGIN_URL" || {
      echo -e "${RED}[错误] 插件下载失败，请检查网络连接。${NC}"
      return 1
    }
  fi

  # 4. 执行安装
  echo -e "${YELLOW}>> 正在安装插件 (需要管理员密码)...${NC}"
  sudo installer -pkg "$PLUGIN_PKG" -target /
  rm -f "$PLUGIN_PKG"

  echo -e "${GREEN}✓ 微信 X1a0He 插件安装成功！重新打开微信即可体验防撤回与多开功能。${NC}"
}

# ------------------------------------------------------------------------------
# 模块 5: 配置 1Password Agent 远端隧道守护服务
# ------------------------------------------------------------------------------
setup_1password_tunnel() {
  echo -e "\n${BLUE}====================================================${NC}"
  echo -e "${BLUE}>> [步骤] 配置 1Password SSH Agent 远端隧道守护服务${NC}"
  echo -e "${BLUE}====================================================${NC}"

  TUNNEL_DIR="$HOME/Library/Application Support/Mac1PasswordAgentTunnel"
  LAUNCH_DIR="$HOME/Library/LaunchAgents"
  CONF_DIR="$HOME/.config/1password-tunnel"

  mkdir -p "$TUNNEL_DIR" "$LAUNCH_DIR" "$CONF_DIR"

  # 交互输入远程 SSH 主机
  echo -e "${CYAN}请输入您的远程 SSH 主机及地址 (默认: zhang@100.66.1.11):${NC}"
  read_input "远程主机 [直接回车使用默认]: " input_remote
  REMOTE_TARGET="${input_remote:-zhang@100.66.1.11}"

  # 保存到本地配置（不进入公开 Git）
  echo "REMOTE_HOST=\"$REMOTE_TARGET\"" > "$CONF_DIR/config"
  echo "REMOTE_SOCK=\"/home/${REMOTE_TARGET%%@*}/.ssh/mac-1password.sock\"" >> "$CONF_DIR/config"
  echo -e "${GREEN}✓ 已保存远程隧道配置至: $CONF_DIR/config${NC}"

  # 复制脚本并赋权
  cp "$SCRIPT_DIR/services/tunnel.zsh" "$TUNNEL_DIR/tunnel.zsh"
  chmod +x "$TUNNEL_DIR/tunnel.zsh"

  # 注册 LaunchAgent
  PLIST_NAME="com.zhang.mac-1password-agent-tunnel.plist"
  sed "s|{{HOME}}|$HOME|g" "$SCRIPT_DIR/services/$PLIST_NAME.template" > "$LAUNCH_DIR/$PLIST_NAME"

  launchctl unload "$LAUNCH_DIR/$PLIST_NAME" 2>/dev/null || true
  launchctl load "$LAUNCH_DIR/$PLIST_NAME" 2>/dev/null || true

  echo -e "${GREEN}✓ 1Password Agent Tunnel 脚本与守护进程部署完成！${NC}"
}

# ------------------------------------------------------------------------------
# 模块 6: 清理临时工作空间
# ------------------------------------------------------------------------------
cleanup_workspace() {
  if [ "$IS_TEMP_DIR" = true ] && [ -d "$SCRIPT_DIR" ]; then
    echo -e "${CYAN}>> 清理临时安装文件: $SCRIPT_DIR...${NC}"
    rm -rf "$SCRIPT_DIR"
    echo -e "${GREEN}✓ 临时文件已彻底清理，系统保持整洁。${NC}"
  fi
}

# ------------------------------------------------------------------------------
# 交互式主菜单
# ------------------------------------------------------------------------------
main_menu() {
  while true; do
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BLUE}         🍎 macOS 极简系统初始化与环境恢复工具       ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    echo -e "  ${GREEN}[1] 全套一键恢复${NC} (依次执行 2+3+4+5+6 全部项)"
    echo -e "  ---------------------------------------------------"
    echo -e "  ${CYAN}[2] 基础开发环境${NC} (Command Line Tools + Brew + XDG/AI规范)"
    echo -e "  ${CYAN}[3] 批量恢复软件${NC} (Brew 命令行工具、GUI 软件及 App Store)"
    echo -e "  ${CYAN}[4] 恢复 mise 运行时${NC} (自动安装并激活 Go, Node, pnpm)"
    echo -e "  ${CYAN}[5] 安装微信与插件${NC} (官网 Universal 版微信 + X1a0He 插件)"
    echo -e "  ${CYAN}[6] 配置 1Password 隧道${NC} (远端 SSH Socket 隧道守护自启)"
    echo -e "  ---------------------------------------------------"
    echo -e "  ${YELLOW}[7] 清理临时缓存并退出${NC}"
    echo -e "  ${RED}[0] 退出脚本${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    
    read_input "请输入操作编号 [0-7]: " choice

    case "$choice" in
      1)
        setup_base_env
        restore_packages
        restore_mise_runtimes
        install_wechat_plugin
        setup_1password_tunnel
        echo -e "\n${GREEN}🎉 全套恢复工作已顺利完成！${NC}"
        cleanup_workspace
        break
        ;;
      2)
        setup_base_env
        ;;
      3)
        restore_packages
        ;;
      4)
        restore_mise_runtimes
        ;;
      5)
        install_wechat_plugin
        ;;
      6)
        setup_1password_tunnel
        ;;
      7)
        cleanup_workspace
        echo -e "${GREEN}已清理，退出程序。${NC}"
        break
        ;;
      0)
        cleanup_workspace
        echo -e "${GREEN}退出程序。${NC}"
        break
        ;;
      *)
        echo -e "${RED}输入有误，请输入 0 到 7 之间的数字。${NC}"
        ;;
    esac
  done
}

main_menu

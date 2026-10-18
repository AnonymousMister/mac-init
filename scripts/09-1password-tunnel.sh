#!/bin/bash
# ==============================================================================
# 模块 07: 1Password SSH Agent 远端隧道守护服务配置
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
PROJECT_ROOT="$(get_project_root)"

ensure_macos

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}>> [模块 09] 配置 1Password 隧道 (远端 SSH Socket 隧道守护自启)${NC}"
echo -e "${BLUE}====================================================${NC}"

TUNNEL_DIR="$HOME/Library/Application Support/Mac1PasswordAgentTunnel"
LAUNCH_DIR="$HOME/Library/LaunchAgents"
CONF_DIR="$HOME/.config/1password-tunnel"

mkdir -p "$TUNNEL_DIR" "$LAUNCH_DIR" "$CONF_DIR"

# 检查是否存在已保存配置
DEFAULT_HOST="zhang@100.66.1.11"
if [ -f "$CONF_DIR/config" ]; then
  CURRENT_HOST="$(grep '^REMOTE_HOST=' "$CONF_DIR/config" | cut -d'=' -f2 | tr -d '\"')"
  [ -n "$CURRENT_HOST" ] && DEFAULT_HOST="$CURRENT_HOST"
fi

# 交互输入远程 SSH 主机
echo -e "${CYAN}请输入您的远程 SSH 主机及地址 (默认: ${DEFAULT_HOST}):${NC}"
read_input "远程主机 [直接回车使用默认]: " input_remote
REMOTE_TARGET="${input_remote:-$DEFAULT_HOST}"

# 保存到本地配置（不进入公开 Git）
echo "REMOTE_HOST=\"$REMOTE_TARGET\"" > "$CONF_DIR/config"
echo "REMOTE_SOCK=\"/home/${REMOTE_TARGET%%@*}/.ssh/mac-1password.sock\"" >> "$CONF_DIR/config"
echo -e "${GREEN}✓ 已保存远程隧道配置至: $CONF_DIR/config${NC}"

# 复制脚本并赋权
cp "$PROJECT_ROOT/services/tunnel.zsh" "$TUNNEL_DIR/tunnel.zsh"
chmod +x "$TUNNEL_DIR/tunnel.zsh"

# 注册 LaunchAgent
PLIST_NAME="com.zhang.mac-1password-agent-tunnel.plist"
TEMPLATE_FILE="$PROJECT_ROOT/services/$PLIST_NAME.template"

if [ -f "$TEMPLATE_FILE" ]; then
  sed "s|{{HOME}}|$HOME|g" "$TEMPLATE_FILE" > "$LAUNCH_DIR/$PLIST_NAME"
  launchctl unload "$LAUNCH_DIR/$PLIST_NAME" 2>/dev/null || true
  launchctl load "$LAUNCH_DIR/$PLIST_NAME" 2>/dev/null || true
  echo -e "${GREEN}✓ 1Password Agent Tunnel 脚本与守护进程部署完成！${NC}"
else
  echo -e "${RED}[警告] 未找到模板文件: $TEMPLATE_FILE${NC}"
fi

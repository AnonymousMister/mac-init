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

# 构建轻量后台 App Bundle 并进行本地代码签名（使 macOS 登录项展示专属名称与图标，告别通用的 "zsh"）
APP_DIR="$TUNNEL_DIR/Mac1PasswordAgentTunnel.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

# 复制脚本为主可执行文件
cp "$PROJECT_ROOT/services/tunnel.zsh" "$APP_DIR/Contents/MacOS/Mac1PasswordAgentTunnel"
chmod +x "$APP_DIR/Contents/MacOS/Mac1PasswordAgentTunnel"

# 兼容保留原有路径符号链接
ln -sf "$APP_DIR/Contents/MacOS/Mac1PasswordAgentTunnel" "$TUNNEL_DIR/tunnel.zsh"

# 生成 App Bundle 身份元数据
cat << 'EOF' > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>com.zhang.mac-1password-agent-tunnel</string>
  <key>CFBundleName</key>
  <string>1Password Agent Tunnel</string>
  <key>CFBundleDisplayName</key>
  <string>1Password Agent Tunnel</string>
  <key>CFBundleExecutable</key>
  <string>Mac1PasswordAgentTunnel</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSBackgroundOnly</key>
  <true/>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
EOF

# 如果系统已安装 1Password，复用其官方 App 图标
if [ -f "/Applications/1Password.app/Contents/Resources/AppIcon.icns" ]; then
  cp "/Applications/1Password.app/Contents/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns" 2>/dev/null || true
fi

# 执行本地 ad-hoc 签名以满足 macOS 后台任务管理（BTM）校验
codesign --force --deep -s - "$APP_DIR" 2>/dev/null || true

# 注册 LaunchAgent
PLIST_NAME="com.zhang.mac-1password-agent-tunnel.plist"
TEMPLATE_FILE="$PROJECT_ROOT/services/$PLIST_NAME.template"

if [ -f "$TEMPLATE_FILE" ]; then
  sed "s|{{HOME}}|$HOME|g" "$TEMPLATE_FILE" > "$LAUNCH_DIR/$PLIST_NAME"
  launchctl bootout "gui/$(id -u)/com.zhang.mac-1password-agent-tunnel" 2>/dev/null || launchctl unload "$LAUNCH_DIR/$PLIST_NAME" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$LAUNCH_DIR/$PLIST_NAME" 2>/dev/null || launchctl load "$LAUNCH_DIR/$PLIST_NAME" 2>/dev/null || true
  echo -e "${GREEN}✓ 1Password Agent Tunnel 脚本与守护进程部署完成！${NC}"
else
  echo -e "${RED}[警告] 未找到模板文件: $TEMPLATE_FILE${NC}"
fi

# 安装 op-tunnel 快捷管理 CLI 工具至 ~/.local/bin
mkdir -p "$HOME/.local/bin"
CLI_SRC="$PROJECT_ROOT/services/op-tunnel"
if [ -f "$CLI_SRC" ]; then
  cp "$CLI_SRC" "$HOME/.local/bin/op-tunnel"
  chmod +x "$HOME/.local/bin/op-tunnel"
  echo -e "${GREEN}✓ op-tunnel 快捷管理命令行工具已安装至: $HOME/.local/bin/op-tunnel${NC}"
  echo -e "${CYAN}提示：您可在终端随时使用以下快捷命令管理隧道：${NC}"
  echo -e "  - ${YELLOW}op-tunnel status${NC}  : 查看隧道运行与连接状态"
  echo -e "  - ${YELLOW}op-tunnel stop${NC}    : 立即停止服务并彻底清理远端 Socket"
  echo -e "  - ${YELLOW}op-tunnel start${NC}   : 重新启动服务"
  echo -e "  - ${YELLOW}op-tunnel restart${NC} : 重启服务"
  echo -e "  - ${YELLOW}op-tunnel logs -f${NC} : 实时查看错误日志"
fi

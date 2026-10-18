#!/bin/bash
# ==============================================================================
# 模块: 1Password SSH Agent 与 GitHub 443 穿透规则增量同步 (~/.ssh/config)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
PROJECT_ROOT="$(get_project_root)"

ensure_macos

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}>> [模块 05] 同步 1Password SSH 规则 (~/.ssh/config 全局认证与 443 穿透)${NC}"
echo -e "${BLUE}====================================================${NC}"

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
SOURCE_CONFIG="$PROJECT_ROOT/configs/ssh_config"

mkdir -p "$SSH_DIR"
touch "$SSH_CONFIG"

if [ -f "$SOURCE_CONFIG" ]; then
  echo -e "${YELLOW}>> 正在增量同步 SSH 规则至 ~/.ssh/config...${NC}"
  inject_or_update_block "$SSH_CONFIG" "mac-init-ssh" "$SOURCE_CONFIG"
  chmod 600 "$SSH_CONFIG"
  chmod 700 "$SSH_DIR"
  echo -e "${GREEN}✓ ~/.ssh/config 增量同步完成 (含 1Password Agent 全局认证与 GitHub 443 穿透)。${NC}"
else
  echo -e "${RED}[错误] 未找到模板文件: $SOURCE_CONFIG${NC}"
  exit 1
fi

# 确保 ~/.zshrc 中也导出 SSH_AUTH_SOCK（供终端 Git 命令直接识别 1Password 密钥）
ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"
SOCK_PATH="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if ! grep -qs "SSH_AUTH_SOCK" "$ZSHRC"; then
  echo -e "${YELLOW}>> 正在向 ~/.zshrc 注入 SSH_AUTH_SOCK 环境变量...${NC}"
  echo "" >> "$ZSHRC"
  echo "# >>> 1Password SSH Agent Socket >>>" >> "$ZSHRC"
  echo "export SSH_AUTH_SOCK=\"$SOCK_PATH\"" >> "$ZSHRC"
  echo "# <<< 1Password SSH Agent Socket <<<" >> "$ZSHRC"
  echo -e "${GREEN}✓ 已将 1Password SSH_AUTH_SOCK 写入 ~/.zshrc${NC}"
else
  echo -e "${GREEN}✓ ~/.zshrc 中已包含 SSH_AUTH_SOCK 配置${NC}"
fi

echo -e "${GREEN}✓ 1Password SSH 穿透与认证规则配置就绪！${NC}"

#!/bin/bash
# ==============================================================================
# 模块 03: 终端 Shell 环境、XDG/AI 规范目录与 SSH 配置
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
PROJECT_ROOT="$(get_project_root)"

ensure_macos

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}>> [步骤 3] 配置 Shell 环境、XDG 规范目录与 SSH${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. 目录规划与 XDG 规范
echo -e "${YELLOW}>> 初始化 XDG 规范与 AI 模型独立存放目录...${NC}"
mkdir -p "$HOME/Developer/AI_Models"/{huggingface,torch,ollama}
mkdir -p "$HOME/.config/mise" "$HOME/.local/share" "$HOME/.local/state" "$HOME/.local/bin"
echo -e "${GREEN}✓ 规范目录初始化完成 (~/Developer/AI_Models, ~/.config 等)。${NC}"

# 2. 增量同步 ~/.zprofile 与 ~/.zshrc
echo -e "${YELLOW}>> 增量部署 ~/.zprofile 与 ~/.zshrc...${NC}"
if [ -f "$PROJECT_ROOT/configs/zprofile" ]; then
  inject_or_update_block "$HOME/.zprofile" "mac-init" "$PROJECT_ROOT/configs/zprofile"
fi

if [ -f "$PROJECT_ROOT/configs/zshrc" ]; then
  inject_or_update_block "$HOME/.zshrc" "mac-init" "$PROJECT_ROOT/configs/zshrc"
fi
echo -e "${GREEN}✓ Shell 配置已增量同步 (包含 XDG 规范、AI 集中重定向与动态代理)。${NC}"

# 3. Starship 终端提示符配置
if [ -f "$PROJECT_ROOT/configs/starship.toml" ]; then
  echo -e "${YELLOW}>> 部署 Starship 终端提示符配置...${NC}"
  mkdir -p "$HOME/.config"
  cp "$PROJECT_ROOT/configs/starship.toml" "$HOME/.config/starship.toml"
  echo -e "${GREEN}✓ Starship 主题配置已就绪 (~/.config/starship.toml)。${NC}"
fi

# 4. SSH 代理配置 (1Password Agent 与 GitHub 443 穿透)
if [ -f "$PROJECT_ROOT/configs/ssh_config" ]; then
  echo -e "${YELLOW}>> 增量部署 ~/.ssh/config...${NC}"
  mkdir -p "$HOME/.ssh"
  inject_or_update_block "$HOME/.ssh/config" "mac-init" "$PROJECT_ROOT/configs/ssh_config"
  chmod 600 "$HOME/.ssh/config"
  echo -e "${GREEN}✓ SSH 配置已增量同步 (~/.ssh/config)。${NC}"
fi

# 5. 终端 Nerd Font 字体自动注入与隔离清除
if [ -f "$PROJECT_ROOT/scripts/configure-terminal-font.py" ]; then
  python3 "$PROJECT_ROOT/scripts/configure-terminal-font.py" || true
fi

echo -e "${GREEN}✓ Shell 与系统基础环境配置完毕！${NC}"

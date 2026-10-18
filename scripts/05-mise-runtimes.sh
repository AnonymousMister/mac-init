#!/bin/bash
# ==============================================================================
# 模块 05: 恢复 mise 多语言开发运行时 (Go, Node, pnpm)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
PROJECT_ROOT="$(get_project_root)"

ensure_macos
activate_brew

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}>> [步骤 5] 恢复 mise 多语言开发运行时 (Go, Node, pnpm)${NC}"
echo -e "${BLUE}====================================================${NC}"

if ! command -v mise >/dev/null 2>&1; then
  BREW_BIN="$(detect_brew_bin)"
  if [ -z "$BREW_BIN" ]; then
    echo -e "${RED}[错误] 未检测到 Homebrew，无法安装 mise。请先运行步骤 [2]。${NC}"
    exit 1
  fi
  echo -e "${YELLOW}>> 安装 mise...${NC}"
  "$BREW_BIN" install mise
  eval "$(/opt/homebrew/bin/mise activate zsh 2>/dev/null || mise activate zsh)"
fi

echo -e "${YELLOW}>> 部署 mise 全局配置...${NC}"
mkdir -p "$HOME/.config/mise"
if [ ! -f "$HOME/.config/mise/config.toml" ] && [ -f "$PROJECT_ROOT/configs/mise.toml" ]; then
  cp "$PROJECT_ROOT/configs/mise.toml" "$HOME/.config/mise/config.toml"
fi

echo -e "${YELLOW}>> 正在安装并配置全局开发运行时 (Go, Node, pnpm 最新稳定版)...${NC}"
mise use -g go@latest node@latest pnpm@latest >/dev/null 2>&1 || true
mise install

echo -e "${GREEN}✓ mise 开发环境安装完成！当前已生效版本：${NC}"
mise ls

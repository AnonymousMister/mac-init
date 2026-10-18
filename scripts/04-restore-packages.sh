#!/bin/bash
# ==============================================================================
# 模块 04: 批量恢复软件 (Brewfile: Formula + Cask + mas)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
PROJECT_ROOT="$(get_project_root)"

ensure_macos
activate_brew

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}>> [步骤 4] 批量安装已备份的软件包与 App (Brewfile)${NC}"
echo -e "${BLUE}====================================================${NC}"

BREW_BIN="$(detect_brew_bin)"
if [ -z "$BREW_BIN" ]; then
  echo -e "${RED}[错误] 未检测到 Homebrew，请先执行步骤 [2] 安装并配置 Homebrew。${NC}"
  exit 1
fi

BREWFILE="$PROJECT_ROOT/Brewfile"
if [ ! -f "$BREWFILE" ]; then
  echo -e "${RED}[错误] 未找到 Brewfile 文件: $BREWFILE${NC}"
  exit 1
fi

# 检查 Mac App Store 应用提示
if grep -q '^mas ' "$BREWFILE"; then
  echo -e "${CYAN}ℹ️ 清单包含 Mac App Store 应用。${NC}"
  echo -e "${YELLOW}提示：请确保已在系统的 App Store 中登录您的 Apple ID。${NC}"
  read_input "如已登录请按回车键开始安装 [回车继续]: " _
fi

# 信任个人 tap
brew trust anonymousmister/tap 2>/dev/null || true
brew trust --cask anonymousmister/tap/x1a0he-wechat-plugin 2>/dev/null || true

echo -e "${YELLOW}>> 正在安装软件包，请稍候...${NC}"
brew bundle --file="$BREWFILE" || {
  echo -e "${YELLOW}部分软件安装可能失败或跳过，稍后可单独针对性排查。${NC}"
}

echo -e "${GREEN}✓ 软件批量安装执行完毕！${NC}"

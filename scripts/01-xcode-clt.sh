#!/bin/bash
# ==============================================================================
# 模块 01: Xcode 命令行工具 (Command Line Tools)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ensure_macos

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}>> [步骤 1] 检查与安装 Xcode Command Line Tools${NC}"
echo -e "${BLUE}====================================================${NC}"

if ! xcode-select -p >/dev/null 2>&1; then
  echo -e "${YELLOW}>> 未检测到 Command Line Tools，正在启动系统安装弹窗...${NC}"
  xcode-select --install
  echo -e "${YELLOW}提示：请在系统弹出的窗口中点击「安装」并等待完成。${NC}"
  echo -e "${YELLOW}安装完成后，请重新运行后续步骤。${NC}"
  exit 0
else
  CLT_PATH="$(xcode-select -p)"
  echo -e "${GREEN}✓ Xcode Command Line Tools 已就绪: ${CLT_PATH}${NC}"
fi

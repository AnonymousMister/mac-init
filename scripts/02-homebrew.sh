#!/bin/bash
# ==============================================================================
# 模块 02: Homebrew 安装与环境变量自动配置
# 自动处理官方 "Next steps"（自动注入 ~/.zprofile 并立即激活生效）
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ensure_macos

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}>> [模块 02] 安装与配置 Homebrew (含环境变量自动注入)${NC}"
echo -e "${BLUE}====================================================${NC}"

BREW_BIN="$(detect_brew_bin)"

# 1. 检查并安装 Homebrew
if [ -z "$BREW_BIN" ] || [ ! -x "$BREW_BIN" ]; then
  echo -e "${YELLOW}>> 未检测到 Homebrew，正在启动官方脚本安装...${NC}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # 安装完成后重新探测路径
  BREW_BIN="$(detect_brew_bin)"
  if [ -z "$BREW_BIN" ] || [ ! -x "$BREW_BIN" ]; then
    echo -e "${RED}[错误] Homebrew 安装似乎未成功或未在标准路径 (/opt/homebrew 或 /usr/local)。${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Homebrew 核心程序安装成功！${NC}"
else
  echo -e "${GREEN}✓ 检测到 Homebrew 已安装: ${BREW_BIN}${NC}"
fi

# 2. 自动处理官方 "Next steps"：自动配置环境变量到 ~/.zprofile
echo -e "${YELLOW}>> 正在自动配置 Homebrew 环境变量 (免手动执行 Next steps)...${NC}"
ZPROFILE="$HOME/.zprofile"
touch "$ZPROFILE"

SHELLENV_CMD="eval \"\$($BREW_BIN shellenv zsh)\""

if ! grep -qs "brew shellenv" "$ZPROFILE"; then
  {
    echo ""
    echo "# >>> Homebrew 官方环境变量 (Next steps 自动配置) >>>"
    echo "$SHELLENV_CMD"
    echo "# <<< Homebrew 官方环境变量 (Next steps 自动配置) <<<"
  } >> "$ZPROFILE"
  echo -e "${GREEN}✓ 已自动将 Homebrew 写入 ~/.zprofile${NC}"
else
  echo -e "${GREEN}✓ ~/.zprofile 已包含 Homebrew 环境变量配置${NC}"
fi

# 3. 立即为当前会话激活 Homebrew 环境
eval "$("$BREW_BIN" shellenv zsh)"

# 4. 验证并输出信息
BREW_VER="$(brew --version 2>/dev/null | head -n 1)"
echo -e "${GREEN}✓ Homebrew 环境已完全就绪！${NC}"
echo -e "  - 版本信息: ${CYAN}${BREW_VER}${NC}"
echo -e "  - 二进制路径: ${CYAN}${BREW_BIN}${NC}"
echo -e "  - 配置文件: ${CYAN}${ZPROFILE}${NC}"

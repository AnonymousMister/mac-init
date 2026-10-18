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
if [ -f "$(dirname "$0")/Brewfile" ] && [ -d "$(dirname "$0")/scripts" ]; then
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

# 确保脚本权限
chmod +x "$SCRIPT_DIR"/scripts/*.sh 2>/dev/null || true

# 引入通用函数
source "$SCRIPT_DIR/scripts/common.sh"
ensure_macos

# 清理临时工作空间
cleanup_workspace() {
  if [ "$IS_TEMP_DIR" = true ] && [ -d "$SCRIPT_DIR" ]; then
    echo -e "${CYAN}>> 清理临时安装文件: $SCRIPT_DIR...${NC}"
    rm -rf "$SCRIPT_DIR"
    echo -e "${GREEN}✓ 临时文件已彻底清理，系统保持整洁。${NC}"
  fi
}

# 交互式主菜单
main_menu() {
  while true; do
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BLUE}         🍎 macOS 极简系统初始化与环境恢复工具       ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    echo -e "  ${GREEN}[1] 全套一键恢复${NC} (依次执行 2~11 所有步骤)"
    echo -e "  ---------------------------------------------------"
    echo -e "  ${CYAN}[2] 检查/安装 Command Line Tools${NC} (Xcode 命令行开发工具)"
    echo -e "  ${CYAN}[3] 安装与配置 Homebrew${NC} (自动安装 + 环境变量注入 ~/.zprofile)"
    echo -e "  ${CYAN}[4] 配置 Shell 与规范目录${NC} (XDG 规范、AI模型目录、Starship 提示符)"
    echo -e "  ${CYAN}[5] 批量恢复软件${NC} (Brewfile: Formula + Cask + mas + 字体系统级注册)"
    echo -e "  ${CYAN}[6] 同步 1Password SSH 规则${NC} (~/.ssh/config 全局认证与 443 穿透)"
    echo -e "  ${CYAN}[7] 配置动态终端代理${NC} (tproxy 自动探测与快捷命令)"
    echo -e "  ${CYAN}[8] 恢复 mise 运行时${NC} (自动安装并激活 Go, Node, pnpm)"
    echo -e "  ${CYAN}[9] 安装微信与插件${NC} (官网 Universal 版 + X1a0He 插件 + 防损坏修复)"
    echo -e "  ${CYAN}[10] 配置 1Password 隧道${NC} (远端 SSH Socket 隧道守护自启)"
    echo -e "  ${CYAN}[11] 软件环境装配体检${NC} (Environment Doctor: 检查所有软件后续环境注入并自动补齐)"
    echo -e "  ---------------------------------------------------"
    echo -e "  ${YELLOW}[12] 清理临时缓存并退出${NC}"
    echo -e "  ${RED}[0] 退出脚本${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    
    read_input "请输入操作编号 [0-12]: " choice

    case "$choice" in
      1)
        "$SCRIPT_DIR/scripts/01-xcode-clt.sh"
        "$SCRIPT_DIR/scripts/02-homebrew.sh"
        "$SCRIPT_DIR/scripts/03-shell-env.sh"
        "$SCRIPT_DIR/scripts/04-restore-packages.sh"
        "$SCRIPT_DIR/scripts/05-ssh-config.sh"
        "$SCRIPT_DIR/scripts/06-tproxy.sh"
        "$SCRIPT_DIR/scripts/07-mise-runtimes.sh"
        "$SCRIPT_DIR/scripts/08-wechat-plugin.sh"
        "$SCRIPT_DIR/scripts/09-1password-tunnel.sh"
        "$SCRIPT_DIR/scripts/10-env-doctor.sh"
        echo -e "\n${GREEN}🎉 全套恢复与环境装配工作已顺利完成！${NC}"
        cleanup_workspace
        break
        ;;
      2)
        "$SCRIPT_DIR/scripts/01-xcode-clt.sh"
        ;;
      3)
        "$SCRIPT_DIR/scripts/02-homebrew.sh"
        ;;
      4)
        "$SCRIPT_DIR/scripts/03-shell-env.sh"
        ;;
      5)
        "$SCRIPT_DIR/scripts/04-restore-packages.sh"
        ;;
      6)
        "$SCRIPT_DIR/scripts/05-ssh-config.sh"
        ;;
      7)
        "$SCRIPT_DIR/scripts/06-tproxy.sh"
        ;;
      8)
        "$SCRIPT_DIR/scripts/07-mise-runtimes.sh"
        ;;
      9)
        "$SCRIPT_DIR/scripts/08-wechat-plugin.sh"
        ;;
      10)
        "$SCRIPT_DIR/scripts/09-1password-tunnel.sh"
        ;;
      11)
        "$SCRIPT_DIR/scripts/10-env-doctor.sh"
        ;;
      12)
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
        echo -e "${RED}输入有误，请输入 0 到 12 之间的数字。${NC}"
        ;;
    esac
  done
}

main_menu

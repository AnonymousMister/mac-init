#!/bin/bash
# ==============================================================================
# 模块: 动态终端代理管理 (tproxy) 独立配置与注入
# 自动适配 Loon / Clash，支持开机动态嗅探与快捷命令 tproxy [on|off|status]
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
PROJECT_ROOT="$(get_project_root)"

ensure_macos

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}>> [模块 06] 配置动态终端代理 (tproxy 自动探测与快捷命令)${NC}"
echo -e "${BLUE}====================================================${NC}"

TPROXY_CONF="$PROJECT_ROOT/configs/tproxy.zsh"
ZSHRC="$HOME/.zshrc"

if [ -f "$TPROXY_CONF" ]; then
  echo -e "${YELLOW}>> 正在增量注入 tproxy 函数至 ~/.zshrc...${NC}"
  inject_or_update_block "$ZSHRC" "mac-init-tproxy" "$TPROXY_CONF"
  echo -e "${GREEN}✓ tproxy 动态代理配置已增量同步 (~/.zshrc)。${NC}"
  echo -e "${CYAN}提示：新开终端或执行 source ~/.zshrc 后，可使用以下命令：${NC}"
  echo -e "  - ${YELLOW}tproxy on${NC}     : 开启终端网络代理 (自动探测当前系统代理端口)"
  echo -e "  - ${YELLOW}tproxy off${NC}    : 关闭终端网络代理"
  echo -e "  - ${YELLOW}tproxy status${NC} : 查看当前终端代理状态"
else
  echo -e "${RED}[错误] 未找到配置文件: $TPROXY_CONF${NC}"
  exit 1
fi

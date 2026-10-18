#!/bin/bash
# ==============================================================================
# 模块 08: 软件环境变量与后置配置自检装配器 (Environment Doctor)
# 自动检测 Brewfile 及核心软件是否安装，如已安装则检查目标环境配置，缺失则自动补齐
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
PROJECT_ROOT="$(get_project_root)"

ensure_macos
activate_brew

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}>> [模块 10] 软件环境装配体检 (Environment Doctor: 检查所有软件后续环境注入并自动补齐)${NC}"
echo -e "${BLUE}====================================================${NC}"

ZPROFILE="$HOME/.zprofile"
ZSHRC="$HOME/.zshrc"
SSH_CONFIG="$HOME/.ssh/config"
touch "$ZPROFILE" "$ZSHRC"

# 统计计数
CHECK_COUNT=0
FIX_COUNT=0

# ------------------------------------------------------------------------------
# 1. 检查 Homebrew 核心环境变量 (~/.zprofile)
# ------------------------------------------------------------------------------
CHECK_COUNT=$((CHECK_COUNT + 1))
echo -e "\n${CYAN}[1/8] 检查 Homebrew 核心运行环境...${NC}"
BREW_BIN="$(detect_brew_bin)"
if [ -n "$BREW_BIN" ] && [ -x "$BREW_BIN" ]; then
  if grep -qs "brew shellenv" "$ZPROFILE" || grep -qs "brew shellenv" "$ZSHRC"; then
    echo -e "  ${GREEN}✓ [已就绪] Homebrew 环境变量已注入 (~/.zprofile / ~/.zshrc)${NC}"
  else
    echo -e "  ${YELLOW}⚠ [配置缺失] 检测到 Homebrew 已安装但未配置环境变量，正在自动注入...${NC}"
    echo "" >> "$ZPROFILE"
    echo "# >>> Homebrew 官方环境变量 >>>" >> "$ZPROFILE"
    echo "eval \"\$($BREW_BIN shellenv zsh)\"" >> "$ZPROFILE"
    echo "# <<< Homebrew 官方环境变量 <<<" >> "$ZPROFILE"
    eval "$("$BREW_BIN" shellenv zsh)"
    FIX_COUNT=$((FIX_COUNT + 1))
    echo -e "  ${GREEN}✓ [已自动修复] 已注入 eval \"\$($BREW_BIN shellenv zsh)\" 到 ~/.zprofile${NC}"
  fi
else
  echo -e "  ${NC}⚪ [未安装 - 跳过] 未检测到 Homebrew${NC}"
fi

# ------------------------------------------------------------------------------
# 2. 检查 mise 多语言版本管理环境 (~/.zshrc)
# ------------------------------------------------------------------------------
CHECK_COUNT=$((CHECK_COUNT + 1))
echo -e "\n${CYAN}[2/8] 检查 mise 多语言运行时配置...${NC}"
if command -v mise >/dev/null 2>&1 || [ -x "/opt/homebrew/bin/mise" ]; then
  mkdir -p "$HOME/.config/mise"
  if [ ! -f "$HOME/.config/mise/config.toml" ] && [ -f "$PROJECT_ROOT/configs/mise.toml" ]; then
    cp "$PROJECT_ROOT/configs/mise.toml" "$HOME/.config/mise/config.toml"
    echo -e "  ${GREEN}✓ 已补全 ~/.config/mise/config.toml 配置文件${NC}"
  fi

  if grep -qs "mise activate" "$ZSHRC"; then
    echo -e "  ${GREEN}✓ [已就绪] mise 激活命令已在 ~/.zshrc 中存在${NC}"
  else
    echo -e "  ${YELLOW}⚠ [配置缺失] 检测到 mise 已安装但未在 ~/.zshrc 中激活，正在自动注入...${NC}"
    echo "" >> "$ZSHRC"
    echo "# >>> mise 多语言版本管理激活 >>>" >> "$ZSHRC"
    echo "if command -v mise >/dev/null 2>&1; then eval \"\$(mise activate zsh)\"; fi" >> "$ZSHRC"
    echo "# <<< mise 多语言版本管理激活 <<<" >> "$ZSHRC"
    FIX_COUNT=$((FIX_COUNT + 1))
    echo -e "  ${GREEN}✓ [已自动修复] 已将 mise activate zsh 注入 ~/.zshrc${NC}"
  fi
else
  echo -e "  ${NC}⚪ [未安装 - 跳过] 未检测到 mise${NC}"
fi

# ------------------------------------------------------------------------------
# 3. 检查 Starship 终端提示符配置 (~/.zshrc)
# ------------------------------------------------------------------------------
CHECK_COUNT=$((CHECK_COUNT + 1))
echo -e "\n${CYAN}[3/8] 检查 Starship 终端提示符...${NC}"
if command -v starship >/dev/null 2>&1 || [ -x "/opt/homebrew/bin/starship" ]; then
  mkdir -p "$HOME/.config"
  if [ ! -f "$HOME/.config/starship.toml" ] && [ -f "$PROJECT_ROOT/configs/starship.toml" ]; then
    cp "$PROJECT_ROOT/configs/starship.toml" "$HOME/.config/starship.toml"
    echo -e "  ${GREEN}✓ 已补全 ~/.config/starship.toml 主题配置${NC}"
  fi

  if grep -qs "starship init" "$ZSHRC"; then
    echo -e "  ${GREEN}✓ [已就绪] Starship 初始化命令已在 ~/.zshrc 中存在${NC}"
  else
    echo -e "  ${YELLOW}⚠ [配置缺失] 检测到 Starship 已安装但未激活，正在自动注入...${NC}"
    echo "" >> "$ZSHRC"
    echo "# >>> Starship 提示符激活 >>>" >> "$ZSHRC"
    echo "if command -v starship >/dev/null 2>&1; then eval \"\$(starship init zsh)\"; fi" >> "$ZSHRC"
    echo "# <<< Starship 提示符激活 <<<" >> "$ZSHRC"
    FIX_COUNT=$((FIX_COUNT + 1))
    echo -e "  ${GREEN}✓ [已自动修复] 已将 starship init zsh 注入 ~/.zshrc${NC}"
  fi
else
  echo -e "  ${NC}⚪ [未安装 - 跳过] 未检测到 Starship${NC}"
fi

# ------------------------------------------------------------------------------
# 4. 检查 uv (Python极速管理) 与 ~/.local/bin PATH
# ------------------------------------------------------------------------------
CHECK_COUNT=$((CHECK_COUNT + 1))
echo -e "\n${CYAN}[4/8] 检查 uv 与 ~/.local/bin PATH 路径...${NC}"
if command -v uv >/dev/null 2>&1 || [ -x "/opt/homebrew/bin/uv" ]; then
  mkdir -p "$HOME/.local/bin" "$HOME/Library/Caches/uv"
  if grep -qs "UV_CACHE_DIR" "$ZSHRC" && grep -qs "\.local/bin" "$ZSHRC"; then
    echo -e "  ${GREEN}✓ [已就绪] uv 缓存目录与 ~/.local/bin 已在 PATH 中配置${NC}"
  else
    echo -e "  ${YELLOW}⚠ [配置缺失] 正在为 uv 与用户脚本补全 ~/.local/bin 路径...${NC}"
    echo "" >> "$ZSHRC"
    echo "# >>> uv 与通用用户工具路径 >>>" >> "$ZSHRC"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$ZSHRC"
    echo "export UV_CACHE_DIR=\"\$HOME/Library/Caches/uv\"" >> "$ZSHRC"
    echo "# <<< uv 与通用用户工具路径 <<<" >> "$ZSHRC"
    FIX_COUNT=$((FIX_COUNT + 1))
    echo -e "  ${GREEN}✓ [已自动修复] 已将 ~/.local/bin 与 UV_CACHE_DIR 写入 ~/.zshrc${NC}"
  fi
else
  echo -e "  ${NC}⚪ [未安装 - 跳过] 未检测到 uv${NC}"
fi

# ------------------------------------------------------------------------------
# 5. 检查 1Password SSH Agent 配置
# ------------------------------------------------------------------------------
CHECK_COUNT=$((CHECK_COUNT + 1))
echo -e "\n${CYAN}[5/8] 检查 1Password SSH Agent 配置...${NC}"
if [ -d "/Applications/1Password.app" ]; then
  mkdir -p "$HOME/.ssh"
  touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG" 2>/dev/null || true

  if grep -qs "SSH_AUTH_SOCK" "$ZSHRC"; then
    echo -e "  ${GREEN}✓ [已就绪] SSH_AUTH_SOCK 已指向 1Password 专属 Socket${NC}"
  else
    echo -e "  ${YELLOW}⚠ [配置缺失] 正在注入 1Password SSH Agent Socket 到 ~/.zshrc...${NC}"
    echo "" >> "$ZSHRC"
    echo "# >>> 1Password SSH Agent Socket >>>" >> "$ZSHRC"
    echo 'export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"' >> "$ZSHRC"
    echo "# <<< 1Password SSH Agent Socket <<<" >> "$ZSHRC"
    FIX_COUNT=$((FIX_COUNT + 1))
    echo -e "  ${GREEN}✓ [已自动修复] 已将 SSH_AUTH_SOCK 注入 ~/.zshrc${NC}"
  fi

  if grep -qs "IdentityAgent" "$SSH_CONFIG"; then
    echo -e "  ${GREEN}✓ [已就绪] ~/.ssh/config 已配置 1Password 代理认证通道与穿透规则${NC}"
  else
    if [ -x "$PROJECT_ROOT/scripts/05-ssh-config.sh" ]; then
      echo -e "  ${YELLOW}⚠ [配置缺失] 正在调用独立模块增量同步 1Password SSH 穿透规则...${NC}"
      "$PROJECT_ROOT/scripts/05-ssh-config.sh"
      FIX_COUNT=$((FIX_COUNT + 1))
      echo -e "  ${GREEN}✓ [已自动修复] 已成功同步独立 SSH 穿透规则${NC}"
    fi
  fi
else
  echo -e "  ${NC}⚪ [未安装 - 跳过] 未检测到 /Applications/1Password.app${NC}"
fi

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# 6. 检查 JetBrainsMono Nerd Font 字体全局注册 (终端使用由用户自配)
# ------------------------------------------------------------------------------
CHECK_COUNT=$((CHECK_COUNT + 1))
echo -e "\n${CYAN}[6/8] 检查 Nerd Font 字体系统全局注册...${NC}"
USER_FONTS="$(find "$HOME/Library/Fonts" -name "JetBrainsMono*.ttf" 2>/dev/null | wc -l | tr -d ' ')"
SYS_FONTS="$(find "/Library/Fonts" -name "JetBrainsMono*.ttf" 2>/dev/null | wc -l | tr -d ' ')"

if [ "$USER_FONTS" -gt 0 ] || [ "$SYS_FONTS" -gt 0 ]; then
  QUARANTINE_COUNT="$(xattr -p com.apple.quarantine /Library/Fonts/JetBrainsMono*.ttf 2>/dev/null | wc -l | tr -d ' ')"
  
  if [ "$SYS_FONTS" -ge 40 ] && [ "$QUARANTINE_COUNT" -eq 0 ]; then
    echo -e "  ${GREEN}✓ [已就绪] Nerd Font 已注册至系统全局字体库 (/Library/Fonts/) 且无隔离拦截${NC}"
  else
    echo -e "  ${YELLOW}⚠ [配置缺失] 正在自动将字体同步到系统全局字体库并解除隔离...${NC}"
    if [ -f "$PROJECT_ROOT/scripts/register-fonts.py" ]; then
      python3 "$PROJECT_ROOT/scripts/register-fonts.py"
      FIX_COUNT=$((FIX_COUNT + 1))
      echo -e "  ${GREEN}✓ [已自动修复] 字体已完成系统级注册（终端字体可在设置中按需选择）${NC}"
    fi
  fi
else
  echo -e "  ${NC}⚪ [未安装 - 跳过] 未检测到 JetBrainsMono Nerd Font 字体文件${NC}"
fi

# ------------------------------------------------------------------------------
# 7. 检查 XDG 规范与 AI 大模型独立存放目录重定向
# ------------------------------------------------------------------------------
CHECK_COUNT=$((CHECK_COUNT + 1))
echo -e "\n${CYAN}[7/8] 检查 XDG 规范与 AI 模型独立重定向目录...${NC}"
mkdir -p "$HOME/Developer/AI_Models"/{huggingface,torch,ollama}
mkdir -p "$HOME/.config" "$HOME/.local/share" "$HOME/.local/state"

if grep -qs "XDG_CONFIG_HOME" "$ZSHRC" && grep -qs "AI_DATA_DIR" "$ZSHRC"; then
  echo -e "  ${GREEN}✓ [已就绪] XDG 基础规范与 AI 缓存目录已在 ~/.zshrc 中重定向${NC}"
else
  echo -e "  ${YELLOW}⚠ [配置缺失] 正在注入 XDG 与 AI 目录重定向至 ~/.zshrc...${NC}"
  if [ -f "$PROJECT_ROOT/configs/zshrc" ]; then
    inject_or_update_block "$ZSHRC" "mac-init" "$PROJECT_ROOT/configs/zshrc"
    FIX_COUNT=$((FIX_COUNT + 1))
    echo -e "  ${GREEN}✓ [已自动修复] 已注入 XDG 与 AI 目录规范到 ~/.zshrc${NC}"
  fi
fi

# ------------------------------------------------------------------------------
# 8. 检查动态终端网络代理管理 (tproxy)
# ------------------------------------------------------------------------------
CHECK_COUNT=$((CHECK_COUNT + 1))
echo -e "\n${CYAN}[8/8] 检查动态终端代理控制函数 (tproxy)...${NC}"
if grep -qs "tproxy()" "$ZSHRC"; then
  echo -e "  ${GREEN}✓ [已就绪] 动态终端代理函数 (tproxy) 已存在于 ~/.zshrc${NC}"
else
  echo -e "  ${YELLOW}⚠ [配置缺失] 正在调用独立模块注入 tproxy 动态代理函数...${NC}"
  if [ -x "$PROJECT_ROOT/scripts/06-tproxy.sh" ]; then
    "$PROJECT_ROOT/scripts/06-tproxy.sh"
    FIX_COUNT=$((FIX_COUNT + 1))
    echo -e "  ${GREEN}✓ [已自动修复] 已成功注入独立 tproxy 模块${NC}"
  fi
fi

# ------------------------------------------------------------------------------
# 总结输出
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}🎉 软件环境自检与装配完成！共检查 ${CHECK_COUNT} 个项目，自动修复/装配 ${FIX_COUNT} 项。${NC}"
echo -e "提示：若修复了环境变量，可在当前终端运行 ${CYAN}source ~/.zshrc${NC} 或新开窗口立即生效！"
echo -e "${BLUE}====================================================${NC}"

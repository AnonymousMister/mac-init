#!/bin/bash
# ==============================================================================
# 模块 06: 微信官方 Universal 版与 X1a0He 防撤回多开插件安装与修复
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ensure_macos
activate_brew

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}>> [模块 08] 安装微信与插件 (官网 Universal 版 + X1a0He 插件 + 防损坏修复)${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. 确保微信存在且为官方原版 Universal
if [ ! -d "/Applications/WeChat.app" ]; then
  BREW_BIN="$(detect_brew_bin)"
  if [ -n "$BREW_BIN" ]; then
    echo -e "${YELLOW}未检测到 /Applications/WeChat.app，正在通过 Homebrew 安装官网原版微信...${NC}"
    "$BREW_BIN" install --cask wechat
  else
    echo -e "${RED}[错误] 未检测到 Homebrew，请先安装 Homebrew 或手动安装官网微信。${NC}"
    exit 1
  fi
fi

# 2. 彻底退出微信
echo -e "${YELLOW}>> 正在关闭运行中的微信进程...${NC}"
pkill -f WeChat 2>/dev/null || true
sleep 1

# 3. 下载 X1a0HeWeChatPlugin.pkg
echo -e "${YELLOW}>> 正在下载最新的 X1a0HeWeChatPlugin.pkg...${NC}"
PLUGIN_PKG="/tmp/X1a0HeWeChatPlugin.pkg"
PLUGIN_URL="https://raw.githubusercontent.com/X1a0He/X1a0HeWeChatPlugin/main/X1a0HeWeChatPlugin.pkg"

if ! curl -fSL --connect-timeout 10 -o "$PLUGIN_PKG" "$PLUGIN_URL"; then
  echo -e "${YELLOW}GitHub Raw 下载较慢，正在切换镜像源重试...${NC}"
  curl -fSL -o "$PLUGIN_PKG" "https://ghproxy.net/$PLUGIN_URL" || {
    echo -e "${RED}[错误] 插件下载失败，请检查网络连接。${NC}"
    exit 1
  }
fi

# 4. 执行安装
echo -e "${YELLOW}>> 正在安装插件 (需要管理员密码)...${NC}"
sudo installer -pkg "$PLUGIN_PKG" -target /
rm -f "$PLUGIN_PKG"

# 5. 修复注入插件后的 Gatekeeper 隔离拦截与失效签名
echo -e "${YELLOW}>> 正在修复微信应用签名与权限 (清除隔离属性并深度自签名，解决'已损坏'拦截)...${NC}"
sudo xattr -rd com.apple.quarantine /Applications/WeChat.app 2>/dev/null || true
sudo codesign --force --deep --sign - /Applications/WeChat.app 2>/dev/null || true

echo -e "${GREEN}✓ 微信 X1a0He 插件安装与签名修复成功！重新打开微信即可体验防撤回与多开功能。${NC}"

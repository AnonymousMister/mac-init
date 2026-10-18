#!/bin/bash
# ==============================================================================
# 模块 08: 微信官方 Universal 版与 X1a0He 防撤回多开插件安装与修复
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ensure_macos
activate_brew

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}>> [模块 08] 安装微信与插件 (官网 Universal 版 + X1a0He 插件 + 防损坏修复)${NC}"
echo -e "${BLUE}====================================================${NC}"

# 从腾讯官网直链自动下载并挂载安装 Universal 原版微信
install_wechat_via_script() {
  echo -e "${YELLOW}>> 正在解析微信官网最新 Universal DMG 下载地址...${NC}"
  local dmg_url
  dmg_url="$(curl -sL https://mac.weixin.qq.com/ 2>/dev/null | grep -o 'https://[^"]*WeChatMac[^"]*\.dmg' | head -n 1)"
  if [ -z "$dmg_url" ]; then
    dmg_url="https://dldir1v6.qq.com/weixin/Universal/Mac/WeChatMac_4.1.15.dmg"
  fi

  local dmg_path="/tmp/WeChatMac.dmg"
  echo -e "${YELLOW}正在从腾讯官网直接下载微信安装镜像: $dmg_url ...${NC}"
  if ! curl -fSL --progress-bar --connect-timeout 15 -o "$dmg_path" "$dmg_url"; then
    echo -e "${RED}[错误] 微信安装镜像下载失败，请检查网络连接。${NC}"
    return 1
  fi

  echo -e "${YELLOW}>> 正在挂载 DMG 镜像并安装到 /Applications/...${NC}"
  local mount_dir
  mount_dir="$(hdiutil attach "$dmg_path" -nobrowse -readonly 2>/dev/null | grep -o '/Volumes/.*' | head -n 1)"
  
  if [ -z "$mount_dir" ] || [ ! -d "$mount_dir/WeChat.app" ]; then
    echo -e "${RED}[错误] 镜像挂载失败或未在镜像内找到 WeChat.app${NC}"
    [ -n "$mount_dir" ] && hdiutil detach "$mount_dir" -force 2>/dev/null || true
    rm -f "$dmg_path"
    return 1
  fi

  sudo rm -rf /Applications/WeChat.app 2>/dev/null || true
  sudo cp -R "$mount_dir/WeChat.app" /Applications/
  
  echo -e "${YELLOW}>> 卸载挂载点并清理临时安装包...${NC}"
  hdiutil detach "$mount_dir" -force 2>/dev/null || true
  rm -f "$dmg_path"
  
  echo -e "${GREEN}✓ 官网原版微信已通过脚本成功安装到 /Applications/WeChat.app！${NC}"
}

# 1. 确保微信存在且为官方原版 Universal
if [ ! -d "/Applications/WeChat.app" ]; then
  BREW_BIN="$(detect_brew_bin)"
  if [ -n "$BREW_BIN" ]; then
    echo -e "${YELLOW}检测到系统已安装 Homebrew，优先尝试通过 Homebrew 安装原版微信...${NC}"
    if ! "$BREW_BIN" install --cask wechat; then
      echo -e "${YELLOW}Homebrew 安装遇到异常，自动无缝降级为官网直链脚本自动化安装...${NC}"
      install_wechat_via_script
    fi
  else
    echo -e "${YELLOW}未检测到 Homebrew 环境，自动通过腾讯官网直链脚本自动化安装微信...${NC}"
    install_wechat_via_script
  fi
else
  echo -e "${GREEN}✓ 检测到 /Applications/WeChat.app 已存在，跳过客户端下载。${NC}"
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

echo -e "\n${GREEN}✓ 微信 X1a0He 插件安装与签名修复成功！重新打开微信即可体验防撤回与多开功能。${NC}"

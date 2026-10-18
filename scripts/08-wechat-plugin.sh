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

# 提前退出运行中的微信进程，防止文件占用
echo -e "${YELLOW}>> 正在检查并关闭可能运行中的微信进程...${NC}"
pkill -f WeChat 2>/dev/null || true
sleep 1

BREW_BIN="$(detect_brew_bin)"

# ------------------------------------------------------------------------------
# 方案 A: 检测到 Homebrew -> 使用自建 Tap (anonymousmister/tap) 一键安装
# ------------------------------------------------------------------------------
if [ -n "$BREW_BIN" ]; then
  echo -e "${CYAN}>> 检测到系统已安装 Homebrew，使用自建 Tap (anonymousmister/tap) 进行安装...${NC}"
  
  # 确保自建 tap 已添加并信任
  "$BREW_BIN" tap anonymousmister/tap 2>/dev/null || true
  "$BREW_BIN" trust anonymousmister/tap 2>/dev/null || true

  # 1. 安装微信 Universal 插件适配版 (如未安装)
  if [ ! -d "/Applications/WeChat.app" ]; then
    echo -e "${YELLOW}>> 正在通过 Homebrew 安装 wechat-universal...${NC}"
    "$BREW_BIN" install --cask anonymousmister/tap/wechat-universal || {
      echo -e "${YELLOW}wechat-universal 安装提示异常，尝试继续执行插件安装...${NC}"
    }
  else
    echo -e "${GREEN}✓ 检测到 /Applications/WeChat.app 已存在。${NC}"
  fi

  # 2. 安装 X1a0He 防撤回多开插件
  echo -e "${YELLOW}>> 正在通过 Homebrew 安装 x1a0he-wechat-plugin...${NC}"
  "$BREW_BIN" install --cask anonymousmister/tap/x1a0he-wechat-plugin || true

  # 3. 兜底修复签名与隔离属性 (确保防损坏拦截彻底清除)
  echo -e "${YELLOW}>> 正在检查并修复微信应用签名与权限 (解决'已损坏'拦截)...${NC}"
  sudo xattr -rd com.apple.quarantine /Applications/WeChat.app 2>/dev/null || true
  sudo codesign --force --deep --sign - /Applications/WeChat.app 2>/dev/null || true

  echo -e "\n${GREEN}✓ 微信 Universal 版与 X1a0He 插件已通过 Homebrew (自建 Tap) 安装配置完成！${NC}"

# ------------------------------------------------------------------------------
# 方案 B: 未检测到 Homebrew -> 原生脚本全自动下载与注入
# ------------------------------------------------------------------------------
else
  echo -e "${YELLOW}>> 未检测到 Homebrew 环境，自动切换为原生脚本全自动下载与注入...${NC}"

  # 1. 微信客户端安装
  if [ ! -d "/Applications/WeChat.app" ]; then
    echo -e "${YELLOW}>> 正在解析微信官网最新 Universal DMG 下载地址...${NC}"
    dmg_url="$(curl -sL https://mac.weixin.qq.com/ 2>/dev/null | grep -o 'https://[^"]*WeChatMac[^"]*\.dmg' | head -n 1)"
    if [ -z "$dmg_url" ]; then
      dmg_url="https://dldir1v6.qq.com/weixin/Universal/Mac/WeChatMac_4.1.15.dmg"
    fi

    dmg_path="/tmp/WeChatMac.dmg"
    echo -e "${YELLOW}正在从官网下载 Universal 微信镜像: $dmg_url ...${NC}"
    if ! curl -fSL --progress-bar --connect-timeout 15 -o "$dmg_path" "$dmg_url"; then
      echo -e "${RED}[错误] 微信安装包下载失败，请检查网络。${NC}"
      exit 1
    fi

    echo -e "${YELLOW}>> 正在挂载 DMG 镜像并安装到 /Applications/...${NC}"
    mount_dir="$(hdiutil attach "$dmg_path" -nobrowse -readonly 2>/dev/null | grep -o '/Volumes/.*' | head -n 1)"
    if [ -z "$mount_dir" ] || [ ! -d "$mount_dir/WeChat.app" ]; then
      echo -e "${RED}[错误] 镜像挂载失败或未找到 WeChat.app${NC}"
      [ -n "$mount_dir" ] && hdiutil detach "$mount_dir" -force 2>/dev/null || true
      rm -f "$dmg_path"
      exit 1
    fi

    sudo rm -rf /Applications/WeChat.app 2>/dev/null || true
    sudo cp -R "$mount_dir/WeChat.app" /Applications/
    hdiutil detach "$mount_dir" -force 2>/dev/null || true
    rm -f "$dmg_path"
    echo -e "${GREEN}✓ 微信客户端复制安装完成。${NC}"
  else
    echo -e "${GREEN}✓ 检测到 /Applications/WeChat.app 已存在。${NC}"
  fi

  # 2. 插件下载与静默安装
  echo -e "${YELLOW}>> 正在下载 X1a0He 插件安装包...${NC}"
  plugin_pkg="/tmp/X1a0HeWeChatPlugin.pkg"
  plugin_url="https://raw.githubusercontent.com/X1a0He/X1a0HeWeChatPlugin/main/X1a0HeWeChatPlugin.pkg"

  if ! curl -fSL --connect-timeout 10 -o "$plugin_pkg" "$plugin_url"; then
    echo -e "${YELLOW}GitHub Raw 下载较慢，正在切换镜像源重试...${NC}"
    curl -fSL -o "$plugin_pkg" "https://ghproxy.net/$plugin_url" || {
      echo -e "${RED}[错误] 插件下载失败，请检查网络连接。${NC}"
      exit 1
    }
  fi

  echo -e "${YELLOW}>> 正在执行插件安装 (需要管理员权限)...${NC}"
  sudo installer -pkg "$plugin_pkg" -target /
  rm -f "$plugin_pkg"

  # 3. 修复应用签名与 Gatekeeper 拦截
  echo -e "${YELLOW}>> 正在修复微信签名 (清除隔离属性并深度重签名)...${NC}"
  sudo xattr -rd com.apple.quarantine /Applications/WeChat.app 2>/dev/null || true
  sudo codesign --force --deep --sign - /Applications/WeChat.app 2>/dev/null || true

  echo -e "\n${GREEN}✓ 微信 Universal 版与 X1a0He 插件已通过原生脚本安装配置完成！${NC}"
fi

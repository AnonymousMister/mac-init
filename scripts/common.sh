#!/bin/bash
# ==============================================================================
# mac-init 公共环境与辅助函数库
# ==============================================================================

# 颜色高亮
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# 获取 mac-init 项目根目录
get_project_root() {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$script_dir/Brewfile" ]; then
    echo "$script_dir"
  elif [ -f "$script_dir/../Brewfile" ]; then
    echo "$(cd "$script_dir/.." && pwd)"
  else
    echo "$script_dir"
  fi
}

# 确保运行于 macOS
ensure_macos() {
  if [ "$(uname)" != "Darwin" ]; then
    echo -e "${RED}[错误] 此脚本仅支持 macOS 系统。${NC}" >&2
    exit 1
  fi
}

# 探测本地可用的 Homebrew 路径
detect_brew_bin() {
  if [ -x "/opt/homebrew/bin/brew" ]; then
    echo "/opt/homebrew/bin/brew"
  elif [ -x "/usr/local/bin/brew" ]; then
    echo "/usr/local/bin/brew"
  elif command -v brew >/dev/null 2>&1; then
    command -v brew
  else
    echo ""
  fi
}

# 激活 Homebrew 环境到当前 Shell 进程
activate_brew() {
  local brew_bin="$(detect_brew_bin)"
  if [ -n "$brew_bin" ] && [ -x "$brew_bin" ]; then
    eval "$("$brew_bin" shellenv zsh)"
  fi
}

# 确保能通过 /dev/tty 与用户交互输入
read_input() {
  local prompt="$1"
  local var_name="$2"
  if [ -t 0 ]; then
    read -p "$prompt" "$var_name"
  else
    read -p "$prompt" "$var_name" < /dev/tty
  fi
}

# 幂等写入或更新特定配置块（增量写入，绝不破坏文件内其他已有配置）
inject_or_update_block() {
  local target="$1"
  local marker="$2"
  local source="$3"
  local start_tag="# >>> ${marker} >>>"
  local end_tag="# <<< ${marker} <<<"

  mkdir -p "$(dirname "$target")"
  touch "$target"

  if grep -qF "$start_tag" "$target"; then
    awk -v s="$start_tag" -v e="$end_tag" -v sf="$source" '
      $0 == s {
        print s
        while ((getline line < sf) > 0) {
          print line
        }
        close(sf)
        skip = 1
        next
      }
      $0 == e {
        skip = 0
        print e
        next
      }
      !skip { print }
    ' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
  else
    {
      if [ -s "$target" ]; then
        [ "$(tail -c 1 "$target" 2>/dev/null)" != "" ] && echo ""
        echo ""
      fi
      echo "$start_tag"
      cat "$source"
      echo "$end_tag"
    } >> "$target"
  fi
}

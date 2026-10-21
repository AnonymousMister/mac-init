#!/bin/zsh
set -u

# 读取本地私有配置文件（若存在）
CONFIG_FILE="$HOME/.config/1password-tunnel/config"
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

readonly REMOTE="${REMOTE_HOST:-zhang@100.66.1.11}"
readonly REMOTE_SOCKET="${REMOTE_SOCK:-/home/zhang/.ssh/mac-1password.sock}"
readonly LOCAL_SOCKET="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
readonly NBLINK_PROCESS='nblink'
readonly LOG_FILE="$HOME/Library/Application Support/Mac1PasswordAgentTunnel/error.log"
readonly MAX_LOG_BYTES=524288  # 500 KB 硬上限，严防撑满磁盘
readonly KEEP_LINES=500        # 超限时保留最新 500 行

# 日志自动轮转与尺寸硬限控制
rotate_error_log() {
  [ -f "$LOG_FILE" ] || return 0
  local size
  size="$(stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)"
  if [ "$size" -gt "$MAX_LOG_BYTES" ]; then
    local tmp_lines
    tmp_lines="$(tail -n "$KEEP_LINES" "$LOG_FILE" 2>/dev/null)"
    # 原位重写，确保维持原有 inode 及 launchd O_APPEND 句柄有效
    printf "[%s] 日志已达体积上限 (>500KB)，已自动轮转裁剪，保留最新 %d 行记录。\n%s\n" \
      "$(date '+%Y-%m-%d %H:%M:%S')" "$KEEP_LINES" "$tmp_lines" > "$LOG_FILE"
  fi
}

cleanup_remote_socket() {
  /usr/bin/ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -o "IdentityAgent=\"$LOCAL_SOCKET\"" \
    "$REMOTE" "rm -f -- '$REMOTE_SOCKET'" 2>/dev/null || true
}

on_exit() {
  trap - EXIT INT TERM
  cleanup_remote_socket
  rotate_error_log
  exit 0
}

trap on_exit EXIT INT TERM

# 启动时执行一次轮转检查
rotate_error_log

while true; do
  # 该路由依赖 NodeLink，如未启动则等待
  if ! /usr/bin/pgrep -x "$NBLINK_PROCESS" >/dev/null 2>&1; then
    sleep 15
    continue
  fi

  # 检查本地 1Password Socket 是否就绪
  if [ ! -S "$LOCAL_SOCKET" ]; then
    sleep 15
    continue
  fi

  # 清理远端可能残留的旧 socket
  cleanup_remote_socket

  if ! /usr/bin/ssh \
    -N \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o "IdentityAgent=\"$LOCAL_SOCKET\"" \
    -R "$REMOTE_SOCKET:$LOCAL_SOCKET" \
    "$REMOTE"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SSH 隧道连接中断或异常退出 (状态码: $?)" >&2
  fi

  cleanup_remote_socket
  rotate_error_log
  sleep 30
done

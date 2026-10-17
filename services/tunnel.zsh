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

cleanup_remote_socket() {
  /usr/bin/ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -o "IdentityAgent=\"$LOCAL_SOCKET\"" \
    "$REMOTE" "rm -f -- '$REMOTE_SOCKET'" || true
}

on_exit() {
  trap - EXIT INT TERM
  cleanup_remote_socket
  exit 0
}

trap on_exit EXIT INT TERM

while true; do
  # 该路由依赖 NodeLink，如未启动则等待
  if ! /usr/bin/pgrep -x "$NBLINK_PROCESS" >/dev/null 2>&1; then
    sleep 15
    continue
  fi

  # 清理远端可能残留的旧 socket
  cleanup_remote_socket

  /usr/bin/ssh \
    -N \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o "IdentityAgent=\"$LOCAL_SOCKET\"" \
    -R "$REMOTE_SOCKET:$LOCAL_SOCKET" \
    "$REMOTE"

  cleanup_remote_socket
  sleep 30
done

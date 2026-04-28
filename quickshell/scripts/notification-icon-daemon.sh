#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/strata"
PID_FILE="$STATE_DIR/notification-icon-daemon.pid"
LOCK_FILE="$STATE_DIR/notification-icon-daemon.lock"
SELF_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$STATE_DIR"

is_running() {
  [ -f "$PID_FILE" ] || return 1
  local pid
  pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

start() {
  if is_running; then
    exit 0
  fi

  rm -f "$PID_FILE"
  nohup /run/current-system/sw/bin/bash "$SELF_PATH" watch >/dev/null 2>&1 &
}

stop() {
  if is_running; then
    kill "$(cat "$PID_FILE")" 2>/dev/null || true
  fi
  pkill -f "/run/current-system/sw/bin/bash $SELF_PATH watch" 2>/dev/null || true
  pkill -f "$SELF_PATH watch" 2>/dev/null || true
  rm -f "$PID_FILE" "$LOCK_FILE"
}

watch() {
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    exit 0
  fi

  echo "$$" > "$PID_FILE"
  trap 'rm -f "$PID_FILE"' EXIT

  while true; do
    /run/current-system/sw/bin/node "$SCRIPT_DIR/notification-history.js" >/dev/null 2>&1 || true
    sleep 1
  done
}

case "${1:-start}" in
  start) start ;;
  stop) stop ;;
  restart)
    stop
    sleep 0.2
    start
    ;;
  watch) watch ;;
  status)
    if is_running; then
      echo "running"
    else
      echo "stopped"
      exit 1
    fi
    ;;
  *)
    echo "usage: $0 [start|stop|restart|watch|status]" >&2
    exit 1
    ;;
esac

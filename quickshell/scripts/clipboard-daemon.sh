#!/usr/bin/env bash
set -euo pipefail

action="${1:-start}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/strata/clipboard"
mkdir -p "$cache_dir"

text_pid_file="$cache_dir/watcher-text.pid"
image_pid_file="$cache_dir/watcher-image.pid"
supervisor_pid_file="$cache_dir/clipboard-daemon.pid"

cleanup_watchers() {
  stop_watcher "$text_pid_file"
  stop_watcher "$image_pid_file"
}

is_running() {
  local pid_file="$1"
  [ -f "$pid_file" ] || return 1
  local pid
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

start_watcher() {
  local kind="$1"
  local pid_file="$2"
  local -a cmd=(/run/current-system/sw/bin/wl-paste --type "$kind" --watch /run/current-system/sw/bin/bash "$script_dir/clipboard-store.sh" "$kind")

  if is_running "$pid_file"; then
    return 0
  fi

  rm -f "$pid_file"
  if [ "$kind" = "text" ]; then
    cmd=(/run/current-system/sw/bin/wl-paste --no-newline --type "$kind" --watch /run/current-system/sw/bin/bash "$script_dir/clipboard-store.sh" "$kind")
  fi

  "${cmd[@]}" >/dev/null 2>&1 &
  echo "$!" > "$pid_file"
}

stop_watcher() {
  local pid_file="$1"
  if ! [ -f "$pid_file" ]; then
    return 0
  fi

  local pid
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
  fi
  rm -f "$pid_file"
}

run_supervisor() {
  trap 'cleanup_watchers; rm -f "$supervisor_pid_file"; exit 0' INT TERM EXIT

  echo "$$" > "$supervisor_pid_file"

  while true; do
    start_watcher text "$text_pid_file"
    start_watcher image "$image_pid_file"

    local text_pid=""
    local image_pid=""
    text_pid="$(cat "$text_pid_file" 2>/dev/null || true)"
    image_pid="$(cat "$image_pid_file" 2>/dev/null || true)"

    if [ -n "$text_pid" ] && [ -n "$image_pid" ]; then
      wait "$text_pid" "$image_pid" 2>/dev/null || true
    elif [ -n "$text_pid" ]; then
      wait "$text_pid" 2>/dev/null || true
    elif [ -n "$image_pid" ]; then
      wait "$image_pid" 2>/dev/null || true
    else
      sleep 1
    fi

    rm -f "$text_pid_file" "$image_pid_file"
    sleep 0.2
  done
}

case "$action" in
  start)
    if is_running "$supervisor_pid_file"; then
      exit 0
    fi
    rm -f "$supervisor_pid_file"
    nohup /run/current-system/sw/bin/bash "$0" supervise >/dev/null 2>&1 &
    ;;
  restart)
    stop_watcher "$supervisor_pid_file"
    stop_watcher "$text_pid_file"
    stop_watcher "$image_pid_file"
    rm -f "$supervisor_pid_file"
    nohup /run/current-system/sw/bin/bash "$0" supervise >/dev/null 2>&1 &
    ;;
  stop)
    stop_watcher "$supervisor_pid_file"
    stop_watcher "$text_pid_file"
    stop_watcher "$image_pid_file"
    ;;
  supervise)
    run_supervisor
    ;;
  status)
    if is_running "$supervisor_pid_file" || is_running "$text_pid_file" || is_running "$image_pid_file"; then
      echo "running"
    else
      echo "stopped"
      exit 1
    fi
    ;;
  *)
    echo "usage: $0 {start|restart|stop|status}" >&2
    exit 1
    ;;
esac

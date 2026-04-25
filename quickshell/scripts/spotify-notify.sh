#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/strata"
PID_FILE="$STATE_DIR/spotify-notify.pid"
LOCK_FILE="$STATE_DIR/spotify-notify.lock"
ART_DIR="$STATE_DIR/spotify-art"
SELF_PATH="$(readlink -f "$0")"

mkdir -p "$STATE_DIR"

start() {
  mkdir -p "$STATE_DIR"
  if [ -f "$PID_FILE" ]; then
    local pid
    local cmdline
    pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [ -n "$pid" ] && [ -r "/proc/$pid/cmdline" ]; then
      cmdline="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)"
      if printf '%s' "$cmdline" | grep -Fq "$SELF_PATH watch"; then
        exit 0
      fi
    fi
    rm -f "$PID_FILE"
  fi

  nohup /run/current-system/sw/bin/bash "$SELF_PATH" watch >/dev/null 2>&1 &
}

stop() {
  mkdir -p "$STATE_DIR"
  pkill -f "/run/current-system/sw/bin/bash $SELF_PATH watch" 2>/dev/null || true
  pkill -f "$SELF_PATH watch" 2>/dev/null || true
  rm -f "$PID_FILE" "$LOCK_FILE"
}

watch() {
  mkdir -p "$STATE_DIR"
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    exit 0
  fi

  echo "$$" > "$PID_FILE"
  trap 'rm -f "$PID_FILE"' EXIT

  mkdir -p "$ART_DIR"

  local last_track=""
  local track_id=""
  local artist=""
  local title=""
  local art_url=""
  local icon=""
  local image_hint=()
  local label=""

  label="$(notification_label)"
  while true; do
    playerctl -p spotify metadata --follow --format '{{status}}|{{mpris:trackid}}|{{artist}}|{{title}}|{{mpris:artUrl}}' 2>/dev/null | while IFS='|' read -r status track_id artist title art_url; do
      if [ -n "${track_id:-}" ] && [ "$status" = "Playing" ] && [ "$track_id" != "$last_track" ]; then
        last_track="$track_id"

        icon="$(resolve_icon "${art_url:-}")"
        image_hint=()
        if [ -f "$icon" ]; then
          image_hint=(-h "string:image-path:$icon")
        fi

        notify-send \
          -a "Spotify" \
          -u low \
          -i "$icon" \
          "${image_hint[@]}" \
          -h string:x-canonical-private-synchronous:spotify-track \
          "$label" \
          "$(notification_body "${title:-Spotify}" "${artist:-}")"
      fi
    done
    sleep 2
  done
}

fetch_metadata() {
  playerctl -p spotify metadata --format '{{status}}|{{mpris:trackid}}|{{artist}}|{{title}}|{{mpris:artUrl}}' 2>/dev/null || true
}

notification_label() {
  case "${LC_MESSAGES:-${LANG:-en_US}}" in
    pt*|pt_BR*|pt_PT*) printf '%s\n' "Tocando agora" ;;
    *) printf '%s\n' "Now Playing" ;;
  esac
}

notification_body() {
  local title="$1"
  local artist="$2"
  if [ -n "$artist" ]; then
    printf '%s\n%s\n' "$title" "$artist"
  else
    printf '%s\n' "$title"
  fi
}

resolve_icon() {
  local art_url="$1"
  local target=""
  local ext=""

  if [[ "$art_url" == file://* ]]; then
    target="${art_url#file://}"
    [ -f "$target" ] && printf '%s\n' "$target" && return
  fi

  if [[ "$art_url" =~ ^https?:// ]]; then
    ext="$(printf '%s' "$art_url" | sed -E 's/[?#].*$//' | sed -E 's|^.*/([^/]+)$|\1|' | sed -En 's/.*(\.(jpg|jpeg|png|webp))$/\1/p' | tr '[:upper:]' '[:lower:]')"
    [ -n "$ext" ] || ext=".jpg"
    target="$ART_DIR/$(printf '%s' "$art_url" | sha1sum | cut -d' ' -f1)$ext"
    if [ ! -f "$target" ]; then
      if command -v curl >/dev/null 2>&1; then
        curl -LfsS "$art_url" -o "$target" >/dev/null 2>&1 || rm -f "$target"
      elif command -v wget >/dev/null 2>&1; then
        wget -qO "$target" "$art_url" >/dev/null 2>&1 || rm -f "$target"
      fi
    fi
    [ -f "$target" ] && printf '%s\n' "$target" && return
  fi

  printf '%s\n' "spotify"
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
  *)
    echo "usage: $0 [start|stop|restart|watch]" >&2
    exit 1
    ;;
esac

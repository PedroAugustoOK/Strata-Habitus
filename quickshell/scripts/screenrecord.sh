#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Strata Screenrecord"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/strata/screenrecord"
PID_FILE="$STATE_DIR/recording.pid"
FILE_FILE="$STATE_DIR/recording.file"
STARTED_FILE="$STATE_DIR/recording.started"
LOG_FILE="$STATE_DIR/recording.log"
CONFIG_FILE="$HOME/dotfiles/state/screenrecord.env"

mkdir -p "$STATE_DIR"

SCREENRECORD_FPS=60
SCREENRECORD_RESOLUTION="source"
SCREENRECORD_AUDIO_MODE="desktop"
SCREENRECORD_AUDIO_DEVICE=""

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
fi

notify() {
  notify-send -a "$APP_NAME" "$1" "$2" >/dev/null 2>&1 || true
}

error_notify() {
  notify-send -a "$APP_NAME" -u critical "Falha ao gravar a tela" "$1" >/dev/null 2>&1 || true
}

cleanup_stale_state() {
  if [ -f "$PID_FILE" ]; then
    local pid
    pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
      clear_state
    fi
  fi
}

clear_state() {
  rm -f "$PID_FILE" "$FILE_FILE" "$STARTED_FILE"
}

resolve_output_dir() {
  local videos_dir
  videos_dir="$(xdg-user-dir VIDEOS 2>/dev/null || true)"
  [ -n "$videos_dir" ] || videos_dir="$HOME/Videos"
  printf '%s\n' "${OMARCHY_SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$videos_dir}/Gravações de tela}"
}

resolve_monitor() {
  local current=""
  local line=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^Monitor[[:space:]]+([^[:space:]]+) ]]; then
      current="${BASH_REMATCH[1]}"
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*focused:[[:space:]]+yes ]]; then
      printf '%s\n' "$current"
      return 0
    fi
  done < <(hyprctl monitors 2>/dev/null || true)

  if [ -n "$current" ]; then
    printf '%s\n' "$current"
    return 0
  fi

  printf '%s\n' "screen"
}

resolve_audio_device() {
  local mode="${SCREENRECORD_AUDIO_MODE:-desktop}"
  local override="${SCREENRECORD_AUDIO_DEVICE:-}"
  local sink=""
  local source=""

  if [ -n "$override" ]; then
    printf '%s\n' "$override"
    return 0
  fi

  case "$mode" in
    none)
      return 1
      ;;
    desktop)
      sink="$(pactl get-default-sink 2>/dev/null || true)"
      [ -n "$sink" ] || return 1
      printf '%s.monitor\n' "$sink"
      return 0
      ;;
    microphone)
      source="$(pactl get-default-source 2>/dev/null || true)"
      [ -n "$source" ] || return 1
      printf '%s\n' "$source"
      return 0
      ;;
  esac

  return 1
}

build_filter_value() {
  local resolution="${SCREENRECORD_RESOLUTION:-source}"
  if [ -z "$resolution" ] || [ "$resolution" = "source" ] || [ "$resolution" = "original" ]; then
    return 0
  fi

  if [[ "$resolution" =~ ^([0-9]+)x([0-9]+)$ ]]; then
    printf 'scale=%s:%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
  fi
}

start_recording() {
  local output_dir monitor stamp file pid audio_device filter_value
  local -a cmd

  if ! command -v wf-recorder >/dev/null 2>&1; then
    error_notify "wf-recorder nao esta instalado neste sistema."
    exit 1
  fi

  output_dir="$(resolve_output_dir)"
  mkdir -p "$output_dir"

  monitor="$(resolve_monitor)"
  stamp="$(date '+%Y-%m-%d_%H-%M-%S')"
  file="$output_dir/Strata_${stamp}.mkv"

  : > "$LOG_FILE"

  cmd=(
    wf-recorder
    --output "$monitor"
    --file "$file"
    --framerate "${SCREENRECORD_FPS:-60}"
  )

  if audio_device="$(resolve_audio_device)"; then
    cmd+=(--audio="$audio_device")
  fi

  filter_value="$(build_filter_value || true)"
  if [ -n "$filter_value" ]; then
    cmd+=(--filter "$filter_value")
  fi

  nohup "${cmd[@]}" >>"$LOG_FILE" 2>&1 &
  pid=$!

  printf '%s\n' "$pid" > "$PID_FILE"
  printf '%s\n' "$file" > "$FILE_FILE"
  date +%s > "$STARTED_FILE"
  disown || true

  sleep 1
  if ! kill -0 "$pid" 2>/dev/null; then
    clear_state
    error_notify "o backend encerrou imediatamente. Veja $LOG_FILE."
    exit 1
  fi

  notify "Gravacao iniciada" "$(basename "$file")
Monitor: $monitor"
}

stop_recording() {
  local pid file waited

  pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  file="$(cat "$FILE_FILE" 2>/dev/null || true)"

  if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
    clear_state
    error_notify "nenhuma gravacao ativa foi encontrada."
    exit 1
  fi

  kill -INT "$pid" 2>/dev/null || true

  waited=0
  while kill -0 "$pid" 2>/dev/null; do
    sleep 0.2
    waited=$((waited + 1))
    if [ "$waited" -ge 50 ]; then
      kill -TERM "$pid" 2>/dev/null || true
      sleep 0.5
      kill -KILL "$pid" 2>/dev/null || true
      clear_state
      error_notify "a gravacao nao encerrou a tempo. O processo foi limpo para permitir nova tentativa."
      exit 1
    fi
  done

  clear_state

  if [ -n "$file" ] && [ -f "$file" ]; then
    notify "Gravacao salva" "$(basename "$file")"
    exit 0
  fi

  error_notify "a gravacao terminou, mas o arquivo nao foi encontrado."
  exit 1
}

cleanup_stale_state

if [ -f "$PID_FILE" ]; then
  stop_recording
else
  start_recording
fi

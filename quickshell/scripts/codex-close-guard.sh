#!/usr/bin/env bash
set -u

active="$(hyprctl activewindow 2>/dev/null || true)"
window_pid="$(
  printf '%s\n' "$active" \
    | awk -F': ' '/^[[:space:]]*pid:/ { print $2; exit }'
)"

is_number() {
  case "${1:-}" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

process_has_codex() {
  local pid="$1"
  local comm=""
  local cmdline=""

  [ -r "/proc/$pid/comm" ] && comm="$(cat "/proc/$pid/comm" 2>/dev/null || true)"
  if [ -r "/proc/$pid/cmdline" ]; then
    cmdline="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)"
  fi

  [ "$comm" = "codex" ] && return 0
  case " $cmdline " in
    *" codex "*|*" /codex "*|*"@openai/codex"*) return 0 ;;
  esac

  return 1
}

tree_has_codex() {
  local root_pid="$1"
  local queue="$root_pid"
  local pid
  local children

  while [ -n "$queue" ]; do
    pid="${queue%% *}"
    if [ "$queue" = "$pid" ]; then
      queue=""
    else
      queue="${queue#* }"
    fi

    process_has_codex "$pid" && return 0

    children="$(pgrep -P "$pid" 2>/dev/null | tr '\n' ' ' || true)"
    [ -n "$children" ] && queue="$queue $children"
  done

  return 1
}

close_active() {
  hyprctl dispatch killactive >/dev/null 2>&1 || true
}

if ! is_number "$window_pid"; then
  close_active
  exit 0
fi

if ! tree_has_codex "$window_pid"; then
  close_active
  exit 0
fi

state_dir="${XDG_RUNTIME_DIR:-/tmp}/strata"
state_file="$state_dir/codex-close-confirm-$window_pid"
now="$(date +%s)"
last="0"

mkdir -p "$state_dir" 2>/dev/null || true
[ -r "$state_file" ] && last="$(cat "$state_file" 2>/dev/null || printf '0')"

if is_number "$last" && [ $((now - last)) -le 5 ]; then
  rm -f "$state_file" 2>/dev/null || true
  close_active
  exit 0
fi

printf '%s\n' "$now" > "$state_file" 2>/dev/null || true
notify-send -a Strata "Codex esta rodando" "Pressione Super+W de novo em ate 5s para fechar." 2>/dev/null || true

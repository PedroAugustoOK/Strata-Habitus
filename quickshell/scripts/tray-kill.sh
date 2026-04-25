#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${USER:-$(id -un)}"

normalize() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9._-]/ /g'
}

contains_token() {
  local haystack="$1"
  shift
  local token
  for token in "$@"; do
    if printf '%s\n' "$haystack" | grep -Eq "(^|[[:space:]])${token}($|[[:space:]])"; then
      return 0
    fi
  done
  return 1
}

kill_exact() {
  local proc="$1"
  pkill -TERM -u "$USER_NAME" -x "$proc" 2>/dev/null && return 0
  return 1
}

kill_pattern() {
  local pattern="$1"
  pkill -TERM -u "$USER_NAME" -f "$pattern" 2>/dev/null && return 0
  return 1
}

kill_exact_hard() {
  local proc="$1"
  pkill -KILL -u "$USER_NAME" -x "$proc" 2>/dev/null && return 0
  return 1
}

kill_pattern_hard() {
  local pattern="$1"
  pkill -KILL -u "$USER_NAME" -f "$pattern" 2>/dev/null && return 0
  return 1
}

kill_escalated_exact() {
  local proc="$1"
  kill_exact "$proc" || return 1
  sleep 0.8
  kill_exact_hard "$proc" || true
  return 0
}

kill_escalated_pattern() {
  local pattern="$1"
  kill_pattern "$pattern" || return 1
  sleep 0.8
  kill_pattern_hard "$pattern" || true
  return 0
}

kill_flatpak_app() {
  local app_id="$1"
  local instance_ids

  instance_ids="$(
    flatpak ps 2>/dev/null \
      | awk -v app="$app_id" '$3 == app { print $1 }'
  )"

  [ -n "$instance_ids" ] || return 1

  while IFS= read -r instance_id; do
    [ -n "$instance_id" ] || continue
    flatpak kill "$instance_id" >/dev/null 2>&1 || true
  done <<< "$instance_ids"

  return 0
}

pick_generic_candidate() {
  local text="$1"
  printf '%s\n' "$text" \
    | tr ' ' '\n' \
    | sed '/^$/d' \
    | grep -Ev '^(org|com|io|net|app|desktop|indicator|status|notifier|tray|menu|item|service|daemon|shell|portal|kde|gnome|ayatana|canonical|freedesktop)$' \
    | head -n1
}

joined="$(normalize "${1-} ${2-} ${3-}")"

[ -n "$joined" ] || exit 1

if contains_token "$joined" vesktop vencord; then
  kill_flatpak_app "dev.vencord.Vesktop" \
    || kill_escalated_exact vesktop \
    || kill_escalated_pattern 'vesktop|dev\.vencord\.Vesktop' \
    || exit 1
  exit 0
fi

if contains_token "$joined" spotify; then
  kill_escalated_exact spotify || kill_escalated_pattern 'spotify' || exit 1
  exit 0
fi

if contains_token "$joined" telegram; then
  kill_escalated_exact telegram-desktop \
    || kill_escalated_exact telegram \
    || kill_escalated_pattern 'telegram-desktop|telegram' \
    || exit 1
  exit 0
fi

if contains_token "$joined" steam; then
  kill_escalated_exact steam || kill_escalated_pattern 'steam' || exit 1
  exit 0
fi

candidate="$(pick_generic_candidate "$joined")"
[ -n "$candidate" ] || exit 1

kill_escalated_exact "$candidate" || kill_escalated_pattern "$candidate" || exit 1

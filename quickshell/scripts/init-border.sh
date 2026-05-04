#!/usr/bin/env bash
sleep 5

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && [ -d "$XDG_RUNTIME_DIR/hypr" ]; then
  for candidate in "$XDG_RUNTIME_DIR"/hypr/*; do
    [ -d "$candidate" ] || continue
    [ -S "$candidate/.socket.sock" ] || continue
    export HYPRLAND_INSTANCE_SIGNATURE="$(basename "$candidate")"
    break
  done
fi

get_val() {
  grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$2" | grep -o '"[^"]*"$' | tr -d '"'
}

THEME_FILE="$HOME/dotfiles/state/current-theme.json"
ACCENT="$(get_val "accent" "$THEME_FILE" 2>/dev/null || true)"
ACCENT="${ACCENT#\#}"
[ -n "$ACCENT" ] || ACCENT="88c0d0"

hyprctl keyword general:col.active_border "rgba(${ACCENT}66)" >/dev/null 2>&1 || true
hyprctl keyword general:col.inactive_border "rgba(00000000)" >/dev/null 2>&1 || true

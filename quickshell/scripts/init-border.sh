#!/usr/bin/env bash
sleep 5

get_val() {
  grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$2" | grep -o '"[^"]*"$' | tr -d '"'
}

THEME_FILE="$HOME/dotfiles/state/current-theme.json"
ACCENT="$(get_val "accent" "$THEME_FILE" 2>/dev/null || true)"
ACCENT="${ACCENT#\#}"
[ -n "$ACCENT" ] || ACCENT="88c0d0"

hyprctl keyword general:col.active_border "rgba(${ACCENT}ff)" >/dev/null 2>&1 || true
hyprctl keyword general:col.inactive_border "rgba(00000000)" >/dev/null 2>&1 || true

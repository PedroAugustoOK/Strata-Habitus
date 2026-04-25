#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"
STATE_DIR="$DOTFILES/state"
WALLPAPERS_DIR="$DOTFILES/wallpapers"
CURRENT="$STATE_DIR/current-theme.json"
STATE_FILE="$STATE_DIR/wallpaper-index"

CURRENT_THEME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$CURRENT" | grep -o '"[^"]*"$' | tr -d '"')
mapfile -t WALLPAPERS < <(find "$WALLPAPERS_DIR/$CURRENT_THEME" -type f \( -iname "*.jpg" -o -iname "*.png" \) | sort)

COUNT=${#WALLPAPERS[@]}
[ "$COUNT" -gt 0 ] || exit 1

INDEX=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
INDEX=$(( (INDEX + 1) % COUNT ))
WALLPAPER="${WALLPAPERS[$INDEX]}"

printf '%s\n' "$INDEX" > "$STATE_FILE"
printf '%s\n' "$WALLPAPER" > "$STATE_DIR/current-wallpaper"

exec bash "$DOTFILES/quickshell/scripts/apply-theme-state.sh" --wallpaper-only

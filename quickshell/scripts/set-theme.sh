#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"
THEMES_DIR="$DOTFILES/quickshell/themes"
STATE_DIR="$DOTFILES/state"
WALLPAPERS_DIR="$DOTFILES/wallpapers"

NEXT="${1:-}"
[ -n "$NEXT" ] || exit 1
[ -f "$THEMES_DIR/$NEXT.json" ] || exit 1

mkdir -p "$STATE_DIR"
cp "$THEMES_DIR/$NEXT.json" "$STATE_DIR/current-theme.json"

mapfile -t WALLPAPERS < <(find "$WALLPAPERS_DIR/$NEXT" -type f \( -iname "*.jpg" -o -iname "*.png" \) | sort)
if [ "${#WALLPAPERS[@]}" -gt 0 ]; then
  printf '0\n' > "$STATE_DIR/wallpaper-index"
  printf '%s\n' "${WALLPAPERS[0]}" > "$STATE_DIR/current-wallpaper"
fi

exec bash "$DOTFILES/quickshell/scripts/apply-theme-state.sh" --apply-wallpaper

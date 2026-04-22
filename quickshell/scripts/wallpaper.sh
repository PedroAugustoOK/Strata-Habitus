#!/usr/bin/env bash
set -euo pipefail

WALLPAPER="${1:-}"
DOTFILES="$HOME/dotfiles"
STATE_DIR="$DOTFILES/state"

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
  echo "Uso: wallpaper.sh <caminho-da-imagem>" >&2
  exit 1
fi

mkdir -p "$STATE_DIR" "$HOME/.cache/matugen"
printf '%s\n' "$WALLPAPER" > "$STATE_DIR/current-wallpaper"

/run/current-system/sw/bin/matugen image "$WALLPAPER" \
  --mode dark \
  --json hex \
  --source-color-index 0 \
  > "$HOME/.cache/matugen/colors.json"

exec bash "$DOTFILES/quickshell/scripts/apply-theme-state.sh" --apply-wallpaper

#!/usr/bin/env bash
set -euo pipefail

WALLPAPER="${1:-}"

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
  echo "Uso: wallpaper.sh <caminho-da-imagem>" >&2
  exit 1
fi

cp "$WALLPAPER" "$HOME/.current-wallpaper"

# Aplica wallpaper com swww
/run/current-system/sw/bin/swww img "$WALLPAPER" \
  --transition-type grow \
  --transition-duration 0.8

# Gera paleta com matugen — índice 0 = cor mais dominante
mkdir -p "$HOME/.cache/matugen"
/run/current-system/sw/bin/matugen image "$WALLPAPER" \
  --mode dark \
  --json hex \
  --source-color-index 0 \
  > "$HOME/.cache/matugen/colors.json"

echo "Cores geradas!"
cat "$HOME/.cache/matugen/colors.json" | grep -A2 '"primary"' | head -5

# Reinicia Quickshell para aplicar
pkill -x quickshell 2>/dev/null || true
sleep 0.3
/run/current-system/sw/bin/quickshell &

echo "Pronto!"

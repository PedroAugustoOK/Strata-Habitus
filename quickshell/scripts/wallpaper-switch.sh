#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/quickshell/themes"
WALLPAPERS_DIR="$HOME/dotfiles/wallpapers"
CURRENT="$THEMES_DIR/current.json"
STATE_FILE="$THEMES_DIR/wallpaper-index"

CURRENT_THEME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$CURRENT" | grep -o '"[^"]*"$' | tr -d '"')

mapfile -t WALLPAPERS < <(find "$WALLPAPERS_DIR/$CURRENT_THEME" -type f \( -iname "*.jpg" -o -iname "*.png" \) | sort)

COUNT=${#WALLPAPERS[@]}
if [ "$COUNT" -eq 0 ]; then
  echo "Nenhum wallpaper encontrado para: $CURRENT_THEME"
  exit 1
fi

INDEX=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
INDEX=$(( (INDEX + 1) % COUNT ))
echo "$INDEX" > "$STATE_FILE"

WALLPAPER="${WALLPAPERS[$INDEX]}"
swww img "$WALLPAPER" --transition-type wave --transition-duration 1.5 --transition-wave 80,80

echo "$WALLPAPER" > "$THEMES_DIR/current-wallpaper"
sed -i "s|^  path    = .*|  path    = $WALLPAPER|" "$HOME/dotfiles/hyprlock.conf"

echo "Wallpaper: $(basename $WALLPAPER) ($((INDEX+1))/$COUNT)"

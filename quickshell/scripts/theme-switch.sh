#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/quickshell/themes"
CURRENT="$THEMES_DIR/current.json"
THEMES=("gruvbox" "rosepine" "nord")

get_val() {
  grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$2" | grep -o '"[^"]*"$' | tr -d '"'
}

CURRENT_NAME=$(get_val "name" "$CURRENT")

NEXT=""
for i in "${!THEMES[@]}"; do
  if [ "${THEMES[$i]}" = "$CURRENT_NAME" ]; then
    NEXT="${THEMES[$(( (i+1) % ${#THEMES[@]} ))]}"
    break
  fi
done
[ -z "$NEXT" ] && NEXT="gruvbox"

bash /home/ankh/.config/quickshell/scripts/set-theme.sh "$NEXT"

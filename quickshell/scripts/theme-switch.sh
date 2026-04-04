#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/quickshell/themes"
CURRENT="$THEMES_DIR/current.json"
THEMES=("gruvbox" "rosepine" "nord")
GSETTINGS="/run/current-system/sw/bin/gsettings"

get_json_value() {
  grep -o "\"$1\": *\"[^\"]*\"" "$2" | sed 's/.*: *"\(.*\)"/\1/'
}

CURRENT_NAME=$(get_json_value "name" "$CURRENT")

NEXT=""
for i in "${!THEMES[@]}"; do
  if [ "${THEMES[$i]}" = "$CURRENT_NAME" ]; then
    NEXT="${THEMES[$(( (i+1) % ${#THEMES[@]} ))]}"
    break
  fi
done
[ -z "$NEXT" ] && NEXT="gruvbox"

THEME_FILE="$THEMES_DIR/$NEXT.json"
cat "$THEME_FILE" > "$CURRENT"

MODE=$(get_json_value "mode" "$THEME_FILE")
ACCENT=$(get_json_value "accent" "$THEME_FILE")
BG0=$(get_json_value "bg0" "$THEME_FILE")
BG1=$(get_json_value "bg1" "$THEME_FILE")
TEXT0=$(get_json_value "text0" "$THEME_FILE")
TEXT1=$(get_json_value "text1" "$THEME_FILE")
TEXT2=$(get_json_value "text2" "$THEME_FILE")
TEXT3=$(get_json_value "text3" "$THEME_FILE")

# Opacidade: claro = 1.0, escuro = 0.92
if [ "$MODE" = "light" ]; then
  OPACITY="1.0"
else
  OPACITY="0.92"
fi

cat > "$HOME/dotfiles/kitty/colors.conf" << KITTYEOF
background $BG0
foreground $TEXT1
selection_background $ACCENT
selection_foreground $BG0
url_color $ACCENT
cursor $ACCENT
background_opacity $OPACITY
color0  #1a1a1e
color8  #3a3a3e
color1  #f28779
color9  #f28779
color2  #87c181
color10 #87c181
color3  #d9bc8c
color11 #d9bc8c
color4  #7bafd4
color12 #7bafd4
color5  $ACCENT
color13 $ACCENT
color6  #80c4c4
color14 #80c4c4
color7  $TEXT1
color15 $TEXT0
KITTYEOF

# GTK dark/light
if [ "$MODE" = "light" ]; then
  $GSETTINGS set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null
  $GSETTINGS set org.gnome.desktop.interface gtk-theme 'adw-gtk3' 2>/dev/null
else
  $GSETTINGS set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null
  $GSETTINGS set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null
fi

# Recarrega Kitty
kill -SIGUSR1 $(pgrep kitty) 2>/dev/null || true

pkill quickshell
sleep 0.5
nohup quickshell > /dev/null 2>&1 &
disown

echo "Tema trocado para: $NEXT ($MODE)"

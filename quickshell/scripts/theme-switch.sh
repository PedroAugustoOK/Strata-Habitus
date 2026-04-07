#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/quickshell/themes"
WALLPAPERS_DIR="$HOME/dotfiles/wallpapers"
CURRENT="$THEMES_DIR/current.json"
THEMES=("gruvbox" "rosepine" "nord")
DCONF="/run/current-system/sw/bin/dconf"
STATE_FILE="$THEMES_DIR/wallpaper-index"

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

THEME_FILE="$THEMES_DIR/$NEXT.json"
cat "$THEME_FILE" > "$CURRENT"

MODE=$(get_val "mode" "$THEME_FILE")
ACCENT=$(get_val "accent" "$THEME_FILE")
BG0=$(get_val "bg0" "$THEME_FILE")
BG1=$(get_val "bg1" "$THEME_FILE")
BG2=$(get_val "bg2" "$THEME_FILE")
TEXT0=$(get_val "text0" "$THEME_FILE")
TEXT1=$(get_val "text1" "$THEME_FILE")

[ "$MODE" = "light" ] && OPACITY="1.0" || OPACITY="0.92"

# Kitty
cat > "$HOME/dotfiles/kitty/colors.conf" << KITTYEOF
background $BG0
foreground $TEXT1
selection_background $ACCENT
selection_foreground $BG0
url_color $ACCENT
cursor $ACCENT
background_opacity $OPACITY
color5  $ACCENT
color13 $ACCENT
color7  $TEXT1
color15 $TEXT0
KITTYEOF

# GTK4 completo
mkdir -p "$HOME/.config/gtk-4.0"
cat > "$HOME/.config/gtk-4.0/gtk.css" << GTKEOF
@define-color accent_color $ACCENT;
@define-color accent_bg_color $ACCENT;
@define-color accent_fg_color $BG0;
@define-color destructive_color #f28779;
@define-color destructive_bg_color #f28779;
@define-color destructive_fg_color $BG0;
@define-color success_color #87c181;
@define-color success_bg_color #87c181;
@define-color success_fg_color $BG0;
@define-color warning_color #d9bc8c;
@define-color warning_bg_color #d9bc8c;
@define-color warning_fg_color $BG0;
@define-color error_color #f28779;
@define-color error_bg_color #f28779;
@define-color error_fg_color $BG0;
@define-color window_bg_color $BG0;
@define-color window_fg_color $TEXT1;
@define-color view_bg_color $BG0;
@define-color view_fg_color $TEXT1;
@define-color headerbar_bg_color $BG1;
@define-color headerbar_fg_color $TEXT1;
@define-color headerbar_border_color rgba(0,0,0,0.3);
@define-color headerbar_backdrop_color @window_bg_color;
@define-color headerbar_shade_color rgba(0,0,0,0.07);
@define-color headerbar_darker_shade_color rgba(0,0,0,0.07);
@define-color sidebar_bg_color $BG1;
@define-color sidebar_fg_color $TEXT1;
@define-color sidebar_backdrop_color @window_bg_color;
@define-color sidebar_shade_color rgba(0,0,0,0.07);
@define-color card_bg_color $BG2;
@define-color card_fg_color $TEXT1;
@define-color card_shade_color rgba(0,0,0,0.07);
@define-color dialog_bg_color $BG1;
@define-color dialog_fg_color $TEXT1;
@define-color popover_bg_color $BG2;
@define-color popover_fg_color $TEXT1;
@define-color popover_shade_color rgba(0,0,0,0.07);
@define-color shade_color rgba(0,0,0,0.07);
@define-color scrollbar_outline_color $ACCENT;
@define-color blue_1 $ACCENT;
@define-color blue_2 $ACCENT;
@define-color blue_3 $ACCENT;
@define-color blue_4 $ACCENT;
@define-color blue_5 $ACCENT;
GTKEOF

# GTK3

# GTK dark/light
if [ "$MODE" = "light" ]; then
  $DCONF write /org/gnome/desktop/interface/color-scheme "'prefer-light'" 2>/dev/null || true
else
  $DCONF write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null || true
fi

# Wallpaper cíclico
mapfile -t WALLPAPERS < <(find "$WALLPAPERS_DIR/$NEXT" -type f \( -iname "*.jpg" -o -iname "*.png" \) | sort)
COUNT=${#WALLPAPERS[@]}
if [ "$COUNT" -gt 0 ]; then
  INDEX=0
  echo "$INDEX" > "$STATE_FILE"
  WALLPAPER="${WALLPAPERS[$INDEX]}"
  swww img "$WALLPAPER" --transition-type wave --transition-duration 1.5 --transition-wave 80,80
fi

# Chromium policy
sudo mkdir -p /etc/chromium/policies/managed
printf '{"BrowserThemeColor":"%s"}' "$ACCENT" | sudo tee /etc/chromium/policies/managed/strata.json > /dev/null
kitty @ set-colors --all /home/ankh/dotfiles/kitty/colors.conf 2>/dev/null || true
hyprctl keyword "general:col.active_border" "rgba($(echo $ACCENT | tr -d '#')ff)"
pkill quickshell
sleep 0.5
nohup quickshell > /dev/null 2>&1 &
disown

echo "Tema trocado para: $NEXT ($MODE)"

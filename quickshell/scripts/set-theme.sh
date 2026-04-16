#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/quickshell/themes"
WALLPAPERS_DIR="$HOME/dotfiles/wallpapers"
DCONF="/run/current-system/sw/bin/dconf"
STATE_FILE="$THEMES_DIR/wallpaper-index"

NEXT="$1"
[ -z "$NEXT" ] && exit 1

THEME_FILE="$THEMES_DIR/$NEXT.json"
[ ! -f "$THEME_FILE" ] && exit 1

cat "$THEME_FILE" > "$THEMES_DIR/current.json"

get_val() {
  grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$2" | grep -o '"[^"]*"$' | tr -d '"'
}

MODE=$(get_val "mode" "$THEME_FILE")
ACCENT=$(get_val "accent" "$THEME_FILE")
BG0=$(get_val "bg0" "$THEME_FILE")
BG1=$(get_val "bg1" "$THEME_FILE")
BG2=$(get_val "bg2" "$THEME_FILE")
TEXT0=$(get_val "text0" "$THEME_FILE")
TEXT1=$(get_val "text1" "$THEME_FILE")

[ "$MODE" = "light" ] && OPACITY="1.0" || OPACITY="0.92"

# Cores ansi adaptadas ao modo
if [ "$MODE" = "light" ]; then
  C0="#2a2a2e"
  C7="#2a2a2a"
  C8="#4a4a4e"
  C15="#1a1a1a"
  C1="#b4637a"
  C2="#286e38"
  C3="#8a6a00"
  C4="#1a6a9a"
  C6="#1a7070"
else
  C0="#1a1a1e"
  C7="#cecece"
  C1="#f28779"
  C2="#87c181"
  C3="#d9bc8c"
  C4="#7bafd4"
  C6="#80c4c4"
  C8="#3a3a3e"
  C15="#f5f5f5"
fi

cat > "$HOME/dotfiles/kitty/colors.conf" << KITTYEOF
background $BG0
foreground $TEXT1
selection_background $ACCENT
selection_foreground $BG0
url_color $ACCENT
cursor $ACCENT
background_opacity $OPACITY
color0  $C0
color8  $C8
color1  $C1
color9  $C1
color2  $C2
color10 $C2
color3  $C3
color11 $C3
color4  $C4
color12 $C4
color5  $ACCENT
color13 $ACCENT
color6  $C6
color14 $C6
color7  $C7
color15 $C15
KITTYEOF

mkdir -p "$HOME/.config/gtk-4.0"
cat > "$HOME/.config/gtk-4.0/gtk.css" << GTKEOF
@define-color accent_color $ACCENT;
@define-color accent_bg_color $ACCENT;
@define-color accent_fg_color $BG0;
@define-color window_bg_color $BG0;
@define-color window_fg_color $TEXT1;
@define-color view_bg_color $BG0;
@define-color view_fg_color $TEXT1;
@define-color headerbar_bg_color $BG1;
@define-color headerbar_fg_color $TEXT1;
@define-color card_bg_color $BG2;
@define-color card_fg_color $TEXT1;
@define-color dialog_bg_color $BG1;
@define-color dialog_fg_color $TEXT1;
@define-color popover_bg_color $BG2;
@define-color popover_fg_color $TEXT1;
GTKEOF

printf '{"BrowserThemeColor":"%s"}' "$ACCENT" | sudo tee /etc/chromium/policies/managed/strata.json > /dev/null

if [ "$MODE" = "light" ]; then
  $DCONF write /org/gnome/desktop/interface/color-scheme "'prefer-light'" 2>/dev/null || true
else
  $DCONF write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null || true
fi

mapfile -t WALLPAPERS < <(find "$WALLPAPERS_DIR/$NEXT" -type f \( -iname "*.jpg" -o -iname "*.png" \) | sort)
COUNT=${#WALLPAPERS[@]}
if [ "$COUNT" -gt 0 ]; then
  INDEX=0
  echo "$INDEX" > "$STATE_FILE"
  WALLPAPER="${WALLPAPERS[$INDEX]}"
  swww img "$WALLPAPER" --transition-type wave --transition-duration 0.8 --transition-wave 80,80 &
  echo "$WALLPAPER" > "$HOME/.config/quickshell/themes/current-wallpaper"
fi

hyprctl keyword "general:col.active_border" "rgba($(echo $ACCENT | tr -d '#')ff)"
echo "Tema aplicado: $NEXT"

# Atualiza hyprlock com accent do tema atual
ACCENT_HEX=$(echo "$ACCENT" | tr -d '#')
R=$(printf "%d" 0x${ACCENT_HEX:0:2})
G=$(printf "%d" 0x${ACCENT_HEX:2:2})
B=$(printf "%d" 0x${ACCENT_HEX:4:2})
ACCENT_RGBA="rgba(${ACCENT_HEX}d9)"
ACCENT_RGBA_FF="rgba(${ACCENT_HEX}ff)"
sed -i "30s|rgba(.*)|rgba(${ACCENT_HEX}d9)|" ~/.config/hypr/hyprlock.conf
sed -i "73s|rgba(.*)|rgba(${ACCENT_HEX}ff)|" ~/.config/hypr/hyprlock.conf
# Atualiza cor no Main.qml do SDDM instalado
bash ~/.config/quickshell/scripts/update-sddm-accent.sh "$ACCENT" 2>/dev/null || true
sed -i "8s|path.*|path    = $(cat $HOME/.config/quickshell/themes/current-wallpaper)|" ~/.config/hypr/hyprlock.conf
# Atualiza SDDM theme
SDDM_THEME="/run/current-system/sw/share/sddm/themes/strata"
WALL_SRC="$(cat $HOME/.config/quickshell/themes/current-wallpaper)"
magick "$WALL_SRC" -scale 10% -scale 1920x1080! /tmp/strata-bg.jpg 2>/dev/null && sudo /run/current-system/sw/bin/cp /tmp/strata-bg.jpg /var/lib/strata/background.jpg 2>/dev/null & 
echo "accent=$ACCENT" > /tmp/strata-accent && sudo /run/current-system/sw/bin/tee /var/lib/strata/theme.conf < /tmp/strata-accent > /dev/null 2>/dev/null || true
# Recarrega fish em todas as sessões

# Atualiza cores do fish via config.fish
if [ "$MODE" = "light" ]; then
  sed -i "s/set -g fish_color_command.*/set -g fish_color_command        1a6a9a  # accent — comandos/" ~/.config/fish/config.fish
  sed -i "s/set -g fish_color_param.*/set -g fish_color_param          2a2a2a  # argumentos/" ~/.config/fish/config.fish
  sed -i "s/set -g fish_color_error.*/set -g fish_color_error          b4637a  # erros/" ~/.config/fish/config.fish
  sed -i "s/set -g fish_color_comment.*/set -g fish_color_comment        888888  # comentários/" ~/.config/fish/config.fish
  sed -i "s/set -g fish_color_quote.*/set -g fish_color_quote          286e38  # strings/" ~/.config/fish/config.fish
else
  sed -i "s/set -g fish_color_command.*/set -g fish_color_command        cf9fff  # accent — comandos/" ~/.config/fish/config.fish
  sed -i "s/set -g fish_color_param.*/set -g fish_color_param          e0e0e0  # argumentos/" ~/.config/fish/config.fish
  sed -i "s/set -g fish_color_error.*/set -g fish_color_error          f28779  # erros/" ~/.config/fish/config.fish
  sed -i "s/set -g fish_color_comment.*/set -g fish_color_comment        555555  # comentários/" ~/.config/fish/config.fish
  sed -i "s/set -g fish_color_quote.*/set -g fish_color_quote          d9bc8c  # strings/" ~/.config/fish/config.fish
fi
# Gera tema btop
mkdir -p ~/.config/btop/themes
cat > ~/.config/btop/themes/strata.theme << BTOPEOF
theme[main_bg]="$BG0"
theme[main_fg]="$TEXT1"
theme[title]="$ACCENT"
theme[hi_fg]="$ACCENT"
theme[selected_bg]="$BG2"
theme[selected_fg]="$TEXT1"
theme[inactive_fg]="$TEXT3"
theme[graph_text]="$ACCENT"
theme[meter_bg]="$BG2"
theme[proc_misc]="$ACCENT"
theme[cpu_box]="$ACCENT"
theme[mem_box]="$ACCENT"
theme[net_box]="$ACCENT"
theme[proc_box]="$ACCENT"
theme[div_line]="$BG2"
theme[temp_start]="$ACCENT"
theme[temp_mid]="$ACCENT"
theme[temp_end]="#f28779"
theme[cpu_start]="$ACCENT"
theme[cpu_mid]="$ACCENT"
theme[cpu_end]="#f28779"
theme[free_start]="$ACCENT"
theme[free_mid]="$ACCENT"
theme[free_end]="#f28779"
theme[cached_start]="$ACCENT"
theme[cached_mid]="$ACCENT"
theme[cached_end]="#f28779"
theme[available_start]="$ACCENT"
theme[available_mid]="$ACCENT"
theme[available_end]="#f28779"
theme[used_start]="$ACCENT"
theme[used_mid]="$ACCENT"
theme[used_end]="#f28779"
theme[download_start]="$ACCENT"
theme[download_mid]="$ACCENT"
theme[download_end]="#f28779"
theme[upload_start]="$ACCENT"
theme[upload_mid]="$ACCENT"
theme[upload_end]="#f28779"
BTOPEOF
sed -i "s/color_theme = .*/color_theme = "strata"/" ~/.config/btop/btop.conf

# Atualiza starship com cores do tema
if [ "$MODE" = "light" ]; then
  STAR_DIR="#1a6a9a"
  STAR_GIT="#286e38"
  STAR_CHAR="$ACCENT"
else
  STAR_DIR="#cf9fff"
  STAR_GIT="#87c181"
  STAR_CHAR="$ACCENT"
fi
cat > "$HOME/dotfiles/starship/starship.toml" << STAREOF
# Strata Habitus — Starship prompt
format = """\
\$directory\$git_branch\$git_status\$cmd_duration\$line_break\$character"""
add_newline = false
[directory]
style            = "bold $STAR_DIR"
truncation_length = 3
truncate_to_repo  = true
read_only        = " 󰌾"
read_only_style  = "#f28779"
format           = "[\$path](\$style)[\$read_only](\$read_only_style) "
[git_branch]
style  = "$STAR_GIT"
format = "[ \$branch](\$style) "
[git_status]
style  = "$STAR_CHAR"
format = "([\$all_status\$ahead_behind](\$style) )"
[cmd_duration]
style  = "dimmed $STAR_DIR"
format = "[ \${duration}](\$style) "
[character]
success_symbol = "[❯](bold $STAR_CHAR)"
error_symbol   = "[❯](bold red)"
STAREOF
pkill quickshell
sleep 0.5
nohup quickshell > /dev/null 2>&1 &
disown
echo "Tema aplicado: $NEXT"

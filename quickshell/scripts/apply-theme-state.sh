#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"
STATE_DIR="$DOTFILES/state"
GENERATED_DIR="$DOTFILES/generated"
THEME_FILE="$STATE_DIR/current-theme.json"
WALLPAPER_FILE="$STATE_DIR/current-wallpaper"
DCONF="/run/current-system/sw/bin/dconf"
AWWW="/run/current-system/sw/bin/awww"
AWWW_DAEMON="/run/current-system/sw/bin/awww-daemon"
LOG_FILE="$HOME/.cache/strata-theme.log"
APPLY_MODE="${1:-}"

mkdir -p "$HOME/.cache" "$STATE_DIR" \
  "$GENERATED_DIR/kitty" "$GENERATED_DIR/mako" "$GENERATED_DIR/starship" \
  "$GENERATED_DIR/fish" "$GENERATED_DIR/nvim" "$GENERATED_DIR/hypr" \
  "$GENERATED_DIR/satty" "$GENERATED_DIR/gtk/gtk-3.0" "$GENERATED_DIR/gtk/gtk-4.0"

get_val() {
  grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$2" | grep -o '"[^"]*"$' | tr -d '"'
}

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

find_hyprland_signature() {
  local runtime_dir candidate

  runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  [ -d "$runtime_dir/hypr" ] || return 1

  for candidate in "$runtime_dir"/hypr/*; do
    [ -d "$candidate" ] || continue
    [ -S "$candidate/.socket.sock" ] || continue
    basename "$candidate"
    return 0
  done

  return 1
}

ensure_hyprland_env() {
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

  if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    local signature
    signature="$(find_hyprland_signature 2>/dev/null || true)"
    if [ -n "$signature" ]; then
      export HYPRLAND_INSTANCE_SIGNATURE="$signature"
    fi
  fi
}

apply_hyprland_border() {
  local accent_hex="$1"

  ensure_hyprland_env
  log "hyprland signature=${HYPRLAND_INSTANCE_SIGNATURE:-<unset>}"

  if ! hyprctl keyword "general:col.active_border" "rgba(${accent_hex}ff)" >/dev/null 2>&1; then
    log "hyprctl failed to apply active border"
  fi

  if ! hyprctl keyword "general:col.inactive_border" "rgba(00000000)" >/dev/null 2>&1; then
    log "hyprctl failed to apply inactive border"
  fi
}

set_gsettings_string() {
  local schema="$1"
  local key="$2"
  local value="$3"
  gsettings set "$schema" "$key" "$value" 2>/dev/null || true
}

force_gtk_runtime_reload() {
  local gtk_theme="$1"
  local icon_theme="$2"
  local color_scheme="$3"
  local temp_theme temp_color temp_icon

  if [ "$gtk_theme" = "Adwaita" ]; then
    temp_theme="Adwaita-dark"
    temp_color="prefer-dark"
    temp_icon="Papirus-Dark"
  else
    temp_theme="Adwaita"
    temp_color="prefer-light"
    temp_icon="Papirus"
  fi

  set_gsettings_string org.gnome.desktop.interface gtk-theme "$temp_theme"
  set_gsettings_string org.gnome.desktop.interface color-scheme "$temp_color"
  set_gsettings_string org.gnome.desktop.interface icon-theme "$temp_icon"

  sleep 0.05

  set_gsettings_string org.gnome.desktop.interface gtk-theme "$gtk_theme"
  set_gsettings_string org.gnome.desktop.interface color-scheme "$color_scheme"
  set_gsettings_string org.gnome.desktop.interface icon-theme "$icon_theme"
}

restart_nautilus_for_theme() {
  if pgrep -x nautilus >/dev/null 2>&1; then
    nautilus -q >/dev/null 2>&1 || true
  fi
}

restart_portal_services_for_theme() {
  local -a units=(
    xdg-desktop-portal-gtk.service
    xdg-desktop-portal.service
  )
  local unit

  for unit in "${units[@]}"; do
    systemctl --user restart "$unit" >/dev/null 2>&1 || true
  done
}

refresh_chromium_theme() {
  local accent="$1"
  local browser_color_scheme="$2"
  local policy_json

  policy_json=$(printf '{"BrowserThemeColor":"%s","BrowserColorScheme":"%s"}' "$accent" "$browser_color_scheme")

  if ! printf '%s' "$policy_json" | sudo -n tee /etc/chromium/policies/managed/strata.json > /dev/null; then
    log "failed to write chromium policy"
    return 0
  fi

  mkdir -p "$HOME/.config/chromium/Default"
  printf '%s\n' "$accent" > "$HOME/.config/chromium/Default/strata-theme-color"

  if ! chromium --refresh-platform-policy --no-startup-window >/dev/null 2>&1; then
    log "chromium policy refresh command failed"
  fi
}

ensure_local_papirus() {
  local theme src dst local_theme
  mkdir -p "$HOME/.local/share/icons"

  for theme in Papirus Papirus-Dark; do
    src="/run/current-system/sw/share/icons/$theme"
    local_theme="$theme-Strata"
    dst="$HOME/.local/share/icons/$local_theme"

    [ -d "$src" ] || continue

    if [ -L "$dst" ]; then
      rm -f "$dst"
    elif [ -d "$dst" ] && [ ! -w "$dst" ]; then
      chmod -R u+rwX "$dst" 2>/dev/null || true
    fi

    [ -d "$dst" ] && continue

    cp -aL "$src" "$dst" 2>/dev/null || true
    chmod -R u+rwX "$dst" 2>/dev/null || true

    if [ -f "$dst/index.theme" ]; then
      sed -i "s/^Name=.*/Name=$local_theme/" "$dst/index.theme" 2>/dev/null || true
    fi
  done
}

recolor_papirus_theme() {
  local theme_dir="$1"
  local folder_color="$2"
  local size prefix file_path file_name symlink_path
  local sizes=("22x22" "24x24" "32x32" "48x48" "64x64")
  local prefixes=("folder" "user")

  [ -d "$theme_dir" ] || return 0

  for size in "${sizes[@]}"; do
    for prefix in "${prefixes[@]}"; do
      for file_path in "$theme_dir/$size/places/$prefix-$folder_color"{-*,}.svg; do
        [ -f "$file_path" ] || continue
        [ -L "$file_path" ] && continue

        file_name="${file_path##*/}"
        symlink_path="${file_path/-$folder_color/}"
        ln -sfn "$file_name" "$symlink_path"
      done
    done
  done
}

apply_papirus_folder_color() {
  local folder_color="$1"
  local light_theme="$HOME/.local/share/icons/Papirus-Strata"
  local dark_theme="$HOME/.local/share/icons/Papirus-Dark-Strata"

  ensure_local_papirus

  recolor_papirus_theme "$light_theme" "$folder_color"
  recolor_papirus_theme "$dark_theme" "$folder_color"
}

reload_kitty_theme() {
  local socket_path socket
  local -a sockets=()

  for socket_path in /tmp/kitty-socket /tmp/kitty-socket-*; do
    [ -S "$socket_path" ] || continue
    sockets+=("$socket_path")
  done

  [ "${#sockets[@]}" -gt 0 ] || return 0

  for socket_path in "${sockets[@]}"; do
    socket="unix:$socket_path"
    kitty @ --to "$socket" set-colors -a -c "$GENERATED_DIR/kitty/colors.conf" >/dev/null 2>&1 || true
  done
}

ensure_wayland_env() {
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

  if [ -z "${WAYLAND_DISPLAY:-}" ]; then
    local sock
    sock=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name 'wayland-*' | sort | head -n1)
    if [ -n "$sock" ]; then
      export WAYLAND_DISPLAY
      WAYLAND_DISPLAY="$(basename "$sock")"
    fi
  fi
}

apply_wallpaper() {
  local wallpaper="$1"
  local transition_type="center"
  local transition_duration="0.42"
  local transition_fps="144"
  local transition_step="28"
  local transition_bezier="0.16,1,0.30,1"

  ensure_wayland_env
  log "apply-theme-state wallpaper=$wallpaper xdg_runtime_dir=${XDG_RUNTIME_DIR:-<unset>} wayland_display=${WAYLAND_DISPLAY:-<unset>}"

  if ! "$AWWW" query >/dev/null 2>&1; then
    nohup "$AWWW_DAEMON" >/dev/null 2>&1 &
    sleep 0.4
  fi

  "$AWWW" img "$wallpaper" \
    --transition-type "$transition_type" \
    --transition-duration "$transition_duration" \
    --transition-fps "$transition_fps" \
    --transition-step "$transition_step" \
    --transition-bezier "$transition_bezier" >> "$LOG_FILE" 2>&1
}

update_wallpaper_targets() {
  local wallpaper="$1"
  local hyprlock_conf="$GENERATED_DIR/hypr/hyprlock.conf"

  mkdir -p "$GENERATED_DIR/hypr"

  if [ -f "$hyprlock_conf" ]; then
    sed -i "s|^[[:space:]]*path[[:space:]]*=.*$|  path    = $wallpaper|" "$hyprlock_conf" 2>/dev/null || true
  fi

  (
    if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
      magick "$wallpaper" -scale 10% -scale 1920x1080! /tmp/strata-bg.jpg 2>/dev/null \
        && sudo -n /run/current-system/sw/bin/cp /tmp/strata-bg.jpg /var/lib/strata/background.jpg 2>/dev/null || true
    fi
  ) >/dev/null 2>&1 &
}

[ -f "$THEME_FILE" ] || exit 1

WALLPAPER="$(cat "$WALLPAPER_FILE" 2>/dev/null || true)"

if [ "$APPLY_MODE" = "--wallpaper-only" ] && [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
  update_wallpaper_targets "$WALLPAPER"
  apply_wallpaper "$WALLPAPER"
  exit 0
fi

THEME_NAME=$(get_val "name" "$THEME_FILE")
MODE=$(get_val "mode" "$THEME_FILE")
ACCENT=$(get_val "accent" "$THEME_FILE")
BG0=$(get_val "bg0" "$THEME_FILE")
BG1=$(get_val "bg1" "$THEME_FILE")
BG2=$(get_val "bg2" "$THEME_FILE")
TEXT0=$(get_val "text0" "$THEME_FILE")
TEXT1=$(get_val "text1" "$THEME_FILE")
TEXT3=$(get_val "text3" "$THEME_FILE")

[ "$MODE" = "light" ] && OPACITY="0.97" || OPACITY="0.92"

TERM_BG="$BG0"
TERM_SELECTION_FG="$TERM_BG"
TERM_ACTIVE_TAB_FG="$TERM_BG"
TERM_INACTIVE_TAB_BG="$BG1"
PAPIRUS_FOLDER_COLOR="grey"

if [ "$MODE" = "light" ]; then
  TERM_BG="$BG2"
  TERM_SELECTION_FG="$TEXT0"
  TERM_ACTIVE_TAB_FG="$TEXT0"
  TERM_INACTIVE_TAB_BG="$BG1"
  C0="#2a2a2e"
  C7="#2a2a2a"
  C8="#4a4a4e"
  C15="#1a1a1a"
  C1="#b4637a"
  C2="#286e38"
  C3="#8a6a00"
  C4="#1a6a9a"
  C6="#1a7070"
  STAR_DIR="#1a6a9a"
  STAR_GIT="#286e38"
  NVIM_THEME="rose-pine-dawn"
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
  STAR_DIR="#cf9fff"
  STAR_GIT="#87c181"
  NVIM_THEME="nord"
fi

case "$THEME_NAME" in
  gruvbox)
    NVIM_THEME="gruvbox"
    PAPIRUS_FOLDER_COLOR="orange"
    ;;
  rosepine)
    NVIM_THEME="rose-pine-dawn"
    TERM_BG="#d7d0c8"
    TERM_SELECTION_FG="#2a2a2a"
    TERM_ACTIVE_TAB_FG="#faf4ed"
    TERM_INACTIVE_TAB_BG="#e1dbd3"
    OPACITY="0.985"
    PAPIRUS_FOLDER_COLOR="pink"
    ;;
  nord)
    NVIM_THEME="nord"
    PAPIRUS_FOLDER_COLOR="nordic"
    ;;
  tokyonight)
    NVIM_THEME="nord"
    PAPIRUS_FOLDER_COLOR="blue"
    ;;
  everforest)
    NVIM_THEME="gruvbox"
    PAPIRUS_FOLDER_COLOR="green"
    ;;
  kanagawa)
    NVIM_THEME="nord"
    PAPIRUS_FOLDER_COLOR="indigo"
    ;;
  catppuccinlatte)
    NVIM_THEME="rose-pine-dawn"
    TERM_BG="#d8dce5"
    TERM_SELECTION_FG="#303446"
    TERM_ACTIVE_TAB_FG="#eff1f5"
    TERM_INACTIVE_TAB_BG="#dde2ea"
    OPACITY="0.985"
    PAPIRUS_FOLDER_COLOR="blue"
    ;;
  flexoki)
    NVIM_THEME="rose-pine-dawn"
    TERM_BG="#e0ddd2"
    TERM_SELECTION_FG="#201f1f"
    TERM_ACTIVE_TAB_FG="#fffcf0"
    TERM_INACTIVE_TAB_BG="#ebe8dd"
    OPACITY="0.985"
    PAPIRUS_FOLDER_COLOR="yellow"
    ;;
  oxocarbon)
    NVIM_THEME="nord"
    PAPIRUS_FOLDER_COLOR="bluegrey"
    ;;
esac

cat > "$GENERATED_DIR/kitty/colors.conf" <<EOF
background $TERM_BG
foreground $TEXT1
selection_background $ACCENT
selection_foreground $TERM_SELECTION_FG
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
url_style            curly
open_url_with        default
detect_urls          yes
tab_bar_style              powerline
tab_powerline_style        slanted
tab_bar_min_tabs           2
tab_bar_margin_width       4
tab_bar_margin_height      4 0
active_tab_foreground      $TERM_ACTIVE_TAB_FG
active_tab_background      $ACCENT
active_tab_font_style      bold
inactive_tab_foreground    $TEXT3
inactive_tab_background    $TERM_INACTIVE_TAB_BG
inactive_tab_font_style    normal
tab_title_template         "  {title}  "
EOF

cat > "$GENERATED_DIR/mako/config" <<EOF
sort=-time
layer=overlay
anchor=top-right
on-button-left=dismiss
on-button-right=none
outer-margin=6,10,0,0
margin=10,14
padding=10,12
width=332
border-size=1
border-radius=14
background-color=$BG1
border-color=$ACCENT
text-color=$TEXT1
font=JetBrains Mono 9
default-timeout=6000
max-icon-size=32
icon-location=left
icon-border-radius=8
text-alignment=left
markup=1
actions=1
history=1
progress-color=over $ACCENT
icons=1
icon-path=/run/current-system/sw/share/icons/Papirus-Dark:/run/current-system/sw/share/icons/Papirus:/run/current-system/sw/share/icons/hicolor

format=<span size="x-small" color="$ACCENT">%a</span>\n<b>%s</b>\n<span size="x-small" color="$TEXT3">%b</span>

[urgency=low]
border-color=$TEXT3
text-color=$TEXT3
default-timeout=3000

[urgency=normal]
border-color=$ACCENT

[urgency=high]
border-size=2
border-color=#f28779
text-color=$TEXT0
default-timeout=0

[grouped]
format=<span size="x-small" color="$ACCENT">%a</span>\n<b>%s</b> <span size="x-small" color="$TEXT3">(%g)</span>\n<span size="x-small" color="$TEXT3">%b</span>
EOF

cat > "$GENERATED_DIR/starship/starship.toml" <<EOF
# Strata Habitus — Starship prompt
format = """\$directory\$git_branch\$git_status\$cmd_duration\$line_break\$character"""
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
style  = "$ACCENT"
format = "([\$all_status\$ahead_behind](\$style) )"
[cmd_duration]
style  = "dimmed $STAR_DIR"
format = "[ \${duration}](\$style) "
[character]
success_symbol = "[❯](bold $ACCENT)"
error_symbol   = "[❯](bold red)"
EOF

cat > "$GENERATED_DIR/fish/theme.fish" <<EOF
set -g fish_color_command        $( [ "$MODE" = "light" ] && echo "1a6a9a" || echo "cf9fff" )
set -g fish_color_param          $( [ "$MODE" = "light" ] && echo "2a2a2a" || echo "e0e0e0" )
set -g fish_color_error          $( [ "$MODE" = "light" ] && echo "b4637a" || echo "f28779" )
set -g fish_color_comment        $( [ "$MODE" = "light" ] && echo "888888" || echo "555555" )
set -g fish_color_quote          $( [ "$MODE" = "light" ] && echo "286e38" || echo "d9bc8c" )
set -g fish_color_redirection    $( [ "$MODE" = "light" ] && echo "1a6a9a" || echo "7bafd4" )
set -g fish_color_operator       $( [ "$MODE" = "light" ] && echo "1a7070" || echo "80c4c4" )
set -g fish_color_autosuggestion 444444
set -g fish_color_valid_path     --underline
EOF

cat > "$GENERATED_DIR/nvim/theme.lua" <<EOF
return "$NVIM_THEME"
EOF

cat > "$GENERATED_DIR/satty/config.toml" <<EOF
[general]
fullscreen = true
early-exit = false
corner-roundness = 12
initial-tool = "arrow"
copy-command = "wl-copy"
annotation-size-factor = 1.0
default-hide-toolbars = false
focus-toggles-toolbars = false
primary-highlighter = "block"
disable-notifications = true
actions-on-enter = ["save-to-clipboard", "save-to-file", "exit"]
actions-on-escape = ["exit"]
no-window-decoration = true
brush-smooth-history-size = 6

[font]
family = "Inter"
style = "Regular"

[color-palette]
palette = [
  "$ACCENT",
  "$TEXT1",
  "#f28779",
  "#d9bc8c",
  "#87c181",
  "#7bafd4",
]
custom = [
  "$ACCENT",
  "$TEXT1",
  "$BG0",
  "$BG1",
  "#f28779",
  "#d9bc8c",
  "#87c181",
  "#7bafd4",
]
EOF

ACCENT_HEX="$(echo "$ACCENT" | tr -d '#')"
TEXT1_HEX="$(echo "$TEXT1" | tr -d '#')"
cat > "$GENERATED_DIR/hypr/hyprlock.conf" <<EOF
general {
  disable_loading_bar = true
  hide_cursor         = true
}

background {
  monitor =
  path    = $WALLPAPER
  blur_passes  = 3
  blur_size    = 8
  brightness   = 0.6
}

label {
  monitor =
  text    = cmd[update:1000] date '+%H:%M'
  color   = rgba(${TEXT1_HEX}ee)
  font_size   = 64
  font_family = JetBrainsMono Nerd Font
  position    = 0, 120
  halign      = center
  valign      = center
}

label {
  monitor =
  text    = cmd[update:60000] date '+%A, %d de %B'
  color   = rgba(${ACCENT_HEX}88)
  font_size   = 14
  font_family = JetBrainsMono Nerd Font
  position    = 0, 60
  halign      = center
  valign      = center
}

input-field {
  monitor =
  size    = 280, 44
  outline_thickness = 1
  outer_color       = rgba(ffffff25)
  inner_color       = rgba(ffffff15)
  font_color        = rgba(ffffffe0)
  fade_on_empty     = false
  placeholder_text  = Password
  check_color       = rgba(${ACCENT_HEX}ff)
  fail_color        = rgba(ff6b6bff)
  fail_text         = Wrong password
  rounding          = 22
  position          = 0, -40
  halign            = center
  valign            = center
}
EOF

mkdir -p "$HOME/.config/btop/themes" "$HOME/.config/gtk-4.0"
cat > "$HOME/.config/btop/themes/strata.theme" <<EOF
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
EOF

mkdir -p "$HOME/.config/gtk-4.0" "$HOME/.config/gtk-3.0" "$HOME/.config/environment.d"

cat > "$HOME/.config/gtk-4.0/gtk.css" <<EOF
@define-color accent_color $ACCENT;
@define-color accent_bg_color $ACCENT;
@define-color accent_fg_color $TEXT0;
@define-color window_bg_color $BG1;
@define-color window_fg_color $TEXT1;
@define-color view_bg_color $BG1;
@define-color view_fg_color $TEXT1;
@define-color headerbar_bg_color $BG1;
@define-color headerbar_fg_color $TEXT1;
@define-color card_bg_color $BG2;
@define-color card_fg_color $TEXT1;
@define-color dialog_bg_color $BG1;
@define-color dialog_fg_color $TEXT1;
@define-color popover_bg_color $BG2;
@define-color popover_fg_color $TEXT1;

row:selected,
.navigation-sidebar row:selected,
sidebar row:selected {
  background-color: alpha($ACCENT, 0.16);
  color: $TEXT1;
  border-radius: 10px;
}

filechooser,
dialog.filechooser,
window.filechooser,
.dialog-action-area {
  color: $TEXT1;
}

filechooser box,
filechooser listview,
filechooser columnview,
filechooser treeview,
filechooser viewport,
filechooser stacksidebar,
filechooser placessidebar,
filechooser .sidebar,
filechooser .navigation-sidebar {
  background-color: $BG1;
  color: $TEXT1;
}

filechooser entry,
filechooser button,
filechooser label,
filechooser dropdown,
filechooser combobox,
filechooser popover {
  color: $TEXT1;
}
EOF

cat > "$HOME/.config/gtk-3.0/gtk.css" <<EOF
@define-color theme_selected_bg_color $ACCENT;
@define-color theme_selected_fg_color $TEXT1;
@define-color theme_base_color $BG1;
@define-color theme_bg_color $BG1;
@define-color theme_fg_color $TEXT1;
@define-color insensitive_bg_color $BG2;
@define-color insensitive_fg_color $TEXT3;
@define-color borders $BG2;
@define-color unfocused_borders $BG2;
@define-color wm_bg_a $BG1;
@define-color wm_bg_b $BG1;
@define-color wm_title $TEXT1;
@define-color headerbar_bg_color $BG1;
@define-color headerbar_fg_color $TEXT1;
@define-color popover_bg_color $BG2;
@define-color popover_fg_color $TEXT1;

GtkFileChooserDialog,
.filechooser,
.filechooser .sidebar,
.filechooser .view,
.filechooser treeview.view,
.filechooser viewport {
  background-color: $BG1;
  color: $TEXT1;
}
EOF

if [ "$MODE" = "light" ]; then
  GTK_THEME_NAME="Adwaita"
  ICON_THEME_NAME="Papirus-Strata"
  GTK_PREFER_DARK="0"
  CHROMIUM_COLOR_SCHEME="light"
  $DCONF write /org/gnome/desktop/interface/color-scheme "'prefer-light'" 2>/dev/null || true
  apply_papirus_folder_color "$PAPIRUS_FOLDER_COLOR"
  force_gtk_runtime_reload "$GTK_THEME_NAME" "$ICON_THEME_NAME" "prefer-light"
  restart_nautilus_for_theme
  echo "QT_STYLE_OVERRIDE=$GTK_THEME_NAME" > "$HOME/.config/environment.d/qt.conf"
else
  GTK_THEME_NAME="Adwaita-dark"
  ICON_THEME_NAME="Papirus-Dark-Strata"
  GTK_PREFER_DARK="1"
  CHROMIUM_COLOR_SCHEME="dark"
  $DCONF write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null || true
  apply_papirus_folder_color "$PAPIRUS_FOLDER_COLOR"
  force_gtk_runtime_reload "$GTK_THEME_NAME" "$ICON_THEME_NAME" "prefer-dark"
  restart_nautilus_for_theme
  echo "QT_STYLE_OVERRIDE=$GTK_THEME_NAME" > "$HOME/.config/environment.d/qt.conf"
fi

refresh_chromium_theme "$ACCENT" "$CHROMIUM_COLOR_SCHEME"

export GTK_THEME="$GTK_THEME_NAME"
echo "GTK_THEME=$GTK_THEME_NAME" > "$HOME/.config/environment.d/gtk-theme.conf"
systemctl --user import-environment GTK_THEME >/dev/null 2>&1 || true
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
  dbus-update-activation-environment --systemd GTK_THEME="$GTK_THEME_NAME" >/dev/null 2>&1 || true
fi

cat > "$GENERATED_DIR/gtk/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME_NAME
gtk-icon-theme-name=$ICON_THEME_NAME
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=$GTK_PREFER_DARK
EOF

cat > "$GENERATED_DIR/gtk/gtk-4.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME_NAME
gtk-icon-theme-name=$ICON_THEME_NAME
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=$GTK_PREFER_DARK
EOF

restart_portal_services_for_theme

reload_kitty_theme

bash "$DOTFILES/quickshell/scripts/update-sddm-accent.sh" "$ACCENT" 2>/dev/null || true
if [ -n "$WALLPAPER" ]; then
  magick "$WALLPAPER" -scale 10% -scale 1920x1080! /tmp/strata-bg.jpg 2>/dev/null \
    && sudo -n /run/current-system/sw/bin/cp /tmp/strata-bg.jpg /var/lib/strata/background.jpg 2>/dev/null || true
fi
echo "accent=$ACCENT" > /tmp/strata-accent
sudo -n /run/current-system/sw/bin/tee /var/lib/strata/theme.conf < /tmp/strata-accent > /dev/null 2>/dev/null || true

apply_hyprland_border "$ACCENT_HEX"
makoctl reload 2>/dev/null || true

if [ "$APPLY_MODE" = "--apply-wallpaper" ] && [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
  update_wallpaper_targets "$WALLPAPER"
  apply_wallpaper "$WALLPAPER"
fi

echo "Tema aplicado: $THEME_NAME"

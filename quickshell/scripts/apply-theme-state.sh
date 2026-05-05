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
NAUTILUS_WAS_RUNNING=0
LOCK_DIR="$HOME/.cache/strata-theme.lock"

cleanup_lock() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}

mkdir -p "$HOME/.cache" "$STATE_DIR" \
  "$GENERATED_DIR/kitty" "$GENERATED_DIR/mako" "$GENERATED_DIR/starship" \
  "$GENERATED_DIR/fish" "$GENERATED_DIR/nvim" "$GENERATED_DIR/hypr" \
  "$GENERATED_DIR/satty" "$GENERATED_DIR/gtk/gtk-3.0" "$GENERATED_DIR/gtk/gtk-4.0"

for _ in $(seq 1 100); do
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    break
  fi

  sleep 0.05
done

if [ ! -d "$LOCK_DIR" ]; then
  log "theme apply skipped: lock timeout"
  exit 0
fi

trap cleanup_lock EXIT

get_val() {
  /run/current-system/sw/bin/node -e '
    const [key, file] = process.argv.slice(1);
    const data = JSON.parse(require("fs").readFileSync(file, "utf8"));
    const value = key.split(".").reduce((obj, part) => obj && obj[part], data);
    if (value === undefined || value === null) process.exit(0);
    if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
      process.stdout.write(String(value));
    }
  ' "$1" "$2"
}

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

write_atomic() {
  local target="$1"
  local tmp

  mkdir -p "$(dirname "$target")"
  tmp="$(mktemp "${target}.tmp.XXXXXX")"
  cat > "$tmp"
  mv "$tmp" "$target"
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
  ensure_hyprland_env
  log "hyprland signature=${HYPRLAND_INSTANCE_SIGNATURE:-<unset>}"

  if ! hyprctl keyword "general:col.active_border" "rgba(00000000)" >/dev/null 2>&1; then
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

apply_gtk_runtime_settings() {
  local icon_theme="$1"
  local color_scheme="$2"

  set_gsettings_string org.gnome.desktop.interface gtk-theme "Adwaita"
  set_gsettings_string org.gnome.desktop.interface color-scheme "$color_scheme"
  set_gsettings_string org.gnome.desktop.interface icon-theme "$icon_theme"
}

stop_nautilus_for_theme() {
  local attempt

  if ! pgrep -x nautilus >/dev/null 2>&1; then
    NAUTILUS_WAS_RUNNING=0
    return 0
  fi

  NAUTILUS_WAS_RUNNING=1
  nautilus -q >/dev/null 2>&1 || true

  for attempt in $(seq 1 40); do
    if ! pgrep -x nautilus >/dev/null 2>&1; then
      return 0
    fi

    sleep 0.05
  done
}

restart_nautilus_for_theme() {
  if [ "$NAUTILUS_WAS_RUNNING" -ne 1 ]; then
    return 0
  fi

  nohup env -u GTK_THEME nautilus --new-window >/dev/null 2>&1 &
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

  if ! printf '%s' "$policy_json" | sudo -n tee /etc/chromium/policies/managed/strata.json > /dev/null 2>> "$LOG_FILE"; then
    log "failed to write chromium policy"
    return 0
  fi

  mkdir -p "$HOME/.config/chromium/Default"
  printf '%s\n' "$accent" > "$HOME/.config/chromium/Default/strata-theme-color"

  if ! chromium --refresh-platform-policy --no-startup-window >/dev/null 2>&1; then
    log "chromium policy refresh command failed"
  fi
}

find_colloid_theme_dir() {
  local mode="$1"
  local scheme="$2"
  local color="$3"
  local best_dir=""
  local best_score=-1
  local candidate base lower score token
  local known_schemes="nord dracula gruvbox everforest catppuccin"
  local known_colors="purple pink red orange yellow green teal grey"

  for candidate in /run/current-system/sw/share/icons/Colloid*; do
    [ -d "$candidate" ] || continue
    [ -f "$candidate/index.theme" ] || continue

    base="$(basename "$candidate")"
    lower="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')"
    score=0

    if [ "$mode" = "dark" ]; then
      [[ "$lower" == *dark* ]] && score=$((score + 8))
      [[ "$lower" == *light* ]] && score=$((score - 3))
    else
      [[ "$lower" == *light* ]] && score=$((score + 8))
      [[ "$lower" == *dark* ]] && score=$((score - 3))
      [[ "$lower" != *light* && "$lower" != *dark* ]] && score=$((score + 4))
    fi

    if [ "$scheme" = "default" ]; then
      for token in $known_schemes; do
        [[ "$lower" == *"$token"* ]] && score=$((score - 2))
      done
    elif [[ "$lower" == *"$scheme"* ]]; then
      score=$((score + 6))
    fi

    if [ "$color" = "default" ]; then
      for token in $known_colors; do
        [[ "$lower" == *"$token"* ]] && score=$((score - 2))
      done
    elif [[ "$lower" == *"$color"* ]]; then
      score=$((score + 6))
    fi

    if [ "$score" -gt "$best_score" ]; then
      best_dir="$candidate"
      best_score="$score"
    fi
  done

  [ -n "$best_dir" ] && printf '%s\n' "$best_dir"
}

link_colloid_theme_alias() {
  local alias_name="$1"
  local target_dir="$2"
  local alias_dir="$HOME/.local/share/icons/$alias_name"
  local inherits_name
  local spotify_source
  local size panel_dir apps_dir categories_dir
  local dir_list=""

  mkdir -p "$HOME/.local/share/icons"
  rm -rf "$alias_dir"
  mkdir -p "$alias_dir"

  inherits_name="$(basename "$target_dir")"

  write_atomic "$alias_dir/index.theme" <<EOF
[Icon Theme]
Name=$alias_name
Comment=Strata icon overlay for $inherits_name
Inherits=$inherits_name,hicolor
Directories=
EOF

  spotify_source="$(find /run/current-system/sw/share/icons/hicolor -path '*/apps/spotify-client.png' | sort | head -n1)"

  if [ -n "$spotify_source" ] && [ -f "$spotify_source" ]; then
    for size in 16x16 22x22 24x24 32x32 48x48; do
      panel_dir="$alias_dir/$size/panel"
      apps_dir="$alias_dir/$size/apps"
      categories_dir="$alias_dir/$size/categories"
      mkdir -p "$panel_dir" "$apps_dir" "$categories_dir"
      ln -sfn "$spotify_source" "$panel_dir/spotify-indicator.png"
      ln -sfn "$spotify_source" "$panel_dir/spotify-linux-32.png"
      ln -sfn "$spotify_source" "$apps_dir/spotify-client.png"
      ln -sfn "$spotify_source" "$apps_dir/spotify.png"
      ln -sfn "$spotify_source" "$categories_dir/spotify-client.png"
      ln -sfn "$spotify_source" "$categories_dir/spotify.png"
      dir_list="${dir_list}${size}/panel,${size}/apps,${size}/categories,"
    done
  fi

  dir_list="${dir_list%,}"

  write_atomic "$alias_dir/index.theme" <<EOF
[Icon Theme]
Name=$alias_name
Comment=Strata icon overlay for $inherits_name
Inherits=$inherits_name,hicolor
Directories=$dir_list
EOF

  for size in 16x16 22x22 24x24 32x32 48x48; do
    cat >> "$alias_dir/index.theme" <<EOF

[${size}/panel]
Size=${size%x*}
Context=Status
Type=Threshold

[${size}/apps]
Size=${size%x*}
Context=Applications
Type=Threshold

[${size}/categories]
Size=${size%x*}
Context=Categories
Type=Threshold
EOF
  done
}

apply_colloid_icon_theme() {
  local scheme="$1"
  local color="$2"
  local light_dir dark_dir

  light_dir="$(find_colloid_theme_dir light "$scheme" "$color")"
  dark_dir="$(find_colloid_theme_dir dark "$scheme" "$color")"

  [ -n "$light_dir" ] && link_colloid_theme_alias "Colloid-Strata-Light" "$light_dir"
  [ -n "$dark_dir" ] && link_colloid_theme_alias "Colloid-Strata-Dark" "$dark_dir"
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
  local transition_type="grow"
  local transition_duration="0.34"
  local transition_fps="144"
  local transition_step="90"
  local transition_bezier="0.23,1,0.61,1"

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
    --transition-pos "0.5,0.5" \
    --transition-bezier "$transition_bezier" >> "$LOG_FILE" 2>&1
}

update_wallpaper_targets() {
  local wallpaper="$1"
  local hyprlock_conf="$GENERATED_DIR/hypr/hyprlock.conf"

  mkdir -p "$GENERATED_DIR/hypr"

  if [ -f "$hyprlock_conf" ]; then
    sed -i "s|^[[:space:]]*path[[:space:]]*=.*$|  path    = $wallpaper|" "$hyprlock_conf" 2>/dev/null || true
  fi

  render_sddm_background "$wallpaper"
}

render_sddm_background() {
  local wallpaper="$1"

  (
    if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
      magick "$wallpaper" \
        -auto-orient \
        -resize 20% \
        -blur 0x10 \
        -resize 1920x1080^ \
        -gravity center \
        -extent 1920x1080 \
        /tmp/strata-sddm-bg.jpg 2>/dev/null \
        && sudo -n /run/current-system/sw/bin/cp /tmp/strata-sddm-bg.jpg /var/lib/strata/background.jpg 2>/dev/null || true
    fi
  ) >/dev/null 2>&1 &
}

[ -f "$THEME_FILE" ] || exit 1

WALLPAPER="$(cat "$WALLPAPER_FILE" 2>/dev/null || true)"
WALLPAPER_APPLIED_EARLY=0

if [ "$APPLY_MODE" = "--wallpaper-only" ] && [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
  update_wallpaper_targets "$WALLPAPER"
  apply_wallpaper "$WALLPAPER"
  exit 0
fi

if [ "$APPLY_MODE" = "--apply-wallpaper" ] && [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
  update_wallpaper_targets "$WALLPAPER"
  apply_wallpaper "$WALLPAPER"
  WALLPAPER_APPLIED_EARLY=1
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
PRIMARY=$(get_val "semantic.primary" "$THEME_FILE")
SECONDARY=$(get_val "semantic.secondary" "$THEME_FILE")
SUCCESS=$(get_val "semantic.success" "$THEME_FILE")
WARNING=$(get_val "semantic.warning" "$THEME_FILE")
DANGER=$(get_val "semantic.danger" "$THEME_FILE")
INFO=$(get_val "semantic.info" "$THEME_FILE")
BAR_BACKGROUND=$(get_val "ui.bar.background" "$THEME_FILE")
BAR_PILL=$(get_val "ui.bar.pill" "$THEME_FILE")
PANEL_BACKGROUND=$(get_val "ui.panel.background" "$THEME_FILE")
PANEL_RAISED=$(get_val "ui.panel.raised" "$THEME_FILE")

[ -n "$PRIMARY" ] || PRIMARY="$ACCENT"
[ -n "$SECONDARY" ] || SECONDARY="$ACCENT"
[ -n "$SUCCESS" ] || SUCCESS="#87c181"
[ -n "$WARNING" ] || WARNING="#d9bc8c"
[ -n "$DANGER" ] || DANGER="#f28779"
[ -n "$INFO" ] || INFO="$SECONDARY"
[ -n "$BAR_BACKGROUND" ] || BAR_BACKGROUND="$BG1"
[ -n "$BAR_PILL" ] || BAR_PILL="$BG2"
[ -n "$PANEL_BACKGROUND" ] || PANEL_BACKGROUND="$BG1"
[ -n "$PANEL_RAISED" ] || PANEL_RAISED="$BG2"

[ "$MODE" = "light" ] && OPACITY="0.89" || OPACITY="0.84"

TERM_BG="$BG0"
TERM_SELECTION_FG="$TERM_BG"
TERM_ACTIVE_TAB_FG="$TERM_BG"
TERM_INACTIVE_TAB_BG="$BG1"
ICON_SCHEME_VARIANT="default"
ICON_COLOR_VARIANT="default"

if [ "$MODE" = "light" ]; then
  TERM_BG="$BG2"
  TERM_SELECTION_FG="$TEXT0"
  TERM_ACTIVE_TAB_FG="$TEXT0"
  TERM_INACTIVE_TAB_BG="$BG1"
  C0="#2a2a2e"
  C7="#2a2a2a"
  C8="#4a4a4e"
  C15="#1a1a1a"
  C1="$DANGER"
  C2="$SUCCESS"
  C3="$WARNING"
  C4="$INFO"
  C6="$SECONDARY"
  STAR_DIR="$INFO"
  STAR_GIT="$SUCCESS"
  NVIM_THEME="rose-pine-dawn"
else
  C0="#1a1a1e"
  C7="#cecece"
  C1="$DANGER"
  C2="$SUCCESS"
  C3="$WARNING"
  C4="$INFO"
  C6="$SECONDARY"
  C8="#3a3a3e"
  C15="#f5f5f5"
  STAR_DIR="$SECONDARY"
  STAR_GIT="$SUCCESS"
  NVIM_THEME="nord"
fi

case "$THEME_NAME" in
  gruvbox)
    NVIM_THEME="gruvbox"
    ICON_COLOR_VARIANT="orange"
    ;;
  rosepine)
    NVIM_THEME="rose-pine-dawn"
    TERM_BG="#d7d0c8"
    TERM_SELECTION_FG="#2a2a2a"
    TERM_ACTIVE_TAB_FG="#faf4ed"
    TERM_INACTIVE_TAB_BG="#e1dbd3"
    OPACITY="0.89"
    ICON_COLOR_VARIANT="pink"
    ;;
  nord)
    NVIM_THEME="nord"
    ICON_COLOR_VARIANT="grey"
    ;;
  tokyonight)
    NVIM_THEME="nord"
    ICON_COLOR_VARIANT="purple"
    ;;
  everforest)
    NVIM_THEME="gruvbox"
    ICON_COLOR_VARIANT="green"
    ;;
  kanagawa)
    NVIM_THEME="nord"
    ICON_COLOR_VARIANT="purple"
    ;;
  catppuccinlatte)
    NVIM_THEME="rose-pine-dawn"
    TERM_BG="#d8dce5"
    TERM_SELECTION_FG="#303446"
    TERM_ACTIVE_TAB_FG="#eff1f5"
    TERM_INACTIVE_TAB_BG="#dde2ea"
    OPACITY="0.89"
    ICON_COLOR_VARIANT="pink"
    ;;
  flexoki)
    NVIM_THEME="rose-pine-dawn"
    TERM_BG="#e0ddd2"
    TERM_SELECTION_FG="#201f1f"
    TERM_ACTIVE_TAB_FG="#fffcf0"
    TERM_INACTIVE_TAB_BG="#ebe8dd"
    OPACITY="0.89"
    ICON_COLOR_VARIANT="orange"
    ;;
  oxocarbon)
    NVIM_THEME="nord"
    ICON_COLOR_VARIANT="grey"
    ;;
esac

cat > "$GENERATED_DIR/kitty/colors.conf" <<EOF
background $TERM_BG
foreground $TEXT1
selection_background $PRIMARY
selection_foreground $TERM_SELECTION_FG
url_color $SECONDARY
cursor $PRIMARY
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
color5  $PRIMARY
color13 $SECONDARY
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
active_tab_background      $PRIMARY
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
outer-margin=0
margin=0
padding=0
width=1
height=1
border-size=0
border-radius=0
background-color=#00000000
border-color=#00000000
text-color=#00000000
font=JetBrains Mono 9
default-timeout=3000
max-visible=1
max-history=100
max-icon-size=1
icon-location=left
icon-border-radius=0
text-alignment=left
markup=1
actions=1
history=1
progress-color=over #00000000
icons=1
icon-path=$HOME/.local/share/icons:/run/current-system/sw/share/icons:/run/current-system/sw/share/icons/hicolor

format=<span size="x-small" color="$SECONDARY">%a</span>\n<b>%s</b>\n<span size="x-small" color="$TEXT3">%b</span>

[urgency=low]
border-color=#00000000
text-color=#00000000
default-timeout=3000

[urgency=normal]
border-color=#00000000

[urgency=high]
border-size=0
border-color=#00000000
text-color=#00000000
default-timeout=9000

[mode=do-not-disturb]
invisible=1

[grouped]
format=<span size="x-small" color="$SECONDARY">%a</span>\n<b>%s</b> <span size="x-small" color="$TEXT3">(%g)</span>\n<span size="x-small" color="$TEXT3">%b</span>
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
style  = "$PRIMARY"
format = "([\$all_status\$ahead_behind](\$style) )"
[cmd_duration]
style  = "dimmed $STAR_DIR"
format = "[ \${duration}](\$style) "
[character]
success_symbol = "[❯](bold $PRIMARY)"
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
  "$PRIMARY",
  "$TEXT1",
  "$DANGER",
  "$WARNING",
  "$SUCCESS",
  "$INFO",
]
custom = [
  "$PRIMARY",
  "$TEXT1",
  "$BG0",
  "$BG1",
  "$DANGER",
  "$WARNING",
  "$SUCCESS",
  "$INFO",
]
EOF

ACCENT_HEX="$(echo "$PRIMARY" | tr -d '#')"
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
theme[title]="$PRIMARY"
theme[hi_fg]="$PRIMARY"
theme[selected_bg]="$BG2"
theme[selected_fg]="$TEXT1"
theme[inactive_fg]="$TEXT3"
theme[graph_text]="$SECONDARY"
theme[meter_bg]="$BG2"
theme[proc_misc]="$PRIMARY"
theme[cpu_box]="$INFO"
theme[mem_box]="$SUCCESS"
theme[net_box]="$SECONDARY"
theme[proc_box]="$PRIMARY"
theme[div_line]="$BG2"
theme[temp_start]="$WARNING"
theme[temp_mid]="$WARNING"
theme[temp_end]="$DANGER"
theme[cpu_start]="$INFO"
theme[cpu_mid]="$WARNING"
theme[cpu_end]="$DANGER"
theme[free_start]="$SUCCESS"
theme[free_mid]="$SUCCESS"
theme[free_end]="$DANGER"
theme[cached_start]="$SECONDARY"
theme[cached_mid]="$SECONDARY"
theme[cached_end]="$DANGER"
theme[available_start]="$SUCCESS"
theme[available_mid]="$SUCCESS"
theme[available_end]="$DANGER"
theme[used_start]="$PRIMARY"
theme[used_mid]="$WARNING"
theme[used_end]="$DANGER"
theme[download_start]="$INFO"
theme[download_mid]="$SECONDARY"
theme[download_end]="$DANGER"
theme[upload_start]="$SECONDARY"
theme[upload_mid]="$WARNING"
theme[upload_end]="$DANGER"
EOF

mkdir -p "$GENERATED_DIR/gtk/gtk-4.0" "$GENERATED_DIR/gtk/gtk-3.0" "$HOME/.config/environment.d"

stop_nautilus_for_theme

write_atomic "$GENERATED_DIR/gtk/gtk-4.0/gtk.css" <<EOF
@define-color accent_color $PRIMARY;
@define-color accent_bg_color $PRIMARY;
@define-color accent_fg_color $TEXT0;

row:selected,
.navigation-sidebar row:selected,
sidebar row:selected {
  background-color: alpha($PRIMARY, 0.16);
  border-radius: 10px;
}
EOF

write_atomic "$GENERATED_DIR/gtk/gtk-3.0/gtk.css" <<EOF
@define-color theme_selected_bg_color $PRIMARY;
@define-color theme_selected_fg_color $TEXT1;
EOF

if [ "$MODE" = "light" ]; then
  GTK_THEME_NAME="Adwaita"
  QT_THEME_NAME="adwaita"
  ICON_THEME_NAME="Colloid-Strata-Light"
  GTK_PREFER_DARK="0"
  CHROMIUM_COLOR_SCHEME="light"
  apply_colloid_icon_theme "$ICON_SCHEME_VARIANT" "$ICON_COLOR_VARIANT"
  GTK_COLOR_SCHEME="prefer-light"
else
  GTK_THEME_NAME="Adwaita"
  QT_THEME_NAME="adwaita-dark"
  ICON_THEME_NAME="Colloid-Strata-Dark"
  GTK_PREFER_DARK="1"
  CHROMIUM_COLOR_SCHEME="dark"
  apply_colloid_icon_theme "$ICON_SCHEME_VARIANT" "$ICON_COLOR_VARIANT"
  GTK_COLOR_SCHEME="prefer-dark"
fi

refresh_chromium_theme "$ACCENT" "$CHROMIUM_COLOR_SCHEME"

write_atomic "$HOME/.config/environment.d/qt.conf" <<EOF
QT_STYLE_OVERRIDE=$QT_THEME_NAME
EOF
rm -f "$HOME/.config/environment.d/gtk-theme.conf"
systemctl --user unset-environment GTK_THEME >/dev/null 2>&1 || true
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
  dbus-update-activation-environment --systemd GTK_THEME= >/dev/null 2>&1 || true
fi

write_atomic "$GENERATED_DIR/gtk/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME_NAME
gtk-icon-theme-name=$ICON_THEME_NAME
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=$GTK_PREFER_DARK
EOF

write_atomic "$GENERATED_DIR/gtk/gtk-4.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME_NAME
gtk-icon-theme-name=$ICON_THEME_NAME
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=$GTK_PREFER_DARK
EOF

$DCONF write /org/gnome/desktop/interface/color-scheme "'$GTK_COLOR_SCHEME'" 2>/dev/null || true
apply_gtk_runtime_settings "$ICON_THEME_NAME" "$GTK_COLOR_SCHEME"
restart_portal_services_for_theme
sleep 0.12
restart_nautilus_for_theme

reload_kitty_theme

bash "$DOTFILES/quickshell/scripts/update-sddm-accent.sh" "$PRIMARY" 2>/dev/null || true
render_sddm_background "$WALLPAPER"
echo "accent=$PRIMARY" > /tmp/strata-accent
sudo -n /run/current-system/sw/bin/tee /var/lib/strata/theme.conf < /tmp/strata-accent > /dev/null 2>/dev/null || true

apply_hyprland_border "$ACCENT_HEX"
makoctl reload 2>/dev/null || true

if [ "$APPLY_MODE" = "--apply-wallpaper" ] && [ "$WALLPAPER_APPLIED_EARLY" != "1" ] && [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
  update_wallpaper_targets "$WALLPAPER"
  apply_wallpaper "$WALLPAPER"
fi

echo "Tema aplicado: $THEME_NAME"

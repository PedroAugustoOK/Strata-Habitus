#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-area}"
ACTION="${2:-copysave}"

THEME_FILE="$HOME/dotfiles/state/current-theme.json"

get_val() {
  grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$2" 2>/dev/null | grep -o '"[^"]*"$' | tr -d '"'
}

launch_editor() {
  local file="$1"

  if command -v satty >/dev/null 2>&1; then
    satty --filename "$file" --fullscreen --output-filename "$file" >/dev/null 2>&1 &
    disown || true
    return 0
  fi

  notify-send -a "Strata Screenshot" -u normal "Satty indisponivel" "Instale/aplique o rebuild para usar edicao." >/dev/null 2>&1 || true
  return 1
}

notify_async() {
  local file="$1"
  local title="$2"
  local body="$3"

  (
    local choice=""
    choice="$(notify-send \
      -a "Strata Screenshot" \
      -i "$file" \
      -h "string:image-path:$file" \
      -A "open=Abrir" \
      -A "edit=Editar" \
      -A "folder=Pasta" \
      -A "path=Copiar caminho" \
      "$title" \
      "$body" \
      --wait 2>/dev/null || true)"

    case "$choice" in
      open)
        xdg-open "$file" >/dev/null 2>&1 || true
        ;;
      edit)
        launch_editor "$file" || true
        ;;
      folder)
        xdg-open "$(dirname "$file")" >/dev/null 2>&1 || true
        ;;
      path)
        printf '%s' "$file" | wl-copy >/dev/null 2>&1 || true
        ;;
    esac
  ) >/dev/null 2>&1 &
}

error_notify() {
  notify-send -a "Strata Screenshot" -u critical "Falha ao capturar" "$1" >/dev/null 2>&1 || true
}

find_grim_bin() {
  if command -v grim >/dev/null 2>&1; then
    command -v grim
    return 0
  fi

  if command -v grimblast >/dev/null 2>&1; then
    local wrapper grim_dir
    wrapper="$(command -v grimblast)"
    grim_dir="$(grep -o "/nix/store/[^']*-grim-[^']*/bin" "$wrapper" 2>/dev/null | head -n1 || true)"
    if [ -n "$grim_dir" ] && [ -x "$grim_dir/grim" ]; then
      printf '%s\n' "$grim_dir/grim"
      return 0
    fi
  fi

  return 1
}

wait_overlay_geometry() {
  command -v quickshell >/dev/null 2>&1 || return 1

  local request state_dir result_file line
  OVERLAY_GEOM=""
  request="shot-$$-$RANDOM-$(date '+%s%N')"
  state_dir="${XDG_RUNTIME_DIR:-/tmp}/strata-screenshot"
  result_file="$state_dir/$request.geom"
  rm -f "$result_file"
  mkdir -p "$state_dir"

  if ! quickshell ipc call screenshot select "$request"; then
    return 1
  fi

  for _ in $(seq 1 350); do
    if [ -s "$result_file" ]; then
      line="$(cat "$result_file" 2>/dev/null || true)"
      rm -f "$result_file"
      if [ "$line" = "cancel" ]; then
        return 130
      fi
      OVERLAY_GEOM="$line"
      return 0
    fi
    sleep 0.02
  done

  rm -f "$result_file"
  return 130
}

capture_area_with_overlay() {
  local file="$1"
  local action="$2"
  local geom capture_file grim_bin

  grim_bin="$(find_grim_bin)" || return 1

  wait_overlay_geometry
  local code=$?
  if [ "$code" -ne 0 ]; then
    [ "$code" -eq 130 ] && return 130
    return 1
  fi
  geom="$OVERLAY_GEOM"

  case "$geom" in
    *,*" "*x*) ;;
    *) return 1 ;;
  esac

  capture_file="$file"
  if [ "$action" = "copy" ]; then
    capture_file="${XDG_RUNTIME_DIR:-/tmp}/strata-screenshot/shot-$$-$RANDOM.png"
  fi

  mkdir -p "$(dirname "$capture_file")"

  if ! "$grim_bin" -g "$geom" "$capture_file" >/dev/null 2>&1; then
    error_notify "grim falhou na geometria $geom"
    return 2
  fi

  case "$action" in
    copy)
      wl-copy < "$capture_file" >/dev/null 2>&1 || true
      rm -f "$capture_file"
      notify-send -a "Strata Screenshot" "Captura copiada" "Regiao selecionada" >/dev/null 2>&1 || true
      ;;
    save)
      notify_async "$capture_file" "Captura salva" "$(basename "$capture_file")"
      ;;
    copysave)
      wl-copy < "$capture_file" >/dev/null 2>&1 || true
      notify_async "$capture_file" "Captura salva" "$(basename "$capture_file")
Copiada para a area de transferencia"
      ;;
    edit)
      launch_editor "$capture_file" || return 2
      notify-send -a "Strata Screenshot" "Captura aberta no editor" "$(basename "$capture_file")" >/dev/null 2>&1 || true
      ;;
  esac

  return 0
}

build_slurp_args() {
  local accent bg0 bg1
  accent="$(get_val "accent" "$THEME_FILE")"
  bg0="$(get_val "bg0" "$THEME_FILE")"
  bg1="$(get_val "bg1" "$THEME_FILE")"

  accent="${accent#\#}"
  bg0="${bg0#\#}"
  bg1="${bg1#\#}"

  if [ -z "$accent" ] || [ -z "$bg0" ] || [ -z "$bg1" ]; then
    printf '%s\n' "-b 1a1a1acc -c cf9fffff -s cf9fff26 -w 2"
    return
  fi

  printf '%s\n' "-b ${bg0}cc -c ${accent}ff -s ${accent}26 -w 2"
}

case "$TARGET" in
  area|screen|output|active)
    ;;
  *)
    error_notify "alvo invalido: $TARGET"
    exit 1
    ;;
esac

case "$ACTION" in
  copy|save|copysave|edit)
    ;;
  *)
    error_notify "acao invalida: $ACTION"
    exit 1
    ;;
esac

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || true)"
[ -n "$PICTURES_DIR" ] || PICTURES_DIR="$HOME/Imagens"
SCREENSHOT_DIR="${XDG_SCREENSHOTS_DIR:-$PICTURES_DIR/Screenshots}"

mkdir -p "$SCREENSHOT_DIR"

STAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
FILE="$SCREENSHOT_DIR/Strata_${STAMP}.png"

if [ "$TARGET" = "area" ]; then
  set +e
  capture_area_with_overlay "$FILE" "$ACTION"
  overlay_status=$?
  set -e

  case "$overlay_status" in
    0|130)
      exit 0
      ;;
  esac
fi

export SLURP_ARGS
SLURP_ARGS="$(build_slurp_args)"

GRIMBLAST_ARGS=()
if [ "$TARGET" = "area" ]; then
  GRIMBLAST_ARGS+=(--freeze)
fi

if [ "$ACTION" = "edit" ]; then
  if ! grimblast "${GRIMBLAST_ARGS[@]}" save "$TARGET" "$FILE" >/dev/null 2>&1; then
    error_notify "grimblast falhou em edit $TARGET"
    exit 1
  fi

  launch_editor "$FILE" || exit 1
  notify-send -a "Strata Screenshot" "Captura aberta no editor" "$(basename "$FILE")" >/dev/null 2>&1 || true
  exit 0
fi

if ! grimblast "${GRIMBLAST_ARGS[@]}" "$ACTION" "$TARGET" "$FILE" >/dev/null 2>&1; then
  error_notify "grimblast falhou em $ACTION $TARGET"
  exit 1
fi

if [ "$ACTION" = "copy" ]; then
  notify-send -a "Strata Screenshot" "Captura copiada" "Regiao: $TARGET" >/dev/null 2>&1 || true
  exit 0
fi

title="Captura salva"
body="$(basename "$FILE")"
if [ "$ACTION" = "copysave" ]; then
  body="$body
Copiada para a area de transferencia"
fi

notify_async "$FILE" "$title" "$body"

#!/usr/bin/env bash

open_search() {
  hyprctl dispatch exec "kitty --title app-search bash $HOME/.config/quickshell/scripts/app-search.sh $1"
  exit 0
}

ACCENT=$(cat ~/.config/quickshell/themes/current.json 2>/dev/null | grep -o '"accent":"[^"]*"' | cut -d'"' -f4)
[ -z "$ACCENT" ] && ACCENT="#d79921"

# Converte hex para cor ANSI 256 aproximada — usa laranja/amarelo como fallback
A="\033[38;2;$(printf '%d;%d;%d' 0x${ACCENT:1:2} 0x${ACCENT:3:2} 0x${ACCENT:5:2})m"
D="\033[2m"; R="\033[0m"; B="\033[1m"

ITEMS=("nix      buscar e instalar" "flatpak  buscar e instalar" "nix      remover" "flatpak  remover")
MODES=(nix_install flatpak_install nix_remove flatpak_remove)
ICONS=("󱄅" "󰏗" "󰩺" "󰩺")

draw() {
  clear
  echo ""
  echo -e "  ${A}${B}Strata Apps${R}\n"
  for i in "${!ITEMS[@]}"; do
    if [ "$i" -eq "$1" ]; then
      echo -e "  ${A}▶  ${ICONS[$i]}  ${ITEMS[$i]}${R}"
    else
      echo -e "  ${D}   ${ICONS[$i]}  ${ITEMS[$i]}${R}"
    fi
  done

}

sel=0
total=${#ITEMS[@]}
draw $sel

while true; do
  IFS= read -r -s -n1 key
  if [[ $key == $'\x1b' ]]; then
    read -r -s -n2 k2
    case "$k2" in
      '[A') ((sel > 0)) && ((sel--)) ;;
      '[B') ((sel < total-1)) && ((sel++)) ;;
    esac
  elif [[ $key == '' ]]; then
    mode="${MODES[$sel]}"
    [ "$mode" = "quit" ] && exit 0
    open_search "$mode"
  elif [[ $key == 'q' || $key == 'Q' ]]; then
    exit 0
  fi
  draw $sel
done

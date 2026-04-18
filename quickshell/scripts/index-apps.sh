#!/usr/bin/env bash
CACHE="$HOME/.cache/strata-apps.cache"
if [ "$1" = "--rebuild" ]; then
  ICON_CACHE=$(mktemp)
  find /run/current-system/sw/share/icons/Papirus-Dark/48x48 /run/current-system/sw/share/icons/Papirus/48x48 /run/current-system/sw/share/icons/hicolor/48x48 -name "*.png" -o -name "*.svg" 2>/dev/null | while read iconfile; do
    base=$(basename "$iconfile")
    name="${base%.*}"
    echo "$name=$iconfile"
  done > "$ICON_CACHE"
  tmp=$(mktemp)
  find /run/current-system/sw/share/applications $HOME/.local/share/applications /var/lib/flatpak/exports/share/applications -name "*.desktop" 2>/dev/null | while read f; do
    nodisplay=$(grep -m1 "^NoDisplay=" "$f" | sed "s/NoDisplay=//")
    [ "$nodisplay" = "true" ] && continue
    name=$(grep -m1 "^Name=" "$f" | sed "s/Name=//")
    [ -z "$name" ] && continue
    exec=$(grep -m1 "^Exec=" "$f" | sed "s/Exec=//" | sed "s/ @@.*//" | sed "s/ %[a-zA-Z].*//")
    [ -z "$exec" ] && continue
    icon=$(grep -m1 "^Icon=" "$f" | sed "s/Icon=//")
    iconpath=$(grep -m1 "^${icon}=" "$ICON_CACHE" | cut -d= -f2-)
    echo "$name|$exec|$iconpath"
  done | sort -u > "$tmp"
  mv "$tmp" "$CACHE"
  rm -f "$ICON_CACHE"
  exit 0
fi
[ -f "$CACHE" ] && cat "$CACHE"
/run/current-system/sw/bin/bash "$0" --rebuild &

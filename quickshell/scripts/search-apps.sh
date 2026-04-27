#!/usr/bin/env bash
q="$1"
find /run/current-system/sw/share/applications ~/.local/share/applications /var/lib/flatpak/exports/share/applications -name "*.desktop" 2>/dev/null | while read f; do
  name=$(grep -m1 "^Name=" "$f" | sed 's/Name=//')
  exec=$(grep -m1 "^Exec=" "$f" | sed "s/Exec=//" | sed "s/ @@.*//" | sed "s/ %[uUfF].*//")
  icon=$(grep -m1 "^Icon=" "$f" | sed 's/Icon=//')
  if echo "$name" | grep -qi "$q"; then
    iconpath=""
    found=$(find /run/current-system/sw/share/icons "$HOME/.local/share/icons" \
      \( -name "${icon}.png" -o -name "${icon}.svg" -o -name "${icon}.xpm" \) 2>/dev/null | head -1)
    [ -n "$found" ] && iconpath="$found"
    echo "$name|$exec|$iconpath"
  fi
done | sort -u | head -8

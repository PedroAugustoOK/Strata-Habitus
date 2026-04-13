#!/usr/bin/env bash
find /run/current-system/sw/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null | while read f; do
  nodisplay=$(grep -m1 "^NoDisplay=" "$f" | sed 's/NoDisplay=//')
  [ "$nodisplay" = "true" ] && continue
  name=$(grep -m1 "^Name=" "$f" | sed 's/Name=//')
  [ -z "$name" ] && continue
  exec=$(grep -m1 "^Exec=" "$f" | sed 's/Exec=//' | sed 's/ %[a-zA-Z]//g' | awk '{print $1}')
  [ -z "$exec" ] && continue
  icon=$(grep -m1 "^Icon=" "$f" | sed 's/Icon=//')
  iconpath=""
  for theme in Papirus-Dark Papirus hicolor; do
    for size in 48 64 32 128; do
      found=$(find "/run/current-system/sw/share/icons/$theme/${size}x${size}" \
        -name "${icon}.png" -o -name "${icon}.svg" 2>/dev/null | head -1)
      [ -n "$found" ] && iconpath="$found" && break 2
    done
  done
  echo "$name|$exec|$iconpath"
done | sort -u

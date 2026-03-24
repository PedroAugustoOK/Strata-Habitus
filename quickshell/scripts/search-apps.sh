#!/usr/bin/env bash
q="$1"
find /run/current-system/sw/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null | while read f; do
  name=$(grep -m1 "^Name=" "$f" | sed 's/Name=//')
  exec=$(grep -m1 "^Exec=" "$f" | sed 's/Exec=//' | sed 's/ %.//g' | awk '{print $1}')
  icon=$(grep -m1 "^Icon=" "$f" | sed 's/Icon=//')
  if echo "$name" | grep -qi "$q"; then
    iconpath=""
    for theme in Papirus-Dark Papirus hicolor; do
      for size in 48 32 64 128 256 24; do
        found=$(find "/run/current-system/sw/share/icons/$theme/${size}x${size}" \
          -name "${icon}.png" -o -name "${icon}.svg" 2>/dev/null | head -1)
        [ -n "$found" ] && iconpath="$found" && break 2
      done
    done
    echo "$name|$exec|$iconpath"
  fi
done | sort -u | head -8

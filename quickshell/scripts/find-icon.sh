#!/usr/bin/env bash
icon="$1"

for theme in Papirus-Dark Papirus hicolor; do
  for size in 48 32 64 128 256 24; do
    found=$(find "/run/current-system/sw/share/icons/$theme/${size}x${size}" \
      -name "${icon}.png" -o -name "${icon}.svg" 2>/dev/null | head -1)
    [ -n "$found" ] && echo "$found" && exit 0
  done
done

echo ""

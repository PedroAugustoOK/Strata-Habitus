#!/usr/bin/env bash
icon="$1"

found=$(find /run/current-system/sw/share/icons "$HOME/.local/share/icons" \
  \( -name "${icon}.png" -o -name "${icon}.svg" -o -name "${icon}.xpm" \) 2>/dev/null | head -1)
[ -n "$found" ] && echo "$found" && exit 0

echo ""

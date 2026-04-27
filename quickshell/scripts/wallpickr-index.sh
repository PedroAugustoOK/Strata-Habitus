#!/usr/bin/env bash
set -euo pipefail

WALLPAPERS_DIR="${1:?wallpapers dir required}"
THEME_NAME="${2:?theme name required}"
CACHE_DIR="${HOME}/.cache/strata/wallpickr/${THEME_NAME}"

mkdir -p "$CACHE_DIR"

find "$WALLPAPERS_DIR/$THEME_NAME" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort | while IFS= read -r source; do
  [ -f "$source" ] || continue

  hash="$(printf '%s' "$source" | sha1sum | cut -d' ' -f1)"
  thumb="$CACHE_DIR/${hash}.jpg"

  if [ ! -f "$thumb" ] || [ "$source" -nt "$thumb" ]; then
    magick "$source" \
      -auto-orient \
      -thumbnail "1280x720^" \
      -gravity center \
      -extent 1280x720 \
      -strip \
      -quality 82 \
      "$thumb" >/dev/null 2>&1 || cp "$source" "$thumb"
  fi

  printf '%s\t%s\n' "$source" "$thumb"
done

#!/usr/bin/env bash
set -euo pipefail

kind="${1:-text}"
bin_dir="/run/current-system/sw/bin"

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/strata/clipboard"
mkdir -p "$cache_dir"

detect_image_mime() {
  local path="$1"
  local signature
  signature="$("$bin_dir/od" -An -tx1 -N 12 "$path" | tr -d ' \n')"

  case "$signature" in
    89504e470d0a1a0a*) echo "image/png" ;;
    ffd8ff*) echo "image/jpeg" ;;
    474946383761*|474946383961*) echo "image/gif" ;;
    424d*) echo "image/bmp" ;;
    52494646????????57454250*) echo "image/webp" ;;
    *)
      if "$bin_dir/grep" -aq "<svg" "$path"; then
        echo "image/svg+xml"
      else
        echo "application/octet-stream"
      fi
      ;;
  esac
}

clipboard_offers_image() {
  "$bin_dir/wl-paste" --list-types 2>/dev/null \
    | "$bin_dir/grep" -Eiq '^image/(png|jpeg|jpg|webp|gif|bmp|svg\+xml|svg)'
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
cat > "$tmp"

if [ ! -s "$tmp" ]; then
  exit 0
fi

if [ "$kind" = "text" ] && clipboard_offers_image; then
  exit 0
fi

hash="$("$bin_dir/sha256sum" "$tmp" | awk '{print $1}')"
hash_file="$cache_dir/last-${kind}.sha256"
data_file="$cache_dir/current-${kind}"
pid_file="$cache_dir/current-${kind}.pid"
mime_file="$cache_dir/current-${kind}.mime"
last_hash=""

if [ -f "$hash_file" ]; then
  last_hash="$(cat "$hash_file" 2>/dev/null || true)"
fi

"$bin_dir/cliphist" store < "$tmp"

if [ "$hash" = "$last_hash" ]; then
  exit 0
fi

printf '%s' "$hash" > "$hash_file"
cp "$tmp" "$data_file"

if [ -f "$pid_file" ]; then
  old_pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
    kill "$old_pid" 2>/dev/null || true
  fi
fi

if [ "$kind" = "image" ]; then
  mime="$(detect_image_mime "$tmp")"
  printf '%s' "$mime" > "$mime_file"
  nohup "$bin_dir/bash" -lc "exec '$bin_dir/wl-copy' --foreground --type '$mime' < '$data_file'" >/dev/null 2>&1 &
else
  printf '%s' 'text/plain;charset=utf-8' > "$mime_file"
  nohup "$bin_dir/bash" -lc "exec '$bin_dir/wl-copy' --foreground --type 'text/plain;charset=utf-8' < '$data_file'" >/dev/null 2>&1 &
fi

echo $! > "$pid_file"

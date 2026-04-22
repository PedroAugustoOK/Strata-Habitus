#!/usr/bin/env bash

find_iface() {
  for path in /sys/class/net/*/wireless; do
    [ -d "$path" ] || continue
    basename "$(dirname "$path")"
    return 0
  done
  return 1
}

iface="$(find_iface)" || {
  echo "off"
  exit 0
}

state="$(iwctl station "$iface" show 2>/dev/null | awk '/State/ {print $NF; exit}')"
[ "$state" = "connected" ] || {
  echo "off"
  exit 0
}

signal="$(iwctl station "$iface" show 2>/dev/null | awk '/signal/ {print $NF; exit}' | tr -d '- ')"
echo "on:${signal:-50}"

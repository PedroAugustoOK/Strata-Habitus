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
  echo "—"
  exit 0
}

name="$(
  iwctl station "$iface" show 2>/dev/null \
    | sed -n 's/.*Connected network[[:space:]]*//p' \
    | head -n1
)"

printf '%s\n' "${name:-—}"

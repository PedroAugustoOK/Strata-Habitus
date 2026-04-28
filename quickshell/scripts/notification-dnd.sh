#!/usr/bin/env bash
set -euo pipefail

MODE_NAME="do-not-disturb"

case "${1:-status}" in
  status)
    if makoctl mode 2>/dev/null | grep -qx "$MODE_NAME"; then
      printf 'on\n'
    else
      printf 'off\n'
    fi
    ;;
  toggle)
    makoctl mode -t "$MODE_NAME" >/dev/null
    if makoctl mode 2>/dev/null | grep -qx "$MODE_NAME"; then
      printf 'on\n'
    else
      printf 'off\n'
    fi
    ;;
  *)
    printf 'usage: %s [status|toggle]\n' "$0" >&2
    exit 1
    ;;
esac

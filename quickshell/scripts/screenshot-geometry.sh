#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
REQUEST_ID="${2:-}"
GEOMETRY="${3:-}"

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/strata-screenshot"

case "$REQUEST_ID" in
  ""|*[!A-Za-z0-9_.-]*)
    exit 1
    ;;
esac

mkdir -p "$STATE_DIR"
TARGET="$STATE_DIR/$REQUEST_ID.geom"

case "$ACTION" in
  finish)
    [ -n "$GEOMETRY" ] || exit 1
    sleep 0.12
    printf '%s\n' "$GEOMETRY" > "$TARGET"
    ;;
  cancel)
    printf 'cancel\n' > "$TARGET"
    ;;
  *)
    exit 1
    ;;
esac

#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/strata/screenrecord"
PID_FILE="$STATE_DIR/recording.pid"
STARTED_FILE="$STATE_DIR/recording.started"

if [ ! -f "$PID_FILE" ]; then
  printf 'idle\t--:--\n'
  exit 0
fi

pid="$(cat "$PID_FILE" 2>/dev/null || true)"
if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
  printf 'idle\t--:--\n'
  exit 0
fi

started="$(cat "$STARTED_FILE" 2>/dev/null || true)"
if [[ ! "$started" =~ ^[0-9]+$ ]]; then
  started="$(date +%s)"
fi

elapsed="$(( $(date +%s) - started ))"
minutes="$(( elapsed / 60 ))"
seconds="$(( elapsed % 60 ))"

printf 'recording\t%02d:%02d\n' "$minutes" "$seconds"

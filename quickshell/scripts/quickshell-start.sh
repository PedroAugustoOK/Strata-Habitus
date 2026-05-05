#!/usr/bin/env bash
set -euo pipefail

SHELL_ENTRY="${HOME}/dotfiles/quickshell/shell.qml"

if pgrep -x quickshell >/dev/null 2>&1; then
  exit 0
fi

exec env QT_WAYLAND_DISABLE_WINDOWDECORATION=1 quickshell -p "${SHELL_ENTRY}" --no-color

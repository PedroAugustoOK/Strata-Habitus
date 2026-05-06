#!/usr/bin/env bash
set -euo pipefail

SHELL_ENTRY="${HOME}/dotfiles/quickshell/shell.qml"

if quickshell list -p "${SHELL_ENTRY}" 2>/dev/null | grep -q '^Instance '; then
  exit 0
fi

for qml_dir in \
  "/run/current-system/sw/lib/qt-6/qml" \
  "${HOME}/.nix-profile/lib/qt-6/qml"; do
  if [ -d "${qml_dir}/Caelestia/Blobs" ]; then
    export QML2_IMPORT_PATH="${qml_dir}${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
    break
  fi
done

exec env QT_WAYLAND_DISABLE_WINDOWDECORATION=1 quickshell -p "${SHELL_ENTRY}" --no-color

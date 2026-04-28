#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Strata Proton VPN"
STATUS_SCRIPT="$HOME/.config/quickshell/scripts/protonvpn-status.sh"

before_state="$("$STATUS_SCRIPT" 2>/dev/null | cut -f1 || true)"

if protonvpn-wg-toggle; then
  after_line="$("$STATUS_SCRIPT" 2>/dev/null || true)"
  after_state="$(printf '%s' "$after_line" | cut -f1)"
  after_body="$(printf '%s' "$after_line" | cut -f2-)"

  if [ "$after_state" = "connected" ]; then
    notify-send -a "$APP_NAME" "VPN conectada" "$after_body" >/dev/null 2>&1 || true
  else
    notify-send -a "$APP_NAME" "VPN desligada" "$after_body" >/dev/null 2>&1 || true
  fi
else
  if [ "$before_state" = "connected" ]; then
    notify-send -a "$APP_NAME" -u critical "Falha ao desligar VPN" "Revise protonvpn-wg.service." >/dev/null 2>&1 || true
  else
    notify-send -a "$APP_NAME" -u critical "Falha ao conectar VPN" "Revise protonvpn-wg.service." >/dev/null 2>&1 || true
  fi
fi

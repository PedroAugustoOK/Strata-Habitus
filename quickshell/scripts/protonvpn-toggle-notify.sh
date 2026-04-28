#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Strata Proton VPN"
STATUS_SCRIPT="$HOME/.config/quickshell/scripts/protonvpn-status.sh"

before_state="$(bash "$STATUS_SCRIPT" 2>/dev/null | cut -f1 || true)"
target_state="connected"

if [ "$before_state" = "connected" ]; then
  target_state="disconnected"
fi

read_status() {
  bash "$STATUS_SCRIPT" 2>/dev/null || true
}

wait_for_state() {
  local expected="$1"
  local attempts="${2:-20}"
  local delay="${3:-0.5}"
  local line state

  while [ "$attempts" -gt 0 ]; do
    line="$(read_status)"
    state="$(printf '%s' "$line" | cut -f1)"
    if [ "$state" = "$expected" ]; then
      printf '%s\n' "$line"
      return 0
    fi
    sleep "$delay"
    attempts=$((attempts - 1))
  done

  return 1
}

confirm_state_async() {
  local expected="$1"

  (
    if after_line="$(wait_for_state "$expected")"; then
      after_body="$(printf '%s' "$after_line" | cut -f2-)"

      if [ "$expected" = "connected" ]; then
        notify-send -a "$APP_NAME" "VPN conectada" "$after_body" >/dev/null 2>&1 || true
      else
        notify-send -a "$APP_NAME" "VPN desligada" "$after_body" >/dev/null 2>&1 || true
      fi
    else
      if [ "$expected" = "connected" ]; then
        notify-send -a "$APP_NAME" -u critical "Falha ao conectar VPN" "O tunel nao estabilizou apos o comando." >/dev/null 2>&1 || true
      else
        notify-send -a "$APP_NAME" -u critical "Falha ao desligar VPN" "O tunel continuou ativo apos o comando." >/dev/null 2>&1 || true
      fi
    fi
  ) >/dev/null 2>&1 &
}

if protonvpn-wg-toggle; then
  if [ "$target_state" = "connected" ]; then
    notify-send -a "$APP_NAME" "Conectando VPN" "Aguardando o tunel WireGuard ficar disponivel." >/dev/null 2>&1 || true
  else
    notify-send -a "$APP_NAME" "Desligando VPN" "Encerrando o tunel WireGuard." >/dev/null 2>&1 || true
  fi

  confirm_state_async "$target_state"
else
  if [ "$before_state" = "connected" ]; then
    notify-send -a "$APP_NAME" -u critical "Falha ao desligar VPN" "Revise protonvpn-wg.service." >/dev/null 2>&1 || true
  else
    notify-send -a "$APP_NAME" -u critical "Falha ao conectar VPN" "Revise protonvpn-wg.service." >/dev/null 2>&1 || true
  fi
fi

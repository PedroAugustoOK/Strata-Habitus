#!/usr/bin/env bash
set -euo pipefail

first_interface="$(ip -o link show type wireguard 2>/dev/null | awk -F': ' '{print $2}' | cut -d@ -f1 | head -n1 || true)"

echo "== protonvpn-status =="
bash "$HOME/.config/quickshell/scripts/protonvpn-status.sh" || true
echo

echo "== wireguard interfaces =="
ip -o link show type wireguard 2>/dev/null | awk -F': ' '{print $2}' | cut -d@ -f1 || true
echo

echo "== protonvpn service =="
systemctl is-active protonvpn-wg.service 2>/dev/null || true
echo

echo "== wireguard handshake =="
if [ -n "$first_interface" ]; then
  handshake_output="$(wg show "$first_interface" latest-handshakes 2>/dev/null || true)"
  if [ -n "$handshake_output" ]; then
    printf '%s\n' "$handshake_output"
  else
    echo "indisponivel sem sudo ou ainda sem handshake registrado"
  fi
else
  echo "sem interface wireguard ativa"
fi
echo

echo "== default routes =="
ip route show default 2>/dev/null || true

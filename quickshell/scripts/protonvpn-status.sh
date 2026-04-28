#!/usr/bin/env bash
set -euo pipefail

interfaces="$(ip -o link show type wireguard 2>/dev/null | awk -F': ' '{print $2}' | cut -d@ -f1 || true)"

if [ -n "$interfaces" ]; then
  first_interface="${interfaces%%$'\n'*}"
  printf 'connected\tProton VPN ativo (%s)\n' "$first_interface"
else
  printf 'disconnected\tProton VPN desligado\n'
fi

#!/usr/bin/env bash
set -euo pipefail

if systemctl is-active --quiet protonvpn-wg.service; then
  printf 'connected\tProton VPN ativo\n'
else
  printf 'disconnected\tProton VPN desligado\n'
fi

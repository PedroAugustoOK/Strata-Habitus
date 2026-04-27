#!/usr/bin/env bash

set -euo pipefail

BTCTL="/run/current-system/sw/bin/bluetoothctl"
RFKILL="/run/current-system/sw/bin/rfkill"
HCICONFIG="/run/current-system/sw/bin/hciconfig"
SUDO="/run/wrappers/bin/sudo"
PRIV_HELPER="/run/current-system/sw/bin/strata-bluetooth-toggle"

btctl() {
  "$BTCTL" "$@" 2>&1
}

primary_hci() {
  "$HCICONFIG" -a 2>/dev/null | awk '
    /^[a-z0-9]+:/ {
      iface = $1
      sub(/:$/, "", iface)
      current = iface
    }
    /BD Address:/ {
      addr = $3
      if (addr != "00:00:00:00:00:00" && chosen == "") {
        chosen = current
      }
    }
    END {
      if (chosen != "") print chosen
    }
  '
}

is_up() {
  local hci="$1"
  "$HCICONFIG" "$hci" 2>/dev/null | grep -q "UP RUNNING\|UP "
}

connected_count() {
  "$BTCTL" devices Connected 2>/dev/null | wc -l
}

status() {
  local hci connected
  hci="$(primary_hci)"
  if [ -z "${hci:-}" ]; then
    printf 'off\n'
    return 0
  fi

  if ! is_up "$hci"; then
    printf 'off\n'
    return 0
  fi

  connected="$(connected_count)"
  if [ "${connected:-0}" -gt 0 ]; then
    printf 'connected\n'
  else
    printf 'on\n'
  fi
}

power_on() {
  local out current

  if ! out="$("$SUDO" "$PRIV_HELPER" on 2>&1)"; then
    printf 'privileged bluetooth on failed: %s\n' "$out" >&2
  fi

  for _ in 1 2 3 4 5; do
    sleep 0.2
    current="$(status)"
    if [ "$current" != "off" ]; then
      printf '%s\n' "$current"
      return 0
    fi
  done

  printf 'bluetooth power on did not stick; adapter is still off\n' >&2
  printf 'off\n'
  return 1
}

power_off() {
  local out current

  if ! out="$("$SUDO" "$PRIV_HELPER" off 2>&1)"; then
    printf 'privileged bluetooth off failed: %s\n' "$out" >&2
  fi

  for _ in 1 2 3 4 5; do
    sleep 0.2
    current="$(status)"
    if [ "$current" = "off" ]; then
      printf 'off\n'
      return 0
    fi
  done

  printf 'bluetooth power off did not stick; adapter is still on\n' >&2
  printf '%s\n' "$(status)"
  return 1
}

toggle() {
  if [ "$(status)" = "off" ]; then
    power_on
  else
    power_off
  fi
}

case "${1:-status}" in
  status) status ;;
  on) power_on ;;
  off) power_off ;;
  toggle) toggle ;;
  *) exit 2 ;;
esac

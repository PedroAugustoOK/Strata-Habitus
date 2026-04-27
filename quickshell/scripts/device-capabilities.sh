#!/usr/bin/env bash

set -euo pipefail

bool() {
  if "$1"; then
    printf 'true'
  else
    printf 'false'
  fi
}

has_battery() {
  for bat in /sys/class/power_supply/BAT*; do
    [ -d "$bat" ] && return 0
  done
  return 1
}

has_brightness() {
  for node in /sys/class/backlight/*; do
    [ -e "$node" ] && return 0
  done
  return 1
}

has_wifi() {
  for node in /sys/class/net/wl*; do
    [ -e "$node" ] && return 0
  done
  return 1
}

has_ethernet() {
  for node in /sys/class/net/en* /sys/class/net/eth*; do
    [ -e "$node" ] && return 0
  done
  return 1
}

has_bluetooth() {
  [ -d /sys/class/bluetooth ] || return 1
  find /sys/class/bluetooth -mindepth 1 -maxdepth 1 | read -r _
}

has_power_profiles() {
  command -v /run/current-system/sw/bin/powerprofilesctl >/dev/null 2>&1
}

printf '{'
printf '"hasBattery":%s,' "$(bool has_battery)"
printf '"hasBrightness":%s,' "$(bool has_brightness)"
printf '"hasWifi":%s,' "$(bool has_wifi)"
printf '"hasBluetooth":%s,' "$(bool has_bluetooth)"
printf '"hasEthernet":%s,' "$(bool has_ethernet)"
printf '"hasPowerProfiles":%s' "$(bool has_power_profiles)"
printf '}\n'

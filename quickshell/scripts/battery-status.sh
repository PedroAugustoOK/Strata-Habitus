#!/usr/bin/env bash

for bat in /sys/class/power_supply/BAT*; do
  [ -d "$bat" ] || continue
  [ -r "$bat/capacity" ] || continue
  [ -r "$bat/status" ] || continue
  printf '%s\t%s\n' "$(cat "$bat/capacity")" "$(cat "$bat/status")"
  exit 0
done

printf '100\tDischarging\n'

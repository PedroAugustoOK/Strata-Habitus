#!/usr/bin/env bash
sleep 5
ACCENT=$(grep -o '"accent":"[^"]*"' $HOME/.config/quickshell/themes/current.json | cut -d'"' -f4 | tr -d '#')
hyprctl keyword general:col.active_border "rgba(${ACCENT}ff)"

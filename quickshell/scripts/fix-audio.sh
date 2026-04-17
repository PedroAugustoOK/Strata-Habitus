#!/usr/bin/env bash
systemctl --user restart pipewire pipewire-pulse wireplumber
sleep 2
wpctl status | grep -A3 "Sinks:"

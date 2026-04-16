#!/usr/bin/env bash
wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null \
  | grep -m1 'node.nick\|node.description' \
  | sed 's/.*= "//;s/".*//'

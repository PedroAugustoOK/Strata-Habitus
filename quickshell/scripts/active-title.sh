#!/bin/sh
hyprctl activewindow -j | grep '"title"' | head -1 | sed 's/.*"title": *"//;s/".*//'

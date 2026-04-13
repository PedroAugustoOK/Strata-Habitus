#!/bin/sh
ACCENT="$1"
TMPFILE=$(mktemp)
sed "s|accentColor:    \"#[a-f0-9]*\"|accentColor:    \"${ACCENT}\"|" /var/lib/strata/Main.qml > "$TMPFILE"
sudo /run/current-system/sw/bin/cp "$TMPFILE" /var/lib/strata/Main.qml
rm "$TMPFILE"

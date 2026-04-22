#!/bin/sh
# Regenera /var/lib/strata/Main.qml a partir da fonte canônica em /nix/store,
# aplicando o accent atual. Ler sempre da store evita corromper o destino
# caso ele já esteja vazio ou inacessível.
ACCENT="$1"
SRC="/run/current-system/sw/share/sddm/themes/strata/Main.qml"
DEST="/var/lib/strata/Main.qml"
TMPFILE=$(mktemp)
sed "s|accentColor:    \"#[a-f0-9]*\"|accentColor:    \"${ACCENT}\"|" "$SRC" > "$TMPFILE"
sudo -n /run/current-system/sw/bin/cp "$TMPFILE" "$DEST" || true
rm "$TMPFILE"

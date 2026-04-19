#!/bin/sh
REPO="PedroAugustoOK/Strata-Habitus"
CACHE="/var/cache/strata-last-commit"
LATEST=$(curl -sf https://api.github.com/repos/$REPO/commits/main | grep -m1 '"sha"' | cut -d'"' -f4)
[ -z "$LATEST" ] && exit 0
CURRENT=$(cat "$CACHE" 2>/dev/null)
if [ "$LATEST" != "$CURRENT" ]; then
  logger "Strata: atualizando para $LATEST"
  nixos-rebuild switch --flake github:$REPO#galaxybook && echo "$LATEST" > "$CACHE"
fi

#!/bin/sh
REPO="PedroAugustoOK/Strata-Habitus"
CACHE="/var/cache/strata-last-commit"
CURL=/run/current-system/sw/bin/curl
REBUILD=/run/current-system/sw/bin/nixos-rebuild

LATEST=$($CURL -sf https://api.github.com/repos/$REPO/commits/main | grep -m1 '"sha"' | cut -d'"' -f4)
[ -z "$LATEST" ] && exit 0
CURRENT=$(cat "$CACHE" 2>/dev/null)
if [ "$LATEST" != "$CURRENT" ]; then
  $REBUILD switch --flake github:$REPO#galaxybook && echo "$LATEST" > "$CACHE"
fi

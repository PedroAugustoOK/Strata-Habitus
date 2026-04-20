#!/bin/sh
REPO="PedroAugustoOK/Strata-Habitus"
CACHE="/var/cache/strata-last-commit"
LOG="/var/log/strata-update.log"
CURL=/run/current-system/sw/bin/curl
REBUILD=/run/current-system/sw/bin/nixos-rebuild

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }

notify_users() {
  URGENCY="$1"; TITLE="$2"; MSG="$3"
  for bus in /run/user/*/bus; do
    uid=$(echo "$bus" | grep -o '[0-9]*')
    user=$(id -un "$uid" 2>/dev/null) || continue
    DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
    XDG_RUNTIME_DIR="/run/user/$uid" \
    su -s /bin/sh "$user" -c \
      "/run/current-system/sw/bin/notify-send -u '$URGENCY' -i system-software-update '$TITLE' '$MSG'" \
      2>/dev/null || true
  done
}

LATEST=$($CURL -sf "https://api.github.com/repos/$REPO/commits/main" \
  | grep -m1 '"sha"' | cut -d'"' -f4)

if [ -z "$LATEST" ]; then
  log "Falha ao buscar commit remoto"
  exit 0
fi

CURRENT=$(cat "$CACHE" 2>/dev/null)
[ "$LATEST" = "$CURRENT" ] && exit 0

log "Novo commit detectado: ${CURRENT:-inicial} → $LATEST"

if $REBUILD switch --flake "github:$REPO#$(hostname)" >> "$LOG" 2>&1; then
  echo "$LATEST" > "$CACHE"
  log "Atualização concluída com sucesso"
  notify_users "normal" "Strata Habitus" "Sistema atualizado com sucesso."
else
  log "Rebuild falhou — revertendo geração anterior"
  $REBUILD switch --rollback >> "$LOG" 2>&1 || true
  notify_users "critical" "Strata Habitus" "Falha na atualização — sistema revertido."
fi

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_DIR:-$SCRIPT_DIR}"
CONF_FILE="${CONF_FILE:-/etc/strata-release.conf}"
REMOTE_NAME="${REMOTE_NAME:-origin}"
CHANNEL_ARG="${1:-}"
HOST_ARG="${2:-}"

log() {
  printf '==> %s\n' "$*"
}

die() {
  printf '[error] %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Comando obrigatorio ausente: $1"
}

load_defaults() {
  if [ -r "$CONF_FILE" ]; then
    # shellcheck disable=SC1090
    . "$CONF_FILE"
  fi

  CHANNEL="${CHANNEL_ARG:-${STRATA_UPDATE_CHANNEL:-stable}}"
  HOST="${HOST_ARG:-${STRATA_UPDATE_HOST:-$(hostname)}}"
}

ensure_clean_worktree() {
  if [ -n "$(git -C "$REPO_DIR" status --short)" ]; then
    die "Worktree com alteracoes locais. Commit/stash antes de aplicar o canal."
  fi
}

ensure_channel_exists() {
  if ! git -C "$REPO_DIR" ls-remote --exit-code --heads "$REMOTE_NAME" "$CHANNEL" >/dev/null 2>&1; then
    die "Canal remoto nao encontrado: $REMOTE_NAME/$CHANNEL"
  fi
}

checkout_channel() {
  if git -C "$REPO_DIR" show-ref --verify --quiet "refs/heads/$CHANNEL"; then
    git -C "$REPO_DIR" checkout "$CHANNEL"
  else
    git -C "$REPO_DIR" checkout -b "$CHANNEL" --track "$REMOTE_NAME/$CHANNEL"
  fi
}

main() {
  need_cmd git
  need_cmd hostname
  need_cmd sudo
  need_cmd nixos-rebuild

  [ -f "$REPO_DIR/flake.nix" ] || die "flake.nix nao encontrado em $REPO_DIR"

  load_defaults
  ensure_clean_worktree

  log "Buscando atualizacoes de $REMOTE_NAME"
  git -C "$REPO_DIR" fetch "$REMOTE_NAME"

  ensure_channel_exists

  log "Trocando repositorio local para o canal $CHANNEL"
  checkout_channel

  log "Sincronizando $CHANNEL com $REMOTE_NAME/$CHANNEL"
  git -C "$REPO_DIR" pull --ff-only "$REMOTE_NAME" "$CHANNEL"

  log "Aplicando configuracao do host $HOST"
  sudo nixos-rebuild switch --flake "path:$REPO_DIR#$HOST"
}

main "$@"

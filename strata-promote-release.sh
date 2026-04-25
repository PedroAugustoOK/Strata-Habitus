#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_DIR:-$SCRIPT_DIR}"
REMOTE_NAME="${REMOTE_NAME:-origin}"
RELEASE_BRANCH="${1:-stable}"
SOURCE_REF="${2:-HEAD}"

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

ensure_clean_worktree() {
  if [ -n "$(git -C "$REPO_DIR" status --short)" ]; then
    die "Worktree com alteracoes locais. Commit antes de promover release."
  fi
}

main() {
  need_cmd git

  [ -d "$REPO_DIR/.git" ] || die "Repositorio git nao encontrado em $REPO_DIR"

  ensure_clean_worktree

  log "Atualizando referencias remotas"
  git -C "$REPO_DIR" fetch "$REMOTE_NAME"

  log "Promovendo $SOURCE_REF para $REMOTE_NAME/$RELEASE_BRANCH"
  git -C "$REPO_DIR" push "$REMOTE_NAME" "$SOURCE_REF:refs/heads/$RELEASE_BRANCH"

  log "Release publicado em $RELEASE_BRANCH"
}

main "$@"

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_DIR:-$SCRIPT_DIR}"
NIX_CONFIG_VALUE="${NIX_CONFIG:-experimental-features = nix-command flakes}"
HOSTNAME_VALUE=""
USERNAME_VALUE=""
TIMEZONE_VALUE=""
GRAPHICS_PROFILE=""
DESKTOP_ENABLE="false"

log() {
  printf '\n==> %s\n' "$*"
}

die() {
  printf '\n[error] %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Comando obrigatorio ausente: $1"
}

prompt_with_default() {
  local prompt="$1"
  local default="$2"
  local value=""

  read -r -p "$prompt [$default]: " value
  printf '%s\n' "${value:-$default}"
}

validate_hostname() {
  printf '%s\n' "$1" | grep -Eq '^[a-z0-9][a-z0-9-]*$'
}

validate_username() {
  printf '%s\n' "$1" | grep -Eq '^[a-z_][a-z0-9_-]*$'
}

detect_timezone() {
  local current
  current="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
  if [ -n "$current" ] && [ "$current" != "n/a" ]; then
    printf '%s\n' "$current"
  else
    printf 'America/Porto_Velho\n'
  fi
}

detect_graphics_profile() {
  local pci
  local has_intel=0
  local has_amd=0
  local has_nvidia=0

  if ! command -v lspci >/dev/null 2>&1; then
    printf 'generic\n'
    return
  fi

  pci="$(lspci -nn | grep -E 'VGA|3D|Display' || true)"

  printf '%s\n' "$pci" | grep -qi 'intel' && has_intel=1 || true
  printf '%s\n' "$pci" | grep -qi 'amd\|advanced micro devices\|ati' && has_amd=1 || true
  printf '%s\n' "$pci" | grep -qi 'nvidia' && has_nvidia=1 || true

  if [ "$has_nvidia" -eq 1 ] && [ "$has_amd" -eq 1 ]; then
    printf 'hybrid-amd-nvidia\n'
  elif [ "$has_nvidia" -eq 1 ] && [ "$has_intel" -eq 1 ]; then
    printf 'hybrid-intel-nvidia\n'
  elif [ "$has_nvidia" -eq 1 ]; then
    printf 'nvidia\n'
  elif [ "$has_amd" -eq 1 ]; then
    printf 'amd\n'
  elif [ "$has_intel" -eq 1 ]; then
    printf 'intel\n'
  else
    printf 'generic\n'
  fi
}

choose_graphics_profile() {
  local detected="$1"
  local answer

  printf '\nPerfil grafico:\n'
  printf '  1) %s [detectado]\n' "$detected"
  printf '  2) intel\n'
  printf '  3) amd\n'
  printf '  4) nvidia\n'
  printf '  5) hybrid-intel-nvidia\n'
  printf '  6) hybrid-amd-nvidia\n'
  printf '  7) generic\n'
  answer="$(prompt_with_default "Escolha" "1")"

  case "$answer" in
    1) GRAPHICS_PROFILE="$detected" ;;
    2) GRAPHICS_PROFILE="intel" ;;
    3) GRAPHICS_PROFILE="amd" ;;
    4) GRAPHICS_PROFILE="nvidia" ;;
    5) GRAPHICS_PROFILE="hybrid-intel-nvidia" ;;
    6) GRAPHICS_PROFILE="hybrid-amd-nvidia" ;;
    7) GRAPHICS_PROFILE="generic" ;;
    *) die "Perfil grafico invalido: $answer" ;;
  esac
}

choose_first_boot_mode() {
  local default_choice="1"
  local answer

  if [ "$GRAPHICS_PROFILE" = "intel" ]; then
    default_choice="2"
  fi

  printf '\nPrimeiro boot do Strata:\n'
  printf '  1) grafico (Hyprland + SDDM)\n'
  printf '  2) tty seguro\n'
  answer="$(prompt_with_default "Escolha" "$default_choice")"

  case "$answer" in
    1) DESKTOP_ENABLE="true" ;;
    2) DESKTOP_ENABLE="false" ;;
    *) die "Modo de boot invalido: $answer" ;;
  esac
}

write_host_meta() {
  cat > "$REPO_DIR/hosts/$HOSTNAME_VALUE/meta.nix" <<EOF
{
  username = "$USERNAME_VALUE";
  system = "x86_64-linux";
  profile = "laptop";
  graphics = "$GRAPHICS_PROFILE";
  timeZone = "$TIMEZONE_VALUE";
  locale = "pt_BR.UTF-8";
  boot = {
    mode = "uefi";
    loader = "systemd-boot";
  };
  desktop = {
    enable = $DESKTOP_ENABLE;
  };
}
EOF
}

write_host_config() {
  case "$GRAPHICS_PROFILE" in
    hybrid-amd-nvidia)
      cat > "$REPO_DIR/hosts/$HOSTNAME_VALUE/config.nix" <<'EOF'
{ lib, ... }:
{
  imports = [
    ../../modules/graphics-debug.nix
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];
}
EOF
      ;;
    hybrid-intel-nvidia)
      cat > "$REPO_DIR/hosts/$HOSTNAME_VALUE/config.nix" <<'EOF'
{ lib, ... }:
{
  imports = [
    ../../modules/graphics-debug.nix
  ];

  boot.kernelParams = lib.mkForce [ "i915.enable_psr=0" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];
}
EOF
      ;;
    nvidia)
      cat > "$REPO_DIR/hosts/$HOSTNAME_VALUE/config.nix" <<'EOF'
{ lib, ... }:
{
  imports = [
    ../../modules/graphics-debug.nix
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
EOF
      ;;
    amd)
      cat > "$REPO_DIR/hosts/$HOSTNAME_VALUE/config.nix" <<'EOF'
{ lib, ... }:
{
  imports = [
    ../../modules/graphics-debug.nix
  ];

  services.xserver.videoDrivers = [ "amdgpu" ];
}
EOF
      ;;
    intel)
      cat > "$REPO_DIR/hosts/$HOSTNAME_VALUE/config.nix" <<'EOF'
{ lib, ... }:
{
  imports = [
    ../../modules/graphics-debug.nix
  ];

  boot.kernelParams = lib.mkForce [ "i915.enable_psr=0" ];
}
EOF
      ;;
    generic)
      cat > "$REPO_DIR/hosts/$HOSTNAME_VALUE/config.nix" <<'EOF'
{ ... }:
{
  imports = [
    ../../modules/graphics-debug.nix
  ];
}
EOF
      ;;
    *)
      die "Perfil grafico invalido: $GRAPHICS_PROFILE"
      ;;
  esac
}

write_host_monitors() {
  cat > "$REPO_DIR/hosts/$HOSTNAME_VALUE/hyprland-monitors.conf" <<'EOF'
monitor = , preferred, auto, 1
EOF
}

main() {
  [ "$(id -u)" -eq 0 ] || die "Execute com sudo."

  need_cmd nixos-generate-config
  need_cmd nixos-rebuild
  need_cmd nix

  [ -f "$REPO_DIR/flake.nix" ] || die "Repo nao encontrado em $REPO_DIR"

  HOSTNAME_VALUE="$(prompt_with_default "Hostname" "$(hostname | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' '-')" )"
  validate_hostname "$HOSTNAME_VALUE" || die "Hostname invalido: $HOSTNAME_VALUE"

  USERNAME_VALUE="$(prompt_with_default "Usuario principal" "$(logname 2>/dev/null || printf 'ankh')")"
  validate_username "$USERNAME_VALUE" || die "Usuario invalido: $USERNAME_VALUE"

  TIMEZONE_VALUE="$(prompt_with_default "Timezone" "$(detect_timezone)")"
  GRAPHICS_PROFILE="$(detect_graphics_profile)"
  choose_graphics_profile "$GRAPHICS_PROFILE"
  choose_first_boot_mode

  mkdir -p "$REPO_DIR/hosts/$HOSTNAME_VALUE"
  log "Gerando hardware-configuration.nix"
  nixos-generate-config --show-hardware-config > "$REPO_DIR/hosts/$HOSTNAME_VALUE/hardware.nix"
  write_host_meta
  write_host_config
  write_host_monitors

  log "Validando host gerado"
  NIX_CONFIG="$NIX_CONFIG_VALUE" nix eval --impure --json "path:$REPO_DIR#nixosConfigurations.$HOSTNAME_VALUE.config.networking.hostName" >/dev/null

  log "Aplicando configuracao"
  NIX_CONFIG="$NIX_CONFIG_VALUE" nixos-rebuild switch --flake "path:$REPO_DIR#$HOSTNAME_VALUE"

  printf '\nBootstrap concluido. Reinicie o sistema.\n'
}

main "$@"

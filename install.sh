#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_ROOT="${TARGET_ROOT:-/mnt}"
DEFAULT_REPO_URL="${STRATA_REPO_URL:-https://github.com/PedroAugustoOK/Strata-Habitus.git}"
LOG_FILE="${STRATA_INSTALL_LOG:-/tmp/strata-install.log}"

BOOT_PART=""
ROOT_PART=""
SWAP_PART=""
SEPARATE_BOOT_PART=""
HOSTNAME=""
USERNAME=""
PASSWORD=""
TIMEZONE=""
LOCALE="pt_BR.UTF-8"
GRAPHICS_PROFILE=""
MACHINE_PROFILE=""
TARGET_DISK=""
SWAP_GIB=""
REPO_SOURCE=""
REPO_TARGET=""
BOOT_MODE=""
BOOT_LOADER=""
INSTALL_MODE=""
DESKTOP_ENABLE="true"
FORMAT_ROOT="yes"
FORMAT_BOOT="yes"
FORMAT_SWAP="yes"
DRY_RUN=0
ALLOW_NON_INSTALLER=0
MOUNTED_ROOT=0
MOUNTED_BOOT=0
SWAP_ENABLED=0

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf '\n[warn] %s\n' "$*" >&2
}

die() {
  printf '\n[error] %s\n' "$*" >&2
  exit 1
}

on_error() {
  warn "Instalacao interrompida. Veja o log em $LOG_FILE"
  if mountpoint -q "$TARGET_ROOT"; then
    warn "Particoes continuam montadas em $TARGET_ROOT para inspecao."
  fi
}

trap on_error ERR

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Comando obrigatorio ausente: $1"
}

run_cmd() {
  printf '  ->'
  printf ' %q' "$@"
  printf '\n'
  "$@"
}

is_installer_environment() {
  [ -r /etc/os-release ] || return 1
  grep -q '^VARIANT_ID=installer$' /etc/os-release
}

require_installer_environment() {
  [ "$ALLOW_NON_INSTALLER" -eq 1 ] && return

  if is_installer_environment; then
    return
  fi

  die "Este script deve ser executado a partir do live ISO do NixOS. Em um sistema ja instalado, use git clone + nixos-rebuild switch --flake path:/home/<usuario>/dotfiles#<host>."
}

confirm() {
  local prompt="$1"
  local default="${2:-N}"
  local answer=""
  local suffix="[y/N]"

  if [ "$default" = "Y" ]; then
    suffix="[Y/n]"
  fi

  read -r -p "$prompt $suffix " answer
  answer="${answer:-$default}"

  case "$answer" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

prompt_with_default() {
  local prompt="$1"
  local default="$2"
  local value=""

  read -r -p "$prompt [$default]: " value
  printf '%s\n' "${value:-$default}"
}

list_disks() {
  lsblk -dpnr -o NAME,SIZE,TYPE,MODEL,TRAN,RM | awk '$3 == "disk" { print }'
}

list_partitions() {
  lsblk -fpno NAME,FSTYPE,SIZE,LABEL,MOUNTPOINTS,PARTTYPE
}

partition_path() {
  local disk="$1"
  local index="$2"

  case "$disk" in
    *nvme*n*|*mmcblk*)
      printf '%sp%s\n' "$disk" "$index"
      ;;
    *)
      printf '%s%s\n' "$disk" "$index"
      ;;
  esac
}

cleanup_mounts() {
  if [ "$SWAP_ENABLED" -eq 1 ] && [ -n "$SWAP_PART" ]; then
    swapoff "$SWAP_PART" >/dev/null 2>&1 || true
  fi
  SWAP_ENABLED=0

  if [ "$MOUNTED_BOOT" -eq 1 ]; then
    umount "$TARGET_ROOT/boot" >/dev/null 2>&1 || true
  fi
  MOUNTED_BOOT=0

  if [ "$MOUNTED_ROOT" -eq 1 ]; then
    umount -R "$TARGET_ROOT" >/dev/null 2>&1 || true
  fi
  MOUNTED_ROOT=0
}

detect_boot_mode() {
  if [ -d /sys/firmware/efi/efivars ]; then
    printf 'uefi\n'
  else
    printf 'legacy\n'
  fi
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

timezone_exists() {
  local tz="$1"
  [ -e "/etc/zoneinfo/$tz" ] \
    || [ -e "/run/current-system/sw/share/zoneinfo/$tz" ] \
    || [ -e "/usr/share/zoneinfo/$tz" ]
}

detect_machine_profile() {
  if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
    printf 'laptop\n'
  else
    printf 'desktop\n'
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

detect_recommended_disk() {
  local disks
  local first_internal=""
  local first_any=""
  local line
  local name size type rest
  local tran rm

  disks="$(list_disks)"
  [ -n "$disks" ] || return 1

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    read -r name size type rest <<<"$line"
    tran="$(printf '%s\n' "$line" | awk '{print $(NF-1)}')"
    rm="$(printf '%s\n' "$line" | awk '{print $NF}')"

    if [ -z "$first_any" ]; then
      first_any="$name"
    fi

    if [ "${tran:-}" != "usb" ] && [ "${rm:-0}" = "0" ]; then
      first_internal="$name"
      break
    fi
  done <<EOF
$disks
EOF

  printf '%s\n' "${first_internal:-$first_any}"
}

choose_disk() {
  local disks
  local default_disk=""
  local answer
  local line
  local idx=0
  local name size type model tran rm
  local disks_cache=""

  disks="$(list_disks)"
  [ -n "$disks" ] || die "Nenhum disco detectado."

  default_disk="$(detect_recommended_disk || true)"
  printf '\nDiscos detectados:\n'
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    idx=$((idx + 1))
    name="$(printf '%s\n' "$line" | awk '{print $1}')"
    size="$(printf '%s\n' "$line" | awk '{print $2}')"
    tran="$(printf '%s\n' "$line" | awk '{print $(NF-1)}')"
    rm="$(printf '%s\n' "$line" | awk '{print $NF}')"
    model="$(printf '%s\n' "$line" | awk '{for (i=4; i<=NF-2; i++) printf("%s%s", $i, (i < NF-2 ? OFS : ""))}')"
    [ -n "$model" ] || model="sem-modelo"
    disks_cache="${disks_cache}${idx}|${name}"$'\n'
    printf '  %d) %s  %s  %s' "$idx" "$name" "$size" "$model"
    if [ "${tran:-}" = "usb" ] || [ "${rm:-0}" = "1" ]; then
      printf ' [removivel]'
    else
      printf ' [interno]'
    fi
    if [ "$name" = "$default_disk" ]; then
      printf ' [recomendado]'
      default_disk="$idx"
    fi
    printf '\n'
  done <<EOF
$disks
EOF

  [ -n "$default_disk" ] || default_disk="1"
  answer="$(prompt_with_default "Disco alvo" "$default_disk")"

  if printf '%s\n' "$answer" | grep -Eq '^[0-9]+$'; then
    answer="$(printf '%s' "$disks_cache" | awk -F'|' -v n="$answer" '$1 == n { print $2; exit }')"
  fi

  [ -b "$answer" ] || die "Disco invalido: $answer"
  printf '%s\n' "$answer"
}

choose_timezone() {
  local detected
  local answer
  local manual

  detected="$(detect_timezone)"

  printf '\nTimezone:\n'
  printf '  1) %s [detectado]\n' "$detected"
  printf '  2) UTC\n'
  printf '  3) Digitar manualmente\n'
  answer="$(prompt_with_default "Escolha" "1")"

  case "$answer" in
    1) TIMEZONE="$detected" ;;
    2) TIMEZONE="UTC" ;;
    3)
      manual="$(prompt_with_default "Timezone" "$detected")"
      TIMEZONE="$manual"
      ;;
    *)
      die "Opcao de timezone invalida: $answer"
      ;;
  esac

  timezone_exists "$TIMEZONE" || die "Timezone invalida: $TIMEZONE"
}

choose_graphics_profile() {
  local answer

  printf '\nPerfil grafico:\n'
  printf '  1) %s [detectado]\n' "$GRAPHICS_PROFILE"
  printf '  2) intel\n'
  printf '  3) amd\n'
  printf '  4) nvidia\n'
  printf '  5) hybrid-intel-nvidia\n'
  printf '  6) hybrid-amd-nvidia\n'
  printf '  7) generic\n'
  answer="$(prompt_with_default "Escolha" "1")"

  case "$answer" in
    1) ;;
    2) GRAPHICS_PROFILE="intel" ;;
    3) GRAPHICS_PROFILE="amd" ;;
    4) GRAPHICS_PROFILE="nvidia" ;;
    5) GRAPHICS_PROFILE="hybrid-intel-nvidia" ;;
    6) GRAPHICS_PROFILE="hybrid-amd-nvidia" ;;
    7) GRAPHICS_PROFILE="generic" ;;
    *) die "Perfil grafico invalido: $answer" ;;
  esac
}

choose_partition() {
  local prompt="$1"
  local required="$2"
  local answer=""

  printf '\nParticoes detectadas:\n'
  list_partitions

  if [ "$required" = "yes" ]; then
    while true; do
      read -r -p "$prompt: " answer
      [ -b "$answer" ] && {
        printf '%s\n' "$answer"
        return
      }
      warn "Particao invalida: $answer"
    done
  fi

  read -r -p "$prompt (enter para nenhum): " answer
  if [ -z "$answer" ]; then
    printf '\n'
    return
  fi

  [ -b "$answer" ] || die "Particao invalida: $answer"
  printf '%s\n' "$answer"
}

read_password_twice() {
  local first
  local second

  while true; do
    read -r -s -p "Senha para o usuario $USERNAME: " first
    printf '\n'
    read -r -s -p "Confirme a senha: " second
    printf '\n'

    [ -n "$first" ] || {
      warn "A senha nao pode ser vazia."
      continue
    }

    [ "$first" = "$second" ] || {
      warn "As senhas nao conferem."
      continue
    }

    PASSWORD="$first"
    return
  done
}

validate_hostname() {
  printf '%s\n' "$1" | grep -Eq '^[a-z0-9][a-z0-9-]*$'
}

validate_username() {
  printf '%s\n' "$1" | grep -Eq '^[a-z_][a-z0-9_-]*$'
}

estimate_swap_gib() {
  local mem_gib
  mem_gib="$(awk '/MemTotal/ { printf "%d", ($2 / 1024 / 1024) + 0.5 }' /proc/meminfo)"

  if [ "$mem_gib" -lt 4 ]; then
    printf '4\n'
  elif [ "$mem_gib" -gt 32 ]; then
    printf '32\n'
  else
    printf '%s\n' "$mem_gib"
  fi
}

print_preflight() {
  printf '\nPreflight:\n'
  printf '  boot mode detectado: %s\n' "$BOOT_MODE"
  printf '  loader selecionado: %s\n' "$BOOT_LOADER"
  printf '  perfil da maquina: %s\n' "$MACHINE_PROFILE"
  printf '  perfil grafico sugerido: %s\n' "$GRAPHICS_PROFILE"
  printf '  primeiro boot grafico: %s\n' "$DESKTOP_ENABLE"
  printf '  memoria total: %s GiB\n' "$(awk '/MemTotal/ { printf "%d", ($2 / 1024 / 1024) + 0.5 }' /proc/meminfo)"
  printf '  log: %s\n' "$LOG_FILE"
}

choose_first_boot_mode() {
  local default_choice="1"
  local answer

  if [ "$MACHINE_PROFILE" = "laptop" ] && [ "$GRAPHICS_PROFILE" = "intel" ]; then
    default_choice="2"
  fi

  printf '\nPrimeiro boot apos instalar:\n'
  printf '  1) grafico (Hyprland + SDDM)\n'
  printf '  2) tty seguro\n'
  answer="$(prompt_with_default "Escolha" "$default_choice")"

  case "$answer" in
    1) DESKTOP_ENABLE="true" ;;
    2) DESKTOP_ENABLE="false" ;;
    *) die "Modo de primeiro boot invalido: $answer" ;;
  esac
}

choose_install_mode() {
  local answer

  printf '\nModo de instalacao:\n'
  printf '  1) apagar disco inteiro\n'
  printf '  2) reaproveitar particoes existentes\n'
  answer="$(prompt_with_default "Escolha" "1")"

  case "$answer" in
    1) INSTALL_MODE="wipe" ;;
    2) INSTALL_MODE="reuse" ;;
    *) die "Modo invalido: $answer" ;;
  esac
}

choose_boot_loader() {
  local default_loader
  local answer

  if [ "$BOOT_MODE" = "legacy" ]; then
    default_loader="grub"
  else
    default_loader="systemd-boot"
  fi

  printf '\nBootloader:\n'
  if [ "$BOOT_MODE" = "uefi" ]; then
    printf '  1) systemd-boot\n'
    printf '  2) grub-efi\n'
    answer="$(prompt_with_default "Escolha" "1")"
    case "$answer" in
      1) BOOT_LOADER="systemd-boot" ;;
      2) BOOT_LOADER="grub" ;;
      *) die "Opcao de bootloader invalida: $answer" ;;
    esac
  else
    BOOT_LOADER="grub"
  fi

  [ -n "$BOOT_LOADER" ] || BOOT_LOADER="$default_loader"
}

plan_partitions() {
  case "$INSTALL_MODE" in
    wipe)
      TARGET_DISK="$(choose_disk)"
      SWAP_GIB="$(prompt_with_default "Swap em GiB (0 desabilita)" "$(estimate_swap_gib)")"
      printf '%s\n' "$SWAP_GIB" | grep -Eq '^[0-9]+$' || die "Swap invalido: $SWAP_GIB"
      ;;
    reuse)
      if [ "$BOOT_MODE" = "legacy" ]; then
        TARGET_DISK="$(choose_disk)"
      fi
      ROOT_PART="$(choose_partition "Particao root (/)" yes)"
      if [ "$BOOT_MODE" = "uefi" ]; then
        BOOT_PART="$(choose_partition "Particao EFI (/boot)" yes)"
      else
        SEPARATE_BOOT_PART="$(choose_partition "Particao /boot separada" no)"
        BOOT_PART="$SEPARATE_BOOT_PART"
      fi
      SWAP_PART="$(choose_partition "Particao swap" no)"

      FORMAT_ROOT="$(confirm "Formatar $ROOT_PART ?" "N" && printf 'yes' || printf 'no')"
      if [ -n "$BOOT_PART" ]; then
        FORMAT_BOOT="$(confirm "Formatar $BOOT_PART ?" "N" && printf 'yes' || printf 'no')"
      else
        FORMAT_BOOT="no"
      fi
      if [ -n "$SWAP_PART" ]; then
        FORMAT_SWAP="$(confirm "Recriar assinatura swap em $SWAP_PART ?" "N" && printf 'yes' || printf 'no')"
      else
        FORMAT_SWAP="no"
      fi
      ;;
    *)
      die "Modo de instalacao invalido: $INSTALL_MODE"
      ;;
  esac
}

partition_disk() {
  local disk="$1"
  local swap_gib="$2"
  local root_start_mib
  local expected_root_part

  wait_for_partition_nodes() {
    local expected=("$@")
    local deadline=20
    local found=0

    while [ "$deadline" -gt 0 ]; do
      found=1
      for node in "${expected[@]}"; do
        [ -b "$node" ] || found=0
      done
      if [ "$found" -eq 1 ]; then
        return 0
      fi
      sleep 1
      deadline=$((deadline - 1))
      run_cmd udevadm settle || true
    done

    return 1
  }

  cleanup_mounts

  if [ "$BOOT_MODE" = "uefi" ]; then
    log "Particionando $disk em GPT/UEFI"
    run_cmd wipefs -af "$disk"
    run_cmd parted -s "$disk" mklabel gpt
    run_cmd parted -s "$disk" mkpart ESP fat32 1MiB 1025MiB
    run_cmd parted -s "$disk" set 1 esp on
    BOOT_PART="$(partition_path "$disk" 1)"

    if [ "$swap_gib" -gt 0 ]; then
      root_start_mib=$((1025 + swap_gib * 1024))
      run_cmd parted -s "$disk" mkpart primary linux-swap 1025MiB "${root_start_mib}MiB"
      run_cmd parted -s "$disk" mkpart primary ext4 "${root_start_mib}MiB" 100%
      SWAP_PART="$(partition_path "$disk" 2)"
      ROOT_PART="$(partition_path "$disk" 3)"
      expected_root_part="$ROOT_PART"
    else
      run_cmd parted -s "$disk" mkpart primary ext4 1025MiB 100%
      ROOT_PART="$(partition_path "$disk" 2)"
      SWAP_PART=""
      expected_root_part="$ROOT_PART"
    fi
  else
    log "Particionando $disk em MBR/Legacy"
    run_cmd wipefs -af "$disk"
    run_cmd parted -s "$disk" mklabel msdos
    if [ "$swap_gib" -gt 0 ]; then
      root_start_mib=$((1 + swap_gib * 1024))
      run_cmd parted -s "$disk" mkpart primary linux-swap 1MiB "${root_start_mib}MiB"
      run_cmd parted -s "$disk" mkpart primary ext4 "${root_start_mib}MiB" 100%
      SWAP_PART="$(partition_path "$disk" 1)"
      ROOT_PART="$(partition_path "$disk" 2)"
      expected_root_part="$ROOT_PART"
    else
      run_cmd parted -s "$disk" mkpart primary ext4 1MiB 100%
      ROOT_PART="$(partition_path "$disk" 1)"
      SWAP_PART=""
      expected_root_part="$ROOT_PART"
    fi
    BOOT_PART=""
  fi

  run_cmd sync
  if ! run_cmd partprobe "$disk"; then
    warn "partprobe falhou em $disk; tentando seguir com udevadm settle"
  fi
  run_cmd udevadm settle

  if [ -n "$BOOT_PART" ] && [ -n "$SWAP_PART" ]; then
    wait_for_partition_nodes "$BOOT_PART" "$SWAP_PART" "$ROOT_PART" \
      || die "Particoes nao apareceram em /dev apos particionamento: $BOOT_PART $SWAP_PART $ROOT_PART"
  elif [ -n "$BOOT_PART" ]; then
    wait_for_partition_nodes "$BOOT_PART" "$ROOT_PART" \
      || die "Particoes nao apareceram em /dev apos particionamento: $BOOT_PART $ROOT_PART"
  else
    wait_for_partition_nodes "$ROOT_PART" \
      || die "Particao root nao apareceu em /dev apos particionamento: $ROOT_PART"
  fi
}

format_partitions() {
  if [ "$FORMAT_ROOT" = "yes" ]; then
    log "Formatando root em $ROOT_PART"
    run_cmd mkfs.ext4 -F -L nixos "$ROOT_PART"
  fi

  if [ -n "$BOOT_PART" ] && [ "$FORMAT_BOOT" = "yes" ]; then
    log "Formatando boot em $BOOT_PART"
    run_cmd mkfs.fat -F 32 -n boot "$BOOT_PART"
  fi

  if [ -n "$SWAP_PART" ] && [ "$FORMAT_SWAP" = "yes" ]; then
    log "Criando swap em $SWAP_PART"
    run_cmd mkswap -L swap "$SWAP_PART"
  fi
}

mount_target() {
  log "Montando sistema em $TARGET_ROOT"
  mkdir -p "$TARGET_ROOT"
  run_cmd mount "$ROOT_PART" "$TARGET_ROOT"
  MOUNTED_ROOT=1

  if [ "$BOOT_MODE" = "uefi" ]; then
    [ -n "$BOOT_PART" ] || die "UEFI exige particao EFI montada em /boot."
    mkdir -p "$TARGET_ROOT/boot"
    run_cmd mount -o umask=077 "$BOOT_PART" "$TARGET_ROOT/boot"
    MOUNTED_BOOT=1
  elif [ -n "$BOOT_PART" ]; then
    mkdir -p "$TARGET_ROOT/boot"
    run_cmd mount "$BOOT_PART" "$TARGET_ROOT/boot"
    MOUNTED_BOOT=1
  fi

  if [ -n "$SWAP_PART" ]; then
    run_cmd swapon "$SWAP_PART"
    SWAP_ENABLED=1
  fi
}

prepare_repo_source() {
  if [ -f "$SCRIPT_DIR/flake.nix" ]; then
    REPO_SOURCE="$SCRIPT_DIR"
    return
  fi

  need_cmd git
  REPO_SOURCE="$(mktemp -d /tmp/strata-install-repo.XXXXXX)"
  log "Clonando repositorio $DEFAULT_REPO_URL"
  git clone "$DEFAULT_REPO_URL" "$REPO_SOURCE"
}

copy_repo_to_target() {
  REPO_TARGET="$TARGET_ROOT/home/$USERNAME/dotfiles"

  log "Copiando dotfiles para $REPO_TARGET"
  mkdir -p "$TARGET_ROOT/home/$USERNAME"
  rm -rf "$REPO_TARGET"
  mkdir -p "$REPO_TARGET"
  cp -a "$REPO_SOURCE"/. "$REPO_TARGET"/
  rm -rf "$REPO_TARGET/generated" "$REPO_TARGET/state"
}

seed_repo_state() {
  log "Semeando estado inicial de tema"
  mkdir -p "$REPO_TARGET/state"
  cp "$REPO_TARGET/quickshell/themes/current.json" "$REPO_TARGET/state/current-theme.json"
  printf '%s\n' "$REPO_TARGET/wallpaper.jpg" > "$REPO_TARGET/state/current-wallpaper"
  printf '0\n' > "$REPO_TARGET/state/wallpaper-index"
}

write_host_meta() {
  local meta_path="$REPO_TARGET/hosts/$HOSTNAME/meta.nix"
  local disk_literal="null"

  if [ -n "$TARGET_DISK" ]; then
    disk_literal="\"$TARGET_DISK\""
  fi

  cat > "$meta_path" <<EOF
{
  username = "$USERNAME";
  system = "x86_64-linux";
  profile = "$MACHINE_PROFILE";
  graphics = "$GRAPHICS_PROFILE";
  timeZone = "$TIMEZONE";
  locale = "$LOCALE";
  boot = {
    mode = "$BOOT_MODE";
    loader = "$BOOT_LOADER";
    disk = $disk_literal;
  };
  desktop = {
    enable = $DESKTOP_ENABLE;
  };
}
EOF
}

write_host_monitors() {
  local monitor_path="$REPO_TARGET/hosts/$HOSTNAME/hyprland-monitors.conf"

  cat > "$monitor_path" <<'EOF'
monitor = , preferred, auto, 1
EOF
}

write_host_config() {
  local config_path="$REPO_TARGET/hosts/$HOSTNAME/config.nix"

  case "$GRAPHICS_PROFILE" in
    hybrid-amd-nvidia)
      cat > "$config_path" <<'EOF'
{ ... }:
{
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
      cat > "$config_path" <<'EOF'
{ ... }:
{
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
      cat > "$config_path" <<'EOF'
{ ... }:
{
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
      cat > "$config_path" <<'EOF'
{ ... }:
{
  services.xserver.videoDrivers = [ "amdgpu" ];
}
EOF
      ;;
    intel)
      cat > "$config_path" <<'EOF'
{ lib, ... }:
{
  # Mitigacao inicial para iGPU Intel em notebooks sensiveis a PSR.
  boot.kernelParams = lib.mkForce [ "i915.enable_psr=0" ];
}
EOF
      ;;
    generic)
      cat > "$config_path" <<'EOF'
{ ... }: { }
EOF
      ;;
    *)
      die "Perfil grafico invalido: $GRAPHICS_PROFILE"
      ;;
  esac
}

import_generated_hardware() {
  local generated="$TARGET_ROOT/etc/nixos/hardware-configuration.nix"
  local destination="$REPO_TARGET/hosts/$HOSTNAME/hardware.nix"

  [ -f "$generated" ] || die "hardware-configuration.nix nao foi gerado em $generated"
  cp "$generated" "$destination"
}

prepare_host_tree() {
  log "Gerando arquivos do host $HOSTNAME"
  mkdir -p "$REPO_TARGET/hosts/$HOSTNAME"
  import_generated_hardware
  write_host_meta
  write_host_config
  write_host_monitors
}

validate_generated_host() {
  log "Validando host gerado"
  nix eval --impure --json "path:$REPO_TARGET#nixosConfigurations.$HOSTNAME.config.networking.hostName" >/dev/null
}

install_system() {
  log "Gerando configuracao de hardware"
  nixos-generate-config --root "$TARGET_ROOT"

  copy_repo_to_target
  seed_repo_state
  prepare_host_tree
  validate_generated_host

  if [ "$DRY_RUN" -eq 1 ]; then
    log "Dry-run ativo: instalacao encerrada antes do nixos-install"
    return
  fi

  log "Instalando NixOS com flake path:$REPO_TARGET#$HOSTNAME"
  nixos-install --root "$TARGET_ROOT" --flake "path:$REPO_TARGET#$HOSTNAME" --no-root-passwd
}

set_installed_user_password() {
  [ "$DRY_RUN" -eq 0 ] || return
  log "Definindo senha do usuario $USERNAME"
  printf '%s:%s\n' "$USERNAME" "$PASSWORD" | nixos-enter --root "$TARGET_ROOT" -c 'chpasswd'
}

fix_target_ownership() {
  [ "$DRY_RUN" -eq 0 ] || return
  log "Ajustando ownership do repositorio do usuario"
  nixos-enter --root "$TARGET_ROOT" -c "chown -R $USERNAME:users /home/$USERNAME/dotfiles"
}

bootstrap_target_theme() {
  [ "$DRY_RUN" -eq 0 ] || return
  log "Materializando generated/* no sistema instalado"
  nixos-enter --root "$TARGET_ROOT" -c "su - $USERNAME -c 'bash /home/$USERNAME/dotfiles/quickshell/scripts/apply-theme-state.sh'" || true
}

persist_log_into_target() {
  if mountpoint -q "$TARGET_ROOT"; then
    mkdir -p "$TARGET_ROOT/var/log"
    cp "$LOG_FILE" "$TARGET_ROOT/var/log/strata-install.log" || true
  fi
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run)
        DRY_RUN=1
        ;;
      --allow-non-installer)
        ALLOW_NON_INSTALLER=1
        ;;
      *)
        die "Argumento invalido: $1"
        ;;
    esac
    shift
  done
}

main() {
  parse_args "$@"

  [ "$(id -u)" -eq 0 ] || die "Execute este instalador como root."
  require_installer_environment

  need_cmd lsblk
  need_cmd parted
  need_cmd mkfs.ext4
  need_cmd nixos-generate-config
  need_cmd nixos-install
  need_cmd nixos-enter
  need_cmd wipefs
  need_cmd nix

  BOOT_MODE="$(detect_boot_mode)"
  MACHINE_PROFILE="$(detect_machine_profile)"
  GRAPHICS_PROFILE="$(detect_graphics_profile)"

  if [ "$BOOT_MODE" = "uefi" ]; then
    need_cmd mkfs.fat
  fi

  printf '=== Strata Installer ===\n'
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'Modo: dry-run\n'
  fi

  choose_install_mode
  choose_boot_loader
  choose_timezone
  choose_graphics_profile
  choose_first_boot_mode
  print_preflight

  HOSTNAME="$(prompt_with_default "Hostname" "$(hostname | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' '-')" )"
  validate_hostname "$HOSTNAME" || die "Hostname invalido. Use apenas minusculas, numeros e hifens."

  USERNAME="$(prompt_with_default "Usuario principal" "ankh")"
  validate_username "$USERNAME" || die "Usuario invalido. Prefira minusculas, numeros, '_' e '-'."

  if [ "$DRY_RUN" -eq 0 ]; then
    read_password_twice
  else
    PASSWORD="dry-run"
  fi

  plan_partitions

  printf '\nResumo da instalacao:\n'
  printf '  modo: %s\n' "$INSTALL_MODE"
  printf '  boot mode: %s\n' "$BOOT_MODE"
  printf '  bootloader: %s\n' "$BOOT_LOADER"
  printf '  hostname: %s\n' "$HOSTNAME"
  printf '  usuario: %s\n' "$USERNAME"
  printf '  timezone: %s\n' "$TIMEZONE"
  printf '  perfil da maquina: %s\n' "$MACHINE_PROFILE"
  printf '  perfil grafico: %s\n' "$GRAPHICS_PROFILE"
  printf '  boot grafico inicial: %s\n' "$DESKTOP_ENABLE"
  printf '  disco: %s\n' "${TARGET_DISK:-<nao definido>}"
  printf '  root: %s\n' "${ROOT_PART:-<a definir>}"
  printf '  boot: %s\n' "${BOOT_PART:-<sem particao separada>}"
  printf '  swap: %s\n' "${SWAP_PART:-<sem swap>}"
  printf '  log: %s\n' "$LOG_FILE"

  confirm "Continuar com o plano acima?" "N" || die "Instalacao cancelada."

  prepare_repo_source

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '\nDry-run concluido.\n'
    printf 'Nenhuma particao foi formatada e nenhuma instalacao foi iniciada.\n'
    printf 'Repositorio fonte validado em %s.\n' "$REPO_SOURCE"
    return
  fi

  if [ "$INSTALL_MODE" = "wipe" ]; then
    [ -n "$TARGET_DISK" ] || die "Disco alvo ausente."
    confirm "Apagar completamente $TARGET_DISK?" "N" || die "Instalacao cancelada."
    partition_disk "$TARGET_DISK" "$SWAP_GIB"
  fi

  format_partitions
  mount_target
  install_system
  set_installed_user_password
  fix_target_ownership
  bootstrap_target_theme
  persist_log_into_target

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '\nDry-run concluido. Nenhum sistema foi instalado.\n'
    printf 'As particoes continuam montadas em %s para inspecao.\n' "$TARGET_ROOT"
    return
  fi

  printf '\nInstalacao concluida.\n'
  printf 'Sistema instalado em %s como host %s.\n' "$TARGET_ROOT" "$HOSTNAME"
  printf 'Log salvo em %s e copiado para /var/log/strata-install.log.\n' "$LOG_FILE"
  printf 'Reinicie quando estiver pronto.\n'
}

main "$@"

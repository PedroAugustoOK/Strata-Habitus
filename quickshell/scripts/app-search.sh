#!/usr/bin/env bash

MODE=$1
CACHE="$HOME/.cache/strata-nix-packages.txt"
FCACHE="$HOME/.cache/strata-flatpak-packages.txt"

ACCENT=$(cat ~/.config/quickshell/themes/current.json 2>/dev/null | grep -o '"accent":"[^"]*"' | cut -d'"' -f4)
BG0=$(cat ~/.config/quickshell/themes/current.json 2>/dev/null | grep -o '"bg0":"[^"]*"' | cut -d'"' -f4)
BG1=$(cat ~/.config/quickshell/themes/current.json 2>/dev/null | grep -o '"bg1":"[^"]*"' | cut -d'"' -f4)
[ -z "$ACCENT" ] && ACCENT="#d79921"
[ -z "$BG0" ]    && BG0="#0d0d0f"
[ -z "$BG1" ]    && BG1="#111113"
AC="${ACCENT#\#}"; B0="${BG0#\#}"; B1="${BG1#\#}"
R1=$(printf '%d' 0x${AC:0:2})
R2=$(printf '%d' 0x${AC:2:2})
R3=$(printf '%d' 0x${AC:4:2})
AR="\033[38;2;${R1};${R2};${R3}m"
D="\033[2m"; R="\033[0m"

FZF_BASE=(
  --height=100%
  --border=none
  --prompt="  > "
  --pointer="▶"
  --color="fg:#555555,fg+:#${AC},bg:#${B0},bg+:#${B1},pointer:#${AC},prompt:#${AC},header:#${AC},info:#333333,separator:#1a1a1a,scrollbar:#222222,hl:#${AC},hl+:#${AC}"
  --no-info
  --margin=1,2
)

refresh_nix_cache() {
  if [ ! -f "$CACHE" ] || [ "$(find "$CACHE" -mtime +1 2>/dev/null)" ]; then
    echo -e "${AR}  atualizando cache nix (~1min)...${R}"
    nix-env -qaP --description 2>/dev/null \
      | awk '{attr=$1;ver=$2;desc="";for(i=3;i<=NF;i++)desc=desc" "$i;sub(/^nixos\./,"",attr);print attr"\t"ver"\t"desc}' \
      > "$CACHE"
  fi
}

refresh_flatpak_cache() {
  if [ ! -f "$FCACHE" ] || [ "$(find "$FCACHE" -mtime +1 2>/dev/null)" ]; then
    echo -e "${AR}  atualizando cache flatpak...${R}"
    flatpak remote-ls flathub --app --columns=name,description,application 2>/dev/null \
      | awk -F'\t' '{print $1"\t"$2"\t"$3}' \
      > "$FCACHE"
  fi
}

get_installed_nix() {
  awk '/environment\.systemPackages = with pkgs;/,/^\s*\];/' ~/dotfiles/modules/packages.nix \
    | grep -v '#\|{\|}\|=\|import\|pkgs\|mkDerivation\|installPhase\|dontBuild\|pname\|version\|\.\|src \|cp \|mkdir\|ln \|environment\|systemPackages\|with ' \
    | tr ' ' '\n' \
    | grep -E '^[a-zA-Z][a-zA-Z0-9_-]+$' \
    | sort -u
}

case "$MODE" in
  nix_install)
    refresh_nix_cache
    result=$(cat "$CACHE" \
      | fzf "${FZF_BASE[@]}" \
        --header=$'  nix — buscar e instalar\n  esc = fechar\n' \
        --header-first \
        --delimiter=$'\t' \
        --with-nth='1' \
        --preview="printf \"\033[38;2;${R1};${R2};${R3}mpacote:\033[0m    %s\n\033[38;2;${R1};${R2};${R3}mversão:\033[0m    %s\n\033[38;2;${R1};${R2};${R3}mdescrição:\033[0m %s\n\" {1} {2} {3}" \
        --preview-window='down:5:wrap')
    [ -z "$result" ] && exit 0
    pkg=$(echo "$result" | cut -f1 | xargs)
    clear
    echo -e "\n  ${AR}pacote:${R}    $pkg"
    echo -e "  ${AR}versão:${R}    $(echo "$result" | cut -f2 | xargs)"
    echo -e "  ${AR}descrição:${R} $(echo "$result" | cut -f3 | xargs)\n"
    echo -e "  ${AR}adicionando ao configuration.nix...${R}"
    sed -i "/hplipWithPlugin glib vesktop/a\    $pkg" ~/dotfiles/modules/packages.nix
    echo -e "  ${AR}rebuilding nixos...${R}\n"
    if sudo nixos-rebuild switch --flake ~/dotfiles#$(hostname) 2>&1 | grep -E "building|copying|activating|error|warning|Done" | tail -8; then
      echo -e "\n  ${AR}✓ ${pkg} instalado!${R}\n  ${D}enter para fechar${R}"
    else
      echo -e "\n  ${AR}✗ falha — revertendo...${R}"
      sed -i "/^\s*${pkg}\s*$/d" ~/dotfiles/modules/packages.nix
      sudo nixos-rebuild switch --rollback 2>/dev/null || true
      echo -e "  ${AR}revertido.${R}\n  ${D}enter para fechar${R}"
    fi
    read -r
    ;;

  flatpak_install)
    refresh_flatpak_cache
    result=$(cat "$FCACHE" \
      | fzf "${FZF_BASE[@]}" \
        --header=$'  flatpak — buscar e instalar\n  esc = fechar\n' \
        --header-first \
        --delimiter=$'\t' \
        --with-nth='1' \
        --preview="printf \"\033[38;2;${R1};${R2};${R3}mnome:\033[0m      %s\n\033[38;2;${R1};${R2};${R3}mdescrição:\033[0m %s\n\033[38;2;${R1};${R2};${R3}mapp id:\033[0m    %s\n\" {1} {2} {3}" \
        --preview-window='down:5:wrap')
    [ -z "$result" ] && exit 0
    appid=$(echo "$result" | cut -f3 | xargs)
    name=$(echo "$result" | cut -f1 | xargs)
    desc=$(echo "$result" | cut -f2 | xargs)
    clear
    echo -e "\n  ${AR}nome:${R}      $name"
    echo -e "  ${AR}descrição:${R} $desc"
    echo -e "  ${AR}app id:${R}    $appid\n"
    echo -e "  ${AR}instalando...${R}\n"
    flatpak install -y "$appid" 2>&1 | grep -E "Instalando|Installing|erro|error" | tail -5
    echo -e "\n  ${AR}✓ instalado!${R}\n  ${D}enter para fechar${R}"
    read -r
    ;;

  nix_remove)
    result=$(get_installed_nix \
      | fzf "${FZF_BASE[@]}" \
        --header=$'  nix — remover\n  esc = fechar\n' \
        --header-first)
    [ -z "$result" ] && exit 0
    pkg=$(echo "$result" | xargs)
    clear
    echo -e "\n  ${AR}removendo ${pkg}...${R}"
    sed -i "/^\s*${pkg}\s*$/d" ~/dotfiles/modules/packages.nix
    echo -e "  ${AR}rebuilding nixos...${R}\n"
    if sudo nixos-rebuild switch --flake ~/dotfiles#$(hostname) 2>&1 | grep -E "building|copying|activating|error|warning|Done" | tail -8; then
      echo -e "\n  ${AR}✓ ${pkg} removido!${R}\n  ${D}enter para fechar${R}"
    else
      echo -e "\n  ${AR}✗ falha — revertendo...${R}"
      sed -i "/^\s*\];/i\    $pkg" ~/dotfiles/modules/packages.nix
      sudo nixos-rebuild switch --rollback 2>/dev/null || true
      echo -e "  ${AR}revertido.${R}\n  ${D}enter para fechar${R}"
    fi
    read -r
    ;;

  flatpak_remove)
    result=$(flatpak list --app --columns=name,application 2>/dev/null \
      | awk -F'\t' '{print $1"\t"$2}' \
      | fzf "${FZF_BASE[@]}" \
        --header=$'  flatpak — remover\n  esc = fechar\n' \
        --header-first \
        --delimiter=$'\t' \
        --with-nth='1' \
        --preview="printf \"\033[38;2;${R1};${R2};${R3}mnome:\033[0m   %s\n\033[38;2;${R1};${R2};${R3}mapp id:\033[0m %s\n\" {1} {2}" \
        --preview-window='down:4:wrap')
    [ -z "$result" ] && exit 0
    appid=$(echo "$result" | cut -f2 | xargs)
    name=$(echo "$result" | cut -f1 | xargs)
    clear
    echo -e "\n  ${AR}removendo ${name}...${R}\n"
    flatpak uninstall -y "$appid"
    echo -e "\n  ${AR}✓ removido!${R}\n  ${D}enter para fechar${R}"
    read -r
    ;;
esac

#!/usr/bin/env bash
set -e

echo "=== Strata Habitus Installer ==="
read -p "Username desejado: " USERNAME
echo "Targets disponíveis:"
echo "  1) nixos (Intel, sem GPU dedicada)"
echo "  2) desktop (NVIDIA)"
read -p "Escolha (1 ou 2): " TARGET_NUM

if [ "$TARGET_NUM" = "2" ]; then
  TARGET="desktop"
else
  TARGET="nixos"
fi

if [ ! -d "$HOME/dotfiles/.git" ]; then
  rm -rf "$HOME/dotfiles"
  nix-shell -p git --run "git clone https://github.com/PedroAugustoOK/Strata-Habitus.git $HOME/dotfiles"
else
  echo "Dotfiles já existem, atualizando..."
  nix-shell -p git --run "git -C $HOME/dotfiles pull"
fi

sed -i "s/username = \"ankh\"/username = \"$USERNAME\"/" ~/dotfiles/flake.nix

sudo nixos-rebuild switch --flake ~/dotfiles#$TARGET

echo "=== Instalação concluída! Reinicie o sistema. ==="

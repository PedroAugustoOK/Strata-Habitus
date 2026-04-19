#!/usr/bin/env bash
set -e

echo "=== Strata Habitus Installer ==="
read -p "Username desejado: " USERNAME

# Usa git do nix-shell se necessário
GIT=$(which git 2>/dev/null || echo "nix-shell -p git --run git")

# Clona os dotfiles se não existir
if [ ! -d "$HOME/dotfiles/.git" ]; then
  rm -rf "$HOME/dotfiles"
  nix-shell -p git --run "git clone https://github.com/PedroAugustoOK/Strata-Habitus.git $HOME/dotfiles"
else
  echo "Dotfiles já existem, atualizando..."
  nix-shell -p git --run "git -C $HOME/dotfiles pull"
fi

# Atualiza o username no flake
sed -i "s/username = \"ankh\"/username = \"$USERNAME\"/" ~/dotfiles/flake.nix

# Aplica o sistema
sudo nixos-rebuild switch --flake ~/dotfiles#galaxybook

echo "=== Instalação concluída! Reinicie o sistema. ==="

#!/usr/bin/env bash
set -e

echo "=== Strata Habitus Installer ==="
read -p "Username desejado: " USERNAME

# Clona os dotfiles se não existir
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/PedroAugustoOK/Strata-Habitus.git ~/dotfiles
else
  echo "Dotfiles já existem, usando os existentes..."
  cd ~/dotfiles && git pull
fi

# Atualiza o username no flake
sed -i "s/username = \"ankh\"/username = \"$USERNAME\"/" ~/dotfiles/flake.nix

# Aplica o sistema
sudo nixos-rebuild switch --flake ~/dotfiles#galaxybook

echo "=== Instalação concluída! ==="
echo "Reinicie o sistema."

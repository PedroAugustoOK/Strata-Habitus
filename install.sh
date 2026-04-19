#!/usr/bin/env bash
# Strata Habitus - Script de instalação
set -e

echo "=== Strata Habitus Installer ==="
read -p "Username desejado: " USERNAME

# Clona os dotfiles
git clone https://github.com/PedroAugustoOK/Strata-Habitus.git ~/dotfiles

# Atualiza o username no flake
sed -i "s/username = \"ankh\"/username = \"$USERNAME\"/" ~/dotfiles/flake.nix

# Aplica o sistema
sudo nixos-rebuild switch --flake ~/dotfiles#galaxybook

echo "=== Instalação concluída! ==="
echo "Reinicie o sistema."

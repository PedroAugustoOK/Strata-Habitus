# Strata Habitus — Melhorias pendentes

### eza + bat + zoxide
Substitutas modernas para `ls`, `cat` e `cd`.
- `eza`: listagem com ícones, cores e git status
- `bat`: cat com syntax highlighting e numeração
- `zoxide`: cd inteligente que aprende os dirs mais usados (`z dotfiles`)

Para implementar:
- Adicionar `eza bat zoxide` em `modules/packages.nix`
- Adicionar em `fish/config.fish`:
  ```fish
  zoxide init fish | source
  abbr -a ls  'eza --icons'
  abbr -a ll  'eza -lah --icons --git'
  abbr -a cat 'bat'
  ```

### stylix
Sistema de temas declarativo via Nix que propaga cores automaticamente para
todos os apps (kitty, fish, mako, nvim, hyprlock, etc.), eliminando o
`set-theme.sh` de 290 linhas.

Para implementar:
- Adicionar `stylix` como input no `flake.nix`
- Configurar `stylix.image` (wallpaper base para gerar paleta)
- Configurar `stylix.base16Scheme` com o tema desejado
- Remover o sistema manual de temas (set-theme.sh, themes/*.json, etc.)

### hardware-configuration do desktop
Gerar o arquivo de hardware na máquina desktop com:
```bash
sudo nixos-generate-config --show-hardware-config > ~/dotfiles/hosts/desktop/hardware.nix
```
O arquivo placeholder está em `hosts/desktop/hardware.nix`.

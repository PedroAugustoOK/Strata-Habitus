# Strata Context

## Como usar
- No inicio de uma nova sessao, ler este arquivo primeiro.
- No fim de uma sessao importante, atualizar este arquivo com o estado real.
- Este arquivo deve registrar decisao, estado e proximo passo, nao brainstorming.

## Projeto
- Nome: Strata
- Repo: `/home/ankh/dotfiles`
- Tipo: setup NixOS/Home Manager com Hyprland, Quickshell, theming manual e utilitarios do desktop
- Host principal visto no repo: `nixos`
- Host adicional no flake: `desktop`

## Ponto atual
- O Strata esta ativo neste repo, nao existe um app separado com esse nome no workspace atual.
- O trabalho recente esta concentrado em tema, wallpaper, Quickshell e ajustes de ambiente.
- O repo esta em `main` e localmente esta `ahead 32` de `origin/main`.
- Existem mudancas locais nao commitadas; assumir arvore dirty antes de qualquer alteracao.
- Backup manual criado antes da refatoracao do motor de temas em `/home/ankh/dotfiles_backup/strata_pre_theme_refactor_20260421_211304`.
- O novo motor de temas foi aplicado e validado em runtime em boa parte do fluxo, mas ainda restam arestas no Kitty e no theming GTK/Papirus.
- O estado ativo do tema/wallpaper agora vive em `state/`, e os arquivos derivados sao gerados em `generated/`.

## Mudancas locais abertas
- `.gitignore`
- `configuration.nix`
- `fish/config.fish`
- `flake.lock`
- `home.nix`
- `hyprlock.conf`
- `hyprland.conf`
- `install.sh`
- `kitty/kitty.conf`
- `modules/desktop.nix`
- `modules/packages.nix`
- `nvim/lazy-lock.json`
- `nvim/lua/config/lazy.lua`
- `nvim/lua/plugins/theme.lua`
- `nvim/lua/plugins/ui.lua`
- `quickshell/Colors.qml`
- `quickshell/Paths.qml`
- `quickshell/bar/StatusRight.qml`
- `quickshell/controlcenter/ControlCenter.qml`
- `quickshell/launcher/Launcher.qml`
- `quickshell/scripts/app-manager.sh`
- `quickshell/scripts/app-search.sh`
- `quickshell/scripts/index-apps.sh`
- `quickshell/scripts/init-border.sh`
- `quickshell/scripts/set-theme.sh`
- `quickshell/scripts/theme-switch.sh`
- `quickshell/scripts/update-sddm-accent.sh`
- `quickshell/scripts/apply-theme-state.sh`
- `quickshell/scripts/battery-status.sh`
- `quickshell/scripts/wifi-name.sh`
- `quickshell/scripts/wifi-status.sh`
- `quickshell/scripts/wallpaper-switch.sh`
- `quickshell/scripts/wallpaper.sh`
- `quickshell/themepicker/ThemePicker.qml`
- `quickshell/wallpickr/WallPickr.qml`
- `STRATA_CONTEXT.md`

## O que ja da para afirmar
- `flake.nix` define `description = "strata"` e expoe os hosts `nixos` e `desktop`.
- O sistema ainda usa mecanismo manual de tema; a migracao para `stylix` nao foi concluida.
- `home.nix` esta centralizando links declarativos para Hyprland, Quickshell, Kitty, Fish, Fastfetch, Git, SSH e Nvim.
- `modules/packages.nix` ja contem parte relevante do ambiente grafico e de desenvolvimento, incluindo `quickshell`, `matugen`, `ollama`, `codex`, `qgis`, `direnv` e `nix-direnv`.
- A partir desta sessao, o estado ativo do tema/wallpaper esta sendo movido para `state/` e os arquivos derivados para `generated/`, ambos gitignorados.
- A direcao definida e manter temas autorais do Strata, sem adotar `stylix` por enquanto.
- O launcher do Quickshell passou a usar `.desktop` via `gio launch`, em vez de executar `Exec=` cru.
- Bateria e Wi-Fi no Quickshell foram extraidos para scripts dedicados, evitando comandos inline fragis no QML.
- `fish/config.fish` agora contem a funcao `codex-safe`, que troca a tecla de interrupcao para `Ctrl+]` enquanto o Codex roda e restaura depois.

## Pendencias registradas
- Corrigir o reload visual do Kitty no `rosepine`; o tema personalizado foi gerado, mas o usuario ainda nao percebeu mudanca visual na janela aberta.
- Fazer a cor dos icones de pasta do Papirus seguir cada tema de forma confiavel a cada troca, nao apenas no primeiro apply.
- Deixar o Nautilus/coerencia GTK mais solido entre sidebar e area principal em todos os temas, evitando combinacoes claras/escuras inconsistentes.
- Buscar wallpapers para os temas novos.

## Ultimo contexto recuperado
- O historico recente do git mostra trocas de tema como `gruvbox` e `nord`.
- A decisao atual e nao usar `stylix`; a direcao e manter temas autorais e separar `state/` de `generated/`.
- A sessao atual confirmou que o foco recente nao era um produto separado, e sim o proprio setup Strata neste repo.
- O tema ativo no estado atual esta em `nord`.
- O usuario pediu protecao contra fechamento acidental do Codex por `Ctrl+C`; isso foi resolvido com a funcao `codex-safe`.
- `modules/packages.nix` agora inclui `eza`, `bat` e `zoxide`.
- `fish/config.fish` agora inicializa `zoxide` e define abbrs para `ls`, `ll` e `cat`.
- `hosts/desktop/hardware.nix` ja esta preenchido com configuracao real; nao e mais placeholder.
- A checagem esttica dos scripts do motor de temas passou em `bash -n`; nao apareceu quebra estrutural.
- O rebuild foi executado com sucesso nesta sessao.
- Foram adicionados os temas `tokyonight`, `everforest`, `kanagawa`, `catppuccinlatte`, `flexoki` e `oxocarbon`, integrados ao ThemePicker e ao ciclo de temas.
- O launcher do Quickshell agora faz indexacao mais rica e ranking por nome, generic name, keywords e desktop file.
- O Nvim agora reage em tempo real a mudanca do arquivo `generated/nvim/theme.lua`.
- O Kitty ganhou tentativa de reload em runtime via remote control, mas o caso do `rosepine` ainda nao foi resolvido visualmente.
- `papirus-folders` foi adicionado e a logica de recolorir pastas por tema foi introduzida, mas ainda nao esta consistente no runtime.
- Foram adicionados binds pensados para teclado 68%, incluindo screenshot, volume, brilho e media.
- `home.nix` agora declara `xdg.userDirs` com nomes em portugues e `createDirectories = true`, cobrindo Desktop, Documentos, Downloads, Musica, Imagens, Publico, Modelos e Videos.

## Proximo passo recomendado
- Corrigir primeiro o reload do Kitty no `rosepine` e a recoloracao confiavel dos icones de pasta do Papirus.
- Refinar o theming GTK/Nautilus para manter sidebar e area principal coesas em todos os temas.
- Adicionar wallpapers para os temas novos.
- Se algo quebrar no motor de temas, restaurar do backup e comparar o diff da refatoracao.

## Regras de retomada
- Ler este arquivo primeiro.
- Conferir `git status --short --branch`.
- Nao assumir que mudancas locais podem ser descartadas.
- Se houver duvida sobre onde paramos, usar este arquivo como fonte principal e `NOTES.md` como complemento.

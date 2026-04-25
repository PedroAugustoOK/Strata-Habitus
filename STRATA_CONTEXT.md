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
- O trabalho recente esta concentrado em tema, wallpaper, Quickshell, fluxo de release por canal e estabilidade do boot grafico.
- O repo esta em `main`; `origin/main` e `origin/stable` existem e hoje apontam para o commit `f372c93`.
- A arvore local esta limpa neste momento.
- Backup manual criado antes da refatoracao do motor de temas em `/home/ankh/dotfiles_backup/strata_pre_theme_refactor_20260421_211304`.
- O novo motor de temas foi aplicado e validado em runtime em boa parte do fluxo, mas ainda restam arestas no Kitty e no theming GTK/Papirus.
- O estado ativo do tema/wallpaper agora vive em `state/`, e os arquivos derivados sao gerados em `generated/`.
- O notebook (`hostname = nixos`) foi sincronizado a partir do `origin/main` depois de salvar o estado antigo em branch de backup local; em geral funcionou, mas pequenas quebras permaneceram e devem ser corrigidas la.
- A sessao de 2026-04-22 passou a focar no problema de boot grafico: o usuario relatou que `Hyprland` sobe manualmente no TTY, mas apos reboot o sistema volta a parecer "quebrado".
- O usuario depois informou que o mesmo sintoma tambem ocorre no notebook; a estrategia passou a ser estruturar uma camada comum para depuracao grafica e separar o que e especifico de GPU por host.

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
- `modules/graphics-debug.nix`
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
- `hosts/nixos/config.nix`

## O que ja da para afirmar
- `flake.nix` define `description = "strata"` e expoe os hosts `nixos` e `desktop`.
- O sistema ainda usa mecanismo manual de tema; a migracao para `stylix` nao foi concluida.
- `home.nix` esta centralizando links declarativos para Hyprland, Quickshell, Kitty, Fish, Fastfetch, Git, SSH e Nvim.
- `modules/packages.nix` ja contem parte relevante do ambiente grafico e de desenvolvimento, incluindo `quickshell`, `matugen`, `ollama`, `codex`, `qgis`, `direnv` e `nix-direnv`.
- No host `desktop`, a saida de video ativa esta na iGPU AMD (`amdgpu`, `DP-2`); `nvidia-drm` sobe sem conectores (`Cannot find any crtc or sizes`), entao forcar `videoDrivers = [ "nvidia" ]` quebra ou deixa instavel o login Wayland.
- Na sessao de 2026-04-22 foi confirmado que a hipotese "o `nixos-rebuild test` nao persistiu" nao explica sozinha o estado atual do `desktop`: o sistema atual ja estava na geracao persistente `15`, com perfil `/nix/var/nix/profiles/system -> system-15-link`, apontando para `nixos-system-desktop-26.05.20260418.b12141e`.
- O boot atual observado nessa investigacao ocorreu em `2026-04-22 09:39`; o perfil persistente da geracao `15` ja existia desde `2026-04-21 22:58`.
- No `desktop`, o `display-manager.service` estava `active (running)` apos o boot investigado; os logs mostraram o `sddm` iniciando com sucesso, o greeter Wayland subindo em `VT1` e o monitor correto `DP-2` sendo detectado e usado pelo Weston do SDDM.
- Ainda no `desktop`, `loginctl list-sessions` mostrou a sessao do usuario em `tty3` enquanto o greeter do SDDM estava em `tty1`; portanto parte do sintoma pode ser simplesmente cair em outro TTY apos boot, mesmo com o greeter vivo no `tty1`.
- O `desktop` continua com indicao forte de conflito/ambiguidade no hibrido AMD/NVIDIA: o framebuffer ativo e os conectores de video uteis estao na AMD, mas a `seat0` ainda exibe a NVIDIA como `drm:card0` master.
- O log relevante do `desktop` nesta sessao mostrou, ao mesmo tempo:
  - `amdgpu` detectando `DP-2` conectado e inicializando o framebuffer principal;
  - `nvidia-drm` inicializando sem conectores validos e registrando `Cannot find any crtc or sizes`;
  - o SDDM carregando o tema em `/var/lib/strata`, subindo greeter Wayland e adicionando view para `DP-2`.
- O tema custom do SDDM parece funcional o bastante para boot: o `display-manager` sobe, o greeter conecta, e o monitor principal e reconhecido; apareceu um aviso de `XMLHttpRequest` local no QML do tema (`file:///var/lib/strata/theme.conf`), mas nao ha evidencias nesta sessao de que isso seja a causa principal do sumico da tela de login.
- A partir desta sessao, o estado ativo do tema/wallpaper esta sendo movido para `state/` e os arquivos derivados para `generated/`, ambos gitignorados.
- A direcao definida e manter temas autorais do Strata, sem adotar `stylix` por enquanto.
- O launcher do Quickshell passou a usar `.desktop` via `gio launch`, em vez de executar `Exec=` cru.
- Bateria e Wi-Fi no Quickshell foram extraidos para scripts dedicados, evitando comandos inline fragis no QML.
- `fish/config.fish` agora contem a funcao `codex-safe`, que troca a tecla de interrupcao para `Ctrl+]` enquanto o Codex roda e restaura depois.
- O host `nixos` ainda nao tinha modulo proprio de override grafico; em `hosts/nixos/` so existiam `hardware.nix` e `hyprland-monitors.conf`.
- A estrategia decidida nesta sessao foi separar o problema em duas camadas:
  - camada comum de debug grafico/boot;
  - camada especifica por host para escolha de GPU, `videoDrivers` e overrides do stack grafico.
- Para implementar isso, foram criados:
  - `modules/graphics-debug.nix`, modulo comum que faz `boot.kernelParams = lib.mkForce []`, `boot.plymouth.enable = lib.mkForce false` e `boot.initrd.verbose = lib.mkForce true`;
  - `hosts/nixos/config.nix`, que importa o modulo comum para o notebook;
  - ajuste em `hosts/desktop/config.nix`, que agora importa o modulo comum e fica focado apenas no override especifico do host hibrido.
- `flake.nix` foi atualizado para incluir `./hosts/nixos/config.nix` no host `nixos`.
- A estrutura nova foi validada por avaliacao do flake via `path:/home/ankh/dotfiles`:
  - `nixosConfigurations.desktop.config.networking.hostName` resolve para `"desktop"`;
  - `nixosConfigurations.desktop.config.services.xserver.videoDrivers` resolve para `["amdgpu","nvidia"]`;
  - `nixosConfigurations.nixos.config.boot.plymouth.enable` resolve para `false`.
- A validacao inicial com `nix eval /home/ankh/dotfiles#...` falhou porque os novos arquivos ainda nao estavam rastreados pelo Git; como o flake estava sendo lido pelo snapshot do repo, o `nix` nao via `modules/graphics-debug.nix` nem `hosts/nixos/config.nix`. A contornacao validada foi usar `path:/home/ankh/dotfiles#...` durante a fase dirty/untracked.

## Pendencias registradas
- No notebook, corrigir o boot grafico para que o SDDM apareca e o login em Hyprland funcione sem cair no TTY.
- Validar no notebook se o mismatch entre sessao `hyprland` e `uwsm-managed` tambem ocorre la, em vez de assumir que o problema e identico ao desktop.
- Aplicar os `switch` nos dois hosts e observar o comportamento apos reboot com a nova camada comum de debug grafico.
- No `desktop`, confirmar depois do rebuild se `Ctrl+Alt+F1` mostra o SDDM quando o usuario achar que "voltou para o TTY", para separar problema de VT errado de problema real de stack grafico.
- No `desktop`, continuar investigando como deixar a AMD inequivocamente como controladora da sessao grafica, mantendo a NVIDIA apenas para CUDA/apps.
- No `nixos`, descobrir a topologia grafica real do notebook antes de copiar qualquer override do `desktop`; nao assumir que o fix de GPU e identico entre as maquinas.
- Corrigir o reload visual do Kitty no `rosepine`; o tema personalizado foi gerado, mas o usuario ainda nao percebeu mudanca visual na janela aberta.
- Fazer a cor dos icones de pasta do Papirus seguir cada tema de forma confiavel a cada troca, nao apenas no primeiro apply.
- Deixar o Nautilus/coerencia GTK mais solido entre sidebar e area principal em todos os temas, evitando combinacoes claras/escuras inconsistentes.
- Buscar wallpapers para os temas novos.
- Revisar no notebook as pequenas regressões apos a sincronizacao; o usuario vai exportar este contexto para la e instalar/abrir o Codex naquela maquina para continuar o reparo diretamente.

## Ultimo contexto recuperado
- Foram publicados os commits:
  - `0eab9be` `Add release channel workflow`
  - `f372c93` `Add fish shortcuts for release workflow`
- O repo agora tem fluxo de "distro caseira" com canais Git:
  - `main` para desenvolvimento/teste
  - `stable` para o notebook
- Foram adicionados:
  - `RELEASES.md`
  - `strata-promote-release.sh`
  - `strata-apply-channel.sh`
- `hosts/desktop/meta.nix` segue `channel = "main"`.
- `hosts/nixos/meta.nix` e `hosts/strata/meta.nix` seguem `channel = "stable"`.
- `modules/update.nix` passou a respeitar `hostMeta.updates` com `enable`, `auto` e `channel`.
- Os timers automaticos de update continuam desligados em todos os hosts (`auto = false`).
- `fish/config.fish` agora tem os atalhos:
  - `release`
  - `release-stable`
  - `update-channel`
  - `update-stable`
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
- O desktop ja publicou `257e254` em `origin/main`.
- No notebook, antes da sincronizacao, havia drift local (`main ahead 1` e varios arquivos modificados). A orientacao foi salvar tudo em uma branch de backup local e depois alinhar `main` com `origin/main`.
- A sincronizacao do notebook funcionou de forma geral, mas houve pequenas quebras pos-update que ainda precisam ser tratadas diretamente naquela maquina.
- Na investigacao de 2026-04-22, o problema reportado inicialmente como "o rebuild era teste e por isso nao persistiu" foi refinado: a geracao persistente ja estava ativa, entao o foco mudou para boot grafico, VT e disputa de GPU no setup hibrido.
- O mesmo sintoma foi declarado pelo usuario para o notebook, o que motivou a extracao da camada compartilhada `modules/graphics-debug.nix`.
- A sessao terminou com os comandos ainda nao aplicados pelo usuario; a orientacao foi sair do Codex e rodar os rebuilds manualmente nos dois hosts.

## Proximo passo recomendado
- No notebook `nixos`, testar primeiro o canal novo com:
  - `cd ~/dotfiles`
  - `./strata-apply-channel.sh`
- Depois do rebuild e reboot no notebook, observar:
  - se o SDDM sobe automaticamente;
  - se a autenticacao grafica entra em `Hyprland` sem voltar ao TTY;
  - qual sessao esta selecionada no SDDM (`Hyprland` vs variante com UWSM, se aparecer);
  - se `Ctrl+Alt+F1` mostra o greeter;
  - o conteudo de `~/.local/share/sddm/wayland-session.log` apos uma tentativa de login.
- Se o notebook repetir o padrao do desktop, priorizar a correção de sessao/defaultSession/UWSM antes de mexer em GPU.
- So depois retomar a investigacao de priorizacao de GPU no `desktop` e as pendencias de tema.

## Regras de retomada
- Ler este arquivo primeiro.
- Conferir `git status --short --branch`.
- Nao assumir que mudancas locais podem ser descartadas.
- Se houver duvida sobre onde paramos, usar este arquivo como fonte principal e `NOTES.md` como complemento.

## Atualizacao de 2026-04-22T10:01:29-04:00
- Foi confirmada a causa do failure atual do rebuild com flake: a `flake.nix` referencia arquivos novos que ainda estao `untracked` no Git.
- O erro reproduzido foi: `Path 'hosts/nixos/config.nix' in the repository "/home/ankh/dotfiles" is not tracked by Git.`
- Os arquivos envolvidos sao:
  - `hosts/nixos/config.nix`
  - `modules/graphics-debug.nix`
- Isso ocorre porque `nix` lendo `/home/ankh/dotfiles#...` usa o snapshot Git do repo; arquivo nao rastreado nao entra no snapshot.
- A avaliacao com `path:/home/ankh/dotfiles#...` fecha corretamente:
  - `nixosConfigurations.nixos.config.system.build.toplevel.drvPath` resolveu com sucesso;
  - `nixosConfigurations.desktop.config.system.build.toplevel.drvPath` resolveu com sucesso.
- Revisao das mudancas:
  - nao foram encontradas outras falhas de avaliacao alem do problema de arquivos nao rastreados;
  - apareceu apenas um warning de Home Manager sobre `xdg.userDirs.setSessionVariables`, sem bloquear build.
- Comando recomendado para rodar agora, sem depender de `git add`, no host atual:
  - se estiver no notebook `nixos`: `sudo nixos-rebuild switch --flake path:/home/ankh/dotfiles#nixos`
  - se estiver no desktop: `sudo nixos-rebuild switch --flake path:/home/ankh/dotfiles#desktop`
- Alternativa para voltar ao fluxo normal de flake sem `path:`:
  - `git -C ~/dotfiles add hosts/nixos/config.nix modules/graphics-debug.nix`
  - depois: `sudo nixos-rebuild switch --flake ~/dotfiles#<host>`

## Atualizacao de 2026-04-22T10:12:00-04:00
- Nesta maquina atual, `cat /etc/hostname` confirmou o host `desktop`.
- O sistema bootado e o perfil atual continuam apontando para `/nix/store/vj6acnjia2fqhzh123214hhjw7wgwdah-nixos-system-desktop-26.05.20260418.b12141e`, com `/nix/var/nix/profiles/system -> system-15-link`.
- Nao apareceu geracao `16+`; portanto, se houve tentativa recente de `switch` persistente, ela nao chegou a gravar uma nova geracao no perfil do sistema.
- O `display-manager.service` esta `active (running)` no boot atual, e o log confirmou:
  - `sddm` usando `VT 1`;
  - greeter Wayland iniciado com sucesso;
  - Weston/greeter usando a AMD em `/dev/dri/card1`;
  - saida `DP-2` detectada e ativada.
- `loginctl list-sessions` voltou a mostrar o padrao:
  - greeter `sddm` em `tty1`;
  - sessao do usuario em `tty3`.
- O `journalctl -b` mostrou que o login do usuario observado neste boot foi de console:
  - `session opened for user ankh ...`
  - `New session '2' ... type 'tty'`
  - logo, nao houve autenticacao grafica do usuario nesse trecho; o usuario entrou no `tty3` enquanto o SDDM permanecia vivo no `tty1`.
- Foram corrigidos os atalhos locais de rebuild para evitar a armadilha de arquivos `untracked` em flakes via snapshot Git:
  - `fish/config.fish`
  - `install.sh`
  - `quickshell/scripts/app-search.sh`
- Todos esses pontos agora usam `--flake path:$HOME/dotfiles#...` em vez de `--flake ~/dotfiles#...`.

## Atualizacao de 2026-04-22T10:20:00-04:00
- O usuario esclareceu o sintoma real no `desktop`: depois do boot ele ve a tela de login, mas evita autenticar no SDDM porque a sessao trava apos digitar a senha; o `tty` e aberto manualmente so como escape.
- Foi encontrado um erro objetivo em `/home/ankh/.local/share/sddm/wayland-session.log`:
  - `Failed to start wayland-session-bindpid@2003.service: Unit wayland-session-bindpid@2003.service not found.`
  - `Command '['systemctl', '--user', 'start', 'wayland-session-bindpid@2003.service']' returned non-zero exit status 5.`
- A leitura do modulo NixOS de `programs.hyprland` no store confirmou:
  - `withUWSM` existe e e `false` por padrao;
  - quando `withUWSM = false`, a sessao correta de DM e a vanilla `hyprland`;
  - quando `withUWSM = true`, o modulo passa a habilitar `programs.uwsm`.
- Como o repo nao habilita `programs.hyprland.withUWSM`, a hipotese principal passou a ser:
  - o SDDM esta tentando iniciar `Hyprland (uwsm-managed)` por estado lembrado/selecionado;
  - essa sessao depende de integracao UWSM que nao esta presente no sistema atual;
  - o login grafico cai imediatamente apos a senha por esse mismatch.
- Correcao aplicada no repo:
  - `modules/desktop.nix` agora fixa `programs.hyprland.withUWSM = false;`
  - `modules/desktop.nix` agora fixa `services.displayManager.defaultSession = "hyprland";`
- Proximo passo operacional no `desktop`:
  - `sudo nixos-rebuild switch --flake path:/home/ankh/dotfiles#desktop`
  - reboot
  - testar login grafico escolhendo explicitamente `Hyprland` se o seletor de sessao aparecer.

## Atualizacao de 2026-04-24T13:55:00-04:00
- O foco desta sessao mudou para Quickshell, App Center, launcher e instalacao de apps.
- O clipboard do Quickshell foi concluido:
  - persistencia funcionando em Wayland;
  - preview de imagem funcionando;
  - a causa principal do bug era layout/geometria em `Clipboard.qml`, nao backend.
- O App Center foi profundamente redesenhado e compactado:
  - fluxo em 3 colunas;
  - fila/lista de compras para apps Nix;
  - Flatpak continua imediato;
  - visual mais minimalista, com progresso no topo.
- Scripts centrais do App Center alterados:
  - `quickshell/scripts/appcenter-index.js`
  - `quickshell/scripts/appcenter-apply.js`
  - `quickshell/scripts/appcenter-queue-apply.js`
  - `quickshell/scripts/appcenter-rebuild.js`
  - `quickshell/appcenter/AppCenter.qml`
  - `quickshell/appcenter/AppCenterStore.qml`
- O `appcenter-rebuild.js` agora:
  - abre terminal kitty com classe `strata-rebuild`;
  - usa regra de janela flutuante menor em `hyprland.conf`;
  - reindexa App Center e launcher apos rebuild bem-sucedido;
  - faz o App Center fechar quando o rebuild abre com sucesso.
- Flatpak foi estabilizado:
  - `desktop.nix` ganhou um oneshot para configurar `flathub`;
  - `flathub` foi adicionado no escopo do usuario para funcionar imediatamente;
  - o indexador consulta `flatpak remote-ls --user flathub` e `--system flathub`;
  - o indexador usa cache como fallback se a consulta falhar;
  - instalacao Flatpak agora usa `flatpak install --user -y flathub <appId>`.
- O App Center passou a separar estado Nix:
  - `Gerenciado` = ja ativo no sistema;
  - `Pendente de rebuild` = no estado declarativo, mas ainda nao presente na geracao ativa.
- O launcher foi ajustado para:
  - chamar scripts JS via `node` explicito;
  - reindexar sempre ao abrir, em vez de confiar indefinidamente no cache.
- Foi confirmado que o launcher usa apenas `.desktop` reais do sistema/Flatpak:
  - ele nao mostra um app so porque o App Center conhece o pacote;
  - ele mostra apenas apps com `.desktop` ativo no indice do launcher.
- Foi validado que um Flatpak real como `Zen Browser` entra na busca do launcher.
- Houve erro de `gio launch` para Steam porque o launcher ainda tinha cache antigo apontando para `/run/current-system/sw/share/applications/steam.desktop`; depois do reindex, essa entrada velha sumiu.
- No fim da sessao, a Steam NAO estava na geracao ativa atual:
  - `/run/current-system/sw/share/applications` nao continha `steam.desktop`;
  - o `catalog.json` do App Center mostrava `steam` com `installed: false`, `managed: false`, `action: install`.
- Portanto, o ponto pendente real nao e mais o launcher: e fechar de vez o fluxo do App Center para que um app Nix adicionado (teste alvo: Steam) chegue ate a geracao ativa do sistema e gere `.desktop` real.

## Proximo passo recomendado
- Retomar pela Steam.
- Verificar o fluxo completo do App Center para Nix:
  - adicionar `steam` a fila;
  - confirmar a fila;
  - deixar `nixos-rebuild switch` terminar sem erro;
  - confirmar depois que `steam.desktop` existe em `/run/current-system/sw/share/applications`;
  - so entao validar launcher e estado `Gerenciado`.
- Se a Steam continuar ausente da geracao ativa apos rebuild aparentemente bem-sucedido, investigar:
  - se o rebuild esta de fato aplicando o `state/apps.nix`;
  - se `pkgs.steam` esta entrando na geracao final;
  - se ha algum detalhe de `allowUnfree`, host, ou aplicacao parcial da geracao.

## Atualizacao de 2026-04-22T10:35:00-04:00
- O usuario informou que caiu repetidamente na sessao errada e quer remover a sessao extra, deixando apenas `Hyprland`.
- Correcao adicional aplicada no repo para endurecer isso no lado declarativo do sistema:
  - `modules/desktop.nix` agora faz `services.displayManager.sessionPackages = lib.mkForce [ config.programs.hyprland.package ];`, limitando as sessoes exportadas ao SDDM para apenas a do pacote atual do Hyprland.
  - `modules/desktop.nix` agora define `services.displayManager.sddm.settings.Users.RememberLastSession = false;` e `RememberLastUser = false;`, para o greeter nao insistir em um estado lembrado ruim.
  - `modules/sddm-theme/Main.qml` deixou de ciclar sessoes por clique e passou a procurar/fixar a sessao `hyprland` como preferida no login.
- Intencao pratica desta mudanca:
  - impedir que o SDDM exponha ou reutilize uma sessao residual como `Hyprland (uwsm-managed)`;
  - reduzir a chance de voltar ao loop de login travado por selecao errada persistida no greeter.
- Proximo passo operacional no `desktop` continua sendo:
  - `sudo nixos-rebuild switch --flake path:/home/ankh/dotfiles#desktop`
  - reboot
  - testar login grafico normal, sem precisar trocar sessao no greeter.

## Atualizacao de 2026-04-22T10:45:00-04:00
- O repo foi endurecido mais um passo para obliterar qualquer sobra declarativa de `uwsm`:
  - `modules/desktop.nix` agora faz `programs.uwsm.enable = lib.mkForce false;`, alem de manter `programs.hyprland.withUWSM = false;`
  - `modules/sddm-theme/Main.qml` agora rejeita explicitamente qualquer sessao cujo nome contenha `uwsm` ao escolher a sessao de login.
- Evidencia local fora do repo continua apontando para mismatch de sessao antiga:
  - `/home/ankh/.local/share/sddm/wayland-session.log` ainda registra `wayland-session-bindpid@....service not found`, erro tipico do caminho `uwsm-managed`.
- Interpretacao atual:
  - mesmo que o sistema ja nao exponha `uwsm` declarativamente, o greeter ainda pode estar vendo/lembrando uma entrada residual;
  - com esta mudanca, o tema para de aceitar essa entrada como fallback.
- Proximo passo operacional no `desktop`:
  - `sudo nixos-rebuild switch --flake path:/home/ankh/dotfiles#desktop`
  - reboot
  - confirmar que o greeter entra direto em `Hyprland` sem mencionar `uwsm`.

## Atualizacao de 2026-04-22T10:55:00-04:00
- O ajuste de sessao/login que fez o `desktop` voltar a autenticar esta no modulo comum `modules/desktop.nix`, importado por `configuration.nix`; portanto o host `nixos` tambem recebe a mesma correção declarativa de SDDM/Hyprland.
- Para reduzir o notebook a um comando unico, `install.sh` agora aceita modo nao interativo:
  - `~/dotfiles/install.sh nixos`
  - opcionalmente: `~/dotfiles/install.sh nixos <username>`
- O script continua aceitando o fluxo interativo anterior quando chamado sem argumentos.

## Atualizacao de 2026-04-22T11:10:00-04:00
- O notebook ainda exibiu/selecionou uma sessao `Hyprland (uwsm-managed)` mesmo depois das correcoes declarativas aplicadas ao repo.
- Foi identificado um endurecimento adicional no tema e no activation script:
  - `modules/sddm-theme/Main.qml` agora recalcula a sessao preferida no `Component.onCompleted`, no `startupGuard` e imediatamente antes de `sddm.login(...)`, para evitar ficar preso em um indice antigo do `sessionModel`.
  - `modules/desktop.nix` agora remove `/var/lib/sddm/state.conf` no activation script, para apagar estado persistido do SDDM que poderia reintroduzir `uwsm`.
- Mesmo assim, no notebook houve erro ao tentar aplicar o flake apos apagar `state.conf`; o usuario relatou mensagem de que `flake.nix` nao foi encontrado.
- Interpretacao pratica:
  - alem do estado ruim do SDDM, o notebook entrou em um estado operacional confuso para continuar depurando no sistema atual;
  - foi decidido abandonar a depuracao incremental e fazer reinstalacao limpa do notebook.

## Plano aprovado para o notebook
- O usuario vai reinstalar o NixOS base usando o instalador grafico, apagando todo o disco.
- Depois do primeiro boot no sistema limpo, a configuracao Strata sera aplicada pela TTY.
- Fluxo operacional combinado para a proxima etapa:
  - instalar NixOS base pelo instalador, apagando todo o disco;
  - criar o usuario final desejado ja durante a instalacao;
  - reboot para o sistema novo;
  - entrar numa TTY;
  - conectar a internet;
  - clonar os dotfiles;
  - rodar `~/dotfiles/install.sh nixos <username>`;
  - reboot.

## Guia acordado para a reinstalacao do notebook
- No instalador:
  - apagar o disco inteiro;
  - usar particionamento padrao do instalador;
  - criar o usuario final que sera usado no notebook;
  - garantir que esse usuario tenha privilegio administrativo/sudo.
- No sistema novo, pela TTY:
  - se necessario, conectar na rede com `nmcli`;
  - clonar o repo com:
    - `nix-shell -p git --run 'git clone https://github.com/PedroAugustoOK/Strata-Habitus.git ~/dotfiles'`
  - aplicar a configuracao com:
    - `~/dotfiles/install.sh nixos <username>`
  - reiniciar.
- Se o problema de sessao do SDDM voltar mesmo no sistema novo:
  - `sudo rm -f /var/lib/sddm/state.conf`
  - `sudo nixos-rebuild switch --flake path:/home/<username>/dotfiles#nixos`
  - `reboot`
- Observacao importante para a proxima sessao:
  - se aparecer erro de `flake.nix not found`, confirmar primeiro `ls /home/<username>/dotfiles/flake.nix` e usar caminho absoluto no `--flake`.

## Atualizacao de 2026-04-23T01:30:00-04:00
- O foco desta sessao mudou de depuracao de boot para refatorar a instalacao do Strata em maquinas novas, aproximando o fluxo de um instalador de distro.
- Problemas estruturais confirmados no modelo antigo:
  - `install.sh` apenas clonava o repo, alterava `username` no `flake.nix` e chamava `nixos-rebuild`, sem particionar disco, sem `nixos-generate-config` e sem gerar `hardware.nix`;
  - `flake.nix` exportava apenas dois hosts fixos (`nixos` e `desktop`);
  - havia referencias absolutas a `/home/ankh` em arquivos que precisavam funcionar para qualquer usuario;
  - `state/` e `generated/` eram necessarios para o desktop, mas nao nasciam automaticamente num clone limpo.
- Refatoracao aplicada no repo:
  - `flake.nix` agora descobre hosts dinamicamente em `hosts/<hostname>/` quando existem `meta.nix` e `hardware.nix`;
  - cada host passa a carregar `meta.nix` com `username`, `system`, `profile`, `graphics`, `timeZone` e `locale`;
  - foram adicionados `hosts/nixos/meta.nix` e `hosts/desktop/meta.nix` para preservar os hosts atuais;
  - `modules/locale.nix` passou a usar `hostMeta.timeZone` e `hostMeta.locale`;
  - `modules/packages.nix` passou a usar `hostMeta.graphics` em vez de `hostname` fixo para decidir extras Intel e a variante do `ollama`;
  - `kitty/kitty.conf` deixou de depender de `/home/ankh/...` e passou a incluir `~/.config/kitty/strata-theme.conf`;
  - `home.nix` ganhou `home.activation.strataBootstrap`, que semeia `state/current-theme.json`, `state/current-wallpaper`, `state/wallpaper-index` e regenera `generated/*` quando estiverem ausentes.
- Novo desenho do instalador (`install.sh`):
  - instalador interativo pensado para rodar do ISO/live;
  - detecta UEFI e aborta em boot Legacy por enquanto;
  - lista discos, pede confirmacao destrutiva, particiona GPT, cria ESP + swap opcional + root ext4;
  - monta em `/mnt`, roda `nixos-generate-config --root /mnt`, copia o repo para `/mnt/home/<user>/dotfiles`, cria `hosts/<hostname>/{meta.nix,hardware.nix,config.nix,hyprland-monitors.conf}` e instala com `nixos-install --root /mnt --flake path:/mnt/home/<user>/dotfiles#<hostname> --no-root-passwd`;
  - detecta perfil grafico sugestivo (`intel`, `amd`, `nvidia`, `hybrid-intel-nvidia`, `hybrid-amd-nvidia`) e escreve `config.nix` do host conforme esse perfil;
  - define a senha do usuario via `nixos-enter` e corrige ownership do repo no target.
- Validacoes feitas nesta sessao:
  - `bash -n install.sh` passou;
  - `nix eval path:/home/ankh/dotfiles#nixosConfigurations.desktop.config.networking.hostName` resolve para `"desktop"`;
  - `nix eval path:/home/ankh/dotfiles#nixosConfigurations.nixos.config.networking.hostName` resolve para `"nixos"`;
  - a descoberta dinamica do flake retorna `["desktop","nixos"]`.
- Riscos residuais anotados:
  - suporte Legacy/GRUB ainda nao foi implementado no instalador novo;
  - setups hibridos Intel+NVIDIA continuam sendo a classe com maior chance de ajuste manual pos-instalacao;
  - o tema/login do SDDM continua sendo um ponto sensivel separado da instalacao em si.

## Atualizacao de 2026-04-23T02:05:00-04:00
- Foi feita a segunda rodada de endurecimento do instalador, focada em confiabilidade operacional e suporte fora do caso ideal.
- Mudancas principais desta rodada:
  - `modules/boot.nix` deixou de assumir `systemd-boot` fixo e agora usa `hostMeta.boot`:
    - `mode = "uefi" | "legacy"`
    - `loader = "systemd-boot" | "grub"`
    - `disk = "/dev/..." | null`
  - `hosts/nixos/meta.nix` e `hosts/desktop/meta.nix` agora registram explicitamente `boot.mode = "uefi"` e `boot.loader = "systemd-boot"`;
  - `install.sh` ganhou logging persistente em `/tmp/strata-install.log` com `tee`, e no fim copia o log para `/var/log/strata-install.log` do sistema instalado;
  - `install.sh` agora aceita `--dry-run`, que valida preflight e o plano sem formatar, montar ou instalar nada;
  - o instalador passou a oferecer dois modos:
    - `wipe`: apaga o disco inteiro;
    - `reuse`: reaproveita particoes existentes, pedindo `root`, `boot` e `swap`, com confirmacao individual de formatacao;
  - suporte inicial a boot Legacy foi implementado:
    - em Legacy o instalador usa `grub`;
    - no modo `wipe`, cria tabela `msdos` com root ext4 e swap opcional;
    - no modo `reuse`, pede tambem o disco de instalacao do GRUB;
  - o instalador agora mostra um resumo/preflight antes de qualquer acao destrutiva:
    - boot mode detectado;
    - bootloader selecionado;
    - perfil da maquina;
    - perfil grafico sugerido;
    - memoria total;
    - caminho do log.
- Validacoes desta rodada:
  - `bash -n install.sh` continuou passando;
  - `nix eval path:/home/ankh/dotfiles#nixosConfigurations.desktop.config.boot.loader.systemd-boot.enable` resolve para `true`;
  - `nix eval path:/home/ankh/dotfiles#nixosConfigurations.nixos.config.boot.loader.systemd-boot.enable` resolve para `true`;
  - `nix eval path:/home/ankh/dotfiles#nixosConfigurations.desktop.config.boot.loader.grub.enable` resolve para `false`.
- Riscos residuais apos a segunda rodada:
  - `--dry-run` hoje e preflight puro; ele ainda nao simula avaliacao completa de um host novo gerado em disco temporario;
  - o suporte Legacy/GRUB foi implementado declarativamente, mas ainda nao foi exercitado numa instalacao real;
  - o modo `reuse` cobre reinstalacao e dual boot mais seguro, mas ainda depende do usuario informar as particoes corretas;
  - o SDDM/tema custom continua sendo a principal area que pode falhar mesmo com a instalacao concluida corretamente.

## Atualizacao de 2026-04-23T02:35:00-04:00
- A investigacao mudou de foco novamente: antes de instalar o Strata no notebook, foi confirmado que o NixOS limpo por si so ainda estava instavel.
- Fatos confirmados do notebook nesta sessao:
  - maquina: Samsung Galaxy Book2 com Intel i5-1235U;
  - `hostnamectl` no sistema limpo mostrou:
    - hostname `nixos`
    - kernel `Linux 6.19.6`
    - arquitetura `x86-64`
    - firmware `P11RGK.050.250403.SX`
  - `lsblk -f` no sistema limpo mostrou:
    - `/boot` em `nvme0n1p1`, UUID `E9FC-1E3F`
    - `/` em `nvme0n1p2`, UUID `ee122d0a-53bc-4258-bd1e-842a8682fde5`
    - `swap` em `nvme0n1p3`, UUID `fd871e0d-ad3f-41cd-a604-ef2851c0790e`
  - a instalacao limpa nao tinha `display-manager.service`; cair direto em TTY foi confirmado como comportamento normal e nao falha;
  - ao tentar apenas operar no TTY (`git clone` / uso normal), a tela voltou a ficar preta e, apos reboot forcado, o notebook caiu outra vez no problema de `initrd`/`emergency`.
- Interpretacao atual, tratada como hipotese principal para a proxima sessao:
  - o notebook sofre primeiro um freeze/black screen de console/iGPU Intel;
  - o desligamento forcado depois desse freeze deixa o sistema em estado ruim para o proximo boot;
  - o retorno ao `emergency mode`/`starting initrd.target` parece ser consequencia secundaria desse freeze anterior, e nao a causa primaria;
  - por isso o Strata foi descartado como causa imediata: o problema reapareceu ate no NixOS limpo, antes de aplicar a configuracao do repo.
- Suspeita tecnica principal:
  - o Galaxy Book2 com Intel Alder Lake / Iris Xe esta sensivel ao stack grafico Intel do kernel atual;
  - o uso de `boot.kernelPackages = pkgs.linuxPackages_latest;` na instalacao limpa foi classificado como suspeito forte de piorar a estabilidade;
  - a mitigacao prioritaria definida foi remover `linuxPackages_latest` e testar `boot.kernelParams = [ "i915.enable_psr=0" ];`.
- Fontes externas pesquisadas nesta sessao e consideradas relevantes:
  - relato de Galaxy Book 2 com black screen no Linux:
    - https://eu.community.samsung.com/t5/computers-it/black-screen-during-installation-of-linux-os-on-galaxy-book-2/td-p/8478013
  - caso de Intel Iris Xe no NixOS resolvido ao desabilitar PSR:
    - https://discourse.nixos.org/t/laptop-screen-has-output-but-does-not-refresh-properly-with-intel-iris-xe-igpu/46650/2
  - bug Ubuntu citado para Galaxy Book2 com mitigacoes Intel/i915:
    - https://bugs.launchpad.net/bugs/2045072
  - wiki NixOS sobre Intel Graphics / Alder Lake:
    - https://nixos.wiki/wiki/Intel_Graphics
- Plano exato decidido para a proxima tentativa no notebook:
  1. reinstalar o NixOS limpo mais uma vez;
  2. antes de clonar repo ou testar o Strata, editar `/etc/nixos/configuration.nix`;
  3. manter bootloader UEFI/systemd-boot normal;
  4. remover/comentar qualquer linha `boot.kernelPackages = pkgs.linuxPackages_latest;`;
  5. adicionar:
     - `boot.kernelParams = [ "i915.enable_psr=0" ];`
  6. aplicar:
     - `sudo nixos-rebuild boot -I nixos-config=/etc/nixos/configuration.nix`
     - `sudo reboot`
  7. so depois, se o TTY/base ficarem estaveis, voltar ao teste do Strata.
- Se o notebook ainda der tela preta mesmo apos remover `linuxPackages_latest` e usar `i915.enable_psr=0`, o proximo experimento ja definido e:
  - `boot.kernelParams = [ "i915.enable_psr=0" "i915.enable_dc=0" ];`
- Estado do instalador Strata ao encerrar esta sessao:
  - a segunda rodada do `install.sh` e dos metadados de host ja foi implementada no repo;
  - porem o instalador nao deve ser testado no notebook antes de estabilizar o NixOS limpo;
  - o bloqueio atual nao e mais “como instalar o Strata”, e sim “como impedir o freeze/black screen do notebook Intel no sistema base”.
- Instrucoes de retomada para a proxima sessao:
  - ler este arquivo primeiro;
  - assumir que o foco inicial e estabilizar o notebook limpo, nao o SDDM e nao o instalador do Strata;
  - nao pular direto para `git clone`/`install.sh` enquanto o TTY do sistema base continuar instavel;
  - depois que o sistema base estiver estavel, retomar o teste do instalador pelo modo `reuse` e preferencialmente com `--dry-run` primeiro.

## Atualizacao de 2026-04-23T03:05:00-04:00
- O repo foi ajustado para refletir a mitigacao Intel que havia ficado apenas como plano:
  - `hosts/nixos/config.nix` agora sobrescreve o `mkForce []` de `modules/graphics-debug.nix` com:
    - `boot.kernelParams = [ "i915.enable_psr=0" ];`
  - `install.sh` deixou de gerar `config.nix` vazio para perfil `intel` e agora escreve a mesma mitigacao no host novo.
- Validacao feita no flake via `path:/home/ankh/dotfiles`:
  - `nixosConfigurations.nixos.config.boot.kernelParams` resolve para `["i915.enable_psr=0"]`;
  - `nixosConfigurations.desktop.config.boot.kernelParams` continua `[]`, mantendo a mitigacao restrita ao notebook Intel.
- Interpretacao atual:
  - a correcao mais importante que faltava no repo era exatamente garantir que o host `nixos` aplicasse a mitigacao Intel no boot real;
  - sem isso, a camada comum de debug limpava todos os `kernelParams` e o notebook continuava sem o experimento principal decidido na sessao anterior.
- Proximo passo operacional recomendado no notebook:
  - aplicar `sudo nixos-rebuild switch --flake path:/home/<user>/dotfiles#nixos`
  - reboot
  - testar primeiro a estabilidade do TTY/base, antes de voltar a culpar SDDM ou o instalador do Strata.
- Se ainda houver tela preta/freeze com `i915.enable_psr=0`, o proximo experimento ja definido continua sendo adicionar tambem:
  - `i915.enable_dc=0`

## Atualizacao de 2026-04-23T03:35:00-04:00
- Foi confirmado em recuperacao via live ISO que o host `nixos` ainda estava criando o usuario errado:
  - o sistema instalado continha apenas `ankh` em `/etc/passwd`;
  - o usuario real desejado para o notebook e `ankh-intel`.
- Correcao registrada no repo:
  - `hosts/nixos/meta.nix` agora usa `username = "ankh-intel";`
- Como o boot grafico do notebook ainda fica preso em estado ruim de SDDM/sessao `uwsm`, o host `nixos` foi endurecido temporariamente para modo seguro:
  - `hosts/nixos/config.nix` agora faz `services.displayManager.sddm.enable = false;`
  - `hosts/nixos/config.nix` agora faz `systemd.defaultUnit = "multi-user.target";`
- Objetivo desta mudanca:
  - recuperar boot confiavel em TTY no notebook;
  - separar o problema de usuario/home do problema de login grafico;
  - impedir que o SDDM continue travando a recuperacao enquanto o host ainda esta sendo acertado.
- Proximo passo operacional no notebook:
  - aplicar estas mesmas mudancas no repo clonado dentro do sistema instalado;
  - rodar `nixos-rebuild boot --flake path:/home/<user>/dotfiles#nixos` via `nixos-enter`;
  - rebootar e validar entrada em TTY antes de tentar restaurar GUI.

## Atualizacao de 2026-04-23T04:10:00-04:00
- A configuracao base foi reestruturada para separar de vez base do sistema e camada grafica:
  - `configuration.nix` agora importa `modules/desktop.nix` condicionalmente via `hostMeta.desktop.enable`;
  - `programs.fish.enable = true;` foi movido para a base, evitando quebrar login TTY quando a GUI estiver desabilitada;
  - `systemd.defaultUnit` agora cai em `multi-user.target` quando `desktop.enable = false`.
- O host versionado `nixos` foi limpo da sujeira recente:
  - `hosts/nixos/meta.nix` voltou para `username = "ankh";`
  - `hosts/nixos/meta.nix` agora declara `desktop.enable = false;`
  - `hosts/nixos/config.nix` manteve apenas a mitigacao Intel `i915.enable_psr=0`, sem override espalhado de SDDM/default target.
- O host versionado `desktop` agora declara explicitamente `desktop.enable = true;`.
- O instalador (`install.sh`) foi endurecido para reinstalacao limpa:
  - continua perguntando usuario e senha;
  - agora tambem pergunta o modo do primeiro boot: grafico ou `tty` seguro;
  - em laptop Intel, o default passou a ser `tty` seguro, que foi o unico caminho validado como estavel no Galaxy Book2;
  - o host gerado passa a carregar `desktop.enable = true|false` no `meta.nix`, eliminando o drift entre usuario real, estado do SDDM e alvo de boot.
- Validacao local concluida:
  - `bash -n install.sh` passou;
  - `nixosConfigurations.nixos.config.systemd.defaultUnit` resolve para `"multi-user.target"`;
  - `nixosConfigurations.nixos.config.services.displayManager.sddm.enable` resolve para `false`;
  - `nixosConfigurations.desktop.config.systemd.defaultUnit` resolve para `"graphical.target"`.
- Pendencia residual conhecida:
  - ainda existe referencia absoluta a `/home/ankh` em `hyprlock.conf`; isso nao bloqueia a reinstalacao em `tty` seguro, mas deve ser saneado antes de reativar o fluxo grafico completo em usuario diferente.
## Atualizacao de 2026-04-23T06:20:00-04:00
- Esta sessao finalmente fechou a recuperacao do notebook Intel em estado operacional.
- O problema real foi refinado assim:
  - havia dois blocos misturados: instabilidade do notebook Intel no boot/base e fragilidade da camada grafica (`SDDM`/tema/sessao);
  - o `SDDM` nao era a causa unica, mas agravava e escondia o problema principal;
  - o caminho que se provou confiavel foi separar boot seguro e sessao grafica manual.

### Estado final confirmado no notebook
- Usuario funcional e usado no notebook atual: `ankh-intel`
- Hostname atual no notebook apos o bootstrap: `strata`
- Kernel visto no notebook limpo/recuperado: `Linux 6.19.6`
- O notebook voltou a:
  - bootar normalmente;
  - aceitar login em `tty`;
  - permanecer em `multi-user.target`;
  - iniciar `Hyprland` manualmente com sucesso a partir do `tty`.
- O `readlink -f /etc/systemd/system/default.target` no notebook resolveu para um caminho terminado em `multi-user.target`.
- O login manual em `Hyprland` foi confirmado como funcional e o usuario reportou que estava "tudo funcionando aparentemente".

### Decisao arquitetural que resolveu
- O modelo do repo deixou de tratar "desktop enable" e "login manager enable" como a mesma coisa.
- A partir desta sessao:
  - um host pode ter stack grafico presente (`Hyprland`, portais, etc.);
  - e ao mesmo tempo manter `SDDM` desligado;
  - e continuar bootando em `multi-user.target`.
- Isso foi implementado com:
  - `hostMeta.desktop.enable`
  - `hostMeta.desktop.loginManager.enable`
- Combinacao final desejada para o notebook (`hosts/nixos/meta.nix`):
  - `desktop.enable = true;`
  - `desktop.loginManager.enable = false;`
- Efeito pratico:
  - `Hyprland` fica instalado;
  - `SDDM` fica desligado;
  - o boot continua em `tty`;
  - a sessao grafica pode ser iniciada manualmente, evitando reabrir o problema de login manager.

### Validacao declarativa final do repo
- O flake local em `path:/home/ankh/dotfiles` foi validado com o seguinte resultado para o host `nixos`:
  - `programs.hyprland.enable = true`
  - `services.displayManager.sddm.enable = false`
  - `systemd.defaultUnit = "multi-user.target"`
- Para o host `desktop`, o resultado permaneceu:
  - `programs.hyprland.enable = true`
  - `services.displayManager.sddm.enable = true`
  - `systemd.defaultUnit = "graphical.target"`

### Fluxo suportado a partir de agora
- O instalador antigo que particiona disco (`install.sh`) nao e mais o fluxo recomendado para esta maquina.
- O fluxo suportado e mais confiavel para NixOS ja instalado passou a ser:
  - instalar NixOS limpo pelo instalador oficial;
  - entrar no `tty`;
  - clonar o repo;
  - rodar `sudo ./bootstrap.sh`;
  - escolher `tty seguro`;
  - reboot;
  - iniciar `Hyprland` manualmente a partir do `tty`.
- `bootstrap.sh` foi criado exatamente para isso:
  - gera `hardware.nix` da maquina atual via `nixos-generate-config --show-hardware-config`;
  - pergunta `hostname`, `usuario`, `timezone`, perfil grafico e modo de boot inicial;
  - habilita `nix-command flakes` por conta propria no momento da execucao;
  - aplica o host com `nixos-rebuild switch`.
- `install.sh` continua existindo para o live ISO, mas foi endurecido e tambem passou a:
  - abortar fora do ambiente instalador;
  - detectar melhor disco/timezone/perfil grafico;
  - oferecer `tty seguro` como default em laptop Intel.
- Mesmo assim, para esta maquina e para retomada pratica, o fluxo a priorizar e o `bootstrap.sh`.

### Commits importantes publicados nesta sessao
- `86014dc` — `Refine installer and stabilize notebook boot`
- `4f0bd60` — `Guard installer against non-ISO usage`
- `7780a30` — `Improve installer auto-detection and prompts`
- `cd7bd57` — `Fix timezone validation on NixOS live ISO`
- `1997ea3` — `Harden disk detection and partition probing`
- `7ae6157` — `Add post-install bootstrap workflow`
- `2cf4282` — `Relax bootstrap dependency on lspci`
- `cfa7f52` — `Enable nix-command automatically in bootstrap`
- `a6efa5a` — `Allow Hyprland without a login manager`

### O que falhou e nao deve ser repetido
- Nao rodar `install.sh` em um sistema ja instalado; isso foi uma das fontes de caos da sessao.
- Nao insistir em reativar `SDDM` no notebook antes de estabilizar a base e a sessao manual.
- Nao misturar "corrigir boot/base" com "corrigir login grafico".
- Nao presumir que o usuario do notebook e `ankh`; nesta maquina operacional o usuario criado e `ankh-intel`.
- Nao usar `~/dotfiles` como atalho mental sem confirmar o usuario atual; no notebook atual o repo funcional ficou em `/home/ankh-intel/dotfiles`.

### Problemas encontrados durante a recuperacao
- O notebook Intel mostrou sensibilidade real a `i915`/PSR. A mitigacao mantida no host e:
  - `boot.kernelParams = [ "i915.enable_psr=0" ];`
- `SDDM` e a sessao residual `uwsm` se mostraram particularmente frageis no notebook.
- Houve falhas repetidas de:
  - tela preta;
  - loop de login grafico;
  - `initrd.target`;
  - emergencia apos reboot forcado.
- Tambem foram observados erros repetidos de ACPI/ventoinha no NixOS limpo:
  - `ACPI Error: Needed [Integer/String/Buffer], found [Reference]`
  - `ACPI Error: AE_AML_OPERAND_TYPE, While resolving operands for [Add]`
  - `ACPI Error: Aborting method \_SB.PC00.LPCB.FAN0._FST`
  - `acpi-fan PNP0C0B:00: Error retrieving current fan status: -5`
- Esses erros ainda nao foram investigados a fundo nesta sessao. O usuario relatou que o notebook esquenta bastante as vezes.
- Hipotese atual sobre ACPI/aquecimento:
  - bug/limite de firmware/BIOS/ACPI do notebook;
  - nao ha evidencia nesta sessao de que isso seja causado pelo Strata;
  - agora que o sistema esta operacional, esse deve ser um dos proximos focos de investigacao.

### Estado atual dos arquivos-chave do repo
- `configuration.nix`
  - importa `modules/desktop.nix` condicionalmente;
  - mantem `programs.fish.enable = true` na base;
  - forca `multi-user.target` quando `loginManager.enable = false`.
- `modules/desktop.nix`
  - continua habilitando `Hyprland`;
  - passa a respeitar `hostMeta.desktop.loginManager.enable` para ligar ou nao o `SDDM`;
  - mantem `withUWSM = false` e `programs.uwsm.enable = false`.
- `hosts/nixos/meta.nix`
  - versionado no repo com:
    - `username = "ankh";`
    - `desktop.enable = true;`
    - `desktop.loginManager.enable = false;`
  - observacao importante:
    - no notebook recuperado em runtime, o host real foi regenerado pelo `bootstrap.sh` com `usuario = ankh-intel` e `hostname = strata`.
    - ou seja, o repo versionado e um baseline; o host real da maquina pode divergir conforme o bootstrap executado localmente.
- `hosts/nixos/config.nix`
  - mantem a mitigacao Intel `i915.enable_psr=0`.
- `bootstrap.sh`
  - passou a ser a ferramenta principal para aplicar Strata por cima de NixOS limpo.

### Regras praticas de retomada no notebook
- Se o notebook continuar funcional:
  - nao mexer em `SDDM` imediatamente;
  - usar `tty` + `Hyprland` manual;
  - investigar aquecimento/ACPI antes de qualquer refinamento cosmetico.
- Se for necessario reaplicar o repo no notebook:
  - usar o usuario real da maquina, hoje `ankh-intel`;
  - clonar/usar `/home/ankh-intel/dotfiles`;
  - rodar `sudo ./bootstrap.sh`;
  - escolher `tty seguro`.
- Se houver duvida sobre o estado de boot:
  - checar `readlink -f /etc/systemd/system/default.target`;
  - o esperado no notebook atual e `multi-user.target`.

### Proximos passos recomendados
- Investigar o erro de ACPI/fan e o aquecimento do notebook agora que o sistema esta estavel.
- Limpar referencias absolutas restantes a `/home/ankh` em arquivos como `hyprlock.conf`.
- Decidir depois, com calma, como entrar no `Hyprland` sem comando manual:
  - autostart no `tty`;
  - ou um login manager mais simples/robusto que `SDDM`.
- Nao reintroduzir `SDDM` no notebook por reflexo antes de validar uma estrategia melhor.

## Atualizacao de 2026-04-23T16:59:24-04:00
- Foi iniciada a investigacao pratica de ACPI/aquecimento no notebook operacional atual, confirmado como host `strata`.
- Identificacao da maquina em runtime:
  - `hostname = strata`
  - `product_name = 550XED`
  - `product_version = P11RGK`
  - CPU `12th Gen Intel(R) Core(TM) i5-1235U`
  - BIOS `P11RGK.050.250403.SX` de `2025-04-03`
- O kernel atual subiu com:
  - `i915.enable_psr=0`
- O runtime mostrou que a pilha termica base esta funcional:
  - zonas termicas expostas em `/sys/class/thermal/thermal_zone*`
  - `intel_pstate` ativo
  - `platform_profile` disponivel
  - `processor_thermal_*`, `intel_rapl_*` e `samsung_galaxybook` carregados
  - `cooling_device12` identificado como `Fan`
- Estado termico observado apos habilitar instrumentacao:
  - `thermald.service` ativo e rodando normalmente
  - `platform_profile = quiet`
  - `intel_pstate` com governor `powersave`
  - `energy_performance_preference = power`
  - limites RAPL observados:
    - `long_term = 20W`
    - `short_term = 44W`
  - leituras de temperatura em idle/uso leve:
    - package CPU em torno de `44 C`
    - zonas ACPI em torno de `45 C`
    - Wi-Fi em torno de `42 C`
    - NVMe em torno de `30.9 C`
- O sensor `acpi_fan` continuou aparecendo como `N/A`, mas isso deixou de apontar para "fan inexistente":
  - o kernel expoe uma cooling device do tipo `Fan`
  - a leitura de RPM/status via interface ACPI continua falhando
  - a interpretacao atual e "telemetria ACPI parcial/bugada", nao ausencia total de controle termico
- Logs relevantes desta investigacao apontaram mais para firmware/ACPI fragil do notebook do que para configuracao termica agressiva no Linux:
  - `ACPI BIOS Error ... AE_AML_PACKAGE_LIMIT` em metodos `_PLD` do XHCI/USB-C
  - `acpi SAM0429:00: failed to execute CSFI; device responded with failure code 0xff`
  - `ucsi_acpi ... PPM init failed`
- Conclusao provisoria desta sessao:
  - nao apareceu evidencia de superaquecimento em idle;
  - o Linux nao esta operando em modo agressivo neste host;
  - o problema remanescente parece ser mais de firmware/ACPI e telemetria parcial do que ausencia de cooling policy.
- Ajustes aplicados no repo para melhorar observabilidade e controle termico:
  - `modules/packages.nix`
    - adicionado `lm_sensors`
  - `hosts/nixos/config.nix`
    - adicionado `services.thermald.enable = true;`
  - `hosts/strata/config.nix`
    - adicionado `services.thermald.enable = true;`
- Houve um detalhe operacional importante:
  - `hosts/strata/` estava com ownership `nobody:nogroup`
  - foi necessario corrigir o ownership para `ankh-intel:users` antes de editar o host real
- O usuario aplicou o rebuild e confirmou em runtime:
  - `thermald` ativo
  - `sensors` funcional
  - `platform_profile` ainda em `quiet`
- Proximo passo recomendado a partir daqui:
  - observar o notebook sob carga real com `watch -n 2 sensors`
  - verificar se a CPU estabiliza em faixa aceitavel sem encostar repetidamente em `95-100 C`
  - so depois decidir se ainda vale limitar turbo/performance ou mexer em politica adicional.

## Atualizacao de 2026-04-23T17:21:28-04:00
- Durante a preparacao para continuar em outra maquina, apareceu uma regressao visual no host `strata` junto de uma mensagem de erro do Hyprland relacionada a monitor/configuracao.
- Investigacao do runtime:
  - `~/.config/hypr/monitors.conf` estava apontando corretamente para `hosts/strata/hyprland-monitors.conf`
  - o arquivo estava legivel e acessivel no filesystem
  - o log do Hyprland mostrou:
    - `eDP-1` conectado
    - `HDMI-A-1` desconectado
    - `DP-1`, `DP-2`, `DP-3` desconectados
- Causa mais provavel da regressao:
  - o host `strata` tinha sido versionado com um `hyprland-monitors.conf` inadequado para o estado real do notebook;
  - primeiro havia um fallback generico;
  - depois foi testada uma versao com `eDP-1` + `HDMI-A-1`;
  - como o HDMI estava desconectado, a configuracao mais segura para o estado atual passou a ser somente a tela interna.
- Correcao aplicada no repo:
  - `hosts/strata/hyprland-monitors.conf` agora ficou em modo seguro:
    - `monitor = eDP-1, 1920x1080@60, 0x0, 1`
- Detalhe operacional importante:
  - o `nixos-rebuild switch` sozinho nao atualizou o visual da sessao do Hyprland ja aberta;
  - a correcao so se refletiu apos:
    - `hyprctl reload`
- Estado final confirmado:
  - apos `hyprctl reload`, a regressao visual desapareceu e a sessao voltou ao normal.
- Regra de retomada a partir daqui:
  - se um ajuste de monitor/visual no Hyprland parecer "nao surtir efeito" logo apos rebuild, testar `hyprctl reload` antes de concluir que o repo ainda esta quebrado.

## Atualizacao de 2026-04-24T01:20:00-04:00
- O trabalho passou a ser continuado no desktop, nao no notebook `strata`.
- Nesta sessao houve tres frentes principais de desenvolvimento no ambiente Quickshell:
  - launcher de apps
  - App Center / instalador de apps do sistema
  - gerenciador de clipboard em `Super+Y`

### Launcher
- O launcher deixou de ser um overlay simples com busca ad hoc e passou por uma refatoracao estrutural.
- Backend novo introduzido:
  - `quickshell/scripts/launcher-index.js`
  - `quickshell/scripts/launcher-search.js`
  - `quickshell/scripts/launcher-launch.js`
  - `quickshell/scripts/launcher-state.js`
- Camada QML nova ou refatorada:
  - `quickshell/launcher/Launcher.qml`
  - `quickshell/launcher/LauncherStore.qml`
  - `quickshell/launcher/LauncherListItem.qml`
  - `quickshell/launcher/LauncherEmptyState.qml`
  - `quickshell/launcher/LauncherFooter.qml`
  - `quickshell/launcher/LauncherActionItem.qml`
- O launcher agora ficou com:
  - indice local
  - busca ranqueada
  - pins e historico
  - painel de acoes secundarias via `Tab`
  - navegacao mais seria
  - animacao de abertura/fechamento
  - fechamento correto apos abrir app
- Foi criada tambem a especificacao:
  - `quickshell/launcher/LAUNCHER_SERIO_SPEC.md`

### App Center / instalador de apps
- Ficou registrado que "instalador" aqui se refere ao instalador de apps do sistema, nao ao instalador do NixOS.
- A modelagem foi refeita para parar de editar `modules/packages.nix` com `sed`.
- Nova fonte declarativa de apps gerenciados:
  - `state/apps.nix`
- `modules/packages.nix` agora importa esse estado e concatena:
  - pacotes base
  - pacotes extras gerenciados pelo App Center
- Backend introduzido:
  - `quickshell/scripts/appcenter-index.js`
  - `quickshell/scripts/appcenter-apply.js`
  - `quickshell/scripts/appcenter-rebuild.js`
- UI nova:
  - `quickshell/appcenter/AppCenter.qml`
  - `quickshell/appcenter/AppCenterStore.qml`
- O App Center terminou a sessao num estado funcional:
  - overlay do Quickshell
  - atalho global em `Super+I`
  - catalogo Nix/Flatpak com cache em `~/.cache/strata/appcenter/`
  - filtros visuais como `Destaques`, `Instalados`, `Gerenciados`, `Base`, `Disponiveis`
  - painel lateral com melhor legibilidade
  - marcacao clara de quando uma acao Nix ainda exige rebuild
  - fluxo de rebuild via `kitty` para `sudo nixos-rebuild switch --flake path:$HOME/dotfiles#$(hostname)`
- Problemas de UX corrigidos durante a sessao:
  - lentidao/travamento ao digitar
  - lista nao acompanhando a selecao
  - textos quebrados/sobrepostos no topo e no painel direito
- Estado final confirmado pelo usuario:
  - App Center ficou bom e funcional no desktop atual.

### Clipboard manager (`Super+Y`)
- O gerenciador de clipboard foi praticamente refeito do zero.
- Arquivos novos ou refatorados:
  - `quickshell/clipboard/Clipboard.qml`
  - `quickshell/scripts/clipboard-list.js`
  - `quickshell/scripts/clipboard-action.js`
  - `quickshell/scripts/clipboard-preview.js`
  - `quickshell/scripts/clipboard-store.sh`
  - `quickshell/scripts/clipboard-daemon.sh`
- Melhorias de UI/comportamento:
  - overlay novo em Quickshell
  - busca e navegacao por teclado
  - `Enter` copia o item selecionado
  - duplo clique tambem copia
  - `Ctrl+Delete` apaga do historico
  - painel lateral com detalhe do item
  - preview de imagem quando o item e imagem
  - fechamento automatico do menu apos copiar com sucesso
- Nova estrategia de persistencia:
  - observar mudancas no clipboard
  - armazenar no `cliphist`
  - espelhar o conteudo atual em cache local
  - reassumir a posse do clipboard com `wl-copy --foreground`
- Mudanca estrutural importante:
  - os watchers antigos em `hyprland.conf` foram removidos
  - a Quickshell agora tenta iniciar o daemon de clipboard no startup
  - abrir o menu de clipboard tambem tenta iniciar o daemon como fallback
- Ponto ainda pendente ao fim desta sessao:
  - a persistencia automatica do clipboard ainda nao foi validada com sucesso na sessao Wayland real do usuario
  - do sandbox nao foi possivel manter os watchers vivos, entao a confirmacao depende de reiniciar o `quickshell` no ambiente grafico real e testar novamente

### Proximo passo recomendado a partir daqui
- Reiniciar o `quickshell` na sessao grafica real do desktop atual.
- Testar primeiro o fluxo do clipboard:
  - copiar texto ou imagem num app
  - fechar o app de origem
  - tentar colar em outro lugar
  - abrir `Super+Y`
  - confirmar:
    - persistencia real do clipboard
    - fechamento do menu apos copiar
    - preview visivel para imagens
- Se a persistencia ainda falhar depois disso:
  - depurar `clipboard-daemon.sh` e `clipboard-store.sh` diretamente no ambiente Wayland real.

## Atualizacao de 2026-04-24T16:00:00-04:00

### Refinamento visual geral
- A sessao passou a focar em polimento visual e consistencia entre Quickshell, Hyprland e Mako.
- O scrim/filtro de fundo dos overlays foi removido dos componentes principais:
  - launcher
  - clipboard
  - theme picker
  - wallpaper picker
  - app center
- Resultado desejado e implementado:
  - overlays abrem diretamente sobre a sessao, sem escurecer/clariar a tela.

### Theme Picker
- O seletor de temas foi redesenhado do zero varias vezes na mesma sessao.
- Direcao final adotada:
  - `Theme Strip`
- Caracteristicas finais:
  - navegacao horizontal
  - tema selecionado sempre centralizado
  - cards com preview simplificado
  - `← →` navegam
  - `Enter` aplica
  - hover/click recentram o tema
  - o overlay ganhou borda propria para nao se confundir com o tema ativo
- Ajuste final importante:
  - a barra superior dos cards passou a acompanhar o arredondamento do topo.

### Wallpaper Picker
- O seletor de wallpapers foi refeito para a linha:
  - `Wallpaper Stage`
- Caracteristicas finais:
  - imagem principal grande no centro
  - slivers laterais do wallpaper anterior/proximo
  - sem nome de arquivo
  - contador discreto
  - clique no palco central ou `Enter` aplica
  - clique nas laterais navega
- Depois do primeiro redesign, o tamanho em tela foi reduzido para respirar melhor.

### Mako
- O Mako foi redesenhado e depois compactado para uma linguagem mais tecnica.
- Estado final da UX:
  - timeout padrao em `6000` ms
  - clique esquerdo fecha
  - clique direito nao faz nada
  - animacao de notificacoes no Hyprland funcionando com:
    - `layerrule = animation slide, match:namespace notifications`

### Spotify notifications
- Foi criada a integracao:
  - `quickshell/scripts/spotify-notify.sh`
- Estado final confirmado:
  - notifica apenas em troca real de faixa
  - mostra capa do album corretamente
  - usa texto editorial por locale (`Tocando agora` em PT)
- Mudanca tecnica importante:
  - o watcher passou de `playerctl -F` para polling por `trackid`, por confiabilidade no ambiente real.

### Animacoes
- O `hyprland.conf` recebeu nova assinatura de animacoes:
  - sem `bounce`
  - `windows` com `popin` sutil
  - `workspaces` com `slidefade` mais contido
  - `layers` mais refinadas
- Os overlays principais do Quickshell tambem foram padronizados para uma cadencia unica:
  - entrada curta, sem overshoot
  - saida seca e rapida

### App Center
- O App Center ficou mais robusto no fluxo de rebuild:
  - status em arquivo
  - log em cache
  - correcao do travamento em `94%`
  - observacao correta do arquivo de status
- O design tambem foi refinado:
  - agora respeita claro/escuro
  - card externo com arredondamento correto

### Steam
- Diagnostico importante consolidado:
  - a Steam Flatpak nao era problema do launcher; ela cai no `steamwebhelper` com `segfault`
  - testes com X11/Xwayland, cache limpo, software rendering e `-vgui` nao resolveram
- Direcao final tomada:
  - parar de insistir na Steam Flatpak
  - habilitar Steam nativa via:
    - `programs.steam.enable = true;`
- Estado ao fim da sessao:
  - Steam nativa ainda nao abre
  - investigacao fica pendente para outra rodada

### Cafeina / hypridle
- Foi identificado um problema estrutural:
  - usar `pkill -STOP hypridle` / `pkill -CONT hypridle` podia levar a suspensao imediata ao desligar a cafeina
- Correcao aplicada:
  - ligar cafeina mata o `hypridle`
  - desligar cafeina mata instancias antigas e sobe um `hypridle` novo
- Isso precisa ser validado na sessao grafica real.

### File manager
- Problema identificado:
  - o atalho global usava `nautilus` puro e acabava nao abrindo nova janela como esperado
- Correcao aplicada:
  - `hyprland.conf` agora usa:
    - `nautilus --new-window`

### Pendencias abertas
- Validar em uso real:
  - cafeina sem suspensao imediata
  - `nautilus --new-window` realmente abrindo multiplas janelas
- Pendencia importante ainda aberta:
  - depurar por que a Steam nativa continua sem abrir.

## Atualizacao de 2026-04-24T18:55:00-04:00

### Vesktop / screen share
- O usuario relatou um problema novo e bem delimitado:
  - nao conseguia mais transmitir tela no `Vesktop`;
  - `OBS` continuava gravando a tela normalmente.
- O repo e o contexto do host confirmavam:
  - sessao em `Hyprland + Wayland`;
  - portal ativo por `xdg.portal.enable = true;` com `xdg-desktop-portal-hyprland`.
- A investigacao mostrou que:
  - o `xdg-desktop-portal-hyprland` criava a sessao de screencast;
  - a selecao de tela/janela acontecia;
  - depois o stream morria no caminho Chromium/Electron do Vesktop.
- Ao rodar o Vesktop com flags Wayland/WebRTC, apareceu erro objetivo:
  - `Error creating EGLImage - EGL_BAD_MATCH`
  - renegociacao de DMA-BUF
  - `Video was requested, but no video stream was provided`
- Conclusao consolidada:
  - o problema nao era do portal de forma geral nem do PipeWire;
  - era especifico do `Vesktop` nativo naquele stack atual.
- Teste de isolamento feito pelo usuario:
  - `Discord web` compartilha normalmente;
  - `Google Meet` tambem funciona.
- Isso fechou a hipotese:
  - o problema ficou isolado ao `Vesktop` nativo, nao ao compartilhamento de tela do sistema.

### Vesktop Flatpak
- O usuario instalou o `Vesktop` via Flatpak.
- Resultado confirmado:
  - compartilhamento de tela voltou a funcionar.
- Direcao tomada:
  - manter `Vesktop Flatpak` como cliente funcional;
  - remover `vesktop` da base Nix para evitar instalacao duplicada e voltar ao estado coerente.

### App Center
- Durante a tentativa de remover o `vesktop` Nix pelo App Center, apareceram 2 problemas de UX:
  - `Enter` parecia nao fazer nada;
  - o badge/estado de pacote instalado estava discreto demais.
- Diagnostico importante:
  - o `vesktop` ainda estava declarado diretamente na base do sistema em `modules/packages.nix`;
  - portanto ele nao era um item realmente removivel pela fila do App Center.
- Correcoes aplicadas:
  - `quickshell/appcenter/AppCenterStore.qml` agora mostra aviso explicito quando o usuario tenta agir sobre um app que pertence a base do sistema;
  - a mensagem orienta remover o app de `modules/packages.nix`, em vez de deixar o `Enter` parecer quebrado;
  - `quickshell/appcenter/AppCenter.qml` recebeu ajuste para preservar melhor o fluxo de teclado apos clique;
  - os badges de estado ficaram mais visiveis:
    - `Instalado` em verde
    - `Gerenciado` em accent
    - `Pendente de rebuild` em amarelo

### Remocao do Vesktop Nix
- Foi removido `vesktop` da base Nix em:
  - `modules/packages.nix`
- Estado real no fim da sessao:
  - o repo ja nao declara mais `vesktop` na base;
  - a sessao ainda precisa de rebuild para retirar a instalacao Nix da geracao ativa.
- Comando de retomada recomendado:
  - `sudo nixos-rebuild switch --flake path:/home/ankh/dotfiles#desktop`

## Atualizacao de 2026-04-24T21:30:00-04:00

### Kitty / `listen_on`
- O usuario reportou erro ao abrir o Kitty:
  - `Invalid listen_on=unix:/tmp/kitty-socket, ignoring`
- A investigacao confirmou que a causa nao era simplesmente o bind do Hyprland.
- Diagnostico consolidado:
  - `kitty/kitty.conf` usa `listen_on unix:/tmp/kitty-socket`;
  - `hyprland.conf` abre o terminal com `kitty --listen-on=unix:/tmp/kitty-socket`;
  - isso por si so nao explica o popup;
  - o problema real estava em `quickshell/scripts/apply-theme-state.sh`, que fazia:
    - `kitty @ --to unix:/tmp/kitty-socket load-config ~/.config/kitty/kitty.conf`
  - o Kitty nao suporta reaplicar `listen_on` via reload de config;
  - ao tentar fazer `load-config` num processo ja ouvindo no socket, o Kitty mostrava o aviso de `Invalid listen_on=...`.
- Correcao aplicada no repo:
  - `apply-theme-state.sh` deixou de chamar `load-config` no Kitty;
  - o reload de tema passou a usar apenas:
    - `kitty @ ... set-colors -a -c generated/kitty/colors.conf`
- Estado final:
  - a sintaxe do comando no `hyprland.conf` ficou corrigida com `--listen-on=...`;
  - a causa raiz do popup foi removida do fluxo de troca de tema;
  - nenhuma nova refatoracao do pipeline de temas foi mantida nesta rodada alem dessa correcao pontual.

## Atualizacao de 2026-04-25T15:21:59-04:00

### Temas / pipeline do Strata
- Houve uma regressao no pipeline de troca de tema:
  - `set-theme.sh` chamava `apply-theme-state.sh --apply-wallpaper`;
  - depois da otimizacao de wallpaper, esse caminho passou a sair cedo demais;
  - o resultado foi que trocar de tema aplicava basicamente so o wallpaper.
- Sintomas observados:
  - borda ativa do Hyprland sumiu e ficou transparente;
  - Nautilus e outros apps GTK demoravam ou nem atualizavam direito;
  - o file picker/portal ficava inconsistente.
- Correcao consolidada:
  - `apply-theme-state.sh` agora usa `--wallpaper-only` apenas para troca isolada de wallpaper;
  - `--apply-wallpaper` voltou a significar "aplicar tema completo e, no fim, aplicar wallpaper";
  - `wallpaper.sh` e `wallpaper-switch.sh` foram atualizados para usar `--wallpaper-only`;
  - `init-border.sh` ficou mais robusto ao ler `accent` e reaplicar `col.active_border`.

### GTK / Nautilus / portal de arquivos
- O atraso visual do Nautilus foi tratado em duas camadas:
  - theme nudge por `gsettings` (`gtk-theme`, `icon-theme`, `color-scheme`);
  - `nautilus -q` quando houver troca de tema.
- O dialogo de abrir/salvar arquivo foi identificado como o file picker do portal:
  - `xdg-desktop-portal-gtk`
- Problemas vistos:
  - atualizacao lenta de tema;
  - contraste ruim por CSS agressivo demais;
  - em certo ponto ele sempre aparecia claro.
- Correcoes aplicadas:
  - o `gtk.css` gerado foi reduzido para seletores menos invasivos e focados no file chooser;
  - `apply-theme-state.sh` passou a reiniciar `xdg-desktop-portal-gtk` e `xdg-desktop-portal` no fim da troca de tema;
  - o repo passou a gerar `generated/gtk/gtk-3.0/settings.ini` e `generated/gtk/gtk-4.0/settings.ini`;
  - `home.nix` agora linka os `settings.ini` do GTK para esses arquivos gerados;
  - `modules/packages.nix` ganhou `gnome-themes-extra`;
  - o tema passou a usar os nomes corretos `Adwaita` / `Adwaita-dark`;
  - `GTK_THEME` passou a ser propagado para a sessao via `environment.d`, `systemctl --user import-environment` e `dbus-update-activation-environment`.
- Estado final reportado pelo usuario:
  - o file picker finalmente troca para o tema correto durante a troca de tema, sem ficar preso no branco.

### Tray / apps em segundo plano
- Foi implementado menu de contexto proprio para a pill de tray:
  - novos componentes `bar/TrayMenu.qml` e `bar/TrayMenuState.qml`;
  - overlay instanciado em `shell.qml`;
  - clique direito nos itens da tray abre o menu.
- Acoes do menu:
  - tentativa de abrir `Menu nativo`;
  - `Encerrar app`.
- O `Menu nativo` nao se mostrou confiavel nos apps testados, mas o overlay do Strata ficou funcional.
- `tray-kill.sh` foi criado para encerrar apps da tray:
  - inclui tratamento especifico para `Vesktop Flatpak` via `flatpak ps` + `flatpak kill`;
  - fallback para apps nativos com escalonamento `TERM -> KILL`.
- O menu tambem passou a fechar com `Esc`.

### Launcher
- O launcher mostrava resultados irrelevantes demais e escondia apps corretos como `Garrafas/Bottles`.
- Diagnostico:
  - o ranking permitia itens sem match textual real;
  - historico e pins conseguiam empurrar apps irrelevantes para quase qualquer busca.
- Correcoes:
  - `launcher-search.js` agora exige match textual real antes de considerar historico/pins;
  - mais peso para `name`, `genericName`, `id`, basename do `.desktop` e basename do `Exec`;
  - aliases PT/EN adicionados;
  - `keywords/categories` ficaram mais restritos;
  - `LauncherStore.qml` reexecuta a busca quando o meta do indice muda;
  - `Launcher.qml` passou de 8 para 10 resultados visiveis.
- Validacao local feita durante a sessao:
  - `files` -> `Arquivos`
  - `bottles` -> `Garrafas`
  - `spot` -> `Spotify`

### Screenshot / satty
- O sistema de screenshot deixou de chamar `grimblast` cru no `hyprland.conf`.
- Foi criado:
  - `quickshell/scripts/screenshot.sh`
- Fluxo novo:
  - `Print`: area, copia + salva
  - `Shift+Print`: tela inteira, copia + salva
  - `Ctrl+Print`: janela ativa, copia + salva
  - `Super+Ctrl+S`: area e abre no `satty`
  - `Super+Ctrl+D`: tela inteira e abre no `satty`
- O wrapper:
  - salva em `~/Imagens/Screenshots/`
  - aplica `SLURP_ARGS` tematizado
  - mostra notificacao com acoes (`Abrir`, `Editar`, `Pasta`, `Copiar caminho`)
- Integracao de anotacao:
  - `modules/packages.nix` ganhou `satty`
  - `apply-theme-state.sh` passou a gerar `generated/satty/config.toml`
  - `home.nix` passou a linkar essa config

### Bar / estatisticas
- `bar/SysStats.qml` foi corrigido para mostrar CPU de forma mais proxima do uso real:
  - duas leituras de `/proc/stat` separadas por `0.35s`;
  - refresh de CPU e RAM a cada `1s`;
  - evitacao de sobreposicao de `Process` enquanto uma coleta ainda estiver rodando.

### Calendario na pill do relogio
- Foi criado um overlay proprio para a pill de data/hora:
  - `bar/CalendarMenu.qml`
  - `bar/CalendarMenuState.qml`
- O calendario:
  - abre ao clicar na pill do relogio;
  - fecha com clique fora ou `Esc`;
  - suporta navegacao por teclado (`←`, `→`, `Home`, `T`);
  - ganhou animacao curta de entrada;
  - destaca o dia atual;
  - possui botao `Voltar para hoje`.
- Houve uma rodada de refinamento visual depois de uma tentativa ruim com coluna de semanas:
  - a coluna lateral foi removida;
  - o layout final voltou para uma grade limpa de 7 colunas com celulas uniformes;
  - o usuario confirmou que a versao final ficou correta.

### Wallpapers
- O repo terminou esta rodada ainda com alteracoes em wallpapers:
  - `wallpapers/nord/Nord1.png`
  - `wallpapers/nord/Nord3.png` removido
  - `wallpapers/nord/Nord3.jpg` novo
  - `wallpapers/rosepine/Rosepine1.png`
  - `wallpapers/rosepine/Rosepine3.jpg`

### Estado ao fim desta sessao
- Tema GTK/portal corrigido e reagindo durante troca de tema.
- Borda ativa do Hyprland corrigida.
- Tray menu funcional.
- Screenshot subsystem modernizado com `satty`.
- Launcher com ranking bem melhor.
- Calendario na pill do relogio implementado e refinado.

## Atualizacao de 2026-04-25T15:35:17-04:00

### Leveza / desempenho do sistema
- O usuario pediu uma rodada de revisao para deixar o sistema mais leve e rapido.
- Medicao objetiva do boot feita com `systemd-analyze`:
  - `graphical.target` em `4.729s` de userspace;
  - o maior atraso real no caminho critico era rede, especialmente `dhcpcd.service` com cerca de `2.248s`;
  - firmware continuava sendo o maior bloco do boot total, fora do alcance direto do repo.
- Diagnostico consolidado:
  - o sistema nao estava catastricamente lento;
  - os maiores ganhos seguros viriam de:
    - tirar trabalho inutil do boot;
    - reduzir polling em background;
    - desligar por padrao servicos opcionais.

### Otimizacoes seguras aplicadas
- `modules/desktop.nix`
  - o setup do Flathub saiu de um servico no boot e virou `system.activationScripts.flatpakFlathub`, reduzindo trabalho recorrente no startup.
- `modules/update.nix`
  - `strata-update.timer` ficou menos agressivo:
    - `OnBootSec` de `5min` para `30min`
    - `OnUnitActiveSec` de `1h` para `12h`
- `quickshell/scripts/clipboard-daemon.sh`
  - o supervisor deixou de fazer polling a cada `2s`;
  - passou a esperar os watchers e rearmar apenas quando necessario.
- `quickshell/scripts/spotify-notify.sh`
  - deixou de consultar estado em loop bruto;
  - passou a usar `playerctl --follow` para reagir a mudancas de faixa.

### IA local removida
- O usuario pediu remocao de IA local do sistema, mas explicitou que `Codex` deveria permanecer.
- Alteracoes aplicadas em `modules/packages.nix`:
  - `ollama` removido de `environment.systemPackages`
  - `services.ollama` removido
  - a logica `useCuda` ligada apenas ao `ollama` foi removida
- Estado validado:
  - `services.ollama.enable = false`
- `codex` foi mantido na base, conforme pedido do usuario.

### Bluetooth e impressao por demanda
- O usuario pediu que Bluetooth e impressao ficassem desligados por padrao, sendo ligados apenas quando necessario.
- Alteracoes aplicadas:
  - `modules/audio.nix`
    - `hardware.bluetooth.powerOnBoot = false`
    - `services.blueman.enable = false`
  - `modules/desktop.nix`
    - `services.printing.enable = false`
- Foram adicionados helpers no `fish/config.fish`:
  - `bt-on`
  - `bt-off`
  - `print-on`
  - `print-off`
- A ideia final ficou:
  - suporte continua presente no sistema;
  - os servicos deixam de subir por padrao.

### Rede
- Em vez de trocar a stack inteira de rede no escuro, foi feito um ajuste conservador em `modules/network.nix`:
  - `networking.dhcpcd.wait = "background"`
- Objetivo:
  - tirar o `dhcpcd` do caminho critico do boot;
  - aceitar que a rede pode terminar de se estabilizar um pouco depois do login.
- Estado validado:
  - `networking.dhcpcd.wait = "background"`

### Estado ao fim desta rodada
- `ollama` removido do sistema declarativo.
- Bluetooth desligado por padrao.
- Impressao desligada por padrao.
- Rede menos bloqueante no boot.
- `codex` preservado na base.

# Strata session memory - 2026-04-24

## Context
- Working repo: `/home/ankh/dotfiles`
- User is now on the desktop host, not the notebook.
- Main active areas in this session:
  - Quickshell app launcher
  - Quickshell App Center / app installer
  - Quickshell clipboard manager on `Super+Y`

## Launcher
- The launcher was substantially refactored into a more serious architecture.
- Backend scripts created:
  - `quickshell/scripts/launcher-index.js`
  - `quickshell/scripts/launcher-search.js`
  - `quickshell/scripts/launcher-launch.js`
  - `quickshell/scripts/launcher-state.js`
- QML/UI side created or refactored:
  - `quickshell/launcher/Launcher.qml`
  - `quickshell/launcher/LauncherStore.qml`
  - `quickshell/launcher/LauncherListItem.qml`
  - `quickshell/launcher/LauncherEmptyState.qml`
  - `quickshell/launcher/LauncherFooter.qml`
  - `quickshell/launcher/LauncherActionItem.qml`
- Also wrote spec:
  - `quickshell/launcher/LAUNCHER_SERIO_SPEC.md`
- Current launcher state:
  - robust indexed backend
  - ranked search
  - pins/history state
  - actions panel via `Tab`
  - improved navigation
  - open/close animation
  - launcher now closes after opening an app
- Residual note:
  - logs still had some generic Quickshell noise, but launcher-specific delegate issues were largely cleaned up

## App Center / app installer
- User clarified that “installer” meant system app installer, not OS installer.
- The app installation model was redesigned away from fragile `sed` edits in `modules/packages.nix`.
- New declarative state file created:
  - `state/apps.nix`
- `modules/packages.nix` now imports that state and combines base packages plus user-managed extras.
- Old shell flow was moved toward App Center architecture:
  - `quickshell/scripts/appcenter-index.js`
  - `quickshell/scripts/appcenter-apply.js`
  - `quickshell/scripts/appcenter-rebuild.js`
  - `quickshell/appcenter/AppCenter.qml`
  - `quickshell/appcenter/AppCenterStore.qml`
- App Center status by end of session:
  - launched as a Quickshell overlay
  - global bind moved to `Super+I`
  - opens to `Disponiveis`
  - catalog built from Nix and Flatpak sources, cached in `~/.cache/strata/appcenter/`
  - heuristic filtering added to make Nix catalog more human-oriented
  - visual filters like `Destaques`, `Instalados`, `Gerenciados`, `Base`, `Disponiveis`
  - side panel improved
  - Nix-managed actions mark rebuild requirement
  - rebuild flow via `appcenter-rebuild.js` opens `kitty` with `sudo nixos-rebuild switch --flake path:$HOME/dotfiles#$(hostname)`
- Important known outcome:
  - `Ctrl+Enter` / `Ctrl+Return` for rebuild did not behave reliably in the session
  - explicit visual rebuild button became the dependable path
- Performance fixes done:
  - reduced expensive QML filtering on every keystroke
  - selection scrolling now follows list navigation
  - top-row layout glitches and overlapping texts were fixed
  - right-side panel overlap was fixed with a scrollable layout
- End state:
  - user confirmed App Center was working and “tudo certo agora”

## Clipboard manager (`Super+Y`)
- User wanted clipboard persistence so copied content survives after closing the source app.
- Clipboard manager was largely rewritten.
- New or refactored files:
  - `quickshell/clipboard/Clipboard.qml`
  - `quickshell/scripts/clipboard-list.js`
  - `quickshell/scripts/clipboard-action.js`
  - `quickshell/scripts/clipboard-preview.js`
  - `quickshell/scripts/clipboard-store.sh`
  - `quickshell/scripts/clipboard-daemon.sh`
- New clipboard UI behavior:
  - overlay-style clipboard manager
  - search/filter
  - `Enter` copies selected item
  - double-click copies
  - `Ctrl+Delete` removes selected history item
  - right-side detail panel
  - image preview support for image entries
  - menu closes after successful copy
- Clipboard backend behavior:
  - history list comes from `cliphist list`
  - copy uses `cliphist decode | wl-copy`
  - image preview is generated into `~/.cache/strata/clipboard/preview-<id>.png`
  - persistence strategy attempts to:
    - watch clipboard changes
    - save them in `cliphist`
    - mirror current clipboard contents into cached files
    - re-own clipboard with `wl-copy --foreground`
- Architecture change:
  - old `wl-paste --watch ...` lines were removed from `hyprland.conf`
  - startup now tries to launch clipboard persistence daemon from `quickshell/shell.qml`
  - opening the clipboard menu also tries to start the daemon as a fallback
- Important current unresolved point:
  - from the sandbox, the clipboard watchers do not stay running because the sandbox does not have the real Wayland session context
  - user reported that persistence still did not work yet in practice
  - likely next step is to verify after restarting Quickshell in the real graphical session
- Expected manual activation step next session:
  - restart Quickshell in the actual desktop session:
    - `pkill quickshell`
    - `quickshell >/dev/null 2>&1 & disown`
  - then test:
    1. copy text/image from an app
    2. close the app
    3. paste elsewhere
    4. open `Super+Y`
    5. confirm preview for images and close-on-copy behavior

## Current priority for tomorrow
- First thing to verify:
  - whether clipboard persistence now works after restarting Quickshell in the real session
- If it still fails:
  - debug `clipboard-daemon.sh` and `clipboard-store.sh` in the real Wayland environment
  - confirm whether `wl-copy --foreground` is successfully taking ownership
  - confirm whether `wl-paste --watch` is alive in-session
- Launcher and App Center are in a substantially better state already; clipboard persistence is the main unresolved item.
# Sessao de 2026-04-24 — App Center, launcher e fluxo de instalacao

## Clipboard
- O clipboard do Quickshell foi concluido.
- Persistencia de clipboard em Wayland ficou funcional.
- Preview de imagem no painel direito ficou funcional.
- O problema principal foi geometria/layout no `Clipboard.qml`; o backend (`cliphist`, `wl-copy`, preview script) estava correto.
- O usuario validou o resultado final como "agora sim, tudo funcionando".

## App Center
- O App Center foi redesenhado para um fluxo em 3 colunas:
  - navegacao/filtros a esquerda
  - busca e lista ao centro
  - detalhes, fila e rebuild a direita
- O visual foi depois compactado e simplificado:
  - menos texto
  - janela menor
  - um CTA principal
  - progresso no topo integrado ao header
- O fluxo Nix foi alterado para "lista de compras":
  - `Enter` em app Nix adiciona/remove da fila
  - o rebuild so acontece ao confirmar a fila
- O fluxo Flatpak continua imediato.

## App Center — backend e scripts
- Arquivos principais alterados:
  - `quickshell/appcenter/AppCenter.qml`
  - `quickshell/appcenter/AppCenterStore.qml`
  - `quickshell/scripts/appcenter-index.js`
  - `quickshell/scripts/appcenter-apply.js`
  - `quickshell/scripts/appcenter-queue-apply.js`
  - `quickshell/scripts/appcenter-rebuild.js`
  - `modules/desktop.nix`
  - `hyprland.conf`
- `AppCenterStore.qml` agora chama scripts JS com `node` explicito.
- O `appcenter-queue-apply.js` foi criado para aplicar em lote as mudancas Nix na `state/apps.nix`.
- O `appcenter-rebuild.js` passou a:
  - abrir kitty com classe `strata-rebuild`
  - usar janela flutuante menor via regra no `hyprland.conf`
  - atualizar os indices do App Center e do launcher apos rebuild bem-sucedido
- O App Center fecha automaticamente quando o terminal do rebuild abre com sucesso.

## Flatpak
- `services.flatpak.enable = true` ja existia em `modules/desktop.nix`.
- O catalogo Flatpak sumiu em alguns momentos por 2 motivos:
  - `flathub` nao estava configurado
  - depois passou a existir em `user` e `system`, e o comando sem escopo ficou ambiguo
- Correcoes aplicadas:
  - `desktop.nix` agora define um oneshot `flatpak-flathub` para configurar `flathub`
  - `flathub` foi adicionado no escopo do usuario para funcionamento imediato
  - `appcenter-index.js` agora consulta `flatpak remote-ls --user flathub` e `--system flathub`
  - o indexador usa cache Flatpak como fallback quando a consulta falha
  - `appcenter-apply.js` instala Flatpaks via `flatpak install --user -y flathub <appId>`
  - remocao Flatpak usa `flatpak uninstall --user -y <appId>`
- O catalogo Flatpak ficou funcional; houve confirmacao fora do sandbox de que `flatpak remote-ls flathub` respondeu normalmente.

## App Center — estado Nix
- Foi corrigida a semantica de estados no App Center:
  - `Gerenciado` nao deve mais significar automaticamente "instalado"
  - apps Nix adicionados ao estado mas ainda nao presentes na geracao ativa aparecem como `Pendente de rebuild`
  - `Gerenciados` agora mostra apenas apps Nix ja ativos no sistema
- `appcenter-index.js` passou a distinguir:
  - apps Nix no estado declarativo (`state/apps.nix`)
  - apps Nix realmente ativos na geracao atual do sistema
- A deteccao de app Nix ativo foi baseada em leitura de requisites de `/run/current-system`.

## Launcher
- O launcher foi parcialmente redesenhado antes desta sessao; nesta sessao o foco foi indice/cache.
- `LauncherStore.qml` foi alterado para:
  - chamar os scripts JS com `node` explicito
  - sempre reindexar ao abrir, em vez de confiar indefinidamente no cache antigo
- O launcher usa `.desktop` reais, nao o catalogo do App Center.
- Portanto:
  - um app so aparece no launcher se houver `.desktop` real disponivel
  - o launcher nao deve mostrar um app Nix "pendente de rebuild"
- Foi confirmado que:
  - `Zen Browser` (Flatpak) aparece no indice e na busca do launcher
  - `Steam` nao aparece quando nao existe `steam.desktop` no sistema ativo
- Houve um erro de `gio launch` para Steam causado por cache velho do launcher apontando para um `steam.desktop` que ja nao existia.
- Depois do reindex, a entrada velha da Steam sumiu do launcher, como esperado.

## Estado objetivo no fim da sessao
- `state/apps.nix` chegou a conter:
  - `pkgs.ghostty`
  - `pkgs.steam`
- Mas no fim da sessao foi confirmado que a geracao ativa atual do sistema nao continha `steam.desktop` em `/run/current-system/sw/share/applications`.
- O catalogo atual do App Center via `catalog.json` mostrava para `steam`:
  - `installed: false`
  - `managed: false`
  - `action: install`
- Conclusao: no fim da sessao, a Steam NAO estava efetivamente instalada no sistema ativo, apesar de em momentos anteriores parecer presente no estado declarativo.

## Pontos pendentes mais importantes
- Fechar de vez o fluxo "instalar Nix pelo App Center" para garantir que:
  - o app entra em `state/apps.nix`
  - o rebuild realmente aplica
  - o app aparece em `/run/current-system/sw/share/applications`
  - o launcher encontra o `.desktop` novo apos reindex
- Teste alvo imediato: Steam.
- Se a Steam continuar nao aparecendo no sistema ativo apos rebuild bem-sucedido, depurar especificamente:
  - se `pkgs.steam` esta realmente presente na geracao resultante
  - se o `.desktop` dela existe na geracao atual
  - se algum rebuild esta falhando/sendo abortado sem refletir no App Center

## Atualizacao de 2026-04-24T16:00:00-04:00

### Estado geral
- A sessao passou a focar em refinamento visual/UX do ambiente Quickshell + Hyprland.
- O estado atual do desktop ficou consideravelmente mais estavel e coerente visualmente.
- O tema ativo continua sendo o eixo central de integracao visual entre overlays, Mako e seletores.

### Steam / launcher / Flatpak
- A Steam Flatpak foi investigada e o problema real nao estava no launcher.
- O launcher passou a abrir apps lendo `Exec=` dos `.desktop`, em vez de depender cegamente de `gio launch`.
- Foi confirmado que a Steam Flatpak cai no `steamwebhelper` com `segfault`, inclusive apos testes com:
  - X11/Xwayland
  - limpeza de cache
  - `LIBGL_ALWAYS_SOFTWARE=1`
  - `-vgui`
- Conclusao pratica:
  - o caminho Flatpak da Steam nao ficou confiavel neste setup atual;
  - a Steam nativa do NixOS foi habilitada via `programs.steam.enable = true;`
  - mesmo assim a Steam ainda ficou pendente de investigacao posterior.
- Estado de retomada:
  - nao gastar mais tempo no Flatpak da Steam;
  - quando retomar, investigar especificamente por que a Steam nativa nao abre.

### App Center
- O App Center recebeu varias correcoes funcionais e de UX:
  - status de rebuild persistido em arquivo
  - log completo do rebuild em cache local
  - correcoes para nao travar visualmente em `94%`
  - observacao correta de mudanca no arquivo de status
  - deteccao de apps Nix instalados pela geracao ativa
  - deteccao e remocao correta de Flatpaks instalados
- Houve tambem uma rodada de refinamento visual:
  - suporte real a claro/escuro em vez de assumir fundo escuro
  - cantos arredondados corrigidos no card externo

### Mako / notificacoes
- O Mako foi redesenhado para uma linguagem `minimal editorial` e depois refinado para uma direcao mais `compacta e tecnica`.
- Estado final configurado:
  - borda fina presente
  - timeout padrao em `6000` ms
  - clique esquerdo fecha
  - clique direito nao faz nada
  - animacao de notificacoes no Hyprland funcionando via:
    - `layerrule = animation slide, match:namespace notifications`
- Tentativas de focar apps/notificacoes por clique direito foram descartadas por nao ficarem confiaveis.

### Spotify notifications
- Foi criada e estabilizada a integracao:
  - `quickshell/scripts/spotify-notify.sh`
- Estado final confirmado pelo usuario:
  - notifica somente em troca real de faixa
  - usa linguagem editorial (`Tocando agora` em locale PT)
  - mostra a capa do album corretamente
- Mudanca tecnica importante:
  - o watcher deixou de usar `playerctl -F` e passou a usar polling por `trackid`, porque o modo anterior ficava vivo mas nao reagia com confiabilidade nesse ambiente.

### Overlays / fundo sem scrim
- O filtro de fundo que escurecia/clareava a tela ao abrir overlays foi removido dos principais componentes:
  - launcher
  - clipboard
  - theme picker
  - wallpaper picker
  - app center
- Estado final:
  - os overlays agora abrem diretamente sobre a sessao, sem scrim.

### Theme Picker
- O seletor de temas foi refeito mais de uma vez na mesma sessao.
- A direcao final adotada foi `Theme Strip`.
- Caracteristicas finais:
  - faixa horizontal de themes/cards
  - o tema selecionado fica sempre centralizado
  - navegacao por `← →`
  - `Enter` aplica
  - clique/hover recentram o tema
  - barra superior dos cards acompanha o arredondamento
  - o card externo do seletor ganhou borda propria para se separar melhor do tema ativo
- Estado final confirmado:
  - o usuario gostou bastante do resultado.

### Wallpaper Picker
- O seletor de wallpapers foi refeito para a linha `Wallpaper Stage`.
- Caracteristicas finais:
  - wallpaper atual grande no centro
  - slivers laterais para anterior/proximo
  - sem nome de arquivo
  - contador discreto
  - clique no palco central ou `Enter` aplica
  - clique nas laterais navega
- Depois do primeiro redesign, o tamanho em tela foi reduzido para respirar melhor.
- Estado final confirmado:
  - o usuario aprovou o resultado.

### Animacoes do sistema
- As animacoes do Hyprland foram retrabalhadas para uma assinatura mais elegante e menos saltada:
  - sem `bounce`
  - `windows` com `popin` mais sutil
  - `workspaces` com `slidefade` mais contido
  - `layers` mais suaves
- Os overlays principais do Quickshell foram padronizados para a mesma linguagem:
  - launcher
  - clipboard
  - theme picker
  - wallpaper picker
  - app center
- Estado final:
  - entrada curta, limpa, sem overshoot
  - saida seca e consistente

### Cafeina / hypridle
- Foi identificado um problema real na abordagem anterior:
  - a cafeina fazia `STOP/CONT` no `hypridle`
  - ao desligar a cafeina, isso podia levar a suspensao imediata
- Correcao aplicada:
  - ligar cafeina agora mata o `hypridle`
  - desligar cafeina mata qualquer instancia velha e sobe um `hypridle` novo
- Estado de retomada:
  - essa correcao precisa ser validada na sessao real do usuario, mas a causa no repo ficou clara.

### File manager
- Foi identificado que o atalho do file manager usava:
  - `nautilus`
- Correcao aplicada:
  - `hyprland.conf` agora usa:
    - `nautilus --new-window`
- Objetivo:
  - permitir abrir multiplas janelas do file manager pelo atalho global.

### Pendencias reais apos esta sessao
- Validar na sessao real:
  - se a correcao da cafeina removeu a suspensao subita
  - se `nautilus --new-window` resolve o problema de abrir apenas uma janela
- Pendencia importante ainda aberta:
  - Steam nativa continua sem abrir e deve ser investigada depois, separadamente do launcher e separadamente do Flatpak.

## Atualizacao adicional - 2026-04-24 noite

### Vesktop screen share
- O usuario relatou que nao conseguia mais transmitir tela no Vesktop, embora o OBS ainda gravasse normalmente.
- Leitura do contexto e do repo confirmou:
  - sessao em `Hyprland + Wayland`
  - portal habilitado via `xdg-desktop-portal-hyprland`
- Diagnostico feito:
  - o problema nao era permissao geral nem PipeWire morto;
  - o `xdg-desktop-portal-hyprland` criava a sessao de screencast, mas o fluxo do cliente Chromium/Electron morria em seguida;
  - ao abrir o Vesktop com flags de Wayland/WebRTC, apareceu erro explicito:
    - `Error creating EGLImage - EGL_BAD_MATCH`
    - renegociacao de DMA-BUF
    - depois `Video was requested, but no video stream was provided`
- Conclusao consolidada:
  - o problema estava isolado no `Vesktop` nativo do sistema atual;
  - `Discord web` e `Google Meet` compartilhavam tela normalmente;
  - portanto o stack geral de portal/captura funcionava, e a regressao era especifica do Vesktop nativo.

### Vesktop Flatpak
- O usuario instalou `Vesktop` via Flatpak e confirmou:
  - transmissao de tela voltou a funcionar normalmente.
- Direcao tomada:
  - parar de usar o `vesktop` empacotado via Nix neste host;
  - manter o Flatpak como versao funcional.

### App Center
- Durante a remocao do Vesktop Nix pelo App Center, apareceram 2 problemas de UX:
  - `Enter` parecia nao fazer nada;
  - o estado visual de pacote instalado nao se destacava o suficiente.
- Diagnostico:
  - no caso do `vesktop`, o pacote ainda fazia parte da base do sistema em `modules/packages.nix`;
  - por isso o item aparecia como instalado de base e nao como item removivel pela fila do App Center.
- Correcoes aplicadas no App Center:
  - `AppCenterStore.qml` agora mostra aviso explicito quando o usuario tenta agir sobre um app que faz parte da base do sistema;
  - a mensagem orienta remover o pacote de `modules/packages.nix`, em vez de parecer que o `Enter` falhou silenciosamente;
  - `AppCenter.qml` agora mantem melhor o fluxo de teclado apos clique nos itens/filtros;
  - badges de estado ficaram mais visiveis:
    - `Instalado` em verde
    - `Gerenciado` em destaque com accent
    - `Pendente de rebuild` em amarelo

### Remocao do Vesktop Nix
- Foi feita a remocao do `vesktop` da base Nix em:
  - `modules/packages.nix`
- Estado ao fim desta sessao:
  - o repo ja nao declara `vesktop` na base;
  - ainda falta aplicar no sistema com rebuild para remover a instalacao Nix da geracao ativa.
- Comando recomendado na retomada:
  - `sudo nixos-rebuild switch --flake path:/home/ankh/dotfiles#desktop`

## Atualizacao adicional - 2026-04-24 fim da noite

### Kitty `listen_on`
- O usuario reportou um erro persistente ao abrir o Kitty:
  - `Invalid listen_on=unix:/tmp/kitty-socket, ignoring`
- A causa real nao era o bind do Hyprland em si.
- Diagnostico consolidado:
  - `kitty/kitty.conf` contem `listen_on unix:/tmp/kitty-socket`, o que e valido para config normal;
  - o Strata tambem fazia reload remoto completo do `kitty.conf` via:
    - `kitty @ --to unix:/tmp/kitty-socket load-config ~/.config/kitty/kitty.conf`
  - o Kitty nao aceita reaplicar `listen_on` por reload de config;
  - por isso o popup aparecia ao recarregar config no socket ja ativo.
- Correcao aplicada:
  - `quickshell/scripts/apply-theme-state.sh` deixou de chamar `load-config` no Kitty;
  - o reload de tema do Kitty ficou restrito a:
    - `kitty @ ... set-colors -a -c generated/kitty/colors.conf`
- Ajuste relacionado mantido:
  - `hyprland.conf` continua com:
    - `kitty --listen-on=unix:/tmp/kitty-socket`
  - isso corrige a sintaxe de CLI do Kitty no launcher do terminal.
- Estado final:
  - o repo ficou com a causa raiz corrigida sem reabrir a refatoracao do pipeline de temas.

## Atualizacao adicional - 2026-04-25 tarde

### Resumo do que foi fechado
- Pipeline de tema do Strata corrigido:
  - `--apply-wallpaper` voltou a aplicar o tema completo;
  - `--wallpaper-only` ficou exclusivo para troca rapida de wallpaper;
  - isso corrigiu a regressao que tinha deixado borda ativa, Nautilus e portal inconsistentes.
- Borda ativa do Hyprland:
  - `init-border.sh` ficou mais robusto na leitura do `accent`;
  - a cor da janela focada voltou a ser reaplicada corretamente.
- GTK / Nautilus / portal:
  - `gtk.css` ficou menos agressivo;
  - `nautilus -q` e restart do portal foram integrados na troca de tema;
  - `settings.ini` do GTK 3/4 passou a ser gerado dinamicamente;
  - `GTK_THEME` passou a ser propagado para a sessao;
  - `gnome-themes-extra` entrou na base;
  - o file picker finalmente passou a reagir ao tema durante a troca.
- Tray:
  - menu de contexto proprio implementado para apps em segundo plano;
  - kill de `Vesktop Flatpak` tratado por `flatpak kill`;
  - menu fecha com `Esc`.
- Launcher:
  - ranking corrigido para exigir match textual real;
  - `Bottles` e outras buscas passaram a aparecer corretamente.
- Screenshot:
  - binds migrados para `screenshot.sh`;
  - notificacoes e fluxo de clipboard + save;
  - integracao com `satty` para edicao/anotacao.
- SysStats:
  - CPU agora usa duas amostras de `/proc/stat`, com refresh de 1s.
- Calendario:
  - clique na pill do relogio abre um overlay proprio;
  - versao final ficou com grade limpa de 7 colunas, navegacao por teclado, destaque do dia atual e botao para voltar a hoje.

### Estado final desta rodada
- O usuario confirmou no fim que:
  - o tema/file picker ficou reagindo corretamente;
  - o calendario ficou correto depois do refinamento final;
  - a sessao poderia ser fechada com commit e atualizacao de contexto/memoria.

## Atualizacao adicional - 2026-04-25 meio/fim da tarde

### Otimizacao leve do sistema
- O usuario pediu uma revisao para deixar o sistema mais leve e rapido.
- Medicao de boot:
  - `graphical.target` chegou em `4.729s` de userspace;
  - o atraso mais relevante no caminho critico era `dhcpcd.service` (~`2.248s`);
  - firmware continuou dominando o tempo total de boot, fora do escopo do repo.
- Conclusao:
  - o sistema nao precisava de refatoracao radical;
  - os melhores ganhos seguros estavam em reduzir servicos/polling e desligar opcionais por padrao.

### Mudancas aplicadas
- `desktop.nix`
  - configuracao do Flathub saiu do boot e foi movida para activation script.
- `update.nix`
  - timer de auto-update ficou bem menos agressivo.
- `clipboard-daemon.sh`
  - supervisor passou a esperar watchers em vez de fazer polling constante.
- `spotify-notify.sh`
  - passou a usar `playerctl --follow`, reduzindo polling.

### Remocao de IA local
- O usuario pediu explicitamente para remover IA local do sistema.
- `ollama` foi removido de `modules/packages.nix`.
- `services.ollama` tambem foi removido.
- `codex` foi preservado por pedido explicito do usuario.

### Bluetooth e impressao
- O usuario pediu para deixar Bluetooth e impressao desligados por padrao.
- Ajustes feitos:
  - Bluetooth:
    - `powerOnBoot = false`
    - `services.blueman.enable = false`
  - Impressao:
    - `services.printing.enable = false`
- Helpers adicionados no Fish:
  - `bt-on`, `bt-off`, `print-on`, `print-off`

### Rede
- Foi feito um ajuste conservador na stack atual:
  - `networking.dhcpcd.wait = "background"`
- Objetivo:
  - reduzir o peso do `dhcpcd` no caminho critico do boot sem trocar de backend de rede.

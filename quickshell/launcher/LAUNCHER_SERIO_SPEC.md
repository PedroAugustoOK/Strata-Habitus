# Strata Launcher

## Objetivo
- Transformar o launcher atual em um componente central do desktop, com indexacao robusta, ranking util em uso diario e UX consistente com o restante do Strata.
- Tirar do `Launcher.qml` a responsabilidade por parsing, cache e heuristicas pesadas.
- Fazer o launcher servir tanto para abrir apps quanto para evoluir depois para acoes do sistema.

## Limites desta fase
- Esta especificacao cobre arquitetura, contratos e plano de refatoracao.
- Nao cobre ainda a implementacao completa.
- O alvo imediato continua sendo "launcher serio de apps". Comandos do sistema entram como extensao posterior, mas a arquitetura ja deixa isso previsto.

## Diagnostico do estado atual

### Problemas no launcher atual
- `quickshell/launcher/Launcher.qml`
  - mistura renderizacao, busca, ranking e launch.
  - depende de `index-apps.sh` no momento do `toggle()`.
  - usa `Column + Repeater`, sem scroll real e sem virtualizacao.
  - fecha imediatamente apos launch, mesmo se `gio launch` falhar.
- `quickshell/scripts/index-apps.sh`
  - faz parsing manual e incompleto de arquivos `.desktop`.
  - usa cache oportunista e rebuild em background sem notificacao de prontidao.
  - resolve icones por basename em um conjunto pequeno de diretorios.
- ranking atual
  - e baseado em substring simples.
  - nao usa historico, frequencia, favoritos ou tolerancia a typo.

### Consequencias praticas
- primeira abertura pode vir vazia ou defasada;
- Flatpak e apps locais podem aparecer de forma inconsistente;
- varios apps ficam sem icone;
- launcher parece "burro" comparado a `rofi` ou `fuzzel`;
- falhas de launch sao silenciosas;
- a UX nao escala para dezenas ou centenas de apps.

## Principios
- Indexacao antes da abertura do launcher.
- Busca barata em runtime.
- Parsing correto de `.desktop`.
- Estado persistido em cache simples e audivel.
- UI focada em navegacao rapida por teclado.
- Estrutura preparada para evoluir para "command palette" do Strata.

## Arquitetura proposta

### Visao geral
Separar em quatro partes:

1. `AppIndex`
- constroi o indice consolidado de apps.
- conhece fontes, cache, normalizacao e resolucao de icones.

2. `AppSearch`
- recebe query + indice + historico.
- devolve resultados ranqueados.

3. `LauncherStore`
- ponte entre backend e QML.
- le cache, dispara reindexacao, persiste historico e favoritos.

4. `Launcher.qml`
- controla overlay, input, navegacao, estados visuais e acoes.

### Organizacao de arquivos proposta
Arquivos novos:

- `quickshell/launcher/LAUNCHER_SERIO_SPEC.md`
- `quickshell/launcher/LauncherStore.qml`
- `quickshell/launcher/LauncherListItem.qml`
- `quickshell/launcher/LauncherEmptyState.qml`
- `quickshell/launcher/LauncherFooter.qml`
- `quickshell/scripts/launcher-index.py`
- `quickshell/scripts/launcher-search.py`
- `quickshell/scripts/launcher-launch.sh`
- `quickshell/scripts/launcher-recent.py`

Arquivos a refatorar:

- `quickshell/launcher/Launcher.qml`
- `quickshell/launcher/qmldir`
- `quickshell/shell.qml`

Arquivos a aposentar depois da migracao:

- `quickshell/scripts/index-apps.sh`

Arquivos de estado/cache propostos:

- `~/.cache/strata/launcher/index.json`
- `~/.cache/strata/launcher/index.meta.json`
- `~/dotfiles/state/launcher-history.json`
- `~/dotfiles/state/launcher-pins.json`

## Contrato do indice

### Formato do `index.json`
Array de objetos, um por entrada launchable.

```json
[
  {
    "id": "org.kde.okular.desktop",
    "name": "Okular",
    "localizedName": "Okular",
    "genericName": "Document Viewer",
    "keywords": ["pdf", "viewer", "document"],
    "categories": ["Office", "Viewer"],
    "desktopFile": "/run/current-system/sw/share/applications/org.kde.okular.desktop",
    "exec": "okular %U",
    "iconName": "okular",
    "iconPath": "/run/current-system/sw/share/icons/hicolor/scalable/apps/okular.svg",
    "terminal": false,
    "startupWmClass": "okular",
    "source": "system",
    "actions": [
      {
        "id": "new-window",
        "name": "Nova janela",
        "exec": "okular --new-window"
      }
    ],
    "hidden": false,
    "noDisplay": false
  }
]
```

### Regras do indice
- incluir apps de:
  - `/run/current-system/sw/share/applications`
  - `$HOME/.local/share/applications`
  - `/var/lib/flatpak/exports/share/applications`
  - opcionalmente `/run/current-system/sw/etc/profiles/per-user/*/share/applications` se fizer sentido depois
- descartar entradas com:
  - `Hidden=true`
  - `NoDisplay=true`
  - `OnlyShowIn` sem compatibilidade com o ambiente atual
  - `NotShowIn` com bloqueio explicito do ambiente atual
- priorizar `Name[pt_BR]` ou locale atual quando existir
- preservar `Desktop Action` como acoes secundarias
- resolver `TryExec` quando presente
- normalizar `keywords` e `categories` em arrays

## Contrato do historico

### Formato do `launcher-history.json`
Mapa por `id`.

```json
{
  "org.kde.okular.desktop": {
    "launchCount": 12,
    "lastLaunchedAt": "2026-04-23T17:44:03-04:00"
  },
  "firefox.desktop": {
    "launchCount": 77,
    "lastLaunchedAt": "2026-04-23T16:02:18-04:00"
  }
}
```

### Formato do `launcher-pins.json`
Lista simples de ids.

```json
[
  "firefox.desktop",
  "kitty.desktop",
  "org.keepassxc.KeePassXC.desktop"
]
```

## Indexacao

### Responsavel
- `quickshell/scripts/launcher-index.py`

### Motivo para sair de shell puro
- parser manual de `.desktop` em shell nao e confiavel o bastante;
- localizar nomes traduzidos, acoes e chaves de ambiente fica muito mais simples;
- fica mais facil emitir JSON valido e testavel.

### Fluxo de indexacao
1. ler todas as fontes de `.desktop`;
2. parsear apenas a secao `Desktop Entry` e `Desktop Action`;
3. filtrar entradas invisiveis ou incompativeis;
4. resolver icone por nome e tema, com fallback para caminho absoluto;
5. deduplicar por `desktopFile` e depois por `id`;
6. escrever `index.json` atomico;
7. escrever `index.meta.json` com:
   - `generatedAt`
   - `entryCount`
   - `sources`
   - `version`

### Estrategia de reindexacao
- indexar uma vez na inicializacao da shell;
- reindexar em background quando:
  - launcher abrir e o cache estiver ausente;
  - o cache estiver velho;
  - houver pedido manual de refresh;
  - watcher detectar mudanca em diretorios de apps.

### Watchers
Nesta fase, a abordagem pragmatica e:
- sem watcher complexo em QML;
- usar `mtime` das pastas fonte + `index.meta.json`;
- reindexacao oportunista e barata.

Se isso ainda for insuficiente:
- avaliar watcher com `inotifywait` ou processo dedicado depois.

## Busca e ranking

### Responsavel
- `quickshell/scripts/launcher-search.py`

### Entrada
- query textual;
- caminho do `index.json`;
- caminho de `launcher-history.json`;
- caminho de `launcher-pins.json`;
- limite de resultados.

### Saida
JSON com lista ordenada de resultados.

### Score sugerido
- `name` com prefixo exato: `+140`
- `name` com match exato completo: `+180`
- fuzzy forte em `name`: `+80`
- match em `genericName`: `+40`
- match em `keywords`: `+25`
- match em `categories`: `+12`
- match em `desktopFile` ou id: `+8`
- pinned: `+60`
- launchCount: boost pequeno e saturado
- recency: boost por decaimento temporal

### Comportamento quando query estiver vazia
Nao retornar lista vazia.
Retornar blocos mesclados nesta ordem:
- fixados;
- recentes;
- apps mais usados;
- fallback para alguns populares configuraveis depois.

### Notas
- se a primeira versao precisar ser mais simples, comecar com:
  - prefixo
  - substring
  - pins
  - frecency
- mas a interface e os contratos ja devem deixar fuzzy pronto para entrar sem refazer tudo.

## Launch e acoes

### Responsavel
- `quickshell/scripts/launcher-launch.sh`

### Regras
- launch principal:
  - `gio launch <desktopFile>`
- action secundaria:
  - `gtk-launch <desktop-id> --action <action-id>` se suportado pelo ambiente
  - ou exec derivado do indice, se esse caminho for mais consistente
- registrar sucesso no `launcher-history.json`
- registrar falha em stderr e devolver codigo de erro

### Feedback para UI
- `Launcher.qml` nao deve simplesmente fechar sem saber o resultado.
- fluxo recomendado:
  1. marcar item como `launching`;
  2. executar processo;
  3. se sucesso, fechar overlay;
  4. se falha, manter overlay aberto e mostrar erro breve no rodape.

## Refatoracao do QML

### `Launcher.qml`
Responsabilidades futuras:
- abrir/fechar overlay;
- capturar query;
- navegar na lista;
- trocar entre resultado principal e acoes;
- exibir estados:
  - carregando indice
  - sem resultados
  - erro de launch
  - reindexando

Responsabilidades a remover:
- parsing de linhas tab-delimited;
- ranking manual no JS do componente;
- controle de cache.

### `LauncherStore.qml`
Responsavel por:
- carregar `index.json`;
- pedir reindexacao quando necessario;
- chamar busca;
- expor:
  - `results`
  - `pinned`
  - `recent`
  - `isIndexing`
  - `isSearching`
  - `launchError`
  - `selectedIndex`

### `LauncherListItem.qml`
Cada item deve mostrar:
- icone
- nome
- subtitulo:
  - `genericName`, categoria ou fonte
- badges opcionais:
  - `Flatpak`
  - `Terminal`
  - `Pinned`

### `LauncherEmptyState.qml`
Estados:
- sem query e sem historico
- query sem resultado
- indice indisponivel

### `LauncherFooter.qml`
Rodape com hints de teclado:
- `Enter abrir`
- `Tab acoes`
- `Ctrl+K fixar`
- `Esc fechar`

## Layout proposto

### Estrutura
- container central entre `620` e `760` px
- input no topo
- lista principal em `ListView`
- rodape contextual curto

### Item de lista
- linha 1: nome
- linha 2: subtitulo
- lado direito:
  - hint de `Enter`
  - badge de fonte quando relevante

### Comportamento visual
- manter identidade visual do Strata;
- reduzir a sensacao de "pill vazia esticando";
- animacao de abertura curta e seca;
- foco visual no item selecionado, nao no contorno inteiro do card.

## Atalhos
- `Enter`: abrir item selecionado
- `Shift+Enter`: abrir acao secundaria default, ou forcar terminal quando aplicavel
- `Tab`: abrir menu de acoes do item
- `Ctrl+K`: fixar/desfixar
- `Ctrl+R`: reindexar
- `Esc`: fechar
- `Up/Down`: navegar
- `PageUp/PageDown`: navegar por bloco

## Evolucao futura para command palette
Depois de estabilizar apps, a mesma arquitetura pode ganhar providers adicionais:
- apps
- configuracoes do Strata
- acoes do sistema
- arquivos recentes
- clipboard

Formato futuro sugerido de provider:

```json
{
  "provider": "apps",
  "items": []
}
```

Por enquanto, nao implementar provider multiplo. Apenas desenhar o backend para nao travar essa evolucao.

## Fases de implementacao

### Fase 1
- criar `launcher-index.py`
- gerar `index.json` robusto
- manter launch atual, mas usando novo indice
- remover dependencia do `index-apps.sh`

### Fase 2
- criar `LauncherStore.qml`
- mover busca para `launcher-search.py`
- trocar `Column + Repeater` por `ListView`
- adicionar rodape e empty states

### Fase 3
- persistir `launcher-history.json`
- suportar pins
- score com frecency
- erro de launch visivel

### Fase 4
- acoes secundarias por app
- refresh manual
- estados mais ricos de carregamento

## Criterios de pronto
- primeira abertura do launcher nao vem vazia por falta de cache;
- apps locais, do sistema e Flatpak aparecem de forma consistente;
- icones resolvem corretamente na maioria dos casos;
- resultados com query vazia sao uteis;
- ranking melhora com uso real;
- falha de launch deixa feedback visivel;
- a UI continua responsiva mesmo com muitas entradas.

## Decisoes que ficam fora desta fase
- trocar Quickshell por launcher externo;
- integrar ainda a instalacao e remocao de apps no mesmo overlay;
- implementar watchers sofisticados em tempo real;
- indexar comandos arbitrarios do shell.

## Recomendacao pratica de execucao
Se formos implementar isso agora, a ordem correta e:

1. backend de indice
2. adaptacao minima do `Launcher.qml` para consumir JSON robusto
3. `LauncherStore.qml`
4. novo ranking
5. persistencia de uso
6. acoes secundarias e polimento visual

Essa ordem reduz risco porque corrige primeiro a base tecnica que hoje torna o launcher instavel e imprevisivel.

# Strata Update Center

## Objetivo
- Criar uma janela de atualizacao do sistema pensada para uso diario no notebook, com abertura rapida, leitura imediata do estado e um fluxo simples para aplicar updates.
- Manter coerencia visual com os overlays mais recentes do Strata:
  - sem scrim
  - card central translúcido
  - borda fina
  - linguagem editorial/tecnica
  - animacoes curtas e secas
- Priorizar confianca e clareza sobre densidade de informacao.

## Papel do componente
- O `Update Center` nao e um terminal disfarçado.
- O componente deve responder primeiro:
  - o sistema esta em dia?
  - ha mudancas prontas para aplicar?
  - a ultima tentativa deu certo ou falhou?
  - qual e a unica acao principal agora?
- Logs e detalhes existem, mas entram como camada secundaria.

## Direcao visual escolhida
- Linha: `Painel Editorial`
- Sensacao desejada:
  - calma
  - segura
  - madura
  - mais proxima de um painel de estado do sistema do que de uma ferramenta de manutencao

## Principios
- Um CTA principal por estado.
- O estado do sistema ocupa o centro da tela.
- Metadados tecnicos aparecem, mas de forma discreta.
- O modo inicial deve ser legivel em 2 a 3 segundos.
- O usuario nao precisa abrir detalhes para saber se pode atualizar com seguranca.

## Escopo da primeira versao
- Overlay dedicado do Quickshell.
- Abertura por bind global.
- Diagnostico basico de estado.
- Acao principal para rodar update.
- Acompanhamento de progresso em alto nivel.
- Painel expansivel de detalhes e log resumido.

## Nomes

### Nome recomendado
- `System Update`

### Alternativas aceitaveis
- `Update Center`
- `Atualizacao do Sistema`

### Recomendacao de tom
- Header em ingles como os demais nomes fortes do desktop.
- Textos auxiliares e estados em PT-BR.

## Estrutura de layout

### Janela
- Tipo: `PanelWindow`
- Anchors: tela toda
- Fundo: transparente
- Sem scrim visual
- Foco por teclado ao abrir

### Card principal
- Posicionado ao centro
- Largura media
- Mais estreito que o App Center
- Altura adaptativa por estado
- Radius alto, na mesma familia dos overlays atuais
- Gradiente sutil de `bg2 -> bg1`
- Borda externa fina
- Wash leve de `accent`

### Estrutura interna
1. Header
2. Hero state
3. Metadata row
4. Stepper/progress area
5. Actions row
6. Expandable details

## Composicao visual

### 1. Header
- Titulo:
  - `System Update`
- Subtitulo:
  - `Uma visao clara do estado do sistema.`
- Badge tecnico no canto direito:
  - `strata • stable`
  - `desktop • main`

### 2. Hero state
- Area central com a mensagem principal da tela.
- E a parte visualmente mais forte do painel.

### Frases-base por estado
- `Sistema em dia`
- `3 mudancas prontas para aplicar`
- `Atualizando o sistema com seguranca`
- `Atualizacao aplicada`
- `A atualizacao nao foi concluida`

### Linha de apoio por estado
- `Nenhuma acao necessaria no momento.`
- `Atualizacoes detectadas e prontas para uso.`
- `Os componentes do sistema estao sendo aplicados agora.`
- `O sistema foi atualizado com sucesso.`
- `Revise os detalhes e tente novamente.`

### 3. Metadata row
- Linha compacta com 3 a 4 blocos pequenos.
- Fonte mono para rotulos e valores tecnicos curtos.

### Campos recomendados
- `Ultimo update`
- `Ultimo lock`
- `Estado atual`
- `Fila pendente`

### Exemplos
- `Ultimo update  Hoje, 14:32`
- `Ultimo lock  Ontem, 22:10`
- `Estado atual  Rebuild necessario`
- `Fila pendente  2 apps`

### 4. Stepper / progress
- Sempre presente, mas discreto.
- Em `idle`, aparece como trilha passiva.
- Em `running`, ganha destaque e progresso.

### Etapas recomendadas
- `Inputs`
- `Build`
- `Switch`
- `Refresh`

### Regras
- Antes de rodar:
  - steps com baixa opacidade
- Durante execucao:
  - step atual com accent
  - anteriores como concluidos
- Em erro:
  - step atual muda para tom de erro
- Em sucesso:
  - todos concluidos

### 5. Actions row
- Um botao principal.
- Uma acao secundaria textual.

### CTA principal por estado
- `Atualizar agora`
- `Executando atualizacao`
- `Concluir`
- `Tentar novamente`

### Acao secundaria
- `Ver detalhes`
- Quando detalhes estiverem abertos:
  - `Ocultar detalhes`

### 6. Details panel
- Fechado por padrao.
- Abre dentro do proprio card, sem trocar de tela.
- Deve parecer um painel tecnico secundario, nao um segundo app.

### Conteudo minimo
- host alvo
- canal alvo
- status do `flake.lock`
- existencia de fila pendente do App Center
- ultima execucao bem-sucedida
- ultima falha, se houver
- log curto ou ultimas linhas
- acao secundaria:
  - `Abrir log completo`

## Estados do componente

### 1. Idle clean
- Sistema sem mudancas pendentes.
- Hero:
  - `Sistema em dia`
- CTA:
  - opcionalmente `Ver detalhes`
  - ou nenhum CTA principal destrutivo

### 2. Idle with updates
- Existe update relevante para aplicar.
- Hero:
  - `3 mudancas prontas para aplicar`
- CTA:
  - `Atualizar agora`

### 3. Running
- Update em execucao.
- Hero:
  - `Atualizando o sistema com seguranca`
- Subtexto:
  - etapa atual em linguagem humana
- CTA:
  - desabilitado ou trocado por estado passivo

### 4. Success
- Update concluido.
- Hero:
  - `Atualizacao aplicada`
- Metadata:
  - hora da conclusao
- CTA:
  - `Concluir`

### 5. Error
- Update falhou ou foi abortado.
- Hero:
  - `A atualizacao nao foi concluida`
- Subtexto:
  - frase curta, sem despejar stack trace
- CTA:
  - `Tentar novamente`
- Secundario:
  - `Ver detalhes`

## Comportamento e interacao

### Abertura
- Bind sugerido:
  - `Super+U`
- Ao abrir:
  - o painel centraliza
  - entra com fade + leve subida
  - foco vai para o CTA principal ou toggle de detalhes

### Fechamento
- `Esc`
- clique fora do card
- CTA `Concluir` apos sucesso

### Teclado
- `Enter`: acao principal
- `Tab`: alterna foco entre CTA principal e detalhes
- `D`: alterna detalhes
- `Esc`: fecha

### Mouse
- CTA principal sempre obvio
- Link de detalhes discreto, mas facil de acertar
- Nenhum comportamento escondido importante

## Animacao
- Mesma linguagem dos overlays recentes.
- Sem bounce.
- Sem overshoot.
- Entrada curta e limpa.
- Saida seca.

### Sugestao
- open:
  - opacity `0 -> 1`
  - scale `0.985 -> 1`
  - y offset `16 -> 0`
- close:
  - opacity `1 -> 0`
  - scale `1 -> 0.992`
  - y offset `0 -> 10`

## Tipografia

### Hierarquia
- Titulo:
  - forte, limpo, maior
- Hero:
  - principal destaque da tela
- Subtexto:
  - discreto
- Metadados:
  - mono

### Direcao
- Header e hero com a mesma familia visual ja usada nos overlays aprovados.
- Metadados com `JetBrains Mono`.

## Paleta e materia

### Base
- Usar `Colors.bg0/bg1/bg2`
- Usar `Colors.text1/text3`
- Accent so em:
  - CTA principal
  - badge
  - progresso
  - estados destacados

### Nao fazer
- nao pintar o card inteiro de accent
- nao usar vermelho forte por padrao
- nao escurecer a sessao com scrim

## Conteudo textual recomendado

### Header
- Titulo:
  - `System Update`
- Subtitulo:
  - `Uma visao clara do estado do sistema.`

### Estado atualizado
- Hero:
  - `Sistema em dia`
- Apoio:
  - `Nenhuma acao necessaria no momento.`

### Estado com update
- Hero:
  - `3 mudancas prontas para aplicar`
- Apoio:
  - `Atualizacoes detectadas e prontas para uso.`

### Estado rodando
- Hero:
  - `Atualizando o sistema com seguranca`
- Apoio:
  - `Aplicando mudancas no host atual.`

### Estado de sucesso
- Hero:
  - `Atualizacao aplicada`
- Apoio:
  - `O sistema foi atualizado com sucesso.`

### Estado de erro
- Hero:
  - `A atualizacao nao foi concluida`
- Apoio:
  - `Revise os detalhes e tente novamente.`

## Contrato minimo de dados

### Estado basico esperado pelo QML
```json
{
  "host": "strata",
  "channel": "stable",
  "status": "updates",
  "summaryCount": 3,
  "lastUpdateAt": "2026-04-26T14:32:00-04:00",
  "lastLockAt": "2026-04-25T22:10:00-04:00",
  "rebuildRequired": true,
  "pendingApps": 2,
  "currentStep": "idle",
  "detailsOpen": false,
  "lastError": "",
  "logPreview": []
}
```

### `status`
- `clean`
- `updates`
- `running`
- `success`
- `error`

### `currentStep`
- `idle`
- `inputs`
- `build`
- `switch`
- `refresh`

## Contrato de backend da primeira fase

### Responsabilidades do backend
- descobrir host atual
- inferir canal correspondente
- ler ultimo update bem-sucedido
- ler ultimo lock conhecido
- detectar se existe fila pendente do App Center
- rodar o comando de update
- persistir status e log em cache local

### Persistencia recomendada
- `~/.cache/strata/update-center/status.json`
- `~/.cache/strata/update-center/update.log`

### Campos uteis de `status.json`
- `status`
- `host`
- `channel`
- `startedAt`
- `finishedAt`
- `currentStep`
- `lastSuccessAt`
- `lastFailureAt`
- `lastError`
- `pendingApps`
- `rebuildRequired`

## Fluxo operacional sugerido

### No notebook `strata`
- CTA principal executa:
  - `sudo nixos-rebuild switch --flake path:$HOME/dotfiles#strata`

### No desktop `desktop`
- CTA principal executa:
  - `sudo nixos-rebuild switch --flake path:$HOME/dotfiles#desktop`

### Evolucao posterior opcional
- modo `Update inputs + rebuild`
- modo `So rebuild`
- modo `Abrir terminal`

## Comportamento em caso de falha
- Nao fechar automaticamente.
- Manter o painel aberto em estado de erro.
- Mostrar mensagem curta.
- Destacar `Ver detalhes`.
- Preservar log de falha no cache.

## Nao objetivos desta fase
- diff detalhado de derivacoes
- changelog completo de pacotes
- comparacao grafica entre geracoes
- rollback pela UI
- multipla escolha de perfis no mesmo painel

## Riscos de UX a evitar
- parecer um terminal escondido
- parecer uma tela de instalador generico
- usar texto demais no estado inicial
- esconder a acao principal entre varios botoes
- fechar silenciosamente em caso de erro

## Estrutura de arquivos sugerida
- `quickshell/updatecenter/UpdateCenter.qml`
- `quickshell/updatecenter/UpdateCenterStore.qml`
- `quickshell/updatecenter/UpdateCenterDetails.qml`
- `quickshell/updatecenter/UPDATE_CENTER_EDITORIAL_SPEC.md`
- `quickshell/scripts/update-center-status.js`
- `quickshell/scripts/update-center-run.sh`

## Decisao de implementacao recomendada
- Implementar primeiro o shell visual completo com estados mockados.
- Depois conectar ao backend real de status.
- Por fim conectar o runner de update e persistencia de log.

## Resultado esperado
- No notebook, abrir `Super+U`, bater o olho e entender imediatamente:
  - se ha algo para atualizar
  - se vale rodar agora
  - o que aconteceu na ultima execucao
- E entao aplicar a atualizacao com um fluxo simples, confiavel e coerente com o Strata.

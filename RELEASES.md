# Canais de release do Strata

O repositorio agora suporta um fluxo simples de "distro caseira" com dois canais:

- `main`: desenvolvimento e validacao no desktop
- `stable`: canal promovido manualmente para notebook

O travamento real das versoes continua sendo o `flake.lock`. O canal decide qual
branch entregar esse lock para cada host.

## Estado atual por host

- `desktop` segue `main`
- `nixos` segue `stable`
- `strata` segue `stable`

Os metadados ficam em `hosts/<host>/meta.nix`, no bloco `updates`.

## Fluxo recomendado

1. Fazer mudancas e testar no desktop com `main`
2. Confirmar que o desktop esta bom
3. Publicar o release no canal `stable`
4. No notebook, aplicar manualmente `stable`

## Publicar um release

No desktop, a partir do repo limpo:

```bash
cd ~/dotfiles
./strata-promote-release.sh
# ou, no fish:
release
```

Por padrao isso faz push do `HEAD` atual para `origin/stable`.

Se quiser promover outro ref:

```bash
./strata-promote-release.sh stable main
./strata-promote-release.sh stable <commit>
```

## Aplicar um canal manualmente

No notebook:

```bash
cd ~/dotfiles
./strata-apply-channel.sh
# ou, no fish:
update-channel
```

Por padrao ele:

- le o canal configurado em `/etc/strata-release.conf`
- usa `stable` se esse arquivo ainda nao existir
- faz `git fetch`
- troca o repo local para o branch do canal
- faz `git pull --ff-only`
- aplica `sudo nixos-rebuild switch --flake path:$HOME/dotfiles#<host>`

Tambem e possivel forcar canal e host:

```bash
./strata-apply-channel.sh stable nixos
./strata-apply-channel.sh main desktop
```

Atalhos extras no `fish`:

```bash
release-stable
update-stable
```

## Update automatico

O modulo `modules/update.nix` agora respeita `hostMeta.updates`:

- `enable`: instala o servico de update
- `auto`: liga ou desliga o timer
- `channel`: branch usado como canal

No estado atual o timer automatico esta desligado em todos os hosts. Se quiser
reativar em uma maquina, ajuste `auto = true;` no `meta.nix` do host.

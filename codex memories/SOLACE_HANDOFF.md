# SOLACE_HANDOFF

Use this file to bootstrap Codex context in the new Solace repo.

## Immediate instruction for Codex on Solace

You are now working in the new Solace project on a fresh Arch Linux notebook.

Read this handoff and create the initial Solace repository memory/context files:

- `codex memories/SOLACE_CONTEXT.md`
- `codex memories/SOLACE_MEMORY.md`

Also create the initial repository structure:

- `scripts/`
- `packages/`
- `hosts/notebook/`
- `config/`
- `docs/`

After creating those files, commit the initial state and push it if `origin` is configured.

## Project identity

- Project name: Solace
- Base distro: Arch Linux
- Target: personal system for the user's own devices
- Not a public distro
- Not an ISO project
- Main goal: a minimal, fast, clean, portable Arch-based personal system
- Preferred stack: Arch + Hyprland + Quickshell

## Current installation context

- First target device: notebook
- Host/system name chosen by user: Solace
- Installed with `archinstall`
- Profile: minimal
- Timezone: `America/Porto_Velho`
- Bootloader: `systemd-boot`
- Filesystem: Btrfs
- Btrfs compression: enabled in archinstall
- LVM: disabled
- Swap direction: zram preferred
- Testing repositories: disabled
- Pacman color: enabled
- Initial network was done through `iwctl`
- NetworkManager is acceptable/preferred for the final notebook setup
- Codex is installed and running on the new Arch system

## Why Solace exists

The user decided to abandon the current Strata implementation and reformulate the system from scratch.

Solace should keep useful ideas from Strata, but it must not continue Strata's current architecture.

The new system should be smaller, cleaner, more intentional, and easier to port between the user's machines.

## Lessons from Strata

### Keep

- Personal system as a versioned repository
- Hyprland as the compositor
- Quickshell as the visual shell/UI layer
- Strong personal visual identity
- Launcher indexed from real `.desktop` files
- Clipboard history and preview
- Screenshot selector idea
- Theme Picker with real previews
- Mako as notification backend/history, with Quickshell as the UI
- Host-specific profiles
- Scripts for update, apply, clean, and diagnostics

### Avoid

- Persistent fullscreen `ShellFrame`
- Permanent fullscreen transparent layer-shell surfaces
- Fake drawer/frame pockets, bridges, sockets, or shoulders
- Moving passive frame surfaces to top layer as a quick visual fix
- Permanent fullscreen click-catchers for normal panels
- App Center / Update Center complexity too early
- Too many global runtime flags before the base architecture is stable
- Rebuilding Strata's frame/drawer architecture in the new project

### Strong architecture rule

Every shell surface should have a clear responsibility:

- visual
- input
- content
- lifecycle

Do not let one fullscreen surface coordinate frame visuals, masks, click capture, drawer state, focus, and content at the same time.

## New design principle

First build a small, clean, predictable system.

Then make it beautiful.

Only then make it ambitious.

## Arch cleanliness model

Arch is mutable, so Solace should control drift through the repo:

- package lists are source of truth
- configs are linked/applied from the repo
- scripts audit drift
- pacman cache should be cleaned through `paccache`
- orphan packages should be reviewed before removal
- custom system pieces should become local PKGBUILDs when useful
- Flatpak can isolate large/proprietary/snowflake apps
- avoid manual untracked installs

## Planned repository shape

Suggested initial tree:

```text
Solace/
  README.md
  codex memories/
    SOLACE_CONTEXT.md
    SOLACE_MEMORY.md
  docs/
    DESIGN.md
  hosts/
    notebook/
      packages.pacman
      packages.aur
  packages/
  config/
    hypr/
    quickshell/
    mako/
    kitty/
  scripts/
    bootstrap
    apply
    update
    clean
    doctor
```

## Preferred first commands to build

Eventually expose these as scripts or a small `solace` command:

- `solace bootstrap`
- `solace apply`
- `solace update`
- `solace clean`
- `solace doctor`

## Initial implementation order

1. Bootstrap/apply scripts
2. Package lists for notebook
3. Service setup
4. Hyprland minimal
5. Quickshell minimal bar
6. Launcher
7. Notifications
8. Theme basics
9. Advanced panels/island only after the base is stable

## First task for Codex in the new repo

Create:

- `codex memories/SOLACE_CONTEXT.md`
- `codex memories/SOLACE_MEMORY.md`
- `docs/DESIGN.md`
- `hosts/notebook/packages.pacman`
- `hosts/notebook/packages.aur`
- executable placeholders for:
  - `scripts/bootstrap`
  - `scripts/apply`
  - `scripts/update`
  - `scripts/clean`
  - `scripts/doctor`

Keep the first scripts conservative. They should not install a full desktop yet unless the user explicitly asks.

## Live bootstrap continuation - 2026-05-07

### What happened after the first handoff

- User installed Arch on the notebook and named the system `Solace`.
- User started Codex successfully on the new Arch system.
- User does not want to manually type long context into the TTY.
- Therefore this handoff file should be used as the bridge for Codex on the new machine.

### GitHub/token state on the Arch notebook

- `github-cli` / `gh` was installed or intended to be installed.
- User chose token login because there was no browser yet.
- Token login succeeded enough for the user to say "consegui conectar".
- User likely selected broad token permissions. This is acceptable temporarily, but later the token should be deleted and replaced by a narrower token.
- Do not ask the user to paste secrets into chat.

### Attempted handoff download

The first raw GitHub download attempt produced an HTML `400 Bad Request` page from OpenResty.

The recommended authenticated API command was:

```bash
gh api repos/PedroAugustoOK/Strata-Habitus/contents/'codex memories/SOLACE_HANDOFF.md' --jq .content > handoff.b64
base64 -d handoff.b64 > SOLACE_HANDOFF.md
```

That returned:

```text
gh: Not Found (HTTP 404)
```

Likely causes:

- token did not have access to `PedroAugustoOK/Strata-Habitus`
- path with space was awkward in GitHub API
- branch/path access issue

Alternative command that was suggested but not yet confirmed:

```bash
gh api 'repos/PedroAugustoOK/Strata-Habitus/contents/codex%20memories/SOLACE_HANDOFF.md?ref=main' --jq .content > handoff.b64
base64 -d handoff.b64 > SOLACE_HANDOFF.md
```

### TTY keyboard issue

- User is on a notebook ABNT2 keyboard in a TTY.
- The backslash key could not be produced.
- `AltGr + Q`, `AltGr + W`, `Ctrl+Alt+Q`, and similar guesses did not work.
- Avoid giving commands that require `\` line continuations.
- Prefer one-line commands or commands split into separate lines without backslash.
- If needed later, try:

```bash
sudo loadkeys br-abnt2
```

or:

```bash
sudo loadkeys br-abnt
```

But at the time of handoff, the user asked for another approach instead of fighting the TTY keyboard.

### Decision: install a temporary graphical environment

Because doing GitHub/token/code transfer in pure TTY was too painful, the user decided to install just enough graphical environment to use a browser and copy commands.

Recommended temporary install command:

```bash
sudo pacman -Syu
sudo pacman -S --needed hyprland kitty firefox xdg-desktop-portal xdg-desktop-portal-hyprland qt6-wayland polkit dbus wayland xorg-xwayland
```

If PipeWire pieces are missing:

```bash
sudo pacman -S --needed pipewire pipewire-pulse wireplumber
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

Create minimal Hyprland config:

```bash
mkdir -p ~/.config/hypr
printf 'monitor=,preferred,auto,1\nexec-once=kitty\nbind=SUPER,Return,exec,kitty\nbind=SUPER,B,exec,firefox\nbind=SUPER,Q,killactive\nbind=SUPER,M,exit\n' > ~/.config/hypr/hyprland.conf
```

Start:

```bash
Hyprland
```

Keybinds:

- `Super+Enter`: open Kitty
- `Super+B`: open Firefox
- `Super+Q`: close active window
- `Super+M`: exit Hyprland

### Font prompt during graphical install

Pacman asked for a TTF font provider while installing the graphical stack.

Recommended choice:

- `noto-fonts`

If available, also install:

- `noto-fonts-emoji`

Reason:

- good default coverage for accents, symbols, Firefox, Hyprland and future Quickshell work.

### Current immediate continuation for Codex on Solace

If this file is successfully present on the Solace machine, Codex should:

1. Read this file.
2. Create `codex memories/SOLACE_CONTEXT.md`.
3. Create `codex memories/SOLACE_MEMORY.md`.
4. Create `docs/DESIGN.md`.
5. Create the first repo structure.
6. Add the real current facts:
   - Arch installed
   - Codex installed and running
   - temporary Hyprland/Firefox environment may have been installed to make browser access possible
   - token/TTY transfer was painful and should not be the normal workflow
7. Commit and push the initial Solace repo.

### Important UX note for future assistance

The user wants the machine transition to feel seamless.

When continuing on the Solace machine, do not ask the user to retype long context.
Prefer reading local handoff/memory files and doing the repo setup directly.

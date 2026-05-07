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

# STRATA_MEMORY

## Stable architectural decisions

### Launcher
- Launcher was refactored into a proper indexed architecture.
- Main files:
  - `quickshell/launcher/Launcher.qml`
  - `quickshell/launcher/LauncherStore.qml`
  - `quickshell/scripts/launcher-index.js`
  - `quickshell/scripts/launcher-search.js`
  - `quickshell/scripts/launcher-launch.js`
- Current model:
  - real `.desktop` files only
  - explicit reindexing
  - ranked search
  - pins/history state
  - keyboard-first navigation

### App Center
- App Center is the system app installer overlay, not an OS installer.
- Nix package state is declarative through:
  - `state/apps.nix`
- Main files:
  - `quickshell/appcenter/AppCenter.qml`
  - `quickshell/appcenter/AppCenterStore.qml`
  - `quickshell/scripts/appcenter-index.js`
  - `quickshell/scripts/appcenter-apply.js`
  - `quickshell/scripts/appcenter-queue-apply.js`
  - `quickshell/scripts/appcenter-rebuild.js`
- Current model:
  - Flatpak actions apply immediately
  - Nix actions go to a queue and require rebuild confirmation
  - installed/managed/pending states are intentionally distinct

### Clipboard
- Clipboard manager is finished and validated.
- Main files:
  - `quickshell/clipboard/Clipboard.qml`
  - `quickshell/scripts/clipboard-list.js`
  - `quickshell/scripts/clipboard-action.js`
  - `quickshell/scripts/clipboard-preview.js`
  - `quickshell/scripts/clipboard-daemon.sh`
- Validated behavior:
  - persistent history
  - image preview
  - close on copy
  - `Super+Y` flow working

### Theme system
- Theme propagation is custom and intentionally integrated across:
  - Quickshell
  - Hyprland
  - GTK
  - Chromium
  - wallpaper
- Important files:
  - `quickshell/scripts/apply-theme-state.sh`
  - `quickshell/scripts/init-border.sh`
  - `home.nix`
  - `generated/gtk/...`
- Critical rule:
  - never go back to writing GTK CSS directly into `~/.config/gtk-*`

### Release workflow
- The repo uses a simple two-channel model:
  - `main` for development
  - `stable` for notebook rollout
- Main scripts:
  - `strata-promote-release.sh`
  - `strata-apply-channel.sh`
  - `strata-update.sh`

## UI language already established
- Quickshell overlays should stay consistent with the current Strata direction:
  - no scrim
  - central card
  - thin border
  - short, dry animation
  - technical/editorial tone
- This applies to:
  - launcher
  - clipboard
  - theme picker
  - wallpaper picker
  - app center
  - update center

## Known open issues worth remembering
- Steam native is still unresolved and should be investigated separately from launcher/App Center
- App Center Nix install flow should still be validated against a real target app after rebuild
- Desktop hardware config placeholder should eventually be replaced with a generated real file:
```bash
sudo nixos-generate-config --show-hardware-config > ~/dotfiles/hosts/desktop/hardware.nix
```

## Low-priority ideas
- `eza`, `bat`, `zoxide`
- possible future `stylix` adoption

## Last major update
- Commit `0a3ab1d`
- Added `Update Center`
- Consolidated repo state after notebook theme fixes and current desktop work

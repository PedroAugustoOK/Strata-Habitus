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

## Session update - 2026-04-27

### Settings Center
- `quickshell/settingscenter/SettingsCenter.qml` was added and iterated heavily.
- Current state:
  - PT-BR naming and copy
  - vertical layout
  - `Super+S`
  - keyboard navigation working
  - action list auto-scrolls with focus
- It is now the preferred native entry point for:
  - `Central de Controle`
  - `Tema`
  - `Wallpapers`
  - `Central de Apps`
  - `Central de Atualizações`
  - system utilities

### New desktop apps / system completeness
- Added system apps for a more complete desktop:
  - `gnome-calculator`
  - `file-roller`
  - `kooha`
  - `gnome-clocks`
  - `gnome-calendar`
  - `gnome-control-center`
  - `simple-scan`
  - `system-config-printer`
  - `thunderbird`
- Printing and scanning were enabled in NixOS config.

### Launcher
- Launcher now also supports a `Todos os Apps` mode inside the existing overlay.
- Main changes:
  - `Ctrl+A` toggles full installed apps listing
  - still searchable/filterable
  - no separate panel was created

### Wallpaper Stage
- `WallPickr` now uses cached thumbnails for navigation performance.
- `quickshell/scripts/wallpickr-index.sh` was added.
- `imagemagick` was added as a dependency.

### Clipboard
- Clipboard text normalization was hardened for broken UTF-16-like browser payloads.
- It now better classifies entries as:
  - `Texto`
  - `Link`
  - `Links`

### Workspaces
- Workspace icons remain monochrome glyphs, not colored app icons.
- Resolution logic now uses:
  - manual map
  - substring/category heuristics
  - title fallback
- This reduces single-letter fallbacks while preserving the visual style.

### Icon theme direction
- Strata moved from Papirus toward Colloid as the system icon theme.
- Current strategy:
  - GTK/File Manager should only switch between light/dark
  - theme identity should come primarily from icon color variants
- Current Colloid build was reduced to a practical subset:
  - schemes: `default`
  - colors: `default`, `pink`, `green`, `grey`, `purple`, `orange`

### Tray / Spotify
- Spotify tray icon broke during the icon-theme migration.
- The tray now contains an explicit fallback in:
  - `quickshell/bar/Tray.qml`
- If a tray item looks like Spotify, it uses the `hicolor` Spotify icon directly.

### File Manager theme issue
- Main finding:
  - trying to fully recolor Nautilus/GTK per palette caused unstable hybrid states
- Current direction:
  - keep Nautilus on `Adwaita` + light/dark
  - use icon theme color for personality
- `apply-theme-state.sh` was simplified in that direction.

### Screen recorder diagnosis
- Kooha is not reliable on host `desktop`.
- Logs showed `xdg-desktop-portal-hyprland` screencast failures:
  - `Out of buffers`
  - `Asked for a wl_shm buffer which is legacy`
  - `tried scheduling on already scheduled cb`
- This correlates with the `desktop` hardware being `hybrid-amd-nvidia`.
- Current mitigation attempted:
  - explicit portal config
  - `~/.config/hypr/xdph.conf` with `force_shm = true`
  - `max_fps = 60`
- Result:
  - Kooha still unreliable / worse on this host
- Practical decision:
  - `gpu-screen-recorder-gtk` also did not work acceptably
  - standardize on `obs-studio`
  - in `SettingsCenter`, `Gravador de Tela` should open `obs-studio`

### Current main unresolved item
- Rebuild and validate the OBS flow on `desktop`.

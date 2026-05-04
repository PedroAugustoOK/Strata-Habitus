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
  - current notebook bind is `Super+V`

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

## Published handoff state
- Current published commit on `main`:
  - `bf1a311` `Add settings center and desktop integration updates`
- This commit was pushed to:
  - `origin/main`
- Intended next consumer:
  - notebook host via the existing release/update workflow

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

### Proton desktop app integration
- Proton apps were installed from Nixpkgs except VPN.
- Problems identified:
  - `Proton Pass` had no launcher icon
  - Proton apps except Mail did not map well in workspace indicators
  - `Proton Authenticator` login could not be completed
- Important packaging findings:
  - `proton-pass` and `protonmail-desktop` contain icon assets in `share/pixmaps`
  - their stock `.desktop` entries still referenced themed icon names instead of explicit paths
  - `proton-authenticator` ships `hicolor` icons, but needed safer desktop/mime integration for callback handling
- Repo fixes added:
  - `home.nix`
    - user desktop entry overrides for:
      - `proton-pass.desktop`
      - `proton-mail.desktop`
      - `Proton Authenticator.desktop`
    - hidden helper:
      - `proton-authenticator-handler.desktop`
    - default mime association:
      - `x-scheme-handler/proton-authenticator -> proton-authenticator-handler.desktop`
  - `quickshell/scripts/launcher-index.js`
    - now scans `pixmaps` roots in addition to normal icon theme roots
  - `quickshell/scripts/ws-icons.js`
    - now includes Proton mappings/heuristics for workspace glyph resolution
- Validation achieved in-session:
  - launcher index cache confirmed valid icon resolution for:
    - `proton-pass.desktop`
    - `proton-mail.desktop`
    - `Proton Authenticator.desktop`
- Still not fully validated:
  - end-to-end `Proton Authenticator` login callback after rebuild activation in the real target session

### Practical continuation note
- Because `mimeapps.list` is managed by Home Manager symlinks, direct `xdg-mime default ...` mutation is not the right long-term fix here.
- The declarative `home.nix` association is the intended solution.
- After rebuild on the notebook, explicitly verify:
  - `xdg-mime query default x-scheme-handler/proton-authenticator`
  - browser redirect back into the app

## Session update - 2026-04-28

### Update Center validation on desktop
- A real `desktop` rebuild was run manually with:
  - `sudo nixos-rebuild switch --flake path:$HOME/dotfiles#desktop`
- Validation found a real UX/logic issue in the local update gate:
  - `codex memories/**` was being treated as dirty worktree state
- Fix applied:
  - `quickshell/scripts/update-center-status.js`
  - `quickshell/scripts/update-center-run.js`
  - both now exclude `codex memories/**`

### Recorder direction changed again
- `obs-studio` remains installed, but it is no longer the primary quick-record flow for Strata.
- Practical desktop decision:
  - keep `OBS` for full/manual capture work
  - use `wf-recorder` for the native quick-record action
- Main files:
  - `quickshell/scripts/screenrecord.sh`
  - `quickshell/scripts/screenrecord-status.sh`
  - `state/screenrecord.env`
- Current product shape:
  - no portal picker
  - record the focused Hyprland output directly
  - save into `~/Vídeos/Gravações de tela`
  - default audio mode is desktop audio only
- Current UX integration:
  - `Super+Alt+R`
  - `Alt+Print`
  - `Settings Center` action
  - `Control Center` toggle

### Bar state indicators
- Screen recording now has its own dedicated bar pill.
- Proton VPN also has its own dedicated bar pill when connected.
- Important layout decision:
  - the right side of the bar is no longer a fixed-anchor mix
  - `CPU/RAM` and `data/hora` try to stay in their original visual position
  - when the right edge grows, they slide left instead of overlapping
- Important motion decision:
  - bar pills now animate on width/opacity/scale changes
  - keep animations short and dry, matching the rest of Strata

### Proton VPN direction
- The official Proton VPN GUI is not the right product path for this setup.
- Root cause found in logs:
  - it depends on `NetworkManager`
  - current Strata desktop uses `iwd` + `dhcpcd`, not `NetworkManager`
- Practical decision:
  - do not migrate desktop networking just to satisfy the Proton GUI
  - standardize on manual Proton WireGuard integration
- Main files:
  - `modules/protonvpn-wireguard.nix`
  - `quickshell/scripts/protonvpn-status.sh`
  - `quickshell/scripts/protonvpn-toggle-notify.sh`
- Current system shape:
  - helper commands:
    - `protonvpn-wg-up`
    - `protonvpn-wg-down`
    - `protonvpn-wg-status`
    - `protonvpn-wg-toggle`
  - UI integration in:
    - `Settings Center`
    - `Control Center`
    - top bar connected-state pill
- Current desktop host config points to:

## Session update - 2026-04-29

### Stable sync attempt on desktop
- User needed to bring `desktop` up to the same level as notebook work already published to `stable`
- Verified branch relationship:
  - `origin/stable` contained one notebook-side commit ahead of `main`
  - commit `06588ea` `Apply notebook stable UI pass and web apps overlay`
- Verified risk profile of that commit:
  - touches Quickshell/UI/session files and `flake.lock`
  - does not touch `hosts/*`, GPU config, `configuration.nix`, or `home.nix`

### What the notebook-side stable commit contains
- Added `Apps Web` overlay
- Added `Settings Center` entry for `Apps Web`
- Updated clipboard UI and binds:
  - notebook bind now uses `Super+V`
  - float/fullscreen binds moved to `Super+Shift+G` and `Super+Shift+F`
- Added expandable notification history cards in `Control Center`
- Improved notification body cleanup for noisy Chromium/site-origin content
- Kept `mako` as the popup delivery layer

### Rebuild blocker encountered on desktop
- `git checkout stable` and `git pull --ff-only origin stable` succeeded
- First `nixos-rebuild test` looked stuck at:
  - `fetching rust-src from https://cache.nixos.org`
- That run was cancelled
- Follow-up diagnostic:
  - `nix build nixpkgs#rustc.src -L` succeeded
- Conclusion:
  - the earlier `rust-src` stall was not a hard permanent failure

### Current real blocker
- Re-running with `-L` advanced into a long local Rust/V8 build:
  - `rusty-v8`
  - `temporal_rs`
  - `temporal_capi`
- Observed long-running visible line:
  - `Compiling temporal_capi v0.2.3`
- This resembles a Deno/V8 dependency path rather than a desktop GPU/config issue

### Current working hypothesis
- The likely trigger is `codex` from `modules/packages.nix`
- `codex` is declared in `environment.systemPackages`
- The hypothesis was based on the dependency shape, not on a completed formal `why-depends` proof
- Practical implication:
  - if the goal is simply to sync desktop to the notebook UI state quickly, temporarily removing `codex` is the best next experiment

### Safe operational rule remembered
- Cancelling `sudo nixos-rebuild test ...` is acceptable here
- Since `test` was cancelled before completion:
  - the old system generation should remain the effective active state
  - shutting down immediately afterward was considered safe

### Next-session continuation plan
- Keep in mind that the local repo is currently checked out on `stable`
- Recommended resume path:
  1. Temporarily remove `codex` from `modules/packages.nix`
  2. Run `sudo nixos-rebuild test --flake path:$HOME/dotfiles#desktop -L`
  3. If successful, run `sudo nixos-rebuild switch --flake path:$HOME/dotfiles#desktop`
  4. Validate Web Apps, clipboard binds, Settings Center, Control Center notification expansion
  5. After validation, switch repo checkout back to `main` for normal desktop development flow
  - `/home/ankh/Projects/VPN/Strata-BR-18.conf`
- Important sudo decision:
  - Strata UI actions may start/stop `protonvpn-wg.service` via NOPASSWD sudo rules

### Proton VPN validated state
- Manual WireGuard tunnel was validated successfully on `desktop`.
- Confirmed good signals:
  - `protonvpn-wg.service` reaches `active (exited)`
  - interface `protonvpn` comes up
  - external IP changes through the tunnel
- Follow-up note:
  - if the Proton config file moves again, update:
    - `hosts/desktop/config.nix`
    - `strata.protonVPNWireGuard.configFile`
  - `quickshell/scripts/update-center-status.js`
  - `quickshell/scripts/update-center-run.js`
  - both treated `codex memories/**` edits as worktree dirtiness
- Fix applied:
  - git dirtiness detection now excludes `codex memories/**`
- Practical result:
  - memory/context note churn no longer blocks local update flow
  - actual config/code edits still correctly block the local `Update Center` path until committed or stashed
- Current remaining nuance:
  - after the validation session, `Update Center` still reports the tree as dirty because the repo now contains real local edits in Quickshell/update scripts

### OBS validation on desktop
- `obs` is present in the rebuilt system:
  - `/run/current-system/sw/bin/obs`
  - version observed: `32.1.1`
- Validation found a command mismatch:
  - Strata UI was launching `obs-studio`
  - installed desktop entry uses `Exec=obs`
- Fix applied:
  - `quickshell/settingscenter/SettingsCenter.qml`
  - `quickshell/controlcenter/ControlCenter.qml`
  - both now launch `obs`
- Updated direction:
  - keep OBS as the recorder standard on `desktop`
  - command reference in repo should be `obs`, not `obs-studio`

### Proton revalidation after rebuild
- Rebuild-confirmed binaries present:
  - `proton-pass`
  - `proton-mail`
  - `proton-authenticator`
- Rebuild-confirmed user desktop overrides present in `~/.local/share/applications`:
  - `proton-pass.desktop`
  - `proton-mail.desktop`
  - `Proton Authenticator.desktop`
  - `proton-authenticator-handler.desktop`
- Launcher index was regenerated and confirmed to resolve:
  - `Proton Pass`
  - `Proton Mail`
  - `Proton Authenticator`
  - `Proton Mail Bridge`
- MIME handler validation succeeded:
  - `xdg-mime query default x-scheme-handler/proton-authenticator`
  - `gio mime x-scheme-handler/proton-authenticator`
  - both point to `proton-authenticator-handler.desktop`
- Still not closed end-to-end from this shell:
  - real browser callback completion for `proton-authenticator://...`
  - live Hyprland workspace glyph appearance for Proton windows

## Session update - 2026-04-28 (notifications + bar + vpn follow-up)

### Bar / status pill
- The right-side status pill was reworked so transient indicators no longer shift the Wi-Fi/Bluetooth block.
- Current behavior:
  - `DND` and `cafeína` live on the left side of the status pill
  - hardware indicators stay anchored on the right
- `quickshell/bar/Tray.qml` was also normalized to the same `28px` pill height used by the rest of the bar.

### Proton VPN UX
- Proton VPN status detection was corrected for the current WireGuard shape.
- Important finding:
  - this setup uses policy routing via `wg-quick`
  - looking only at the main routing table was a false negative
- Current repo state:
  - `quickshell/scripts/protonvpn-status.sh` treats an active WireGuard interface as connected
  - `quickshell/scripts/protonvpn-toggle-notify.sh` now sends immediate `Conectando/Desligando` feedback and confirms final state asynchronously
  - `quickshell/scripts/protonvpn-diagnose.sh` was added for fast tunnel inspection
- Real validation achieved:
  - `protonvpn-wg.service` starts successfully
  - interface `Strata-BR-18` appears
  - `wg show ... latest-handshakes` returns a non-zero handshake timestamp
  - external IP changes through the Proton tunnel

### Notification architecture
- Main architectural correction:
  - the active desktop notification source is `mako`, not Quickshell's internal `NotificationServer`
  - `quickshell/shell.qml` still has `Notifications {}` disabled
- Because of that, the Control Center inbox now reads from `makoctl history -j` and `makoctl list -j`.
- New helpers:
  - `quickshell/scripts/notification-history.js`
  - `quickshell/scripts/notification-dnd.sh`
  - `quickshell/scripts/notification-icon-daemon.sh`

### Notification inbox behavior
- The Control Center notifications section was redesigned into a mobile-style card stack.
- Current behavior:
  - fixed inbox area with empty state
  - session-visible history sourced from `mako`
  - `silenciar` toggles real `mako` mode `do-not-disturb`
  - `limpar` removes inbox items locally and dismisses active `mako` notifications
  - normal notification fallback timeout is now `3000ms`
- `mako` config direction:
  - `default-timeout=3000`
  - explicit `[mode=do-not-disturb] invisible=1`

### Notification content shaping
- Website notifications now suppress raw site/domain lines when they are only noise:
  - examples like `claude.ai`
  - `web.whatsapp.com`
- Spotify notification handling was deduplicated:
  - inbox keeps at most one Spotify notification card
  - newer track changes replace/update the previous Spotify card instead of stacking

### Notification icons
- Notification cards now attempt to render app/site icons.
- Important Chromium/web finding:
  - `mako` exposes site icons through temporary `app_icon` files under `/tmp/...`
  - those files expire too quickly for a late-read inbox
- Practical fix:
  - `notification-icon-daemon.sh` runs in the background with Quickshell
  - it continuously warms icon cache through `notification-history.js`
  - temporary web icons are copied into `~/.cache/strata/notifications`
- Result:
  - Chromium notifications in the Control Center can preserve the site icon instead of falling back to the browser icon

## Session update - 2026-04-28 (notebook-only UI iteration)

### Important branch/host note
- This round of changes was made directly on notebook host `strata`
- The working branch during this session is `stable`
- Treat these as notebook-originated UI changes until they are intentionally replayed or merged back into the desktop development path

### Web apps overlay
- New files were added for a native web-app management overlay:
  - `quickshell/webapps/WebApps.qml`
  - `quickshell/webapps/WebAppsStore.qml`
  - `quickshell/scripts/webapp-lib.js`
  - `quickshell/scripts/webapps-index.js`
  - `quickshell/scripts/webapps-apply.js`
- Current notebook integration:
  - `Super+K`
  - `Settings Center -> Apps Web`
- Current design direction:
  - simpler two-column card
  - no top counter
  - no inline search field on the installed list
  - main action labeled `Adicionar`
- Important implementation caveat still remembered:
  - catalog/state/install identity for web apps still needs a cleaner architectural pass later

### Clipboard UI pass on notebook
- Clipboard overlay was restyled to align better with the rest of Strata:
  - title/body typography moved away from the old all-monospace treatment
  - light-theme panel contrast was corrected
  - excess instructional copy in the header was removed
- Current notebook binds:
  - `Super+V` -> clipboard
  - `Super+Shift+G` -> floating toggle
  - `Super+Shift+F` -> fullscreen

### Control Center notifications
- Notification cards in the Control Center now support click-to-expand for longer text
- The explicit `expandir/mostrar menos` hint text was intentionally removed
- Web notification normalization was refined so site-origin noise can be removed from the body without breaking deduplication keys

### Notification renderer decision
- Keep `mako` as the live popup notification renderer
- Do not move Chromium/site popup rendering back into Quickshell yet
- Practical reason:
  - Chromium notifications remain more reliable through `mako`
  - Quickshell should continue as the inbox/history layer on top

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

## Session update - 2026-05-05/06

### Current host / branch workflow
- Current active development is happening on notebook host `strata`.
- `main` is being used as the active development branch in this session.
- Earlier in the session, `main`, `stable`, `origin/main`, and `origin/stable` were aligned at commit `0f2ae7b`.
- Working tree currently contains experimental Quickshell frame/drawer work that has not been finalized or promoted.

### Frame / drawer direction
- Manual edge-bar rendering was tested and rejected visually.
- The rejected approach created separate bars/canvases around the screen and did not feel like one continuous frame.
- Hyprland gaps were restored to the desired baseline:
  - `gaps_in = 3`
  - `gaps_out = 0`
  - `border_size = 0`
- Do not reintroduce Hyprland outer gaps as the main way to create the frame unless there is a deliberate design change.

### Caelestia finding
- Official Caelestia references were cloned locally:
  - `/home/ankh-intel/Projects/references/caelestia-shell`
  - `/home/ankh-intel/Projects/references/caelestia-dotfiles`
- Key architectural finding:
  - Caelestia does not build the frame from independent edge rectangles.
  - It uses fullscreen layer-shell drawer/content windows, exclusion windows, computed regions, and the `Caelestia.Blobs` QML plugin.
  - Visual continuity comes from `BlobInvertedRect` / `BlobRect`, not from stacked bars.

### Current prototype state
- A first Strata drawer architecture exists under `quickshell/frame/`:
  - `StrataDrawers.qml`
  - `StrataFrameExclusions.qml`
  - `StrataFrameRegions.qml`
  - `STRATA_DRAWERS_NOTES.md`
- `FrameEdges.qml` still exists but is explicitly experimental fallback only, not production direction.
- `StrataDrawers.qml` has been moved toward `import Caelestia.Blobs`.
- The Caelestia QML plugin was built successfully through Nix:
  - `/nix/store/whjm0zgmflq05wzdl6rnv0qnpkcn9ii3-caelestia-qml-plugin`
  - QML import path:
    `/nix/store/whjm0zgmflq05wzdl6rnv0qnpkcn9ii3-caelestia-qml-plugin/lib/qt-6/qml`
- A minimal `import Caelestia.Blobs` test passed when `QML2_IMPORT_PATH` included that path.
- The initial full `shell.qml` validation attempt failed only because the sandboxed process could not access Wayland:
  - `Failed to create wl_display`
- This was later rerun successfully with real Wayland access; see the follow-up validation note below.

### Important caveat
- `quickshell/scripts/quickshell-start.sh` currently hardcodes the built Caelestia plugin store path as a local prototype.
- Before treating this as production or syncing between machines, make the plugin path reproducible through Nix configuration instead of relying on the current store path.

### Follow-up validation - 2026-05-05 late session
- Full `shell.qml` validation with the Caelestia plugin succeeded outside the sandbox with real Wayland access.
- The live Quickshell instance was restarted through `quickshell/scripts/quickshell-start.sh` and loaded successfully.
- `StrataDrawers.qml` was adjusted so the visual fullscreen drawer surface uses:
  - `WlrLayershell.layer: WlrLayer.Bottom`
- Reason:
  - when the fullscreen drawer stayed in the top layer it visually covered the existing Strata bar
  - the invisible exclusion windows can stay above normal windows while the visual frame sits below them
- `StrataFrameExclusions.qml` was simplified toward the Caelestia shape:
  - one tiny exclusion zone for left
  - one tiny exclusion zone for right
  - one tiny exclusion zone for bottom
- `StrataDrawers.qml` now uses a 15px side/bottom frame thickness.
- Confirmed live Hyprland geometry on notebook `strata`:
  - active tiled window at `15,34`
  - active tiled window size `1890x1031`
  - `gaps_in = 3`
  - `gaps_out = 0`
- Confirmed layer layout:
  - background: wallpaper
  - bottom: fullscreen `StrataDrawers` visual surface
  - top: Strata bar, existing utility layer windows, and tiny drawer exclusion windows
- Quickshell was finally started as a transient user service:
```bash
systemd-run --user --unit=strata-quickshell --collect /home/ankh-intel/dotfiles/quickshell/scripts/quickshell-start.sh
```
- Confirmed running instance:
  - unit: `strata-quickshell.service`
  - Quickshell instance id: `5qjmm3flet`
  - pid at validation time: `1051997`
- Remaining known warnings are non-blocking:
  - `Could not attach Keys property ... is not an Item`
  - missing App Center rebuild status file under `~/.cache/strata/appcenter/rebuild-status.txt`
- Current critical next step remains:
  - package the Caelestia QML plugin through Strata/Nix instead of relying on the hardcoded local `/nix/store/...` path.

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
- `quickshell/scripts/notification-history.js` normalizes `mako` payloads into inbox cards
- notification cards now prefer app name, summary, body, and timestamp in a compact mobile-like layout

## Session update - 2026-05-03 (codex update + nix rebuild path)

### Root cause of the long rebuild stall
- The earlier hypothesis that `codex` itself was causing the huge local build was incorrect.
- Dependency tracing on `desktop` showed the problematic chain was:
  - `mpv`
  - `mpv-with-scripts`
  - `yt-dlp`
  - `deno`
  - `rusty-v8`
- Practical outcome:
  - removing `mpv` from `modules/packages.nix` allowed both:
    - `sudo nixos-rebuild test --flake path:$HOME/dotfiles#desktop -L`
    - `sudo nixos-rebuild switch --flake path:$HOME/dotfiles#desktop`
  - to finish successfully

### Branch / memory handling note
- During the same session, `codex memories/STRATA_CONTEXT.md` and `codex memories/STRATA_MEMORY.md` were real modified files in git.
- The user explicitly wants memory files committed/pushed when needed so they can resume context on another machine later.

### Full flake update outcome
- `nix flake update` was run successfully on `main`.
- `home-manager` and `nixpkgs` both advanced in `flake.lock`.
- First full rebuild after the update did not fail on compilation logic.
- It failed on binary substitute/network instability from `cache.nixos.org`.
- Repeated signals in the failed run:
  - `HTTP error 206`
  - `Failed sending data to the peer`
  - `OpenSSL SSL_read: SSL_ERROR_SYSCALL`
- Packages affected by substitute failures included:
  - `chromium`
  - `deno`
  - `gdal`
  - `hyprland`
  - `kitty`
  - `libreoffice`
  - `linux`
  - `yt-dlp`

### Working rebuild retry strategy
- The rebuild passed after reducing cache download concurrency.
- Working command:
  - `sudo nixos-rebuild switch --flake path:$HOME/dotfiles#desktop -L --option http-connections 2 --option max-substitution-jobs 2 --option connect-timeout 15 --option stalled-download-timeout 30`
- Important operational note:
  - the current blocker for large updates on this machine is unstable substitute downloads, not evaluation or the `codex` package itself
  - `--fallback` is still a bad default here because it could trigger very large local builds

### Codex package state after successful rebuild
- After the successful reduced-concurrency rebuild, the system `codex` version was still:
  - `codex-cli 0.125.0`
- Local validation confirmed this matched the package exposed by the current `nixpkgs` snapshot:
  - `nix eval 'path:/home/ankh/dotfiles#nixosConfigurations.desktop.pkgs.codex.version' -> 0.125.0`
- Binary path at that point:
  - `/run/current-system/sw/bin/codex`
  - real store path under `/nix/store/...-codex-0.125.0/bin/codex`

### Upstream Codex version validation
- Official/current published npm package was verified during the session:
  - `npm view @openai/codex version -> 0.128.0`
- This established the exact gap:
  - upstream npm release: `0.128.0`
  - current `nixpkgs` package in this flake: `0.125.0`

### Codex override implemented in repo
- A local Nix overlay was added so `pkgs.codex` no longer depends on the lagging `nixpkgs` package definition.
- Files added/changed:
  - `flake.nix`
  - `pkgs/codex.nix`
- Implementation choice:
  - do not rebuild the Rust package from source
  - instead package the official Linux x64 npm release tarball:
    - `https://registry.npmjs.org/@openai/codex/-/codex-0.128.0-linux-x64.tgz`
- The packaged tarball contains:
  - vendored `codex` binary
  - vendored `rg`
- The local wrapper keeps `bubblewrap` on `PATH`, preserving expected Linux runtime behavior.

### Codex override validation
- The override evaluated successfully:
  - `nix eval 'path:/home/ankh/dotfiles#nixosConfigurations.desktop.pkgs.codex.version' -> 0.128.0`
- The package built successfully via:
  - `nix build 'path:/home/ankh/dotfiles#nixosConfigurations.desktop.pkgs.codex' -L --no-link`
- Built binary validation succeeded:
  - `/nix/store/...-codex-0.128.0/bin/codex --version -> codex-cli 0.128.0`

### Resume point for next session
- Current repo state after this work includes:
  - updated `flake.lock`
  - `flake.nix` overlay change
  - new `pkgs/codex.nix`
- Next practical step on the real machine:
  - run `sudo nixos-rebuild switch --flake path:$HOME/dotfiles#desktop -L --option http-connections 2 --option max-substitution-jobs 2 --option connect-timeout 15 --option stalled-download-timeout 30`
  - then confirm `codex --version`
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

## Session update - 2026-05-03 (theme system direction)

### Theme model
- Strata themes now carry two explicit layers:
  - `semantic`: primary, secondary, success, warning, danger, info
  - `ui`: bar style/colors, panel colors, radius scale, accent strength
- `Colors.qml` treats theme `ui` values as the default source of interface personality.
- `theme-preferences.json` is now an explicit override file only when it contains `"enabled": true`; otherwise it does not freeze all themes into the same bar/panel style.

### Applied visual semantics
- Top bar indicators use role colors instead of a single accent.
- App Center uses:
  - success for installed apps
  - warning for queued/pending rebuild state
  - danger for errors
  - primary for main actions
- Update Center derives a status tone:
  - success for clean/success
  - warning for blocked local state
  - info for running
  - danger for error
- Control Center uses semantic tones for VPN, Wi-Fi, Bluetooth, DND, caffeine, recording, power profile, volume muted state, and notification cards.

### Theme Picker
- The Theme Picker no longer hardcodes themes.
- It loads normalized theme data from `quickshell/scripts/theme-list.js`.
- Theme cards now preview a miniature Strata UI:
  - bar
  - workspace/status pills
  - semantic color row
  - notification-like card
- Applying a theme triggers a short dry color pulse before closing.

## Session update - 2026-05-04 (wallpaper picker + animation test)

### WallPickr direction
- `WallPickr` was changed from a large carousel into a compact centered grid.
- Current shape:
  - centered, minimal panel
  - 3-column wallpaper grid for the active theme
  - vertical scrolling when a theme has more options
  - selected wallpaper has a primary border
  - currently applied wallpaper has a success check marker
  - thumbnails are clipped through an inner rounded mask so image corners match the card
- This was inspired by the grid screenshot the user provided.

### Animation state
- Hyprland is currently using a Zephyr-inspired animation preset:
  - `strataZephyr = 0.23, 1, 0.61, 1`
  - window open uses quick `popin 92%`
  - workspace/special workspace uses longer `slide`
  - window close uses faster `strataClose` with `popin 86%` to avoid ghost-like lingering
- Quickshell workspace slider now uses the same Zephyr-like QML bezier curve:
  - `Easing.BezierSpline`
  - curve `[0.23, 1, 0.61, 1, 1, 1]`
  - duration `570ms`
- `hyprctl reload` succeeded after the config change.
- Quickshell was restarted and loaded the new WallPickr.

## Session update - 2026-05-04 (Zephyr screenshot selector)

### Screenshot selector
- Strata now has a Quickshell-native screenshot area selector inspired by `flickowoa/dotfiles` branch `hyprland-zephyr`.
- Main files:
  - `quickshell/screenshot/ScreenshotSelector.qml`
  - `quickshell/screenshot/Rope.qml`
  - `quickshell/screenshot/qmldir`
  - `quickshell/scripts/screenshot-geometry.sh`
  - `quickshell/scripts/screenshot.sh`
  - `quickshell/shell.qml`
- Visual behavior:
  - fullscreen dimmed overlay
  - drag selection rectangle
  - primary-colored border
  - circular corner handles
  - animated rope lines from screen corners to the selected rectangle
- Integration:
  - `quickshell ipc call screenshot select <requestId>`
  - `screenshot.sh area ...` tries this overlay first
  - previous `grimblast --freeze` / `slurp` area capture remains the fallback
- Supported screenshot actions retained:
  - `copy`
  - `save`
  - `copysave`
  - `edit`

### Screenshot capture implementation notes
- Area captures through the new overlay use `grim -g "$geometry"`.
- `modules/packages.nix` now includes `grim` explicitly.
- Until a rebuild exposes `grim` directly on PATH, `screenshot.sh` can find the `grim` binary referenced inside the current `grimblast` wrapper.
- Geometry results are passed through runtime files under:
  - `${XDG_RUNTIME_DIR:-/tmp}/strata-screenshot`
- Canceling the selector writes `cancel` and exits cleanly without falling through to a capture.

### Validation state
- Script syntax validation passed:
  - `bash -n quickshell/scripts/screenshot.sh`
  - `bash -n quickshell/scripts/screenshot-geometry.sh`
- Nix package list evaluation for `desktop` passed after adding `grim`.
- Quickshell was restarted and loaded the config successfully.
- Remaining manual validation:
  - press `Print` or `Super+Shift+S`
  - drag a region
  - confirm the saved/copied image matches the selected geometry

### Current publish bundle
- The user asked to save all context/memory and push to GitHub.
- This publish should include the current complete repo state, including:
  - Codex package override files under `pkgs/`
  - flake updates
  - theme model updates
  - notification/icon daemon updates
  - WallPickr grid changes
  - Zephyr animation changes
  - screenshot selector implementation

## Session update - 2026-05-04 (login polish + Codex close guard + theme transitions)

### SDDM/login
- User reported the previous session was interrupted and asked to inspect/fix login behavior.
- Implemented current wallpaper propagation to SDDM:
  - `modules/desktop.nix`
    - activation now reads `/home/ankh/dotfiles/state/current-wallpaper`
    - generates `/var/lib/strata/background.jpg` with strong ImageMagick blur
    - fallback remains repo `wallpaper.jpg`
  - `quickshell/scripts/apply-theme-state.sh`
    - added `render_sddm_background()`
    - updates `/var/lib/strata/background.jpg` when wallpaper/theme changes
- Implemented likely cursor fix for SDDM:
  - `services.displayManager.sddm.settings.Theme.CursorSize = "24"`
  - `environment.pathsToLink = [ "/share/icons" ]`
- Reason:
  - live `/run/current-system/sw/share/icons` exposed only generic icon dirs, so SDDM likely could not see Bibata cursor assets.

### Codex close guard
- Initial broad guard blocking all terminal close was removed after user clarified the requirement.
- Final behavior:
  - `Super+W` closes windows normally
  - if the active terminal process tree includes `codex`, first press warns and does not close
  - second press within 5 seconds confirms close
- Files:
  - `hyprland.conf`
  - `quickshell/scripts/codex-close-guard.sh`
- Validation:
  - `bash -n quickshell/scripts/codex-close-guard.sh`
  - `hyprctl reload`

### Smooth theme transitions
- User wanted theme changes to feel modern, smooth, and fast.
- Implemented:
  - `quickshell/Colors.qml`
    - global color/number property animations for theme properties
    - `themeTransitionDuration = 220`
    - `Easing.OutCubic`
  - `quickshell/scripts/apply-theme-state.sh`
    - awww wallpaper transition changed to fast centered grow:
      - `grow`
      - `0.34s`
      - `144fps`
      - `step=90`
      - bezier `0.23,1,0.61,1`
    - wallpaper application moved to the beginning of `--apply-wallpaper`
    - prevents delayed wallpaper change after GTK/kitty/mako work
- Validation:
  - `bash -n quickshell/scripts/apply-theme-state.sh`
  - Quickshell loaded with the updated `Colors.qml`
  - tested real switches:
    - `rosepine -> nord -> rosepine`
  - restored wallpaper:
    - `/home/ankh/dotfiles/wallpapers/rosepine/Rosepine3.jpg`
  - confirmed only one Quickshell instance remained in Hyprland layers.

## Session update - 2026-05-04 (Caelestia shell research + future Strata frame)

### User direction
- User asked to research how Caelestia Shell makes windows/panels and borders feel like they expand from corners and integrate with the system instead of floating.
- User approved pursuing that direction for Strata.

### Research summary
- Caelestia Shell:
  - Quickshell-based desktop shell for Hyprland
  - QML/Qt6 UI with C++ plugins for deeper integration/deformation
  - main repo: `caelestia-dots/shell`
- Relevant source inspected:
  - `shell.qml`
  - `modules/drawers/Drawers.qml`
  - `modules/drawers/ContentWindow.qml`
  - `modules/drawers/Panels.qml`
  - `modules/drawers/Backgrounds.qml`
  - `modules/drawers/Interactions.qml`
  - `modules/drawers/Exclusions.qml`
  - `modules/launcher/Wrapper.qml`
  - `modules/launcher/Background.qml`
  - `modules/sidebar/Wrapper.qml`
  - `modules/sidebar/Background.qml`
- Key architecture:
  - fullscreen transparent Quickshell `PanelWindow` per monitor
  - persistent bar/border/drawer frame belongs to that window
  - drawer contents are anchored `Item`s, not separate floating windows
  - drawers animate through `offsetScale`
  - backgrounds are drawn as connected shapes through `ShapePath`
  - Caelestia also uses `Caelestia.Blobs` for organic deformation/smoothing
  - interactions are edge/corner driven through hover and drag thresholds

### Future implementation plan for Strata
- Do not copy Caelestia wholesale.
- Build a Strata-native integrated shell frame:
  1. Add a fullscreen transparent `ShellFrame` layer.
  2. Move current border pieces into that layer.
  3. Add edge-attached drawer wrappers with shared animation tokens.
  4. Start with QML `Shape` / `ShapePath` connected backgrounds.
  5. Convert overlays gradually:
     - launcher from bottom
     - settings/update/app center from right/top
     - theme picker and wallpickr as integrated drawers
  6. Preserve Strata visual identity and current theme system.
  7. Consider plugin/blob deformation only after QML-only implementation is proven.
- Target feel:
  - panels expand from the screen frame/corners
  - borders and panels are one cohesive shell surface
  - fewer floating-card overlays

### Publish intent
- User requested:
  - record everything in memory/context
  - push complete current repo state to GitHub

## Session update - 2026-05-04 (dynamic island + notification surface)

### Dynamic island role
- The active production island is `quickshell/bar/DynamicPill.qml`.
- `quickshell/island/Island.qml` was confirmed to be a second/test island only.
- Workspaces were separated from the island and restored as an always-visible pill in the bar.
- Bar direction:
  - active window title on the left
  - workspace pill near center
  - dynamic island in center
  - status/tray/clock on the right
- This avoids hiding workspace navigation whenever media/notifications/recording are active.

### New island state files
- Added:
  - `quickshell/OverlayState.qml`
  - `quickshell/DynamicIslandState.qml`
  - `quickshell/bar/DynamicPill.qml`
  - `quickshell/bar/DynamicIslandCard.qml`
- Registered:
  - `OverlayState` and `DynamicIslandState` in `quickshell/qmldir`
  - `DynamicPill` and `DynamicIslandCard` in `quickshell/bar/qmldir`
- `shell.qml` now instantiates:
  - `DynamicIslandCard {}`

### Overlay animation integration
- `OverlayState` now records the island geometry.
- Major overlays use that geometry as their animation origin:
  - Launcher
  - Clipboard
  - App Center
  - Update Center
  - Theme Picker
  - WallPickr
  - Control Center
- This preserves existing card UI while making overlays feel like they emerge from the island.
- It is the current bridge toward the future Caelestia-inspired Strata frame/drawer architecture.

### Expanded island
- Clicking the island now opens an expanded card when context exists:
  - media -> compact media controls
  - notification -> notification detail card
  - recording -> recording status card
- The expanded island is a separate overlay layer because it cannot be drawn inside the bar window without clipping.
- Media card controls:
  - previous
  - play/pause
  - next
  - progress bar
- Notification card shows:
  - app/icon
  - summary
  - body/app fallback
  - urgency tone
- Click outside or Escape closes the expanded card.
- The card closes automatically if the island mode changes and would otherwise show stale content.

### Notifications and mako
- Mako is now intended to be invisible notification backend/history, not the visible notification UI.
- Generated mako config now includes:
  - `max-visible=0`
  - `max-history=100`
  - high urgency timeout `9000ms`
- `hyprland.conf` starts mako explicitly with:
  - `mako --config ~/dotfiles/generated/mako/config`
- `DynamicPill` polls `notification-history.js` every `900ms`.
- The island notification pill now handles:
  - cached notification icon
  - app name
  - summary/body
  - high urgency danger color
  - right-click dismissal through `makoctl dismiss -n <id> --no-history`
- Control Center remains the notification inbox/history.

### Validation
- QML load validation passed with:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- `apply-theme-state.sh` syntax validation passed with:
```bash
bash -n quickshell/scripts/apply-theme-state.sh
```
- Known remaining warnings:
  - pre-existing `Keys` attachment warnings on some overlay `PanelWindow`s.

## Session update - 2026-05-04 (Dynamic Island fixes + music refinement)

### ActivSpot direction
- User clarified that the Strata island is based conceptually on:
  - `https://github.com/Devvvmn/ActivSpot`
- Relevant ActivSpot idea retained:
  - island/launcher illusion is driven by shared top-center positioning and state changes
  - Strata should use its existing `OverlayState`/IPC instead of copying ActivSpot's `/tmp/qs_*` file IPC model

### Notifications fixed
- Root cause:
  - `mako` backend/history was present on DBus, but `notification-history.js` did not recognize the current `makoctl` JSON keys:
    - `app_name`
    - `desktop_entry`
  - older parser only looked for forms like `app-name` / `desktop-entry`
- Fix:
  - `quickshell/scripts/notification-history.js` now recognizes both snake_case and dashed notification fields
- Product correction:
  - `max-visible=0` is no longer used because it prevented the expected backend/history flow from behaving reliably
  - generated `mako` config now keeps a transparent `1x1` notification surface:
    - `max-visible=1`
    - transparent background/border/text
    - `width=1`
    - `height=1`
  - this preserves DBus/history without showing visible banners; the island is the visible notification surface
- Startup hardening:
  - `hyprland.conf` and `quickshell/shell.qml` now check for `org.freedesktop.Notifications` before starting `mako`
  - fallback still starts `mako --config ~/dotfiles/generated/mako/config`
  - `home.nix` now defines a declarative user service:
    - `systemd.user.services.mako`

### Island actions
- `DynamicPill.qml` actions now include:
  - left click idle -> launcher
  - right click -> Control Center
  - middle click -> Settings Center
  - left click while overlay mode is active -> toggles/closes the active overlay
  - media/notification/recording states still open their expanded card on left click
  - media right click still play/pauses
  - notification right click dismisses through `makoctl`

### Overlay morph
- `OverlayState.qml` now exposes helper functions for island-origin morph animation:
  - `morphStartYOffset()`
  - `morphStartXScale()`
  - `morphStartYScale()`
- Major overlays now open/close from the island position instead of only doing a subtle center scale:
  - Launcher
  - Clipboard
  - App Center
  - Update Center
  - Theme Picker
  - WallPickr
  - Control Center
  - Settings Center
- This is the current Strata-native ActivSpot-style morph implementation.

### Music island refinement
- `DynamicIslandState.qml` now carries richer media state:
  - `mediaArtPath`
  - `mediaPositionText`
  - `mediaDurationText`
- `DynamicPill.qml` now resolves Spotify/MPRIS album art from:
  - `mpris:artUrl`
  - cached files under `${XDG_RUNTIME_DIR}/strata/spotify-art`
- Compact island media state now shows:
  - album art when available
  - title
  - artist
  - play/pause affordance
  - progress bar
- `DynamicIslandCard.qml` media mode was redesigned:
  - wider/taller card
  - prominent album art
  - title can use two lines
  - artist/status chip
  - progress bar with current time/duration
  - larger previous/play-pause/next controls
  - clicking album art attempts to focus Spotify through Hyprland

### Validation
- Quickshell QML load passed:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Theme script syntax passed:
```bash
bash -n quickshell/scripts/apply-theme-state.sh
```
- `nix eval` confirmed the declarative `mako` service shape.
- Real notification tests via `notify-send` were parsed correctly by:
```bash
node /home/ankh/dotfiles/quickshell/scripts/notification-history.js
```
- Quickshell was restarted after the changes and loaded successfully.

## Session update - 2026-05-05 (Dynamic Island redesign + bar layout)

### Dynamic Island architecture
- The island was refactored toward a more iPhone-like shared-surface model.
- Main files changed:
  - `quickshell/bar/DynamicPill.qml`
  - `quickshell/bar/DynamicIslandCard.qml`
  - `quickshell/DynamicIslandState.qml`
  - `quickshell/bar/Bar.qml`
  - `quickshell/scripts/notification-history.js`
- Important behavior:
  - the bar pill hides while the expanded island surface is visible
  - the expanded card starts from the real island geometry
  - compact content is rendered inside the morphing surface first
  - expanded content fades/lifts in after the surface grows
  - clicking a notification card collapses it
  - notification cards are passive and no longer steal keyboard/mouse focus
- Key fix:
  - notification mode now uses `WlrKeyboardFocus.None`
  - it does not call `forceActiveFocus()`
  - the fullscreen click-catcher is disabled for notifications
  - only the notification card itself is clickable

### Music / Spotify island
- Compact media state was redesigned around the current track.
- The album/song cover now becomes a real circular spinning disc:
  - `DynamicPill.qml` resolves Spotify art
  - generates circular `*.disc.png` assets under `${XDG_RUNTIME_DIR}/strata/spotify-art`
  - QML uses the circular PNG instead of relying on `Rectangle clip` masking
- Reason:
  - QML `Rectangle { radius; clip: true }` did not reliably mask album art as a circle
  - `Qt5Compat.GraphicalEffects` / `OpacityMask` is not installed on the current system
- Music controls:
  - compact play/pause button no longer opens the card
  - play/pause updates optimistically for instant UI feedback
  - a short refresh confirms the real `playerctl` state after `120ms`
  - scroll gestures for next/previous were removed from the compact island
- Spotify notifications are filtered out in `notification-history.js` because music state is already represented by the island.

### Notification card
- New notification arrival now opens the island automatically when no larger overlay is active.
- The old `Abrir histórico` button was removed from notification cards.
- Notification card is now compact/minimal:
  - app/icon
  - app name
  - summary
  - body up to two lines
  - optional high-urgency chip
- Current known refinement idea:
  - add intelligent autoclose:
    - normal notification: around 5-6s
    - high urgency: around 9-10s
    - pause timer on hover

### Child pills / bar layout
- Proton VPN indicator moved out of the main island surface into a child pill beside it.
- The main island publishes only the primary surface geometry for morphing.
- `Bar.qml` now reserves a fixed center area for the Dynamic Island:
  - prevents workspaces, window title, stats, clock, tray, and status pills from shifting when the island changes width
  - Dynamic Island remains visually centered
  - child pill space is balanced so VPN does not visually move the main island
- Workspaces and active window title were swapped:
  - workspaces are now on the left
  - active window title is to their right
- Recording state was made more compact:
  - `Gravando 00:15` became `REC 00:15`
- Future child-pill direction:
  - generalize the child rail for VPN, REC, DND, caffeine, and update states
  - keep the main island for the highest-priority active context

### Suggested next refinements
- Implement notification autoclose with hover pause.
- Move recording into a child pill when media or notification is the main context.
- Define a strict island priority model:
  - overlay active
  - new notification
  - media
  - idle
  - persistent states as child pills
- Make the media-card morph more content-aware:
  - compact disc should move toward the expanded art position
  - compact title should morph toward expanded title
  - controls should enter with a short delayed lift
- Consider reducing polling by using MPRIS events or a more event-driven player state path later.

### Validation
- Quickshell QML load was repeatedly validated with:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Validation result:
  - config loaded successfully
  - only pre-existing `Keys` warnings remain on some overlay `PanelWindow`s
- Circular media disc generation was confirmed by a generated file under:
```bash
${XDG_RUNTIME_DIR}/strata/spotify-art/*.disc.png
```

## Session update - 2026-05-05 (ShellFrame migration completed)

### Integrated shell default
- The Strata integrated `ShellFrame` is now the default path:
  - `quickshell/shell.qml`
  - `integratedFrameEnabled: true`
- A runtime override remains available:
  - `state/shell-frame-enabled`
  - current local value: `true`
  - set to `false` to fall back to legacy overlays without editing QML.

### Migrated drawers
- Integrated drawers now implemented:
  - launcher: `FrameLauncher.qml`
  - settings: `FrameSettingsCenter.qml`
  - updates: `FrameUpdateCenter.qml`
  - themes: `FrameThemePicker.qml`
  - wallpapers: `FrameWallPickr.qml`
  - app center: `FrameAppCenter.qml`
  - clipboard: `FrameClipboard.qml`
  - power menu: `FramePowerMenu.qml`
- Shared drawer primitives:
  - `BottomDrawer.qml`
  - `RightDrawer.qml`
- `ShellFrame.qml` now centralizes:
  - frame borders
  - drawer focus
  - `Esc` handling
  - click-outside dismissal
  - `closeDrawers(except)`
  - `anyDrawerOpen()`

### Scope intentionally not migrated
- `ControlCenter` remains standalone for now because it is large and tightly coupled to current panel layout, notifications, system toggles, and live status scripts.
- `ScreenshotSelector` remains standalone because it is a fullscreen capture interaction.
- Tray/calendar menus remain bar-attached popups.
- OSDs and Dynamic Island remain separate shell surfaces.

### Live validation
- Integrated mode was validated with:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Live Quickshell was started through Hyprland.
- Duplicate older Quickshell instance was removed.
- Hyprland layers show one Quickshell instance after cleanup.
- IPC smoke tests succeeded for several integrated drawers.
- Strict log scan showed no QML load/type/reference/property errors.

### Mouse/input correction after enabling frame
- Important implementation note:
  - a transparent fullscreen `PanelWindow` can still block pointer input on Wayland
  - disabling the fullscreen `MouseArea` is not enough
- `ShellFrame.qml` now masks input dynamically:
  - drawer open -> fullscreen `inputRegion`
  - no drawer open -> zero-size `emptyInputRegion`
- This preserves click-outside dismissal while preventing the frame from eating mouse input when idle.

### Completed IPC smoke test
- A real IPC smoke loop opened and closed every integrated drawer:
  - launcher
  - settingscenter
  - updatecenter
  - themepicker
  - wallPickr
  - appcenter
  - clipboard
  - powermenu
- The command had to run outside the sandbox because Quickshell IPC socket access is blocked inside it.
- Post-test state:
  - one Quickshell instance in Hyprland layers
  - no overlay layer left open
  - no strict QML/log errors found

### Autostart hardening
- Added `quickshell/scripts/quickshell-start.sh`.
- `hyprland.conf` now uses:
```bash
exec-once = bash ~/.config/quickshell/scripts/quickshell-start.sh
```
- The wrapper starts the explicit Strata entrypoint:
```bash
quickshell -p ~/dotfiles/quickshell/shell.qml --no-color
```
- The wrapper exits when a `quickshell` process already exists, so login should not create duplicate shells.
- Validation completed:
  - shell script syntax passed with `bash -n`
  - QML load test passed with `timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color`
  - `hyprctl reload` returned `ok`
  - live layer check still showed a single Quickshell instance, pid `3344506`

### GitHub sync request
- User asked to save the final state in memory/context files and push to GitHub.
- Branch: `main`
- Remote: `git@github.com:PedroAugustoOK/Strata-Habitus.git`
- Commit should include:
  - the integrated frame/drawer QML files
  - the `shell.qml` integrated routing and runtime toggle
  - `quickshell/scripts/quickshell-start.sh`
  - the `hyprland.conf` autostart update
  - current memory/context notes

## 2026-05-05 - Current shell state for next session

### What happened
- User reviewed the Caelestia-style shell attempt with screenshots and identified persistent issues:
  - screen/window border looked wrong and mismatched the top bar
  - launcher/theme picker/power menu did not feel connected to the border/frame
  - drawers sometimes needed mouse movement before clicks/keyboard worked
  - notifications could stop clicks/keyboard from working
- Treat these reports as correct. Do not assume the old fullscreen ShellFrame approach is fixed.

### Current decision
- The always-on fullscreen `ShellFrame PanelWindow` approach is disabled for stability.
- Caelestia remains the target inspiration, but the implementation needs to be rebuilt using smaller, exact-size panel windows instead of a fullscreen fake frame.
- `FrameSurface.qml` and the updated frame drawer files are retained as experimental/reference code.

### Stabilized defaults
- `quickshell/shell.qml`
  - `integratedFrameEnabled: false`
  - `screenFrameVisible: false`
- Runtime state:
  - `state/shell-frame-enabled` contains `false`
- Hyprland:
  - `border_size = 0`
  - `gaps_out = 0`
  - active/inactive borders transparent
- Theme scripts:
  - `quickshell/scripts/init-border.sh` sets transparent Hyprland borders
  - `quickshell/scripts/apply-theme-state.sh` does not reapply accent borders
- Dynamic Island / notifications:
  - notification mode uses a smaller input mask around the card instead of a broad input region

### Validation
- QML validation passed with:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Diff whitespace validation passed with:
```bash
git diff --check
```
- Live session was updated with Hyprland keywords for border/gap cleanup and Quickshell restart.

### Git / release target
- Repo: `/home/ankh/dotfiles`
- Remote: `git@github.com:PedroAugustoOK/Strata-Habitus.git`
- Development branch: `main`
- Notebook rollout channel: `stable`
- After committing on `main`, publish current state for notebooks with:
```bash
./strata-promote-release.sh stable HEAD
```

### Notebook continuation command
- Preferred command on the notebook when continuing this work and applying the updated system:
```bash
cd ~/dotfiles && ./strata-apply-channel.sh stable
```
- Alternative direct update path if the notebook already has the installed update script configured:
```bash
sudo ~/dotfiles/strata-update.sh
```

### Next implementation guidance
- Do not continue trying to fix input by adding more fullscreen ShellFrame masks.
- Rebuild the integrated shell in this order:
  - keep standalone overlays active as the stable baseline
  - create one exact-size panel window for one drawer
  - validate click, keyboard, Esc, notification behavior
  - migrate the next drawer only after the previous one is proven
  - reconnect visual borders/animations last

## Stable branch notebook notes preserved during 2026-05-05 merge

### Notebook-originated UI work
- Branch `stable` had notebook-only commits before the ShellFrame stabilization merge:
  - `06588ea Apply notebook stable UI pass and web apps overlay`
  - `fda46c2 Update memories and temporarily remove mpv`
- Preserve these notebook decisions when continuing work on the notebook.

### Web apps overlay
- Native web-app management overlay exists on the notebook rollout path:
  - `quickshell/webapps/WebApps.qml`
  - `quickshell/webapps/WebAppsStore.qml`
  - `quickshell/scripts/webapp-lib.js`
  - `quickshell/scripts/webapps-index.js`
  - `quickshell/scripts/webapps-apply.js`
- Integration:
  - `Super+K`
  - `Settings Center -> Apps Web`
- Current web-app UI direction:
  - simpler two-column card
  - no top counter
  - no inline search field on installed list
  - main action labeled `Adicionar`
- Catalog/state/install identity still needs a cleaner architectural pass later.

### Clipboard and notification notes
- Notebook clipboard UI pass:
  - title/body typography moved away from the old all-monospace treatment
  - light-theme panel contrast was corrected
  - excess instructional copy in the header was removed
- Notebook binds:
  - `Super+V` -> clipboard
  - `Super+Shift+V` and `Super+Shift+G` -> floating toggle
  - `Super+Shift+F` -> fullscreen
- Control Center notification cards support click-to-expand for longer text.
- Keep `mako` as the live popup notification renderer; Quickshell remains the inbox/history layer.

### Package note
- `mpv` was intentionally removed from the `stable` package list in the notebook branch.
- During the merge, this was preserved while keeping newer main additions such as `appimage-run` and `gearlever`.

## Session update - 2026-05-05/06 (Caelestia plugin reproducibility)

### What changed
- The local hardcoded Caelestia QML plugin path in `quickshell/scripts/quickshell-start.sh` was replaced with profile/system QML module discovery:
  - `/run/current-system/sw/lib/qt-6/qml`
  - `$HOME/.nix-profile/lib/qt-6/qml`
- `flake.nix` now pins `caelestia-dots/shell` as a non-flake source input at:
  - `54cdd80c1b7671deeb057cc554f83e436765596a`
- The Strata overlay exposes:
  - `pkgs.caelestia-qml-plugin`
- `modules/packages.nix` installs:
  - `caelestia-qml-plugin`

### Important implementation correction
- `shell.qml` no longer instantiates `StrataDrawers` directly.
- It now loads `quickshell/frame/StrataDrawers.qml` dynamically only when:
  - `state/strata-drawers-enabled` is true
- Reason:
  - `StrataDrawers.qml` imports `Caelestia.Blobs`
  - the stable shell must still load before a system rebuild exposes the plugin under `/run/current-system/sw`
- `StrataDrawers` was removed from `quickshell/frame/qmldir` so importing the `frame` module does not force the Caelestia import in the stable baseline.

### Validation
- `nix eval` confirmed:
  - `nixosConfigurations.strata.pkgs.caelestia-qml-plugin.name -> "caelestia-qml-plugin"`
- Isolated plugin build passed:
```bash
nix build 'path:/home/ankh-intel/dotfiles#nixosConfigurations.strata.pkgs.caelestia-qml-plugin' -L --no-link
```
- Built output:
```text
/nix/store/whjm0zgmflq05wzdl6rnv0qnpkcn9ii3-caelestia-qml-plugin
```
- Stable shell validation passed with `state/strata-drawers-enabled=false` and no `Caelestia.Blobs` import warning.
- Experimental drawer validation passed with:
  - `state/strata-drawers-enabled=true`
  - explicit `QML2_IMPORT_PATH=/nix/store/whjm0zgmflq05wzdl6rnv0qnpkcn9ii3-caelestia-qml-plugin/lib/qt-6/qml`
  - `timeout 5 quickshell -p /home/ankh-intel/dotfiles/quickshell/shell.qml --no-color`
- `git diff --check` passed.

### Current runtime baseline
- Keep these local state flags off unless deliberately validating the experimental path:
  - `state/shell-frame-enabled=false`
  - `state/strata-drawers-enabled=false`
- After a NixOS rebuild, `quickshell-start.sh` should discover the plugin through `/run/current-system/sw/lib/qt-6/qml`.

### Follow-up validation and launcher panel pass
- After rebuild, the plugin path was confirmed live:
```bash
test -d /run/current-system/sw/lib/qt-6/qml/Caelestia/Blobs && echo ok
```
- `state/strata-drawers-enabled=true` restored the Strata drawer exclusions and moved tiled windows away from the screen edges again.
- Hyprland was restored to the previous margin model because windows were again sitting behind the bars with `gaps_out=0`:
  - `gaps_in = 3`
  - `gaps_out = 5, 15, 15, 15`
  - `border_size = 3`
- Runtime check after `hyprctl reload` showed:
  - `general:gaps_out -> 5 15 15 15`
  - active tiled window around `33,42`, size `1854x1005` on 1920x1080
- `LauncherPanel.qml` was corrected from a full-width bottom layer to an exact-width centered bottom layer:
  - changed anchors from `left/right/bottom` to only `bottom`
  - added `implicitWidth: launcherContent.panelWidth`
  - input region starts at `x: 0`
- Live layer validation after restart and `quickshell ipc call launcher toggle` showed:
```text
Layer level 2 (top):
  quickshell launcher panel xywh: 600 460 720 620
```
- Visual correction after screenshot review:
  - the launcher was too tall and the footer sat on the screen edge
  - `FrameLauncher.qml` now limits the launcher to 5 visible rows
  - `LauncherStore.resultLimit` is now 5 for the frame launcher path
  - added `bottomInset = 22` so footer content does not collide with the attached bottom edge
  - live layer after the correction:
```text
Layer level 2 (top):
  quickshell launcher panel xywh: 600 624 720 456
```
- This is the current first successful small-panel drawer direction; continue from here rather than reviving the old fullscreen `ShellFrame`.

### Caelestia-style launcher surface pass
- Follow-up after comparing Caelestia internals:
  - `modules/drawers/ContentWindow.qml`
  - `modules/drawers/Regions.qml`
  - `modules/drawers/Panels.qml`
  - `modules/launcher/Wrapper.qml`
- Key finding:
  - Caelestia coordinates panel content and panel background through the same `offsetScale`
  - the panel background is a `BlobRect` in the drawer surface, not a normal rounded rectangle card
  - wrappers remain alive while `offsetScale < 1`, so close animations are not cut off
- Strata changes made:
  - `FrameLauncher.qml` now imports `Caelestia.Blobs`
  - launcher surface uses `BlobGroup` + `BlobRect`
  - launcher blob has straight bottom corners:
    - `bottomLeftRadius: 0`
    - `bottomRightRadius: 0`
  - `LauncherPanel.qml` remains visible while either:
    - launcher is open
    - or `drawerVisible` is true during animation
  - `BottomDrawer.qml` animation now uses the Strata/Zephyr bezier:
    - `[0.23, 1, 0.61, 1, 1, 1]`
    - `animationDuration = 320`
  - `FrameSurface.qml` bottom-attached mode now squares off the bottom edge instead of preserving a full card silhouette
- Live validation:
  - Quickshell restarted successfully
  - launcher opened through `quickshell ipc call launcher toggle`
  - layer geometry stayed:
```text
xywh: 600 624 720 456
```
  - no new fatal QML errors
  - `git diff --check` passed
- Remaining architectural gap:
  - this is still an exact panel window with a blob surface inside it
  - a later pass should move background/mask/regions into a shared drawer surface if we want the full Caelestia-style unified frame illusion

### Shared drawer/frame state pass
- Added shared drawer state singleton:
  - `quickshell/FrameDrawerState.qml`
  - registered in `quickshell/qmldir`
- `LauncherPanel.qml` now publishes launcher state/geometry:
  - `launcherOpen`
  - `launcherVisible`
  - `launcherOffsetScale`
  - `launcherX`
  - `launcherY`
  - `launcherWidth`
  - `launcherHeight`
- `FrameLauncher.qml` exposes:
  - `drawerOffsetScale`
- `StrataDrawers.qml` now consumes `FrameDrawerState` and draws a launcher pocket in the same `BlobGroup` as the frame:
  - `BlobRect`
  - aligned to the launcher panel
  - follows launcher open/close progress
  - straight bottom corners
- `StrataFrameRegions.qml` now includes the launcher pocket region in the render mask.
- A test moved `StrataDrawers.qml` visual surface from `WlrLayer.Bottom` to `WlrLayer.Top` with the strict mask still applied.
  - result was visually rejected by screenshot review:
    - top/bar composition disappeared or looked broken
    - launcher pocket became an ugly permanent dark cutout/shape
  - rollback applied immediately:
    - `StrataDrawers.qml` is back on `WlrLayer.Bottom`
  - keep this as the safe baseline unless a later pass implements a proper shared top-layer mask/input model.
- Live validation:
  - `quickshell ipc call launcher toggle` opens launcher
  - launcher layer remains exact:
```text
xywh: 600 624 720 456
```
  - active window geometry remains:
```text
at: 33,42
size: 1854,1005
```
  - `git diff --check` passed
- Manual validation still required:
  - click through normal windows when launcher is closed
  - click/keyboard in launcher
  - hover/click near left/right/bottom frame edges
  - notifications while frame surface is on `WlrLayer.Top`
  - if trying top-layer frame again, validate visual composition before continuing

## Publish handoff - 2026-05-06

### Final state before GitHub push
- Work is on branch:
  - `main`
- Remote:
  - `origin git@github.com:PedroAugustoOK/Strata-Habitus.git`
- Goal of this push:
  - preserve all current notebook-side Strata frame/drawer work so development can continue on desktop.

### Files/areas included
- Nix/package reproducibility:
  - `flake.nix`
  - `flake.lock`
  - `modules/packages.nix`
  - `quickshell/scripts/quickshell-start.sh`
- Hyprland margin restoration:
  - `hyprland.conf`
- Quickshell frame/drawer work:
  - `quickshell/FrameDrawerState.qml`
  - `quickshell/frame/StrataDrawers.qml`
  - `quickshell/frame/StrataFrameRegions.qml`
  - `quickshell/frame/StrataFrameExclusions.qml`
  - `quickshell/frame/LauncherPanel.qml`
  - `quickshell/frame/BottomDrawer.qml`
  - `quickshell/frame/FrameLauncher.qml`
  - `quickshell/frame/FrameSurface.qml`
  - `quickshell/frame/qmldir`
  - `quickshell/qmldir`
  - `quickshell/shell.qml`
- Experimental/reference files retained:
  - `quickshell/frame/FrameEdges.qml`
  - `quickshell/frame/STRATA_DRAWERS_NOTES.md`

### Desktop continuation guidance
- First apply/rebuild on desktop normally.
- Confirm Caelestia plugin path exists after rebuild:
```bash
test -d /run/current-system/sw/lib/qt-6/qml/Caelestia/Blobs && echo ok
```
- Confirm runtime flags:
```bash
cat ~/dotfiles/state/shell-frame-enabled
cat ~/dotfiles/state/strata-drawers-enabled
cat ~/dotfiles/state/launcher-panel-enabled
```
- Expected for this experimental continuation:
  - `shell-frame-enabled=false`
  - `strata-drawers-enabled=true`
  - `launcher-panel-enabled=true`
- Validate visually/input in this order:
  - normal click-through with launcher closed
  - launcher open/typing/Escape
  - tiled two-window layout
  - notifications/dynamic island while launcher/frame is enabled
  - fullscreen window behavior
- Avoid re-enabling the old fullscreen `ShellFrame` path as a fix for launcher visuals.
- Avoid moving `StrataDrawers` back to `WlrLayer.Top` without redesigning masks/input first.

## Session update - 2026-05-06 - exact-size panels and pocket rollback

### Starting point
- Continued on `main` from commit `8ac8e89 Add Caelestia-backed Strata drawer prototype`.
- Confirmed the Caelestia plugin exists at:
```bash
/run/current-system/sw/lib/qt-6/qml/Caelestia/Blobs
```
- Local runtime flags used for this experimental pass:
  - `state/shell-frame-enabled=false`
  - `state/strata-drawers-enabled=true`
  - `state/launcher-panel-enabled=true`
  - `state/frame-edges-enabled=false`
  - `state/theme-picker-panel-enabled=true`
  - `state/wallpickr-panel-enabled=true`
  - `state/powermenu-panel-enabled=true`
  - `state/clipboard-panel-enabled=true`

### Quickshell startup fix
- `quickshell/scripts/quickshell-start.sh` was changed to avoid fragile `pgrep -x quickshell` duplicate detection.
- It now exits only when `quickshell list -p "${SHELL_ENTRY}"` reports an actual `Instance`.
- It starts Quickshell normally with:
```bash
quickshell -p "${SHELL_ENTRY}" --no-color
```
- A previous attempt with `--no-duplicate` was rejected because stale/dead instance state could falsely block startup after `quickshell kill`.

### User-reported visual issue
- User screenshots showed:
  - a bottom ghost/notch even when no drawer/panel was open
  - a second active-looking surface behind Theme Picker
  - the same duplicate-surface behavior with Launcher
- Root cause found:
  - `StrataDrawers` pocket surfaces and `StrataFrameRegions` pocket regions were drawing a fake bridge behind the real panel.
  - This produced duplicate active surfaces and residual bottom notches.

### Fix applied
- Removed the Theme Picker pocket/region.
- Removed the Launcher pocket/region.
- Removed `quickshell/FrameDrawerState.qml`.
- Removed the `FrameDrawerState` singleton registration from `quickshell/qmldir`.
- Removed `LauncherPanel` bindings to `FrameDrawerState`.
- Current rule: do not add pocket/bridge surfaces inside `StrataDrawers` until there is a real single-surface/shared-surface design.

### Exact-size panel wrappers added
- Added exact-size, top-layer panel wrappers:
  - `quickshell/frame/ThemePickerPanel.qml`
  - `quickshell/frame/WallPickrPanel.qml`
  - `quickshell/frame/PowerMenuPanel.qml`
  - `quickshell/frame/ClipboardPanel.qml`
- Registered those wrappers in `quickshell/frame/qmldir`.
- Existing content components now expose panel state/sizing:
  - `FrameThemePicker.qml`: `drawerVisible`
  - `FrameWallPickr.qml`: `drawerVisible`, dynamic `panelWidth`, dynamic `panelHeight`
  - `FramePowerMenu.qml`: `drawerVisible`, `panelWidth`, `panelHeight`
  - `FrameClipboard.qml`: `drawerVisible`, fixed `panelWidth: 920`, fixed `panelHeight: 620`
- Clipboard originally opened at about 102px high because of circular sizing; fixed by using explicit fixed dimensions.

### Shell routing
- `quickshell/shell.qml` gained flags for:
  - `themePickerPanelEnabled`
  - `wallPickrPanelEnabled`
  - `powerMenuPanelEnabled`
  - `clipboardPanelEnabled`
- Added `closeFramePanels(except)` to close Launcher, Theme Picker, WallPickr, Power Menu and Clipboard as a coordinated group.
- Added/touched toggle functions:
  - `toggleThemePicker()`
  - `toggleWallPickr()`
  - `togglePowerMenu()`
  - `toggleClipboard()`
- IPC routes, SettingsCenter callbacks, ShellFrame callbacks and Launcher routing now close conflicting frame panels before opening another.

### Validation
- QML load validation passed repeatedly:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Only known `Keys property ... is not an Item` warnings remained.
- `git diff --check` passed.
- Live Quickshell ended with one active instance and no drawer/panel open.
- Final `hyprctl layers` state showed:
  - bottom fullscreen `StrataDrawers`
  - top bar/exclusions
  - no drawer layer open
- Panel geometries validated:
```text
Launcher:     600,624 720x456
ThemePicker: 392,608 1136x472
WallPickr:   502,758 916x322
PowerMenu:   816,1000 288x80
Clipboard:   452,438 1016x642
```
- Coordination validated:
  - WallPickr -> Theme Picker -> Launcher closes the previous panel.
  - Panels open as one top-layer panel with no pocket/second surface behind.
  - Clipboard opened with list and image preview after the fixed-size correction.

### Current direction
- Keep old fullscreen `ShellFrame` disabled.
- Keep `StrataDrawers` only as passive bottom-layer frame/exclusion support, without drawer pockets.
- Continue migrating overlays one at a time to exact-size `PanelWindow` wrappers with local masks.
- Do not fake visual integration by drawing a second surface behind a panel.
- Reconnect visual integration only after designing a truly shared/single surface.

## Session update - 2026-05-06 - right-side exact panel migration

### What changed
- Migrated three more frame overlays to exact-size top-layer panel wrappers:
  - `quickshell/frame/SettingsCenterPanel.qml`
  - `quickshell/frame/UpdateCenterPanel.qml`
  - `quickshell/frame/AppCenterPanel.qml`
- Registered the wrappers in `quickshell/frame/qmldir`.
- Updated content components to expose stable panel sizing and close-animation visibility:
  - `FrameSettingsCenter.qml`
  - `FrameUpdateCenter.qml`
  - `FrameAppCenter.qml`
- `shell.qml` gained new runtime flags:
  - `settingsCenterPanelEnabled`
  - `updateCenterPanelEnabled`
  - `appCenterPanelEnabled`
- Local state files used for validation:
  - `state/settingscenter-panel-enabled=true`
  - `state/updatecenter-panel-enabled=true`
  - `state/appcenter-panel-enabled=true`
- Reminder:
  - `state/` is gitignored, so these flags must be recreated locally when continuing on another machine.

### Routing behavior
- IPC routes now use:
  - `toggleSettingsCenter()`
  - `toggleUpdateCenter()`
  - `toggleAppCenter()`
- `SettingsCenterPanel` forwards internal actions to:
  - Control Center
  - Theme Picker
  - WallPickr
  - App Center
  - Update Center
- `closeFramePanels(except)` now closes all exact-size frame panels before opening another:
  - Launcher
  - Theme Picker
  - WallPickr
  - Power Menu
  - Clipboard
  - Settings Center
  - Update Center
  - App Center

### Validation
- QML load passed:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Whitespace diff check passed:
```bash
git diff --check
```
- Live Quickshell was restarted through:
```bash
hyprctl dispatch exec /home/ankh/dotfiles/quickshell/scripts/quickshell-start.sh
```
- Smoke-tested IPC:
```bash
quickshell ipc call settingscenter toggle
quickshell ipc call updatecenter toggle
quickshell ipc call appcenter toggle
```
- Validated live layer geometries on 1920x1080:
```text
Settings Center: 1282,28 638x1024
Update Center:   1182,28 738x1024
App Center:       982,28 938x1024
```
- Final live layer state had no drawer/panel left open.
- Strict log scan showed only known non-blocking `Keys property ... is not an Item` warnings.

### Current continuation point
- The exact-size panel path now covers:
  - Launcher
  - Theme Picker
  - WallPickr
  - Power Menu
  - Clipboard
  - Settings Center
  - Update Center
  - App Center
- Still keep `ShellFrame` disabled.
- Still keep `StrataDrawers` passive and bottom-layer only.
- Remaining standalone surfaces include Control Center, Web Apps, Screenshot Selector, Dynamic Island, OSDs and bar-attached menus.

## Session update - 2026-05-06 - Web Apps exact panel

### What changed
- `quickshell/webapps/WebApps.qml` is no longer a fullscreen layer with a centered card.
- It is now an exact-size centered `PanelWindow`:
  - `implicitWidth: 1040`
  - `implicitHeight: 648`
  - local mask tied to the card
- Removed the fullscreen `MouseArea` click-catcher.
- Added explicit `open` state so close animation can finish before hiding the panel.
- `shell.qml` gained `toggleWebApps()`.
- `closeFramePanels(except)` now closes Web Apps when another exact-size panel opens.
- `FrameSettingsCenter.qml` now includes `Apps Web` and emits `openWebApps`.
- `SettingsCenterPanel.qml` forwards `openWebApps` to shell routing.

### Validation
- QML load passed:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- `git diff --check` passed.
- Live Quickshell was restarted.
- Smoke-tested:
```bash
quickshell ipc call webapps toggle
quickshell ipc call settingscenter toggle
```
- Validated Web Apps exact geometry on 1920x1080:
```text
Web Apps: 440,216 1040x648
```
- Opening Settings Center after Web Apps left only the Settings Center layer open:
```text
Settings Center: 1282,28 638x1024
```
- Strict log scan still showed only known non-blocking `Keys property ... is not an Item` warnings.

### Updated continuation point
- The exact-size panel path now covers:
  - Launcher
  - Theme Picker
  - WallPickr
  - Power Menu
  - Clipboard
  - Settings Center
  - Update Center
  - App Center
  - Web Apps
- Remaining standalone surfaces:
  - Control Center
  - Screenshot Selector
  - Dynamic Island
  - OSDs
  - tray/calendar menus

## Session update - 2026-05-06 - Control Center layer reduction

### What changed
- `quickshell/controlcenter/ControlCenter.qml` no longer uses a fullscreen overlay layer.
- It now anchors to the top-right with a small layer window:
```text
Control Center: 1548,0 372x695
```
- The actual panel remains visually offset below the bar by `44px`.
- Removed fullscreen `MouseArea` click-catcher.
- Added `mask: Region { item: panel }`.
- Changed keyboard focus from:
  - `WlrKeyboardFocus.Exclusive`
  - to `WlrKeyboardFocus.OnDemand`
- The panel height is capped with:
```qml
Math.min(Screen.height - 56, col.implicitHeight + 28)
```

### Coordination fix
- `closeFramePanels(except)` now closes Control Center unless the active target is Control Center.
- `toggleControlCenter()` now calls:
```qml
closeFramePanels("controlcenter")
```
- This preserves the behavior where Control Center closes the exact-size panels, while exact-size panels also close Control Center.

### Validation
- QML load passed:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- `git diff --check` passed.
- Live smoke:
```bash
quickshell ipc call controlcenter toggle
quickshell ipc call settingscenter toggle
```
- Layer result after opening Settings Center from Control Center:
  - Control Center overlay closed.
  - Settings Center top-layer panel remained:
```text
Settings Center: 1282,28 638x1024
```
- Strict log scan showed only known non-blocking `Keys property ... is not an Item` warnings.

### Updated continuation point
- The reduced/exact panel direction now covers:
  - Launcher
  - Theme Picker
  - WallPickr
  - Power Menu
  - Clipboard
  - Settings Center
  - Update Center
  - App Center
  - Web Apps
  - Control Center
- Remaining standalone fullscreen/special surfaces:
  - Screenshot Selector
  - Dynamic Island
  - OSDs
  - tray/calendar menus

## Session update - 2026-05-06 - stabilization point 1 closed

### Scope
- User asked to close point 1 from the Caelestia-readiness plan:
  - validate stability/input/layers before starting visual polish.
- Result:
  - point 1 is closed for the current live session.

### Fix found during validation
- Idle still had a fullscreen Quickshell overlay layer.
- Cause:
  - `DynamicIslandCard.qml` still used a fullscreen overlay `PanelWindow`.
- Fix:
  - changed `DynamicIslandCard` to a top-centered exact-size card layer.
  - converted island start geometry into local card-window coordinates.
  - removed the fullscreen input region.
  - card input mask remains local to the card.

### Validated idle state
- After Quickshell restart and notification autoclose:
  - no overlay layer remained in idle.
  - only expected layers remained:
    - wallpaper background
    - bottom `StrataDrawers`
    - top bar/exclusions

### Validated migrated panels
- Opened each panel via IPC and checked `hyprctl layers`.
- Each opened as one active layer, and opening the next panel closed the previous one:
```text
Launcher:        600,624 720x456
Theme Picker:    392,608 1136x472
WallPickr:       502,758 916x322
Power Menu:      816,1000 288x80
Clipboard:       452,438 1016x642
Settings Center: 1282,28 638x1024
Update Center:   1182,28 738x1024
App Center:       982,28 938x1024
Web Apps:         440,216 1040x648
Control Center:  1548,0 372x695
```

### Notification validation
- Sent a real notification:
```bash
notify-send 'Strata validação' 'teste de notificação durante fechamento do ponto 1'
```
- Dynamic Island notification opened as:
```text
770,0 380x108
```
- It autocleared and returned to no overlay layer.

### Fullscreen validation
- `hyprctl dispatch fullscreen 1` failed in sandboxed mode but worked after command approval.
- Active Kitty was toggled fullscreen.
- Launcher opened over the fullscreen client as a single exact panel layer.
- Fullscreen was toggled back off.
- Final client state confirmed:
  - `fullscreen: 0`
  - no panel left open

### Validation commands
- QML:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Diff:
```bash
git diff --check
```
- Logs:
```bash
strings /run/user/1000/quickshell/by-id/sxm4lkcmet/log.qslog | rg -n "ERROR|ReferenceError|TypeError|Cannot assign|Cannot read|Unable|Failed|Could not attach"
```
- Only known non-blocking `Keys property ... is not an Item` warnings remain.

### Caveat
- Automated Escape-key injection was not completed.
- `hyprctl dispatch sendshortcut` returned a socket-timeout error in sandboxed execution.
- Close behavior was validated through IPC toggle and panel coordination, not synthetic keyboard injection.

### Next phase
- Proceed to point 2:
  - standardize geometry and animation tokens before starting heavy Caelestia-like visual polish.

## Handoff summary - 2026-05-06

### Current state
- The current shell direction is no longer the old fullscreen `ShellFrame`.
- Current stable experimental foundation:
  - exact-size panel wrappers
  - local input masks
  - coordinated close/open routing
  - passive bottom-layer `StrataDrawers`
  - no drawer pockets or fake bridge surfaces
- Point 1 is closed:
  - idle layer state is clean
  - notification layer state is clean
  - panel sequencing is clean
  - fullscreen sanity was validated

### Files central to this phase
- Routing:
  - `quickshell/shell.qml`
- Passive frame/exclusions:
  - `quickshell/frame/StrataDrawers.qml`
  - `quickshell/frame/StrataFrameRegions.qml`
  - `quickshell/frame/StrataFrameExclusions.qml`
- Exact wrappers:
  - `quickshell/frame/LauncherPanel.qml`
  - `quickshell/frame/ThemePickerPanel.qml`
  - `quickshell/frame/WallPickrPanel.qml`
  - `quickshell/frame/PowerMenuPanel.qml`
  - `quickshell/frame/ClipboardPanel.qml`
  - `quickshell/frame/SettingsCenterPanel.qml`
  - `quickshell/frame/UpdateCenterPanel.qml`
  - `quickshell/frame/AppCenterPanel.qml`
- Reduced standalone panels:
  - `quickshell/webapps/WebApps.qml`
  - `quickshell/controlcenter/ControlCenter.qml`
  - `quickshell/bar/DynamicIslandCard.qml`
- Startup:
  - `quickshell/scripts/quickshell-start.sh`

### Local runtime flags
- `state/` is ignored by git.
- Recreate/check these on the next machine/session:
```text
shell-frame-enabled=false
strata-drawers-enabled=true
launcher-panel-enabled=true
frame-edges-enabled=false
theme-picker-panel-enabled=true
wallpickr-panel-enabled=true
powermenu-panel-enabled=true
clipboard-panel-enabled=true
settingscenter-panel-enabled=true
updatecenter-panel-enabled=true
appcenter-panel-enabled=true
```

### Do not regress
- Do not re-enable fullscreen `ShellFrame` as a visual fix.
- Do not reintroduce `FrameDrawerState` pocket/bridge surfaces.
- Do not make `StrataDrawers` top-layer again as a quick fix.
- Do not add permanent fullscreen click-catchers for normal panels.
- If outside-click close is needed later, add a temporary, explicit modal catcher for that open state only.

### Next points for development
1. **Point 2: geometry and animation tokens**
   - Create a shared token component, likely `FrameTokens.qml`.
   - Centralize:
     - panel widths/heights
     - top/bar offsets
     - side and bottom insets
     - right-panel gutter
     - animation durations
     - close/open easing
     - radius and border constants
   - Replace per-file literals with token references.

2. **Point 3: shared exact-panel primitives**
   - Consolidate repeated wrapper behavior:
     - bottom attached panel
     - right attached panel
     - centered utility panel
   - Keep each wrapper's write scope small and test one group at a time.

3. **Point 4: Caelestia-like visual attachment**
   - Start with Launcher and Theme Picker only.
   - Make connected edges feel attached to the screen frame/bar.
   - Use squared/reduced connected corners and consistent frame border/fill.
   - Avoid fake second surfaces behind panels.

4. **Point 5: selective blob pass**
   - Use `Caelestia.Blobs` only after geometry is stable.
   - Candidate order:
     - Launcher
     - Theme Picker
     - WallPickr
     - then larger right panels.

5. **Point 6: final QA before publish**
   - Validate:
     - click/keyboard/Esc
     - notifications
     - fullscreen
     - tiled/floating windows
     - restart/login startup
     - light/dark themes
   - Then commit/push/promote when the visual direction is no longer experimental.

## Session update - 2026-05-06 - point 3 shared exact-panel primitives

### Scope
- Completed point 3 from the Caelestia-readiness plan:
  - shared exact-panel primitives for bottom, right and centered panel windows.

### Added primitives
- Added:
  - `quickshell/frame/ExactBottomPanelWindow.qml`
  - `quickshell/frame/ExactRightPanelWindow.qml`
  - `quickshell/frame/ExactCenterPanelWindow.qml`
- Registered them in:
  - `quickshell/frame/qmldir`

### Migrated wrappers
- Bottom primitive now backs:
  - `LauncherPanel.qml`
  - `ThemePickerPanel.qml`
  - `WallPickrPanel.qml`
  - `PowerMenuPanel.qml`
  - `ClipboardPanel.qml`
- Right primitive now backs:
  - `SettingsCenterPanel.qml`
  - `UpdateCenterPanel.qml`
  - `AppCenterPanel.qml`
- Center primitive now backs:
  - `quickshell/webapps/WebApps.qml`

### Validation
- QML load passed:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Diff whitespace check passed:
```bash
git diff --check
```
- Live Quickshell was restarted through:
```bash
quickshell kill
hyprctl dispatch exec /home/ankh/dotfiles/quickshell/scripts/quickshell-start.sh
```
- Smoke-tested geometries on 1920x1080:
```text
Launcher:        600,624 720x456
Settings Center: 1282,28 638x1024
Web Apps:         440,216 1040x648
```
- Final `hyprctl layers` returned to a clean state with no panel open.
- Strict log scan showed only the known non-blocking `Keys property ... is not an Item` warnings.

### Continuation
- Point 4 is next:
  - start Caelestia-like visual attachment with Launcher and Theme Picker only.
  - Keep using exact-size primitives and local masks.
  - Do not reintroduce fake pocket/bridge surfaces behind panels.

## Session update - 2026-05-06 - point 4 visual attachment pass

### Scope
- Completed point 4 from the Caelestia-readiness plan with a narrow visual pass on:
  - Launcher
  - Theme Picker
- No fake pocket/bridge surface was reintroduced.
- `StrataDrawers` remains passive bottom-layer frame/exclusion support.

### What changed
- Added shared attachment tokens in `FrameTokens.qml`:
  - `attachedEdgeDepth`
  - `attachedEdgeStrokeOffset`
- `FrameSurface.qml` now uses those tokens for bottom-attached surfaces.
- `FrameLauncher.qml` now uses the same attachment depth/stroke tokens as `FrameSurface`.
- `ThemePickerPanel.qml` / `FrameThemePicker.qml` were adjusted so the visual Theme Picker surface reaches the bottom frame while keeping the content inset internally.
- Theme Picker now preserves its validated layer geometry while visually attaching to the bottom edge.

### Validation
- QML load passed:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Diff whitespace check passed:
```bash
git diff --check
```
- Live Quickshell was restarted and smoke-tested.
- Validated geometries on 1920x1080:
```text
Theme Picker: 392,608 1136x472
Launcher:     600,624 720x456
```
- Screenshots were captured and visually inspected:
  - `/tmp/point4-theme.png`
  - `/tmp/point4-launcher.png`
- Final layer state returned to no open Strata panel.
- Strict log scan showed only the known non-blocking `Keys property ... is not an Item` warnings.

### Continuation
- Point 5 is next:
  - selective blob pass.
  - Candidate order remains Launcher, Theme Picker, WallPickr, then larger right panels.
  - Keep exact-size panel primitives and local masks as the stable base.

## Session update - 2026-05-06 - point 5 selective blob pass

### Scope
- Completed point 5 with a selective blob pass on:
  - Launcher
  - Theme Picker
- Did not migrate WallPickr or larger right panels in this pass.
- Exact-size panel primitives and local masks remain the stable base.

### What changed
- Added shared blob surface component:
  - `quickshell/frame/FrameBlobSurface.qml`
- Registered it in:
  - `quickshell/frame/qmldir`
- `FrameBlobSurface` centralizes the `Caelestia.Blobs` import and draws:
  - `BlobGroup`
  - `BlobRect`
  - normal border/top highlight
  - bottom/right attachment fill support
- `FrameLauncher.qml` now uses `FrameBlobSurface` instead of local `BlobGroup`/`BlobRect` drawing.
- `FrameThemePicker.qml` now uses `FrameBlobSurface` instead of `FrameSurface`.
- `FrameLauncher.qml` no longer imports `Caelestia.Blobs` directly.

### Validation
- QML load passed:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Diff whitespace check passed:
```bash
git diff --check
```
- Live Quickshell was restarted.
- Validated geometries on 1920x1080:
```text
Launcher:     600,624 720x456
Theme Picker: 392,608 1136x472
```
- Screenshots were captured and visually inspected:
  - `/tmp/point5-launcher.png`
  - `/tmp/point5-theme.png`
- Final `hyprctl layers` returned to a clean state with no panel open.
- Strict log scan showed only the known non-blocking `Keys property ... is not an Item` warnings.

### Continuation
- Point 6 is next:
  - final QA before publish.
  - Validate click/keyboard/Esc, notifications, fullscreen, tiled/floating windows, restart/login startup, and light/dark themes.

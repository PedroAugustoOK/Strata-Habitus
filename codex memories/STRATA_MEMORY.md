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

# STRATA_CONTEXT

## Repo
- Working repo: `/home/ankh/dotfiles`
- Primary development host: `desktop`
- Notebook release host: `strata`

## Release model
- `main`: development and validation on `desktop`
- `stable`: manually promoted channel for notebook hosts
- Current mapping:
  - `desktop` -> `main`
  - `nixos` -> `stable`
  - `strata` -> `stable`

## Current validated state
- Notebook `strata`
  - SDDM is working again
  - Strata SDDM theme loads correctly
  - graphical login path is stable
  - theme propagation is fixed and validated in the real session
  - Quickshell, Hyprland border colors, and Chromium all follow theme changes
- Desktop `desktop`
  - remains the default environment for implementation and validation
  - current active UI work includes the new `Update Center`

## Update Center
- New Quickshell overlay available at:
  - `quickshell/updatecenter/UpdateCenter.qml`
  - `quickshell/updatecenter/UpdateCenterStore.qml`
  - `quickshell/updatecenter/UpdateCenterDetails.qml`
- Backend scripts:
  - `quickshell/scripts/update-center-status.js`
  - `quickshell/scripts/update-center-run.js`
- Global bind:
  - `Super+U`
- Behavior:
  - on `desktop`, runs local update flow:
    - `nix flake update`
    - `sudo nixos-rebuild switch --flake path:$HOME/dotfiles#desktop`
  - on `strata`, runs release-style update flow through:
    - `sudo ~/dotfiles/strata-update.sh`

## Important implementation notes
- `apply-theme-state.sh` must not write GTK CSS directly into:
  - `~/.config/gtk-3.0/gtk.css`
  - `~/.config/gtk-4.0/gtk.css`
- Reason:
  - those paths are Home Manager symlinks into the Nix store on this setup
- Correct shape:
  - generated GTK CSS lives under `~/dotfiles/generated/gtk/...`
  - `home.nix` links those generated files into `~/.config`
- Hyprland theme refresh:
  - discover `HYPRLAND_INSTANCE_SIGNATURE` from `/run/user/$UID/hypr/*/.socket.sock` when missing
- Chromium theme refresh:
  - policy-based via `/etc/chromium/policies/managed/strata.json`
  - writes both:
    - `BrowserThemeColor`
    - `BrowserColorScheme`

## Key commands
- Desktop rebuild:
```bash
cd ~/dotfiles && sudo nixos-rebuild switch --flake path:$HOME/dotfiles#desktop
```

- Notebook rebuild:
```bash
cd ~/dotfiles && sudo nixos-rebuild switch --flake path:$HOME/dotfiles#strata
```

- Promote current desktop state to notebook channel:
```bash
cd ~/dotfiles && ./strata-promote-release.sh
```

- Apply configured channel on notebook:
```bash
cd ~/dotfiles && ./strata-apply-channel.sh
```

## Current open items
- Validate the `Update Center` in the real Quickshell session end-to-end
- If needed, refine the live status/log behavior after the first real update run
- Steam native remains a separate unresolved issue and should not be mixed with launcher/App Center diagnosis
- Proton desktop apps should be revalidated after rebuild on the target host:
  - `Proton Pass` launcher icon
  - Proton app workspace glyph resolution
  - `Proton Authenticator` login callback flow

## Session continuation point - 2026-04-27

### What changed today
- A native `Centro de Configuração` was added in Quickshell and bound to `Super+S`.
- PT-BR naming/copy was propagated through the main Strata overlays.
- The launcher gained a `Todos os Apps` mode inside the existing overlay.
- The icon theme direction changed from Papirus toward Colloid.
- File Manager theming was intentionally simplified:
  - only light/dark mode for GTK/Nautilus
  - theme personality via icon colors instead of full palette repainting

### Colloid state
- Current package subset is intentionally reduced for rebuild practicality:
  - scheme variants: `default`
  - color variants: `default`, `pink`, `green`, `grey`, `purple`, `orange`
- Theme color mapping currently follows:
  - `rosepine` -> `pink`
  - `everforest` -> `green`
  - `nord` -> `grey`
  - `tokyonight` -> `purple`
  - `kanagawa` -> `purple`
  - `gruvbox` -> `orange`
  - `flexoki` -> `orange`
  - `oxocarbon` -> `grey`
  - `catppuccinlatte` -> `pink`

### Recorder diagnosis on desktop
- Host `desktop` is `hybrid-amd-nvidia`.
- Kooha was tested and is not reliable there.
- Logs from `xdg-desktop-portal-hyprland` repeatedly showed:
  - `Out of buffers`
  - `Asked for a wl_shm buffer which is legacy`
  - `tried scheduling on already scheduled cb`
- `force_shm = true` in `~/.config/hypr/xdph.conf` did not solve it.
- Conclusion:
  - this is currently treated as an XDPH screencast problem on the hybrid-GPU host, not a generic Kooha UI issue.

### Recorder decision
- `gpu-screen-recorder-gtk` also failed in practice on `desktop`.
- Product direction is now:
  - use `obs-studio` as the recorder
  - stop spending time on Kooha/XDPH and `gpu-screen-recorder-gtk` for this setup
- `SettingsCenter` should launch `obs-studio` for `Gravador de Tela`.

### Immediate next step for tomorrow
- Rebuild `desktop` if needed and validate the OBS flow.
- If OBS is acceptable:
  - keep it as the default recorder direction
  - do not spend more time on Kooha/XDPH or `gpu-screen-recorder-gtk` for this host.

## Session continuation point - 2026-04-27 (publish + notebook handoff)

### Published repo state
- Current published commit on `main`:
  - `bf1a311` `Add settings center and desktop integration updates`
- `origin/main` was pushed successfully and is now the source the notebook should consume.

### Proton app status
- Proton desktop packages currently installed through Nixpkgs:
  - `protonmail-desktop`
  - `protonmail-bridge-gui`
  - `proton-pass`
  - `proton-authenticator`
- Important packaging finding:
  - `proton-pass` and `protonmail-desktop` shipped `.desktop` files referencing icon names, but their actual icon assets were only exposed in `share/pixmaps`
  - `proton-authenticator` already shipped `hicolor` icons
- Fixes added in repo:
  - `home.nix` now defines user-level `.desktop` overrides for Proton apps
  - `launcher-index.js` now also indexes `pixmaps`, not only icon themes
  - `ws-icons.js` now recognizes Proton app classes/titles for workspace glyphs
  - `home.nix` now also declares:
    - `x-scheme-handler/proton-authenticator = proton-authenticator-handler.desktop`
    - hidden helper entry `proton-authenticator-handler.desktop`

### Important validation state
- From the current desktop session, the launcher cache was reindexed and confirmed to resolve:
  - `proton-pass.desktop`
  - `proton-mail.desktop`
  - `Proton Authenticator.desktop`
  all with valid `iconPath` and `source: "user"`
- What was NOT fully validated yet:
  - actual end-to-end `Proton Authenticator` browser callback after rebuild/home-manager activation
  - real workspace glyph appearance for the Proton windows in a live Hyprland session after restart/rebuild

### Recommended first notebook steps
- On notebook host, pull/apply the published channel state normally.
- After switch/login, validate in this order:
  1. launcher icon for `Proton Pass`
  2. workspace glyphs for Proton apps
  3. `Proton Authenticator` login callback completion
- If `Authenticator` still fails:
  - inspect the live `mimeapps.list`
  - confirm `xdg-mime query default x-scheme-handler/proton-authenticator`
  - confirm the browser redirect actually targets `proton-authenticator://...`

## Session continuation point - 2026-04-28

### Desktop rebuild validation
- A real manual rebuild was completed on `desktop` with:
  - `sudo nixos-rebuild switch --flake path:$HOME/dotfiles#desktop`

### Update Center findings
- Validation found that local `Update Center` dirtiness detection was too broad.
- Cause:
  - `quickshell/scripts/update-center-status.js`
  - `quickshell/scripts/update-center-run.js`
  - both counted `codex memories/**` changes as blocking worktree dirtiness
- Fix:
  - exclude `codex memories/**` from git dirtiness detection
- Important current state:
  - `Update Center` will still show blocked on the current repo snapshot if there are real local code/config edits
  - this is now expected behavior, not the old false positive from memory files

### OBS findings
- The rebuilt system installs OBS as `obs`, not `obs-studio`.
- Launcher index already resolves the system desktop entry:
  - `com.obsproject.Studio.desktop`
  - `exec: "obs"`
- Repo fixes applied:
  - `quickshell/settingscenter/SettingsCenter.qml` now launches `obs`
  - `quickshell/controlcenter/ControlCenter.qml` now launches `obs`
- Practical conclusion:
  - OBS remains the chosen recorder direction on `desktop`
  - all Strata launch points should reference `obs`

### Proton state after rebuild
- Confirmed present after rebuild:
  - `proton-pass`
  - `proton-mail`
  - `proton-authenticator`
- Confirmed desktop override files active under `~/.local/share/applications`.
- Confirmed launcher index entries with valid icon resolution for:
  - `Proton Pass`
  - `Proton Mail`
  - `Proton Authenticator`
  - `Proton Mail Bridge`
- Confirmed callback handler association:
  - `x-scheme-handler/proton-authenticator -> proton-authenticator-handler.desktop`
- Still pending only in a live graphical session:
  - real `Proton Authenticator` browser callback completion
  - actual Proton workspace glyph appearance via Hyprland live clients

### Recorder state on desktop
- Quick recording no longer depends on OBS launch flow.
- Current quick-record path:
  - `wf-recorder`
  - direct focused-output capture under Hyprland
  - no portal selection UI
- Main script:
  - `quickshell/scripts/screenrecord.sh`
- Status script:
  - `quickshell/scripts/screenrecord-status.sh`
- Save path:
  - `~/Vídeos/Gravações de tela`
- Current integrations:
  - `Super+Alt+R`
  - `Alt+Print`
  - `Settings Center`
  - `Control Center`
  - top bar recording pill

### Proton VPN state on desktop
- The Proton VPN GUI should be considered deprecated for this setup.
- Reason:
  - it expects `NetworkManager`
  - desktop networking remains on `iwd` + `dhcpcd`
- Supported path now:
  - Proton WireGuard through `wg-quick`
- Main module:
  - `modules/protonvpn-wireguard.nix`

## Session continuation point - 2026-05-03

### Nix rebuild / Codex update context
- User wanted the latest available `codex` on `desktop`.
- Full sequence that matters for continuation:
  1. The long-running local build was traced away from `codex`.
  2. The expensive build chain came from `mpv -> mpv-with-scripts -> yt-dlp -> deno -> rusty-v8`.
  3. Temporarily removing `mpv` from `modules/packages.nix` allowed rebuilds to pass.
  4. After `nix flake update`, the next major failure was network/substitute instability, not compilation logic.
  5. Rebuild finally passed when `http-connections` and `max-substitution-jobs` were both reduced to `2`.

### Important verified state
- Successful rebuild command:
  - `sudo nixos-rebuild switch --flake path:$HOME/dotfiles#desktop -L --option http-connections 2 --option max-substitution-jobs 2 --option connect-timeout 15 --option stalled-download-timeout 30`
- Even after that successful rebuild, system `codex` remained:
  - `codex-cli 0.125.0`
- Current `nixpkgs` snapshot in the flake was verified to expose:
  - `pkgs.codex.version = 0.125.0`
- Upstream published npm package was separately verified to be:
  - `@openai/codex 0.128.0`

### Repo change made for future resume
- A local override was added so this repo can install `codex 0.128.0` immediately without waiting for `nixpkgs`.
- Relevant files:
  - `flake.nix`
  - `pkgs/codex.nix`
- Design choice:
  - package the official Linux x64 npm tarball inside Nix
  - avoid reintroducing a heavy Rust source build path for `codex`
- Validation already completed:
  - Nix evaluation returns `0.128.0`
  - the package builds successfully
  - the built binary prints `codex-cli 0.128.0`

### Next action when resuming
- Re-run the system switch with the same reduced-cache-concurrency options.
- Then verify:
  - `codex --version`
- If another rebuild fails, assume substitute/network instability first, not a bad `codex` override.

## Session continuation point - 2026-05-03 (themes)

### Theme direction
- User asked for a more impactful theme system, excluding wallpaper coupling and icon-theme changes.
- Implemented direction:
  - semantic theme roles across overlays
  - per-theme `ui` personality values
  - dynamic Theme Picker previews
  - short theme-apply transition
- Important behavior:
  - `theme-preferences.json` only overrides theme UI when it contains `"enabled": true`
  - otherwise the selected theme controls bar/panel style
- Validation completed:
  - all theme JSON files parse
  - `theme-list.js` returns 9 normalized themes with bar styles:
    - solid, tinted, contrast, soft
  - running a new Quickshell instance was skipped because the same config is already active

## Session continuation point - 2026-05-04

### Wallpaper picker
- `quickshell/wallpickr/WallPickr.qml` now uses a compact centered grid instead of the old carousel.
- Behavior:
  - minimal centered panel
  - shows wallpapers for the active theme in 3 columns
  - scrolls vertically for themes with many options
  - selected item uses primary border
  - active/current wallpaper uses success marker
  - image thumbnails are clipped by an inner rounded mask

### Animation test state
- Hyprland has been switched to a Zephyr-inspired test preset.
- Important values:
  - `bezier = strataZephyr, 0.23, 1, 0.61, 1`
  - windows use `popin 92%` with speed `2`
  - workspaces use `slide` with speed `6`
- Close path was adjusted after user feedback:
  - `bezier = strataClose, 0.33, 0, 0.12, 1`
  - `windowsOut` uses speed `2`, `popin 86%`
- Quickshell workspace indicator uses the same visual curve with a `570ms` duration.
- Live application:
  - `hyprctl reload` returned `ok`
  - Quickshell was restarted successfully
- Main helpers:
  - `protonvpn-wg-up`
  - `protonvpn-wg-down`
  - `protonvpn-wg-status`
  - `protonvpn-wg-toggle`
- Current configured file on `desktop`:
  - `/home/ankh/Projects/VPN/Strata-BR-18.conf`
- UI integrations:
  - `Settings Center` toggle
  - `Control Center` action card
  - top bar connected-state pill
- Manual validation already achieved:
  - service starts successfully
  - `protonvpn` interface appears
  - external IP changes through the tunnel

### Bar behavior
- The bar right side now uses a hybrid layout:
  - `CPU/RAM` and `data/hora` keep their old ideal visual position
  - when edge pills grow, they slide left instead of overlapping
- Current transient pills:
  - recording
  - Proton VPN connected
- Motion rule:
  - pills should animate in/out with short width/opacity/scale transitions

## Session continuation point - 2026-04-28 (notifications + polish)

### Control Center notifications source of truth
- Important implementation finding:
  - the visible desktop notification system is `mako`
  - Quickshell notification toasts are currently disabled in `quickshell/shell.qml`
- Consequence:
  - inbox/history in `ControlCenter.qml` must read from `makoctl`, not from `NotificationService.notifications`

### Current notification stack
- Main files:
  - `quickshell/controlcenter/ControlCenter.qml`
  - `quickshell/scripts/notification-history.js`
  - `quickshell/scripts/notification-dnd.sh`
  - `quickshell/scripts/notification-icon-daemon.sh`
  - `quickshell/scripts/apply-theme-state.sh`
  - `generated/mako/config`
- Current behavior:
  - inbox is always present in the Control Center
  - notifications are shown as mobile-style cards
  - source is `makoctl history -j` + `makoctl list -j`
  - normal notifications use `3000ms` timeout
  - DND button maps to real `mako` mode `do-not-disturb`

### Web notification icon preservation
- Chromium/web notifications expose temporary `app_icon` paths.
- Directly reading history later is not enough because those files may already be gone.
- Current fix:
  - background daemon pre-caches notification icons into:
    - `~/.cache/strata/notifications`
- This is required if the Control Center should keep site icons after the popup disappears.

### Notification shaping rules
- Raw site lines should be suppressed in website notification bodies when they are only transport noise.
- Spotify is intentionally grouped into a single evolving inbox card instead of stacking multiple track-change cards.

### Shared UI scope
- Current `ControlCenter.qml` remains shared between desktop and notebook.
- Therefore both currently inherit:
  - Proton VPN section
  - screen recorder section
  - notifications inbox
- No host-specific split was introduced in this session.

### Publish state
- Session changes were committed on `main` as:
  - `ae5d3ed` `Refine control center notifications and VPN UX`
- The same commit was pushed to:
  - `origin/main`
  - `origin/stable`
- Intended notebook action:
  - run the normal channel apply flow on the notebook host

## Session continuation point - 2026-05-04 (Zephyr screenshot selector + publish)

### User request
- User provided a screenshot of the Zephyr selection overlay and referenced:
  - `https://github.com/flickowoa/dotfiles/tree/hyprland-zephyr`
- Goal:
  - implement that screenshot selection screen in the current Strata repo.

### Reference inspected
- The remote Zephyr branch was inspected directly from GitHub.
- Important files from the reference:
  - `ss.sh`
  - `quickshell/Main.qml`
  - `quickshell/windows/Geom.qml`
  - `quickshell/windows/Rope.qml`
- Reference behavior:
  - a script sends `geom` to a Quickshell socket
  - Quickshell shows a fullscreen selector
  - the user drags a rectangle
  - the selector returns geometry like `x,y WxH`
  - the overlay draws:
    - dimmed background
    - highlighted rectangle
    - round corner handles
    - animated rope lines from screen corners

### Strata implementation
- Implemented a Strata-native adaptation instead of copying the Zephyr shell architecture.
- New Quickshell module:
  - `quickshell/screenshot/ScreenshotSelector.qml`
  - `quickshell/screenshot/Rope.qml`
  - `quickshell/screenshot/qmldir`
- New IPC entry:
  - target: `screenshot`
  - method: `select(requestId)`
  - registered in `quickshell/shell.qml`
- New geometry bridge script:
  - `quickshell/scripts/screenshot-geometry.sh`
  - writes selection result under:
    - `${XDG_RUNTIME_DIR:-/tmp}/strata-screenshot/<request>.geom`
- Existing screenshot flow updated:
  - `quickshell/scripts/screenshot.sh`
  - area captures now try the new Quickshell overlay first
  - fallback remains the previous `grimblast` / `slurp` path
  - `copy`, `save`, `copysave`, and `edit` actions are preserved

### Package/runtime notes
- `modules/packages.nix` now lists `grim` explicitly.
- Before rebuild, the script can still locate the `grim` binary vendored into the current `grimblast` wrapper.
- This allows the new overlay path to work immediately on the current generation if `grimblast` is present.

### Validation done
- `bash -n` passed for:
  - `quickshell/scripts/screenshot.sh`
  - `quickshell/scripts/screenshot-geometry.sh`
- Nix evaluation of desktop system packages succeeded:
  - `nix eval path:/home/ankh/dotfiles#nixosConfigurations.desktop.config.environment.systemPackages --apply 'pkgs: builtins.length pkgs'`
- Quickshell was restarted from:
  - `/home/ankh/dotfiles/quickshell/shell.qml`
- Quickshell logs showed:
  - `Configuration Loaded`
  - no new screenshot selector load error
- The final interactive drag/capture behavior still needs real user validation by pressing `Print` or the configured screenshot area shortcut.

### Publish intent
- User then requested:
  - save everything in context/memory files
  - push to GitHub
- The current publish should include the complete working tree snapshot, not only the screenshot selector, because the repo already contained many real local edits.

## Session continuation point - 2026-05-04 (login polish, theme transitions, Caelestia direction)

### Safety and terminal close behavior
- User clarified the desired safety behavior:
  - `Super+W` may close terminals normally
  - but should protect a terminal only when it is running Codex
  - "encerrar" referred to accidental Codex/session interruption, not Hyprland `Super+P`
- Implemented scoped guard:
  - `hyprland.conf`
    - `Super+W` now calls `quickshell/scripts/codex-close-guard.sh`
  - `quickshell/scripts/codex-close-guard.sh`
    - reads active Hyprland window PID
    - walks child process tree through `/proc` / `pgrep -P`
    - if no `codex` process is found, dispatches `killactive`
    - if `codex` is found, first `Super+W` warns via notification
    - second `Super+W` within 5 seconds confirms close
- `Super+P` remains `exit`; the earlier broad guard was removed.

### SDDM/login polish
- User requested:
  - SDDM wallpaper should follow the current active theme wallpaper
  - SDDM wallpaper should be strongly blurred
  - mouse cursor should appear/work on the login screen
- Relevant implementation:
  - `modules/desktop.nix`
    - SDDM activation reads `/home/ankh/dotfiles/state/current-wallpaper`
    - generates `/var/lib/strata/background.jpg` through ImageMagick with:
      - `-auto-orient`
      - `-resize 20%`
      - `-blur 0x10`
      - crop/extent to `1920x1080`
    - `settings.Theme.CursorSize = "24"`
    - `environment.pathsToLink = [ "/share/icons" ]`
  - `quickshell/scripts/apply-theme-state.sh`
    - `render_sddm_background()` updates `/var/lib/strata/background.jpg` from the current wallpaper during theme/wallpaper changes
- Rationale for cursor fix:
  - live `/run/current-system/sw/share/icons` only showed `hicolor`/`icons`, so SDDM likely could not resolve the configured Bibata cursor theme from the system profile.

### Theme transition behavior
- User wanted theme switching to feel modern, smooth, and fast from wallpaper through colors.
- Implemented:
  - `quickshell/Colors.qml`
    - added global `Behavior` animations for all primary theme color properties
    - duration: `220ms`
    - easing: `Easing.OutCubic`
  - `quickshell/scripts/apply-theme-state.sh`
    - wallpaper transition changed to:
      - `transition-type=grow`
      - `transition-duration=0.34`
      - `transition-fps=144`
      - `transition-step=90`
      - `transition-pos=0.5,0.5`
      - `transition-bezier=0.23,1,0.61,1`
    - wallpaper is now applied early in `--apply-wallpaper`, immediately after reading `current-wallpaper`
    - final wallpaper application is skipped if already applied early
- Result:
  - wallpaper now starts changing together with Quickshell color interpolation instead of after the heavier GTK/kitty/mako/portal work.
- Validation:
  - `bash -n quickshell/scripts/apply-theme-state.sh`
  - real theme switch tests:
    - `rosepine -> nord -> rosepine`
    - restored wallpaper to `wallpapers/rosepine/Rosepine3.jpg`
  - Quickshell was reloaded and duplicate old instance was removed.

### Caelestia Shell research and future implementation direction
- User likes Caelestia's shell because panels feel integrated into the screen frame instead of floating as separate cards.
- Research sources inspected:
  - `caelestia-dots/shell` GitHub repo
  - DeepWiki pages for Caelestia architecture and Hyprland integration
  - raw source files:
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
- Main finding:
  - Caelestia's effect is architectural, not just an animation preset.
  - It uses a fullscreen transparent Quickshell `PanelWindow` per monitor.
  - A unified drawer/background surface is drawn inside that window.
  - Panels are `Item`s anchored to screen edges and animated by an `offsetScale`.
  - Backgrounds are drawn with `ShapePath` and, in Caelestia, enhanced through `Caelestia.Blobs` plugin deformation/smoothing.
  - Interaction zones on edges/corners decide when drawers open via hover/drag/shortcuts.
- Future Strata implementation plan:
  1. Build a Strata `ShellFrame` fullscreen transparent Quickshell layer.
  2. Move existing screen border pieces into that unified frame.
  3. Introduce drawer wrappers anchored to edges:
     - launcher from bottom
     - settings/update/app center from right or top
     - theme picker / wallpickr as integrated drawers instead of floating cards
  4. Use QML `Shape`/`ShapePath` first for connected rounded backgrounds.
  5. Keep Strata's current visual language; do not clone Caelestia wholesale.
  6. Only consider plugin-level blob deformation later if QML shapes are not enough.
- Important design goal:
  - panels should feel like they expand out of the Strata screen frame/corners, not like separate floating overlays.

### Publish intent
- User asked to record everything in memory/context and push the complete repo state to GitHub.
- Current publish should include:
  - screenshot selector work still pending from previous memory
  - SDDM/login wallpaper/cursor fixes
  - Codex close guard
  - smooth theme/wallpaper transition work
  - Caelestia research notes and future implementation direction

## Session continuation point - 2026-05-04 (dynamic island)

### Dynamic island architecture
- The active island is now the bar-integrated `DynamicPill`, not the separate experimental `quickshell/island/Island.qml`.
- The experimental island folder still exists as test/lab code and is not instantiated in `shell.qml`.
- Main new files:
  - `quickshell/OverlayState.qml`
  - `quickshell/DynamicIslandState.qml`
  - `quickshell/bar/DynamicPill.qml`
  - `quickshell/bar/DynamicIslandCard.qml`
- `OverlayState` tracks:
  - active overlay name
  - island geometry (`islandX`, `islandY`, `islandWidth`, `islandHeight`)
  - island center coordinates
- `DynamicIslandState` tracks the expanded island payload:
  - media
  - notification
  - recording

### Bar layout decision
- Workspaces no longer live inside the island.
- Current intended bar composition:
  - left: active window title
  - center-left: workspace pill
  - center: dynamic island
  - right: status/tray/clock
- Rationale:
  - workspaces are spatial navigation and should remain visible
  - the island is contextual system state and command surface

### Overlay animation direction
- Major overlays now scale from the island geometry instead of from a generic center/corner:
  - Launcher
  - Clipboard
  - App Center
  - Update Center
  - Theme Picker
  - WallPickr
  - Control Center
- This is a QML-only first step toward the future integrated frame/drawer direction.
- The overlays still retain their current card layouts; only their animation origin was unified.

### Expanded island card
- `DynamicIslandCard` is a separate overlay `PanelWindow`, because drawing expansion inside the bar window would be clipped by the bar height.
- Behavior:
  - click media island -> opens compact media card
  - media card includes title, artist, progress, previous/play-pause/next
  - click notification island -> opens compact notification card
  - click recording island -> opens recording status card
  - click outside or Escape closes
  - if island mode changes, stale expanded card closes

### Mako notification integration
- Product direction:
  - mako is now the DBus/history backend
  - the island is the visible notification surface
  - Control Center is the notification history/inbox
- `apply-theme-state.sh` now generates mako config with:
  - `max-visible=0`
  - `max-history=100`
  - high urgency timeout `9000ms`
- `hyprland.conf` starts mako with:
  - `mako --config ~/dotfiles/generated/mako/config`
- `DynamicPill` polls `notification-history.js` every `900ms`.
- Notification pill shows:
  - app name
  - summary/body
  - cached icon when available
  - danger tone for high urgency
- Right-click on notification mode dismisses the active mako notification without preserving it in history.

### Validation
- Quickshell config load was validated repeatedly with:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Result:
  - configuration loaded successfully
  - only pre-existing `Keys` warnings appeared for some overlay `PanelWindow`s
- Script validation:
```bash
bash -n quickshell/scripts/apply-theme-state.sh
```

## Session continuation point - 2026-05-04 (Dynamic Island fixes + music card)

### Conceptual source
- User clarified the island should continue in the direction of:
  - `https://github.com/Devvvmn/ActivSpot`
- The useful ActivSpot concept is the morph illusion:
  - island and overlay share top-center origin/state
  - island gives way as launcher/overlay appears
- Strata implementation should stay native:
  - use `OverlayState`
  - use existing Quickshell IPC handlers
  - do not switch to ActivSpot's `/tmp/qs_*` file IPC model

### Current Dynamic Island files
- Main island files:
  - `quickshell/bar/DynamicPill.qml`
  - `quickshell/bar/DynamicIslandCard.qml`
  - `quickshell/DynamicIslandState.qml`
  - `quickshell/OverlayState.qml`
- Important behavior:
  - idle left click opens launcher
  - right click opens Control Center
  - middle click opens Settings Center
  - media/notification/recording left click opens expanded card
  - overlay mode left click toggles the active overlay

### Notification state
- Mako remains the DBus/history backend.
- The visible notification surface is the island, not `mako`.
- Important correction:
  - do not use `max-visible=0`
  - generated mako config now uses a transparent `1x1` notification surface with:
    - `max-visible=1`
    - `width=1`
    - `height=1`
    - transparent background/border/text
- Reason:
  - `makoctl history -j` and active/history behavior need a real visible slot even if it is visually hidden.
- Parser fix:
  - `notification-history.js` must recognize current `makoctl` keys:
    - `app_name`
    - `desktop_entry`
  - as well as older/dashed variants.
- Startup:
  - `home.nix` now declares `systemd.user.services.mako`
  - `hyprland.conf` and `shell.qml` check `org.freedesktop.Notifications` before attempting to start mako

### Overlay morph state
- `OverlayState.qml` now has morph helper functions:
  - `morphStartYOffset(windowHeight)`
  - `morphStartXScale(targetWidth)`
  - `morphStartYScale(targetHeight)`
- Major overlays animate from the island geometry:
  - Launcher
  - Clipboard
  - App Center
  - Update Center
  - Theme Picker
  - WallPickr
  - Control Center
  - Settings Center

### Music player state
- `DynamicIslandState.qml` media payload now includes:
  - `mediaArtPath`
  - `mediaPositionText`
  - `mediaDurationText`
- `DynamicPill.qml` media polling now reads Spotify via `playerctl`:
  - status
  - title
  - artist
  - position
  - length
  - `mpris:artUrl`
- Album art resolution:
  - direct `file://` art paths when present
  - cached remote art under:
    - `${XDG_RUNTIME_DIR}/strata/spotify-art`
- Compact island player:
  - album art
  - title/artist
  - play-pause affordance
  - progress bar
- Expanded media card:
  - wider/taller card
  - prominent album art
  - title with up to two lines
  - artist and status chip
  - progress with current time/duration
  - previous/play-pause/next controls
  - album-art click focuses Spotify

### Validation performed
- Quickshell config load:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Theme script syntax:
```bash
bash -n quickshell/scripts/apply-theme-state.sh
```
- Notification parser was validated against real `notify-send` entries.
- Active Quickshell instance was restarted and loaded successfully after the music-card changes.

### Next likely refinement
- Visually inspect the expanded music card with real playback and tune:
  - card height/spacing
  - progress bar position
  - title wrapping
  - whether album art should also double-click or right-click to launch/focus Spotify.

## Session continuation point - 2026-05-05 (Dynamic Island shared surface)

### Current island direction
- The Dynamic Island is now a central shell component, not just a status pill.
- Current product model:
  - main island surface shows the highest-priority context
  - persistent states should become child pills around the island
  - the bar should not reflow when the island changes width
- The current implementation is still QML-only.

### Files changed in this session
- `quickshell/bar/DynamicPill.qml`
- `quickshell/bar/DynamicIslandCard.qml`
- `quickshell/DynamicIslandState.qml`
- `quickshell/bar/Bar.qml`
- `quickshell/scripts/notification-history.js`

### Important implemented behavior
- Expanded island now morphs from the actual island geometry.
- The compact bar pill hides while the expanded island surface is visible.
- Compact content is drawn inside the expanding surface before expanded content appears.
- Notification mode is passive:
  - no keyboard focus
  - no forced active focus
  - no fullscreen mouse capture
  - clicking the card itself closes/collapses it
- New notifications automatically open the island if no larger overlay is active.
- Notification card no longer has `Abrir histórico`.
- Spotify notifications are filtered out of `notification-history.js`.
- Compact media play/pause:
  - clickable button pauses/plays without opening the card
  - visual state updates optimistically immediately
  - real state refresh follows after `120ms`
- Mouse wheel next/previous gestures were removed from the compact media island.

### Album-art disc implementation
- User wanted the album/song cover itself to become a round spinning disc.
- Failed approach:
  - QML `Rectangle { radius; clip: true }` around `Image`
  - result looked broken because the image still behaved like a square crop
- Also not available:
  - `Qt5Compat.GraphicalEffects`
  - `OpacityMask` import failed because the module is not installed
- Current working implementation:
  - `DynamicPill.qml` uses ImageMagick (`magick` or `convert`) to generate a circular transparent PNG from the current album art
  - generated files are cached under:
    - `${XDG_RUNTIME_DIR}/strata/spotify-art/*.disc.png`
  - `DynamicIslandState.qml` carries:
    - `mediaDiscPath`
    - `mediaDiscSource`
  - both `DynamicPill.qml` and `DynamicIslandCard.qml` use the circular `mediaDiscSource`
  - the disc rotates while media is playing
- Important note:
  - keep the full square album art for the expanded media card
  - use circular disc art only for compact island/morph state

### Bar layout
- `Bar.qml` now reserves a fixed center area for the island.
- This avoids the left/right bar items moving when the island changes width.
- Workspaces and title were swapped:
  - workspaces first
  - active window title second
- Proton VPN is now a child pill, not part of the main island surface.
- `DynamicPill.qml` balances child-pill width on both sides so the main island remains visually centered.

### Current issues / next refinements
- Implement notification autoclose:
  - normal notification: 5-6s
  - high urgency: 9-10s
  - pause on hover
- Build a real child-pill rail:
  - VPN
  - REC
  - DND
  - caffeine
  - update state
- Move screen recording out of the primary island when media/notification is active.
- Define island priority explicitly:
  - overlay active
  - new notification
  - media
  - idle
  - persistent states as children
- Improve media card morph:
  - compact disc moves toward expanded album art
  - compact title moves toward expanded title
  - controls lift/fade in with a short delay

### Validation
- QML load validation command:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Result:
  - loads successfully
  - only known pre-existing `Keys` warnings remain

## Session update - 2026-05-05 (integrated ShellFrame default)

### Integrated shell frame
- The Caelestia-inspired Strata `ShellFrame` migration is now implemented and enabled by default in code.
- Main files:
  - `quickshell/frame/ShellFrame.qml`
  - `quickshell/frame/BottomDrawer.qml`
  - `quickshell/frame/RightDrawer.qml`
  - `quickshell/frame/FrameLauncher.qml`
  - `quickshell/frame/FrameSettingsCenter.qml`
  - `quickshell/frame/FrameUpdateCenter.qml`
  - `quickshell/frame/FrameThemePicker.qml`
  - `quickshell/frame/FrameWallPickr.qml`
  - `quickshell/frame/FrameAppCenter.qml`
  - `quickshell/frame/FrameClipboard.qml`
  - `quickshell/frame/FramePowerMenu.qml`
- `quickshell/shell.qml` now defaults:
  - `integratedFrameEnabled: true`
- Runtime override still exists:
  - `state/shell-frame-enabled`
  - `true` uses integrated drawers
  - `false` falls back to legacy standalone overlays

### Current integrated IPC routing
- Integrated through `ShellFrame` when enabled:
  - `launcher`
  - `settingscenter`
  - `updatecenter`
  - `themepicker`
  - `wallPickr`
  - `appcenter`
  - `clipboard`
  - `powermenu`
- Kept as standalone/specialized windows:
  - `controlcenter`
  - `screenshot`
  - bar tray/calendar menus
  - OSDs and Dynamic Island

### Validation state
- QML load validation passes with integrated mode enabled:
```bash
timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color
```
- Live session was started through:
```bash
hyprctl dispatch exec "quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color"
```
- Duplicate old Quickshell process `1937` was killed.
- Hyprland layers now show one active Quickshell instance:
  - pid `3162204`
- Basic IPC smoke tests were run for:
  - `launcher`
  - `settingscenter`
  - `themepicker`
  - `clipboard`
- Strict log scan found no QML `ReferenceError`, unavailable type, invalid property, or failed-load errors.

### Mouse/input fix
- After enabling the fullscreen `ShellFrame`, the mouse appeared broken because the transparent fullscreen `PanelWindow` could still own the Wayland input region.
- Fix applied:
  - `ShellFrame.qml` now uses a dynamic `mask`
  - when any drawer is open, the mask covers the fullscreen `inputRegion`
  - when no drawer is open, the mask points to a zero-size `emptyInputRegion`
- Result:
  - click-outside still works while a drawer is open
  - normal mouse input should pass through to apps/bar when drawers are closed

### IPC smoke validation
- Real IPC smoke tests completed successfully outside the sandbox for:
  - `launcher`
  - `settingscenter`
  - `updatecenter`
  - `themepicker`
  - `wallPickr`
  - `appcenter`
  - `clipboard`
  - `powermenu`
- Each target was toggled open and closed.
- Follow-up layer check showed one Quickshell instance:
  - pid `3344506`
- Strict log scan after smoke tests found no QML type/reference/property/load errors and no IPC socket errors.

### Autostart hardening
- Added `quickshell/scripts/quickshell-start.sh`.
- `hyprland.conf` now starts Quickshell through:
```bash
bash ~/.config/quickshell/scripts/quickshell-start.sh
```
- The wrapper uses the explicit shell entry:
```bash
~/dotfiles/quickshell/shell.qml
```
- It exits if a `quickshell` process is already running, reducing accidental duplicate shells at login.
- Validation:
  - `bash -n quickshell/scripts/quickshell-start.sh` passed
  - `timeout 5 quickshell -p /home/ankh/dotfiles/quickshell/shell.qml --no-color` loaded successfully
  - `hyprctl reload` returned `ok`
  - `hyprctl layers` still showed one live Quickshell instance, pid `3344506`

### GitHub sync request
- User asked to save all context/memory files and push the completed ShellFrame work to GitHub.
- Branch: `main`
- Remote: `git@github.com:PedroAugustoOK/Strata-Habitus.git`
- Expected commit scope:
  - integrated `quickshell/frame` drawers and frame primitives
  - default `ShellFrame` routing in `quickshell/shell.qml`
  - autostart wrapper and `hyprland.conf` startup change
  - updated Strata context/memory notes

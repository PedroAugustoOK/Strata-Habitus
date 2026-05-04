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

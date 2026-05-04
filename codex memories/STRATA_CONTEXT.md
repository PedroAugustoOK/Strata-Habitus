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

## Notebook divergence note - 2026-04-28
- Current session work is being done directly on notebook host `strata`
- These UI changes were made on `stable` from the notebook, not from `desktop`
- Treat this as notebook-side polish/divergence for now
- Do not assume the same behavior or files are already validated on `desktop`
- A later pass should decide how to port or replay the notebook changes back onto the desktop development flow

## Session continuation point - 2026-04-28 (notebook UI pass)

### What changed on notebook
- A new `Apps Web` overlay was added and bound to `Super+K`
- `Settings Center` gained an `Apps Web` entry
- The `Clipboard` overlay was simplified:
  - help text was removed from the header
  - typography was moved closer to the rest of Strata overlays
  - light-theme surfaces were corrected to avoid washed-out white-on-white panels
- Clipboard binds changed on notebook:
  - `Super+V` -> clipboard
  - `Super+Shift+G` -> floating toggle
  - `Super+Shift+F` -> fullscreen
- Control Center notifications gained per-card expand/collapse on click
- Chromium/web notifications in the Control Center now suppress noisy raw site-origin lines in the body

### Important notebook-specific notification decision
- Keep `mako` as the active popup notification renderer
- Do not switch popup rendering back to Quickshell for Chromium/site notifications right now
- Reason:
  - `mako` remains the reliable delivery path for Chromium web notifications on this host
  - Quickshell should keep acting as inbox/history presentation on top of `mako`

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

## Session continuation point - 2026-04-29 (stable sync attempt on desktop)

### What was confirmed about branches
- User confirmed the notebook-side changes were published to `stable`, not `main`
- Git comparison on `desktop` showed:
  - `origin/stable` is ahead of `main` by one commit
  - commit: `06588ea` `Apply notebook stable UI pass and web apps overlay`
- Reverse diff showed no commits on `main` missing from `origin/stable`

### What `06588ea` actually changes
- Affects UI/session files, not host/GPU files
- Files touched include:
  - `quickshell/webapps/*`
  - `quickshell/controlcenter/ControlCenter.qml`
  - `quickshell/settingscenter/SettingsCenter.qml`
  - `quickshell/clipboard/Clipboard.qml`
  - `quickshell/scripts/notification-history.js`
  - `hyprland.conf`
  - `mako/config`
  - `flake.lock`
- Important non-findings:
  - does **not** touch `hosts/*`
  - does **not** touch `configuration.nix`
  - does **not** touch `home.nix`
  - does **not** touch GPU-specific modules/config for the hybrid AMD/NVIDIA desktop

### Desktop sync attempt
- The desktop repo was switched to `stable` successfully:
```bash
cd ~/dotfiles
git fetch origin
git checkout stable
git pull --ff-only origin stable
```
- First rebuild attempt:
```bash
sudo nixos-rebuild test --flake path:$HOME/dotfiles#desktop
```
- It appeared stuck for a long time at:
  - `fetching rust-src from https://cache.nixos.org`
- That attempt was cancelled safely with `Ctrl+C`

### Diagnostic findings from the failed attempt
- After cancellation there was no leftover `nixos-rebuild`/`nix build` process still running
- Isolated fetch test succeeded:
```bash
nix build nixpkgs#rustc.src -L
```
- This strongly suggests the earlier `rust-src` stall was transient and not a permanent cache/network failure

### Second rebuild attempt
- Retried with detailed logs:
```bash
cd ~/dotfiles
sudo nixos-rebuild test --flake path:$HOME/dotfiles#desktop -L
```
- This progressed past the old fetch point and entered a heavy local build path:
  - `rusty-v8`
  - `v8`
  - `temporal_rs`
  - `temporal_capi`
- The visible long-running point was:
  - `rusty-v8>    Compiling temporal_capi v0.2.3`
- User reported the notebook had shown the same behavior before
- The second attempt was also cancelled because the user had to leave

### Current best hypothesis
- The sync problem is **not** the hybrid AMD/NVIDIA desktop config
- The active blocker is a large Rust/V8 build triggered by the current package set under the updated `flake.lock`
- Most likely suspect inside the declarative package list:
  - `codex` in `modules/packages.nix`
- Rationale:
  - `codex` is present in `environment.systemPackages`
  - the build chain resembles a Deno/V8-style dependency path (`rusty-v8`, `temporal_*`)
- This was not fully dependency-proven in-session, but it is the current operational hypothesis

### Safe stopping state
- The user cancelled `nixos-rebuild test`, not `switch`
- Therefore:
  - no partially activated test generation should be relied upon
  - the currently booted system should still be the prior working state
  - powering off after cancellation was considered safe

### Recommended continuation next session
- Goal: sync desktop to `stable` without spending hours in the Rust/V8 build path
- First practical option:
  - temporarily remove `codex` from `modules/packages.nix`
  - rerun:
```bash
cd ~/dotfiles
sudo nixos-rebuild test --flake path:$HOME/dotfiles#desktop -L
sudo nixos-rebuild switch --flake path:$HOME/dotfiles#desktop
```
- Second option:
  - keep `codex` and allow the long `rusty-v8` build to continue if time permits
- Important note:
  - branch checkout is currently on `stable`
  - after successful validation on `desktop`, the repo should usually be switched back to `main` for normal development flow
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

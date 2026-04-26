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

# STRATA_CONTEXT

## Current host
- Active machine during the latest validated session: notebook `strata`

## Release model
- `main`: desktop development/validation
- `stable`: manually promoted notebook channel
- Current host mapping:
  - `desktop` -> `main`
  - `nixos` -> `stable`
  - `strata` -> `stable`

## Notebook status
- SDDM on `strata` is working again.
- The custom Strata SDDM theme loads correctly.
- Graphical login path is considered stable.

## Theme propagation status
- Notebook theme propagation is currently fixed and validated in the real user session.
- Confirmed working after rebuild:
  - Quickshell updates on theme switch
  - Hyprland border color updates
  - Chromium follows the selected theme again

## Important implementation notes
- `apply-theme-state.sh` must not write GTK CSS directly into
  `~/.config/gtk-3.0/gtk.css` or `~/.config/gtk-4.0/gtk.css` on this setup,
  because those are Home Manager links into the Nix store.
- Generated GTK CSS now lives under `~/dotfiles/generated/gtk/...` and is linked
  into `~/.config` by `home.nix`.
- Hyprland theme application now discovers
  `HYPRLAND_INSTANCE_SIGNATURE` from `/run/user/$UID/hypr/*/.socket.sock`
  when the environment does not already provide it.
- Chromium theme refresh is policy-based through
  `/etc/chromium/policies/managed/strata.json` and now writes:
  - `BrowserThemeColor`
  - `BrowserColorScheme` matching the theme mode

## Current rebuild command for the notebook
```bash
cd ~/dotfiles && sudo nixos-rebuild switch --flake path:$HOME/dotfiles#strata
```

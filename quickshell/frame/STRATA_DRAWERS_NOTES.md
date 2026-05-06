# Strata Drawers Notes

## Reference

Local Caelestia references:

- `/home/ankh-intel/Projects/references/caelestia-shell/modules/drawers/ContentWindow.qml`
- `/home/ankh-intel/Projects/references/caelestia-shell/modules/drawers/Regions.qml`
- `/home/ankh-intel/Projects/references/caelestia-shell/modules/drawers/Exclusions.qml`
- `/home/ankh-intel/Projects/references/caelestia-shell/modules/drawers/Panels.qml`
- `/home/ankh-intel/Projects/references/caelestia-shell/modules/drawers/Interactions.qml`

## Finding

The Caelestia frame effect is not built from separate edge rectangles.
It uses a fullscreen layer-shell window per monitor, but with a computed
input mask. The visual surface is continuous:

- `Exclusions.qml` reserves border space through tiny exclusion windows.
- `ContentWindow.qml` owns the fullscreen visual layer.
- `Regions.qml` computes the interactive/input regions.
- `BlobInvertedRect` draws the outer frame as one continuous surface.
- `BlobRect` draws attached panel backgrounds that deform into the frame.

## Strata Direction

Do not keep improving `FrameEdges.qml` as production UI. It exists only as
an experimental fallback.

The next implementation should:

- keep current standalone overlays as the stable baseline;
- build a new Strata drawer surface separately from the old `ShellFrame`;
- start with border/exclusion behavior only;
- validate fullscreen apps, tiled windows, pointer input, keyboard focus, and notifications;
- connect the launcher only after the base surface behaves correctly.

Avoid recreating the earlier failure mode:

- no always-on broad input capture;
- no stacked edge bars pretending to be one surface;
- no drawer migration before the frame/exclusion layer is proven.

## Current Prototype State

Current Strata files:

- `StrataDrawers.qml`
- `StrataFrameRegions.qml`
- `StrataFrameExclusions.qml`

Current runtime flag:

- `state/strata-drawers-enabled`

Current approach:

- `StrataFrameExclusions.qml` reserves left/right/bottom edge space through
  small layer-shell exclusion windows.
- `StrataFrameRegions.qml` limits the fullscreen drawer window mask to the
  frame areas.
- `StrataDrawers.qml` is now moving toward the Caelestia plugin path via
  `import Caelestia.Blobs`.
- The visual drawer window is intentionally on `WlrLayer.Bottom` while the
  invisible exclusion windows stay in the top layer. This keeps normal windows
  out of the reserved frame space without letting the fullscreen drawer cover
  the existing Strata top bar.

Current validated geometry on notebook `strata`:

- active tiled window: `x=15`, `y=34`, `width=1890`, `height=1031`
- Hyprland gaps:
  - `gaps_in = 3`
  - `gaps_out = 0`
- effective reserved space:
  - top: existing Strata bar exclusive zone, 34px
  - left/right/bottom: Strata drawer exclusions, 15px

## Caelestia Plugin

The Caelestia QML plugin was built locally with:

```bash
nix build /home/ankh-intel/Projects/references/caelestia-shell#caelestia-shell.plugin -L --no-link
```

Built store path:

```text
/nix/store/whjm0zgmflq05wzdl6rnv0qnpkcn9ii3-caelestia-qml-plugin
```

QML import path:

```text
/nix/store/whjm0zgmflq05wzdl6rnv0qnpkcn9ii3-caelestia-qml-plugin/lib/qt-6/qml
```

A minimal `Caelestia.Blobs` import test passed with this import path.

Full Strata shell validation also passed with real Wayland session access and
the same import path. The earlier `Failed to create wl_display` result was only
a sandbox access failure, not a QML/plugin failure.

## Live Validation - 2026-05-05

The live shell was restarted successfully through:

```bash
/home/ankh-intel/dotfiles/quickshell/scripts/quickshell-start.sh
```

It was then left running as a transient user service:

```bash
systemd-run --user --unit=strata-quickshell --collect /home/ankh-intel/dotfiles/quickshell/scripts/quickshell-start.sh
```

Confirmed service state:

- unit: `strata-quickshell.service`
- Quickshell instance id at validation time: `5qjmm3flet`
- pid at validation time: `1051997`

Confirmed Hyprland layer state:

- background: wallpaper
- bottom: fullscreen `StrataDrawers` visual surface
- top: Strata bar, existing utility layer windows, and tiny exclusion windows

Confirmed active tiled window geometry:

- position: `15,34`
- size: `1890x1031`

This means the exclusions are functionally reserving the frame space:

- top: 34px from the existing Strata bar
- left/right/bottom: 15px from `StrataFrameExclusions`

Important implementation note:

- `StrataDrawers.qml` uses `WlrLayershell.layer: WlrLayer.Bottom`.
- The tiny exclusion windows remain top-layer surfaces.
- This avoids the earlier problem where the fullscreen drawer visual surface
  covered the existing Strata top bar.

## Production Caveat

`quickshell/scripts/quickshell-start.sh` currently hardcodes the local Nix store
plugin path as a prototype. Before this becomes production, package the plugin
through the Strata Nix configuration so both desktop and notebook get the same
QML import path reproducibly.

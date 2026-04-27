{ pkgs, ... }:
let
  bluetoothToggle = pkgs.writeShellScriptBin "strata-bluetooth-toggle" ''
    #!/usr/bin/env bash
    set -euo pipefail

    BTMGMT="/run/current-system/sw/bin/btmgmt"
    HCICONFIG="/run/current-system/sw/bin/hciconfig"
    RFKILL="/run/current-system/sw/bin/rfkill"

    primary_hci() {
      "$HCICONFIG" -a 2>/dev/null | awk '
        /^[a-z0-9]+:/ {
          iface = $1
          sub(/:$/, "", iface)
          current = iface
        }
        /BD Address:/ {
          addr = $3
          if (addr != "00:00:00:00:00:00" && chosen == "") {
            chosen = current
          }
        }
        END {
          if (chosen != "") print chosen
        }
      '
    }

    hci="$(primary_hci)"
    if [ -z "''${hci:-}" ]; then
      echo "no usable bluetooth controller found" >&2
      exit 1
    fi

    case "''${1:-toggle}" in
      on)
        "$RFKILL" unblock bluetooth >/dev/null 2>&1 || true
        "$BTMGMT" --index "$hci" power on
        "$HCICONFIG" "$hci" up
        ;;
      off)
        "$BTMGMT" --index "$hci" power off || true
        "$HCICONFIG" "$hci" down
        ;;
      toggle)
        if "$HCICONFIG" "$hci" 2>/dev/null | grep -q "UP RUNNING\|UP "; then
          "$BTMGMT" --index "$hci" power off || true
          "$HCICONFIG" "$hci" down
        else
          "$RFKILL" unblock bluetooth >/dev/null 2>&1 || true
          "$BTMGMT" --index "$hci" power on
          "$HCICONFIG" "$hci" up
        fi
        ;;
      *)
        exit 2
        ;;
    esac
  '';
in {
  security.rtkit.enable = true;

  services.pipewire = {
    enable             = true;
    alsa.enable        = true;
    alsa.support32Bit  = true;
    pulse.enable       = true;
    wireplumber.enable = true;
  };

  # Auto-conecta dispositivos Bluetooth
  services.pipewire.wireplumber.extraConfig = {
    "bluetooth-auto-connect" = {
      "monitor.bluez.rules" = [{
        matches = [{ "device.name" = "~bluez_card.*"; }];
        actions.update-props = {
          "bluez5.auto-connect" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
          "bluez5.hw-volume"    = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
        };
      }];
    };
  };

  # Garante que WirePlumber sobe depois do PipeWire
  systemd.user.services.wireplumber = {
    after = [ "pipewire.service" ];
    serviceConfig.ExecStartPre = "/run/current-system/sw/bin/sleep 3";
  };

  hardware.bluetooth.enable      = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable        = false;

  environment.systemPackages = [ bluetoothToggle ];
}

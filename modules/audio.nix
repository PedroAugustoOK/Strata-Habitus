{ ... }: {
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
}

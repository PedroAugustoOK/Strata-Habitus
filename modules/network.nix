{ ... }: {
  networking.dhcpcd.wait = "background";

  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings = {
    General.EnableNetworkConfiguration = true;
    Network.EnableIPv6 = true;
  };

  # Some boots expose inconsistent /dev/rfkill state and systemd-rfkill
  # can spend its full 90s timeout early in userspace. Disabling it avoids
  # the boot stall without affecting normal Wi-Fi/Bluetooth operation.
  systemd.sockets.systemd-rfkill.enable = false;
  systemd.services.systemd-rfkill.enable = false;
}

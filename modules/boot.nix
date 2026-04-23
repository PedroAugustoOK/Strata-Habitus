{ lib, hostMeta ? {}, ... }:
let
  bootMeta = hostMeta.boot or {};
  bootMode = bootMeta.mode or "uefi";
  bootLoader = bootMeta.loader or (if bootMode == "legacy" then "grub" else "systemd-boot");
  bootDisk = bootMeta.disk or null;
in {
  boot.loader.systemd-boot.enable      = bootMode == "uefi" && bootLoader == "systemd-boot";
  boot.loader.efi.canTouchEfiVariables = bootMode == "uefi";
  boot.loader.grub = {
    enable = bootLoader == "grub";
    device =
      if bootMode == "legacy" then
        lib.mkDefault (if bootDisk != null then bootDisk else "/dev/sda")
      else
        "nodev";
    efiSupport = bootMode == "uefi";
  };
  boot.loader.timeout                  = 1;

  boot.kernelParams = [
    "quiet" "splash"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "vt.global_cursor_default=0"
    "nowatchdog"
  ];

  boot.initrd.verbose        = false;
  # The systemd-based initrd intermittently breaks while re-parsing /etc/fstab,
  # dropping the machine into emergency mode with "root account is locked".
  # The classic initrd avoids that generator path on both hosts.
  boot.initrd.systemd.enable = false;
  boot.consoleLogLevel       = 0;
  boot.plymouth.enable       = true;

  systemd.services.NetworkManager-wait-online.enable = false;
}

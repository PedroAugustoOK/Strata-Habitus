{ ... }: {
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;
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
  boot.initrd.systemd.enable = true;
  boot.consoleLogLevel       = 0;
  boot.plymouth.enable       = true;

  systemd.services.NetworkManager-wait-online.enable = false;
}

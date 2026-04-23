{
  username = "ankh";
  system = "x86_64-linux";
  profile = "desktop";
  graphics = "hybrid-amd-nvidia";
  timeZone = "America/Porto_Velho";
  locale = "pt_BR.UTF-8";
  boot = {
    mode = "uefi";
    loader = "systemd-boot";
  };
  desktop = {
    enable = true;
  };
}

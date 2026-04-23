{
  username = "ankh-intel";
  system = "x86_64-linux";
  profile = "laptop";
  graphics = "intel";
  timeZone = "America/Porto_Velho";
  locale = "pt_BR.UTF-8";
  boot = {
    mode = "uefi";
    loader = "systemd-boot";
  };
  desktop = {
    enable = true;
    loginManager = {
      enable = false;
    };
  };
}

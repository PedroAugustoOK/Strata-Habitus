{ config, pkgs, lib, modulesPath, username ? "ankh", hostname ? "nixos", ... }:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
    ./configuration.nix
  ];

  boot.loader.timeout = lib.mkForce 10;
  networking.wireless.enable = lib.mkForce false;

  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  users.users.${username} = {
    isNormalUser = true;
    password = "strata";
    extraGroups = [ "wheel" "video" "audio" "networkmanager" "seat" "input" ];
  };

  services.greetd = lib.mkForce {
    enable = true;
    settings.default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd Hyprland";
      user = username;
    };
  };

  security.sudo.wheelNeedsPassword = false;
  security.polkit.enable = true;
  services.seatd.enable = true;
}

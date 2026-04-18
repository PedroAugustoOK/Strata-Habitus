{ config, pkgs, lib, modulesPath, username ? "ankh", hostname ? "nixos", ... }:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
    ./configuration.nix
  ];

  boot.initrd.availableKernelModules = lib.mkForce [
    "xhci_pci" "ahci" "usb_storage" "sd_mod" "nvme"
  ];

  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.isoName = "strata-habitus.iso";

  users.users.${username} = {
    isNormalUser = true;
    password = "strata";
    extraGroups = [ "wheel" "video" "audio" "networkmanager" ];
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "Hyprland";
      user = username;
    };
  };

  security.sudo.wheelNeedsPassword = false;
}

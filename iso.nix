{ config, pkgs, lib, username ? "ankh", hostname ? "nixos", ... }:
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix>
    ./configuration.nix
  ];

  # Remove hardware-configuration pois não existe no live
  boot.initrd.availableKernelModules = lib.mkForce [
    "xhci_pci" "ahci" "usb_storage" "sd_mod" "nvme"
  ];

  # ISO settings
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.isoName = "strata-habitus.iso";

  # Live user
  users.users.${username} = {
    isNormalUser = true;
    password = "strata";
    extraGroups = [ "wheel" "video" "audio" "networkmanager" ];
  };

  # Auto-login no live
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "Hyprland";
      user = username;
    };
  };

  # Sem senha para sudo no live
  security.sudo.wheelNeedsPassword = false;
}

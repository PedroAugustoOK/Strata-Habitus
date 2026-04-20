{ pkgs, username ? "ankh", hostname ? "nixos", ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/boot.nix
    ./modules/network.nix
    ./modules/locale.nix
    ./modules/audio.nix
    ./modules/packages.nix
    ./modules/desktop.nix
    ./modules/security.nix
    ./modules/update.nix
  ];

  networking.hostName = hostname;

  users.users.${username} = {
    isNormalUser = true;
    description  = "Pedro Augusto";
    extraGroups  = [ "wheel" "video" ];
    shell        = pkgs.fish;
    packages     = [];
  };

  system.stateVersion = "25.11";
}

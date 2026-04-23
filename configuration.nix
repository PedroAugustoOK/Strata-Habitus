{ pkgs, lib, username ? "ankh", hostname ? "nixos", hostMeta ? {}, ... }:
let
  desktopMeta = hostMeta.desktop or {};
  desktopEnabled = desktopMeta.enable or true;
in
{
  imports =
    [
      ./modules/boot.nix
      ./modules/network.nix
      ./modules/locale.nix
      ./modules/audio.nix
      ./modules/packages.nix
      ./modules/security.nix
      ./modules/chromium.nix
      ./modules/update.nix
    ]
    ++ lib.optionals desktopEnabled [
      ./modules/desktop.nix
    ];

  programs.fish.enable = true;

  networking.hostName = hostname;
  systemd.defaultUnit = lib.mkDefault (if desktopEnabled then "graphical.target" else "multi-user.target");

  users.users.${username} = {
    isNormalUser = true;
    description  = "Pedro Augusto";
    extraGroups  = [ "wheel" "video" ];
    shell        = pkgs.fish;
    packages     = [];
  };

  system.stateVersion = "25.11";
}

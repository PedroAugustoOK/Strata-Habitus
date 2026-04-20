{ config, pkgs, lib, username ? "ankh", hostname ? "desktop", ... }:
{
  imports = [ ./configuration.nix ];

  networking.hostName = hostname;

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
}

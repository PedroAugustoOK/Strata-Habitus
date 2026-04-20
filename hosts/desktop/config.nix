{ config, pkgs, lib, username ? "ankh", hostname ? "desktop", ... }:
{
  networking.hostName = lib.mkForce hostname;

  # Boot normal sem splash para debug
  boot.kernelParams = lib.mkForce [];
  boot.plymouth.enable = lib.mkForce false;
  boot.initrd.verbose = lib.mkForce true;

  # NVIDIA
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  # Root com senha para emergências
  users.users.root.initialPassword = "strata";
}

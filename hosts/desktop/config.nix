{ config, pkgs, lib, username ? "ankh", hostname ? "desktop", ... }:
{
  imports = [
    ../../modules/graphics-debug.nix
  ];

  networking.hostName = lib.mkForce hostname;

  # Desktop híbrido: a tela está ligada na iGPU AMD (DP-2),
  # então o stack gráfico precisa priorizar amdgpu. A NVIDIA
  # continua disponível para CUDA/apps sem dirigir a sessão.
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];
  hardware.graphics.enable = true;
  hardware.i2c.enable = true;

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
    motherboard = "amd";
    startupProfile = "red.orp";
  };

  users.users.${username}.extraGroups = [ "i2c" ];

  environment.systemPackages = with pkgs; [
    i2c-tools
  ];

  strata.protonVPNWireGuard = {
    enable = true;
    autoStart = false;
    configFile = "/home/ankh/Projects/VPN/Strata-BR-18.conf";
  };

  # Sem senha root — acesso via sudo com usuário wheel
}

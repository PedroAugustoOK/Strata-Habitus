{ lib, ... }:
{
  # Mantém o boot gráfico mais explícito enquanto investigamos problemas
  # de display manager/Wayland em hosts diferentes.
  boot.kernelParams = lib.mkForce [];
  boot.plymouth.enable = lib.mkForce false;
  boot.initrd.verbose = lib.mkForce true;
}

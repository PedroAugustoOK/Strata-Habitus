{ lib, ... }:
{
  imports = [
    ../../modules/graphics-debug.nix
  ];

  # Intel laptop: thermald complements the kernel thermal zones and RAPL limits.
  services.thermald.enable = true;

  boot.kernelParams = lib.mkForce [ "i915.enable_psr=0" ];
}

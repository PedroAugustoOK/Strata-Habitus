{ lib, ... }:
{
  imports = [
    ../../modules/graphics-debug.nix
  ];

  # Galaxy Book2 / Intel Xe: PSR tem forte indicio de causar freeze/black screen
  # antes mesmo do Strata entrar. Sobrescreve o mkForce do modulo comum.
  boot.kernelParams = lib.mkForce [ "i915.enable_psr=0" ];
}

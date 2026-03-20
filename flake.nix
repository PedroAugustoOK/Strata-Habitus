{
  description = "dotfiles do ankh";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

    outputs = { self, nixpkgs, ...}: {
      nixosConfigurations.galaxybook = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
      };
    };
  }

{
  description = "strata";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, home-manager, ... }:
  let
    lib = nixpkgs.lib;
    defaultSystem = "x86_64-linux";
    hostDirs = lib.filterAttrs (name: type:
      type == "directory"
      && builtins.pathExists (./hosts + "/${name}/meta.nix")
      && builtins.pathExists (./hosts + "/${name}/hardware.nix")
    ) (builtins.readDir ./hosts);

    mkHost = hostname:
      let
        hostMeta = import (./hosts + "/${hostname}/meta.nix");
        system = hostMeta.system or defaultSystem;
        username = hostMeta.username;
        hostConfigPath = ./hosts + "/${hostname}/config.nix";
        hmModule = {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = {
            inherit username hostname hostMeta;
          };
          home-manager.users.${username} = import ./home.nix;
        };
      in
      lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit username hostname hostMeta;
        };
        modules =
          [
            ./configuration.nix
            (./hosts + "/${hostname}/hardware.nix")
          ]
          ++ lib.optional (builtins.pathExists hostConfigPath) hostConfigPath
          ++ [
            home-manager.nixosModules.home-manager
            hmModule
          ];
      };
  in {
    nixosConfigurations = lib.genAttrs (builtins.attrNames hostDirs) mkHost;
  };
}

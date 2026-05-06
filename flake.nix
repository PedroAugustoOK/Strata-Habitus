{
  description = "strata";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    caelestia-shell = {
      url = "github:caelestia-dots/shell/54cdd80c1b7671deeb057cc554f83e436765596a";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, home-manager, caelestia-shell, ... }:
  let
    lib = nixpkgs.lib;
    defaultSystem = "x86_64-linux";
    codexOverlay = final: prev: {
      codex = final.callPackage ./pkgs/codex.nix { };
      caelestia-qml-plugin = (final.callPackage "${caelestia-shell}/nix" {
        rev = "54cdd80c1b7671deeb057cc554f83e436765596a";
        stdenv = final.clangStdenv;
        quickshell = final.quickshell;
        caelestia-cli = null;
      }).plugin;
    };
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
            {
              nixpkgs.overlays = [ codexOverlay ];
            }
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

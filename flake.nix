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
    username = "ankh";
    hostname = "nixos";
    system = "x86_64-linux";
    hmModule = {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.extraSpecialArgs = { inherit username; };
      home-manager.users.${username} = import ./home.nix;
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit username hostname; };
      modules = [
        ./configuration.nix
        ./hosts/nixos/hardware.nix
        home-manager.nixosModules.home-manager
        hmModule
      ];
    };

    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit username; hostname = "desktop"; };
      modules = [
        ./configuration.nix
        ./hosts/desktop/hardware.nix
        ./hosts/desktop/config.nix
        home-manager.nixosModules.home-manager
        hmModule
      ];
    };
  };
}

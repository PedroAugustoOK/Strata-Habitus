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
  in {
    nixosConfigurations.galaxybook = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit username hostname; };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs   = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit username; };
          home-manager.users.${username} = import ./home.nix;
        }
      ];
    };

    nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit username hostname; };
      modules = [
        ./iso.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs   = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit username; };
          home-manager.users.${username} = import ./home.nix;
        }
      ];
    };
  };
}

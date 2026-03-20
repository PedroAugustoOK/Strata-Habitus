{
  description = "dotfiles do ankh";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ags = {
  url = "github:aylur/ags";
  inputs.nixpkgs.follows = "nixpkgs";
   };
  };

  outputs = { self, nixpkgs, home-manager, stylix, ags, ... }: {
    nixosConfigurations.galaxybook = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit ags; };
      modules = [
        ./configuration.nix
        stylix.nixosModules.stylix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs    = true;
          home-manager.useUserPackages  = true;
          home-manager.extraSpecialArgs = { inherit ags; };
          home-manager.users.ankh       = import ./home.nix;
        }
      ];
    };
  };
}

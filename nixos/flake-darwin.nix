{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    lazyvim.url = "github:pfassina/lazyvim-nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, home-manager, lazyvim, ... }:
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#MacStudio-von-jian
    darwinConfigurations."MacStudio-von-jian" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs; };

      modules = [
        ./configuration.nix
        home-manager.darwinModules.default
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "bak";
            users.jian = ./home.nix; # replace <USERNAME> with your actual username
	    extraSpecialArgs = { inherit inputs lazyvim; };
          };
        }
      ];
    };
  };
}

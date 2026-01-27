{
  description = "Jian's home flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lazyvim.url = "github:pfassina/lazyvim-nix";
  };

  outputs = { self, nixpkgs, home-manager, lazyvim, ... }: {
    homeConfigurations = {
      "jian" = home-manager.lib.homeManagerConfiguration {
        # System is very important!
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        modules = [
          ./home.nix
          lazyvim.homeManagerModules.default
        ];
      };
    };
  };
}

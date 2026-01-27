{
  description = "NixOS/Home Manager configuration of jian";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    lazyvim.url = "github:pfassina/lazyvim-nix";
  };

  outputs = inputs @
    { self, nixpkgs, nixos-wsl, home-manager, flake-utils, lazyvim, ... }: 

    # Standalone Home Manager for each architecture
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      lib = pkgs.lib;
      users = [ "jian" "luoj" ];
      homeConfig = username: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          ./users/${username}/home.nix
          ./home/home.nix
          lazyvim.homeManagerModules.default
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    in
    {
      legacyPackages = {
        homeConfigurations = lib.genAttrs users homeConfig;
      };
    })

    //

    # Host configuration
    {
    nixosConfigurations = {
      "AT-L-PF5S785B" = let
        username = "luoj";
        specialArgs = { inherit username; };
      in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          modules = [
            ./hosts/thinkpad/configuration.nix
            ./users/${username}/nixos.nix
            nixos-wsl.nixosModules.wsl
        ];
      };
      machinist = let
        username = "jian";
        specialArgs = { inherit username; };
      in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          modules = [
            ./hosts/machinist/configuration.nix
            ./users/${username}/nixos.nix
            #lazyvim.homeManagerModules.default

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.extraSpecialArgs = inputs // specialArgs;
              home-manager.users.${username} = import ./users/user.nix;
            }
        ];
      };
    };
  };
}

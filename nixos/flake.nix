{
  description = "NixOS/Home Manager configuration of jian";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    lazyvim.url = "github:pfassina/lazyvim-nix";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      # add ?ref=<tag> to track a tag
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";

      # THIS IS IMPORTANT
      # Mismatched system dependencies will lead to crashes and other issues.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      flake-utils,
      nix-darwin,
      ...
    }:

    let

      # Helper to create a unified system configuration
      mkSystem =
        {
          builder,
          hmModule,
        }:
        {
          hostname,
          username,
          system,
          homeModules ? [ "console" ],
        }:
        builder {
          inherit system;

          # Pass args to modules
          specialArgs = {
            inherit inputs hostname username;
          };

          modules = [
            ./hosts/${hostname}/nixos.nix
            ./users/${username}/nixos.nix

            hmModule
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "bak";
              home-manager.extraSpecialArgs = { inherit username inputs homeModules; };
              home-manager.users.${username} = import ./users/user.nix;
            }
          ];
        };

      mkNixOS = mkSystem {
        builder = nixpkgs.lib.nixosSystem;
        hmModule = home-manager.nixosModules.home-manager;
      };

      mkNixDarwin = mkSystem {
        builder = nix-darwin.lib.darwinSystem;
        hmModule = home-manager.darwinModules.home-manager;
      };

    in

    # Standalone Home Manager for each architecture
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        homeConfig =
          { username, homeModules ? [ "console" ] }:
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            # Specify your home configuration modules here, for example,
            # the path to your home.nix.
            modules = [
              ./users/user.nix
              ./home/standalone.nix
            ];

            # Optionally use extraSpecialArgs
            # to pass through arguments to home.nix
            extraSpecialArgs = { inherit username inputs homeModules; };
          };
      in
      {
        legacyPackages = {
          homeConfigurations = {
            "jian@linux" = homeConfig {
              username = "jian";
              homeModules = [
                "console"
                "desktop"
              ];
            };
            "jian@wsl" = homeConfig {
              username = "jian";
              homeModules = [ "console" ];
            };
            "jian@darwin" = homeConfig {
              username = "jian";
              homeModules = [ "console" ];
            };
            "atjiluo" = homeConfig {
              username = "atjiluo";
              homeModules = [ "console" ];
            };
            "jianl" = homeConfig {
              username = "jianl";
              homeModules = [ "console" ];
            };
          };
        };
        checks = {
          sanity = pkgs.runCommand "sanity" { } "echo ok > $out";
        };
      }
    )
    # Host configuration
    // {
      nixosConfigurations = {
        "AT-L-PF5S785B" = mkNixOS {
          hostname = "AT-L-PF5S785B";
          username = "atjiluo";
          system = "x86_64-linux";
          homeModules = [ "console" ];
        };
        scopio = mkNixOS {
          hostname = "scopio";
          username = "jian";
          system = "x86_64-linux";
          homeModules = [ "console" "desktop" ];
        };
        rhino = mkNixOS {
          hostname = "rhino";
          username = "jian";
          system = "x86_64-linux";
          homeModules = [ "console" "desktop" ];
        };
        soyo = mkNixOS {
          hostname = "soyo";
          username = "jian";
          system = "x86_64-linux";
          homeModules = [ "console" "desktop" ];
        };
        windy = mkNixOS {
          hostname = "windy";
          username = "jianl";
          system = "x86_64-linux";
          homeModules = [ "console" ];
        };
      };
      darwinConfigurations = {
        "MacStudio-von-jian" = mkNixDarwin {
          hostname = "MacStudio-von-jian";
          username = "jian";
          system = "aarch64-darwin";
          homeModules = [ "console" ];
        };
      };
    };
}

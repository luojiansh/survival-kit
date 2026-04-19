# Top-level flake: all NixOS hosts, nix-darwin hosts, and standalone
# Home Manager configurations are wired from this single entry-point.
{
  description = "NixOS/Home Manager configuration of jian";

  inputs = {
    # --- Core inputs ---
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
    nix-homebrew.url = "github:zhaofengli/nix-homebrew"; # Homebrew management for Darwin
    lazyvim.url = "github:pfassina/lazyvim-nix"; # LazyVim Neovim distribution

    # --- Desktop shell (Linux only) ---
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell"; # add ?ref=<tag> to pin
      # Must follow our nixpkgs — ABI mismatch causes runtime crashes.
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
      nix-homebrew,
      ...
    }:

    let

      # mkSystem: two-stage curried builder.
      #   Stage 1 — pick the platform (NixOS vs Darwin) and its HM module.
      #   Stage 2 — provide per-host args (hostname, username, system, etc.).
      # This avoids duplicating the Home Manager wiring for every host.
      mkSystem =
        {
          builder, # nixpkgs.lib.nixosSystem or nix-darwin.lib.darwinSystem
          hmModule, # home-manager.nixosModules or darwinModules
        }:
        {
          hostname,
          username,
          system,
          homeModules ? [ "console" ], # selects modules from users/modules/<name>/
          extraModules ? [ ],
        }:
        builder {
          inherit system;

          # Make flake inputs and host identity available to all modules
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
              home-manager.extraSpecialArgs = {
                inherit username inputs homeModules;
              };
              home-manager.users.${username} = import ./users/user.nix;
            }
          ]
          ++ extraModules;
        };

      # Partially-applied builders for each platform
      mkNixOS = mkSystem {
        builder = nixpkgs.lib.nixosSystem;
        hmModule = home-manager.nixosModules.home-manager;
      };

      # Darwin wraps mkSystem and injects nix-homebrew automatically
      mkNixDarwin =
        {
          hostname,
          username,
          system,
          homeModules ? [ "console" ],
        }:
        mkSystem
          {
            builder = nix-darwin.lib.darwinSystem;
            hmModule = home-manager.darwinModules.home-manager;
          }
          {
            inherit
              hostname
              username
              system
              homeModules
              ;
            extraModules = [
              nix-homebrew.darwinModules.nix-homebrew
              {
                nix-homebrew = {
                  enable = true;
                  user = username;
                  autoMigrate = true;
                };
              }
            ];
          };

    in

    # Per-system outputs (standalone Home Manager + checks).
    # flake-utils generates these for every default system (x86_64-linux,
    # aarch64-linux, aarch64-darwin, …).
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        # Standalone Home Manager builder — used on machines where we
        # don't own the NixOS/Darwin system config (e.g. Ubuntu WSL).
        homeConfig =
          {
            username,
            homeModules ? [ "console" ],
          }:
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./users/user.nix
              ./home/standalone.nix # adds flake + unfree settings
            ];
            extraSpecialArgs = { inherit username inputs homeModules; };
          };
      in
      {
        legacyPackages = {
          homeConfigurations = {
            "jian" = homeConfig {
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
    # Merge fixed host outputs into the per-system set above.
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
          homeModules = [
            "console"
            "desktop"
          ];
        };
        rhino = mkNixOS {
          hostname = "rhino";
          username = "jian";
          system = "x86_64-linux";
          homeModules = [
            "console"
            "desktop"
          ];
        };
        soyo = mkNixOS {
          hostname = "soyo";
          username = "jian";
          system = "x86_64-linux";
          homeModules = [
            "console"
            "desktop"
          ];
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

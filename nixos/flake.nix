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
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-homebrew.url = "github:luojiansh/nix-homebrew";
    lazyvim.url = "github:pfassina/lazyvim-nix/v15.14.0"; # LazyVim Neovim distribution

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
      flake-parts,
      nix-darwin,
      nix-homebrew,
      ...
    }:
    let
      # Host specifications: system, user, and home modules
      linuxHosts = {
        "AT-L-PF5S785B" = {
          system = "x86_64-linux";
          username = "atjiluo";
          homeModules = [
            "console"
            "homebrew"
          ];
        };
        scopio = {
          system = "x86_64-linux";
          username = "jian";
          homeModules = [
            "console"
            "desktop"
          ];
        };
        rhino = {
          system = "x86_64-linux";
          username = "jian";
          homeModules = [
            "console"
            "desktop"
          ];
        };
        soyo = {
          system = "x86_64-linux";
          username = "jian";
          homeModules = [
            "console"
            "desktop"
          ];
        };
        windy = {
          system = "x86_64-linux";
          username = "jianl";
          homeModules = [ "console" ];
        };
      };

      darwinHosts = {
        "MacStudio-von-jian" = {
          system = "aarch64-darwin";
          username = "jian";
          homeModules = [
            "console"
            "homebrew"
          ];
        };
        "Jians-MacBook-Air" = {
          system = "aarch64-darwin";
          username = "jian";
          homeModules = [
            "console"
            "homebrew"
          ];
        };
      };

      # Standalone Home Manager user parameters.
      standaloneHomeUsers = {
        "jian" = {
          username = "jian";
          homeModules = [ "console" ];
        };
        "atjiluo" = {
          username = "atjiluo";
          homeModules = [
            "console"
            "homebrew"
          ];
        };
        "jianl" = {
          username = "jianl";
          homeModules = [ "console" ];
        };
      };

      # mkSystem: two-stage curried builder.
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

      # Platform-specific host builders.
      mkLinuxHost = mkSystem {
        builder = nixpkgs.lib.nixosSystem;
        hmModule = home-manager.nixosModules.home-manager;
      };

      mkDarwinHost = mkSystem {
        builder = nix-darwin.lib.darwinSystem;
        hmModule = home-manager.darwinModules.home-manager;
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        let
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
              extraSpecialArgs = {
                inherit username inputs homeModules;
              };
            };
        in
        {
          legacyPackages = {
            homeConfigurations = nixpkgs.lib.mapAttrs (_: cfg: homeConfig cfg) standaloneHomeUsers;
          };

          checks = {
            sanity = pkgs.runCommand "sanity" { } "echo ok > $out";
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              git
              nixfmt
              nil
              statix
              deadnix
            ];
          };
        };

      flake = {
        # NixOS hosts
        nixosConfigurations = nixpkgs.lib.mapAttrs (
          hostname: cfg: mkLinuxHost (cfg // { inherit hostname; })
        ) linuxHosts;

        # Darwin hosts
        darwinConfigurations = nixpkgs.lib.mapAttrs (
          hostname: cfg: mkDarwinHost (cfg // { inherit hostname; })
        ) darwinHosts;
      };
    };
}

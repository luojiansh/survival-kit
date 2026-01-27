{
  description = "NixOS/Home Manager configuration of jian";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
      ...
    }:

    let

      # Helper to create a host configuration
      mkHost =
        {
          hostname,
          username,
          system,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;

          # Pass args to modules
          specialArgs = {
            inherit inputs;
            inherit hostname;
            inherit username;
          };

          modules = [
            ./hosts/${hostname}/nixos.nix
            ./users/${username}/nixos.nix

          #   home-manager.nixosModules.home-manager
          #   {
          #     home-manager.useGlobalPkgs = true;
          #     home-manager.useUserPackages = true;
          #     home-manager.backupFileExtension = "bak";
          #
          #     home-manager.extraSpecialArgs = { inherit username inputs; };
          #     home-manager.users.${username} = import ./users/user.nix;
          #   }
          ];
        };

    in

    # Standalone Home Manager for each architecture
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        users = [
          "jian"  # Linux user
          "jianl" # WSL user
          "luoj"  # Company laptop user
        ];
        homeConfig =
          username:
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
            extraSpecialArgs = { inherit username inputs; };
          };
      in
      {
        legacyPackages = {
          homeConfigurations = lib.genAttrs users homeConfig;
        };
        checks = {
          sanity = pkgs.runCommand "sanity" { } "echo ok > $out";
        };
      }
    )
      # Host configuration
    // {
      nixosConfigurations = {
        "AT-L-PF5S785B" = mkHost {
          hostname = "AT-L-PF5S785B";
          username = "luoj";
          system = "x86_64-linux";
        };
        scopio = mkHost {
          hostname = "scopio";
          username = "jian";
          system = "x86_64-linux";
        };
        rhino = mkHost {
          hostname = "rhino";
          username = "jian";
          system = "x86_64-linux";
        };
        soyo = mkHost {
          hostname = "soyo";
          username = "jian";
          system = "x86_64-linux";
        };
        windy = mkHost {
          hostname = "windy";
          username = "jianl";
          system = "x86_64-linux";
        };
      };
    };
}

# in configuration.nix
{
  pkgs,
  lib,
  inputs,
  ...
}:
# inputs.self, inputs.nix-darwin, and inputs.nixpkgs can be accessed here
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    nixfmt
  ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = "jian";

  # Global Configuration
  #  programs.neovim = {
  #    enable = true;
  #    defaultEditor = true;
  #    viAlias = true;
  #    vimAlias = true;
  #    plugins = with pkgs; [
  #      vimPlugins.nvim-treesitter.withAllGrammars
  #      #vimPlugins.opencode-nvim
  #    ];
  #    extraPackages = with pkgs; [
  #      tree-sitter
  #      lua-language-server
  #    ];
  #  };
}

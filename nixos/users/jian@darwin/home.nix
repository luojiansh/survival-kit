# in configuration.nix
{
  pkgs,
  lib,
  inputs,
  lazyvim,
  ...
}:
# inputs.self, inputs.nix-darwin, and inputs.nixpkgs can be accessed here
{
  imports = [ lazyvim.homeManagerModules.default ];

  home.username = "jian";
  home.stateVersion = "25.11";
  home.packages = with pkgs; [
    fzf
    fd
  ];
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    #    plugins = with pkgs; [
    #      vimPlugins.nvim-treesitter.withAllGrammars
    #      #vimPlugins.opencode-nvim
    #    ];
    #    extraPackages = with pkgs; [
    #      tree-sitter
    #      lua-language-server
    #    ];
  };
  programs.lazyvim = {
    enable = true;

    # Core LazyVim dependencies (git, ripgrep, fd, etc.)
    installCoreDependencies = true; # default: true

    extras = {
      lang.nix.enable = true;
      lang.python = {
        enable = true;
        installDependencies = true; # Install ruff
        installRuntimeDependencies = true; # Install python3
      };
      lang.go = {
        enable = true;
        installDependencies = true; # Install gopls, gofumpt, etc.
        installRuntimeDependencies = true; # Install go compiler
      };
    };

    # Additional packages (optional)
    extraPackages = with pkgs; [
      nixd # Nix LSP
      alejandra # Nix formatter
    ];

    # Only needed for languages not covered by LazyVim extras
    treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
      wgsl # WebGPU Shading Language
      templ # Go templ files
    ];
  };
}

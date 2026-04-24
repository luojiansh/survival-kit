# Console module — shared terminal environment for all platforms.
# Provides: Neovim + LazyVim, git, gh, shell config, and dev tooling.
{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.lazyvim.homeManagerModules.default
  ];

  home.packages =
    with pkgs;
    [
      git
      lazygit
      gcc
      fzf
      ripgrep
      fd
      gh
      python314Packages.uv
      nodejs
      nixfmt
      rustup
    ]
    ++ (pkgs.lib.optional pkgs.stdenv.isLinux wl-clipboard); # Wayland clipboard (Linux only)

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.home-manager.enable = true;

  # Source distro-provided rc files if they exist (e.g. on Ubuntu WSL).
  # Home Manager moves ~/.bashrc aside; this re-includes the original.
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      if [ -f ~/.bashrc.dist ]; then
          . ~/.bashrc.dist
      fi
    '';
    profileExtra = ''
      if [ -f ~/.profile.dist ]; then
          . ~/.profile.dist
      fi
    '';
  };

  programs.readline = {
    enable = true;
    bindings = {
      "\\C-H" = "backward-kill-word"; # Ctrl+Backspace deletes previous word
    };
    variables = {
      editing-mode = "vi";
    };
  };

  programs.git = {
    enable = true;
  };

  # GitHub CLI with credential helper for HTTPS clones
  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
      hosts = [
        "https://github.com"
        "https://gist.github.com"
      ];
    };
  };

  # Neovim: system-level config (plugins are managed by LazyVim below)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    extraPackages = with pkgs; [
      tree-sitter
      lua-language-server
    ];
  };

  # LazyVim distribution — language extras are toggled here
  programs.lazyvim = {
    enable = true;
    installCoreDependencies = true;
    extras = {
      lang.nix.enable = true;
      lang.python = {
        enable = true;
        installDependencies = true;
        installRuntimeDependencies = true;
      };
      lang.go = {
        enable = true;
        installDependencies = true;
        installRuntimeDependencies = true;
      };
    };
    extraPackages = with pkgs; [
      nixd # Nix LSP
      alejandra # alternative Nix formatter used by nixd
    ];
    treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
      wgsl
      templ
    ];
  };

  # direnv for project-specific environment variables
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.zellij.enable = true;
}

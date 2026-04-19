{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.lazyvim.homeManagerModules.default
  ];

  home.packages = with pkgs; [
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
  ] ++ (pkgs.lib.optional pkgs.stdenv.isLinux wl-clipboard);

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.home-manager.enable = true;

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
      "\\C-H" = "backward-kill-word";
    };
    variables = {
      editing-mode = "vi";
    };
  };

  programs.git = {
    enable = true;
  };

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
      nixd
      alejandra
    ];
    treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
      wgsl
      templ
    ];
  };
}

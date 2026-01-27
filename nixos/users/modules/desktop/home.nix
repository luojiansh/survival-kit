{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.noctalia.homeModules.default
    ./noctalia.nix
  ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    # Niri
    xwayland-satellite # xwayland support

    # Quickshell
    # inputs.quickshell.packages.${stdenv.targetPlatform.system}.default
    # brightnessctl
    #xdg-desktop-portal-hyprland
    #ddcutil

    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.symbols-only
    nerd-fonts.sauce-code-pro
    nerd-fonts.caskaydia-mono
    nerd-fonts.blex-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.ubuntu
    nerd-fonts.go-mono
    nerd-fonts.monaspace
    nerd-fonts.caskaydia-cove
    nerd-fonts.intone-mono
    nerd-fonts.open-dyslexic
    nerd-fonts.noto
    nerd-fonts.hack

    google-chrome

  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/jian/etc/profile.d/hm-session-vars.sh
  #
  # Niri
  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs.quickshell = {
    enable = true;
  };

  programs.noctalia-shell = {
    enable = true;
  };

  programs.cava = {
    enable = true;
  };

  programs.ghostty = {
    enable = true;
    settings = {
      background-opacity = 0.9;
      alpha-blending = "native"; # (or linear-corrected)
    };
  };

  services.cliphist = {
    enable = true;
  };

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300; # 5 minutes of inactivity
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors"; # Turn off monitors
      }
      {
        timeout = 600; # 10 minutes of inactivity
        command = "${
          inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
        }/bin/noctalia-shell ipc call lockScreen lock"; # Lock the screen
      }
    ];
  };

  programs.fuzzel = {
    enable = true;
  };
  programs.distrobox = {
    enable = true;
  };
  # services.wlsunset = {
  #   enable = true;
  #   sunrise = "06:00";
  #   sunset = "18:00";
  # };

  fonts.fontconfig.enable = true;
}

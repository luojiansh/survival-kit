# Desktop module — Wayland desktop environment for Linux hosts.
# Stack: Niri (compositor) + Noctalia Shell (bar/panels) + Quickshell.
# Only imported on hosts with homeModules = [ "console" "desktop" ].
{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.noctalia.homeModules.default
    ./noctalia.nix # Noctalia Shell settings (UI preferences)
  ];

  # Fonts: Nerd Fonts for terminal/editor glyphs + Noto for broad Unicode
  home.packages = with pkgs; [
    xwayland-satellite # bridges X11 apps into the Niri Wayland session
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
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # Niri compositor config (managed as a static file)
  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs.quickshell.enable = true;
  programs.noctalia.enable = true;
  programs.cava.enable = true; # audio visualiser

  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 0.9; # slight transparency for the terminal
    };
  };

  services.cliphist.enable = true; # clipboard history manager

  # Idle behaviour: dim monitors after 5 min, lock screen after 10 min
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
      }
      {
        timeout = 600;
        command = "${
          inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
        }/bin/noctalia msg session lock";
      }
    ];
  };

  programs.fuzzel.enable = true; # Wayland app launcher
  programs.distrobox.enable = true; # run other distros in containers

  fonts.fontconfig.enable = true;
}

{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.noctalia.homeModules.default
    ./noctalia.nix
  ];

  home.packages = with pkgs; [
    xwayland-satellite
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

  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  programs.quickshell.enable = true;
  programs.noctalia-shell.enable = true;
  programs.cava.enable = true;

  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 0.9;
    };
  };

  services.cliphist.enable = true;

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
      }
      {
        timeout = 600;
        command = "${inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/noctalia-shell ipc call lockScreen lock";
      }
    ];
  };

  programs.fuzzel.enable = true;
  programs.distrobox.enable = true;

  fonts.fontconfig.enable = true;
}

{
  config,
  pkgs,
  hostname,
  ...
}:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = nixpkgs.lib.mkForce true;

  services.envfs.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        ControllerMode = "dual";
        FastConnectable = "true";
        Experimental = "true";
      };
      Policy = {
        AutoEnable = "true";
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    niri
    google-chrome
  ];

  fonts.packages = with pkgs; [
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
  ];

  # Niri
  programs.niri.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}

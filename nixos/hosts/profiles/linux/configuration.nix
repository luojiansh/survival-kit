{
  config,
  pkgs,
  hostname,
  ...
}:

{
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

  # Niri
  programs.niri.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.gpu-screen-recorder = {
    enable = true;
  };

}

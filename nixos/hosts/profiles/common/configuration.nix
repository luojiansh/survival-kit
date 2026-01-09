{
  config,
  pkgs,
  hostname,
  ...
}:

{
  networking.hostName = pkgs.lib.mkForce "${hostname}"; # Define your hostname.

  #services.envfs.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    neovim
    python313
  ];

  # Global Configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Enable flake
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}

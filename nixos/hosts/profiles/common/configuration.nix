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

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      ## Put here any library that is required when running a package
      ## ...
      ## Uncomment if you want to use the libraries provided by default in the steam distribution
      ## but this is quite far from being exhaustive
      ## https://github.com/NixOS/nixpkgs/issues/354513
      # (pkgs.runCommand "steamrun-lib" {} "mkdir $out; ln -s ${pkgs.steam-run.fhsenv}/usr/lib64 $out/lib")
    ];
  };
}

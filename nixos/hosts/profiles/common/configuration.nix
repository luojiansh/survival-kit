{
  config,
  pkgs,
  username,
  hostname,
  ...
}:

{
  networking.hostName = pkgs.lib.mkForce "${hostname}"; # Define your hostname.
  # Allow unfree packages
  nixpkgs.config.allowUnfree = pkgs.lib.mkForce true;

  environment.systemPackages = with pkgs; [
    wget
    neovim
    python314
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
    ];
  };

  services.dbus.implementation = "broker";
  users.groups.${username}.gid = 1000;
  users.users.${username}.group = "${username}";

  programs.htop.enable = true;

}

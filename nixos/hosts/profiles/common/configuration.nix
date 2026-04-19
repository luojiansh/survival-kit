# Common profile — settings shared by every NixOS and Darwin host.
# Imported by each host's nixos.nix via ../profiles/common/configuration.nix.
{
  config,
  pkgs,
  username,
  hostname,
  ...
}:

{
  # mkForce: host-specific nixos.nix may set a different hostname;
  # this guarantees the flake-provided value always wins.
  networking.hostName = pkgs.lib.mkForce "${hostname}";
  nixpkgs.config.allowUnfree = pkgs.lib.mkForce true;

  # Base packages available system-wide on every host
  environment.systemPackages = with pkgs; [
    wget
    neovim
    python314
  ];

  # System-wide Neovim as default editor (user-level config is in console module)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Flakes are required for this repo's workflow
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # nix-ld: run unpatched Linux binaries (e.g. VS Code remote server)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
    ];
  };

  # dbus-broker is faster and more secure than the classic dbus-daemon
  services.dbus.implementation = "broker";

  # Convention: primary user always gets GID/UID 1000
  users.groups.${username}.gid = 1000;
  users.users.${username}.group = "${username}";

  programs.htop.enable = true;

}

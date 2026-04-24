# Homebrew Home Manager module — manages Homebrew via nix-homebrew.
{ pkgs, inputs, ... }:
{
  imports = [
    inputs.nix-homebrew.homeManagerModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    autoMigrate = true;
  };

  home.sessionPath = pkgs.lib.optionals pkgs.stdenv.isDarwin [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];
}

# Standalone Home Manager defaults — applied when HM is used
# outside of a NixOS/Darwin system configuration (e.g. on Ubuntu WSL).
# Enables flakes and unfree packages at the user level since there
# is no system-level NixOS config to provide them.
{ config, pkgs, ... }:
{
  nix = {
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
  nixpkgs.config.allowUnfree = true;
}

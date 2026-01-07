{ pkgs, username, ... }:
{
  imports = [
    ./${username}/home.nix
  ];
  nixpkgs.config.allowUnfree = pkgs.lib.mkForce true;
}

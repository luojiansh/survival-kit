{ config, pkgs, ... }:
{
  imports = [
    ./common.nix
  ];
 
  nix = {
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
}

{ pkgs, username, homeModules ? [ "console" ], ... }:
{
  imports = [
    ./${username}/home.nix
  ] ++ (builtins.map (m: ./modules/${m}/home.nix) homeModules);
}

# Dynamic Home Manager entrypoint — imported once per user.
# Pulls in the user's personal home.nix and then each module listed
# in homeModules (e.g. [ "console" "desktop" ] → modules/console/home.nix
# + modules/desktop/home.nix).
{
  pkgs,
  username,
  homeModules ? [ "console" ],
  ...
}:
{
  imports = [
    ./${username}/home.nix
  ]
  ++ (builtins.map (m: ./modules/${m}/home.nix) homeModules);
}

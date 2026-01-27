{ lazyvim, username, noctalia, ... }:

{
  imports = [
    noctalia.homeModules.default
    lazyvim.homeManagerModules.default
    ./${username}/home.nix
  ];
}

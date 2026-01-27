{ lazyvim, username, ... }:

{
  imports = [
    lazyvim.homeManagerModules.default
    ./${username}/home.nix
  ];
}

{ username, ... }:
{
  imports = [
    ./${username}/home.nix
    ./common/home/home.nix
  ];
}

{ hostname, ... }:

{
  imports = [
    ./${hostname}/configuration.nix
    ./common/configuration.nix
  ];
}

# MacStudio-von-jian — macOS host managed by nix-darwin.
# No shared profiles are imported here because Darwin doesn't use
# the NixOS module system; all common tooling lives in Home Manager.
{
  imports = [
    ./configuration.nix
  ];
}

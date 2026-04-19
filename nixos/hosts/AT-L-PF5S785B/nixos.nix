# AT-L-PF5S785B — company WSL laptop.
# Composes: common + WSL + virtualization profiles, plus host-specific config.
{
  imports = [
    ./configuration.nix
    ../profiles/common/configuration.nix
    ../profiles/wsl/configuration.nix
    ../profiles/virtualization/configuration.nix
  ];
}

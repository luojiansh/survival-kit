# windy — personal WSL instance (no virtualization, no certs needed).
# Composes: common + WSL profiles, plus host-specific config.
{
  imports = [
    ./configuration.nix
    ../profiles/common/configuration.nix
    ../profiles/wsl/configuration.nix
  ];
}

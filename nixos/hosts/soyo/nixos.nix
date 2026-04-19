# soyo — desktop workstation (no virtualization profile).
# Composes: common + linux profiles, plus host-specific config.
{
  imports = [
    ./configuration.nix
    ../profiles/common/configuration.nix
    ../profiles/linux/configuration.nix
  ];
}

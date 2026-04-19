# windy host-specific configuration — personal WSL, no corporate proxy.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Pin to the NixOS release used at first install.
  system.stateVersion = "25.11";
}

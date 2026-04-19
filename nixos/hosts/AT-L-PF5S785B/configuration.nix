# AT-L-PF5S785B host-specific configuration.
# This WSL machine sits behind a corporate proxy, so we inject
# the company CA bundle to make TLS verification work for Nix.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Pin to the NixOS release used at first install.
  system.stateVersion = "25.11";

  # Corporate CA bundle — allows Nix fetches through the MITM proxy.
  security.pki.certificateFiles = [
    ./ca-certificates.crt
  ];
}

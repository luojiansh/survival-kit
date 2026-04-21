# WSL profile — enables NixOS-WSL integration.
# Sets the default WSL user to match the flake's username.
# Docs: https://github.com/nix-community/NixOS-WSL
{
  username,
  inputs,
  ...
}:

{
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];
  # --- System services ---
  services.envfs.enable = true;
  wsl.enable = true;
  wsl.defaultUser = "${username}";
}

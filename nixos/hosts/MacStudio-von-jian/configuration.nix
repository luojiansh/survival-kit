# MacStudio-von-jian — nix-darwin system configuration.
{
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # System-wide packages (most tooling is in Home Manager's console module)
  environment.systemPackages = with pkgs; [
    nixfmt
  ];

  # Flakes are required for this repo's workflow
  nix.settings.experimental-features = "nix-command flakes";

  # Track the current flake revision for `darwin-version`
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Pin to the nix-darwin state version at first install.
  # Run `darwin-rebuild changelog` before bumping.
  system.stateVersion = 6;

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Required by nix-darwin for user-level service management
  system.primaryUser = "jian";
}

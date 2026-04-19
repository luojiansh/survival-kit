# scopio host-specific configuration — LUKS-encrypted root.
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Unlock the LUKS partition at boot
  boot.initrd.luks.devices."luks-568d8056-acf9-4073-aaa3-bd7e654a1180".device =
    "/dev/disk/by-uuid/568d8056-acf9-4073-aaa3-bd7e654a1180";
}

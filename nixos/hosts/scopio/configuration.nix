{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  boot.initrd.luks.devices."luks-568d8056-acf9-4073-aaa3-bd7e654a1180".device =
    "/dev/disk/by-uuid/568d8056-acf9-4073-aaa3-bd7e654a1180";
}

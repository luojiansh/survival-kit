{
  pkgs,
  username,
  ...
}:

{
  # Docker
  virtualisation.docker.enable = true;
  users.users.${username}.extraGroups = [ "docker" ];

  # Kind
  environment.systemPackages = with pkgs; [
    kind
    kubectl
  ];
}

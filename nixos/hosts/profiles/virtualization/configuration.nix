# Virtualization profile — adds Docker and Kubernetes tooling.
# Imported by hosts that need container workloads.
{
  pkgs,
  username,
  ...
}:

{
  virtualisation.docker.enable = true;
  users.users.${username}.extraGroups = [ "docker" ];

  # kind: local Kubernetes clusters inside Docker containers
  environment.systemPackages = with pkgs; [
    kind
    kubectl
  ];
}

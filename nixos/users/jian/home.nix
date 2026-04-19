# Per-user config: jian (personal accounts, cross-platform).
{ pkgs, ... }:
{
  home.username = "jian";
  # mkForce: on NixOS the system sets homeDirectory; override it here
  # so standalone HM and Darwin also get the right path.
  home.homeDirectory = pkgs.lib.mkForce (
    if pkgs.stdenv.isDarwin then "/Users/jian" else "/home/jian"
  );

  programs.git = {
    settings = {
      user = {
        name = "Jian Luo";
        email = "jian.luo.cn@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };

  # Pin to the Home Manager release at first install.
  home.stateVersion = "25.11";
}

{ pkgs, ... }:

{
  imports = [
    ../../home/common.nix
  ];
  
  home.username = "luoj";
  home.homeDirectory = "luoj";

  # Git account
  programs.git.settings = {
    user = {
      name = "Jian Luo";
      email = "jian.luo@at.abb.com";
    };
  };
}

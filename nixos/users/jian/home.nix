{
  imports = [
    ../../home/common.nix
  ];
 
  home.username = "jian";
  home.homeDirectory = "/home/jian";

  # Git account
  programs.git.settings = {
    user = {
      name = "Jian Luo";
      email = "jian.luo.cn@gmail.com";
    };
  };
}

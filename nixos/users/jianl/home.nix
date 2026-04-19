# Per-user config: jianl (personal account, WSL only).
{
  home.username = "jianl";
  home.homeDirectory = "/home/jianl";

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

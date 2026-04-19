# Per-user config: atjiluo (company account, WSL only).
{
  home.username = "atjiluo";
  home.homeDirectory = "/home/atjiluo";

  programs.git = {
    settings = {
      user = {
        name = "Jian Luo";
        email = "jian.luo@at.abb.com";
      };
      init.defaultBranch = "main";
    };
  };

  # Pin to the Home Manager release at first install.
  home.stateVersion = "25.11";
}

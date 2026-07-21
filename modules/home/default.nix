{ localConfig, ... }:

{
  imports = [
    ./packages.nix
    ./filen-menubar.nix
    ./fish.nix
    ./git.nix
    ./gpg.nix
    ./ssh.nix
    ./otty.nix
    ./zed.nix
    ./directories.nix
    ./tmux.nix
    ./topgrade.nix
  ];

  # Home Manager state version
  home.stateVersion = "24.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Home directory
  home.username = localConfig.username;
  home.homeDirectory = localConfig.homeDirectory;

  # Environment variables
  home.sessionVariables = {
    EDITOR = "zed --wait";
    VISUAL = "zed --wait";
    TERMINAL = "otty";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # XDG directories
  xdg.enable = true;
}

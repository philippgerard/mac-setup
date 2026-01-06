{ config, pkgs, ... }:

{
  imports = [
    ./packages.nix
    ./fish.nix
    ./git.nix
    ./ghostty.nix
    ./tmux.nix
    ./topgrade.nix
  ];

  # Home Manager state version
  home.stateVersion = "24.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Home directory
  home.username = "philippgerard";
  home.homeDirectory = "/Users/philippgerard";

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nano";
    VISUAL = "zed";
    TERMINAL = "ghostty";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };

  # XDG directories
  xdg.enable = true;
}

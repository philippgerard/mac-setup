{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Shell and core utilities
    coreutils
    ripgrep
    eza
    bat
    fzf
    delta
    htop
    jq
    unzip
    curl
    wget

    # Security, maintenance, and repository validation
    actionlint
    _1password-cli
    gitleaks
    gnupg
    pinentry_mac
    shellcheck
    terminal-notifier
    topgrade
  ];
}

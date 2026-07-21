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

    # Development
    claude-code
    biome
    cocoapods
    fastlane
    ffmpeg
    gh
    git-lfs
    go
    imagemagick
    mkcert
    mosh
    pandoc
    pnpm
    fnm
    sentry-cli
    tea
    uv
    watchman
    xcbeautify
    xcodegen

    # Security, maintenance, and repository validation
    gnupg
    pinentry_mac
    shellcheck
    terminal-notifier
    topgrade
  ];
}

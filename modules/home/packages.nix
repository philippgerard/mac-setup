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
    # Keep the BEAM pair explicit so Mix worktrees get the tested OTP release.
    beam.interpreters.erlang_29
    beam.packages.erlang_29.elixir_1_20
    biome
    cargo
    claude-code
    clippy
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
    rust-analyzer
    rustc
    rustfmt
    sentry-cli
    tea
    uv
    watchman
    xcbeautify
    xcodegen

    # Security, maintenance, and repository validation
    _1password-cli
    gitleaks
    gnupg
    pinentry_mac
    shellcheck
    terminal-notifier
    topgrade
  ];
}

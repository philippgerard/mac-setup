{ pkgs, ... }:

{
  imports = [
    ./oh-my-claudecode.nix
    ./zed.nix
  ];

  home.sessionVariables = {
    EDITOR = "zed --wait";
    VISUAL = "zed --wait";
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      prompt = "enabled";
    };
  };

  home.packages = with pkgs; [
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
  ];
}

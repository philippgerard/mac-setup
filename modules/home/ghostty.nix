{ config, pkgs, ... }:

{
  # Ghostty terminal configuration
  # https://ghostty.org/docs/config
  home.file.".config/ghostty/config".text = ''
    # Ghostty Configuration
    # https://ghostty.org/docs/config

    term = xterm-256color
    theme = dark:0x96f,light:Apple System Colors Light
    font-family = FiraCode Nerd Font Mono Reg
    background-opacity = .95
    shell-integration = detect
    macos-titlebar-style = tabs
    macos-icon = xray
    keybind = shift+enter=text:\x1b\r
  '';
}

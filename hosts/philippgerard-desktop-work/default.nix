{ config, pkgs, hostname, ... }:

{
  # Work Desktop configuration

  networking.hostName = hostname;
  networking.computerName = hostname;

  # Work desktop-specific casks (in addition to shared ones)
  homebrew.casks = [
    "cursor"
    "microsoft-teams"
    "slack"
  ];

  # Desktop-specific system settings
  system.defaults = {
    dock = {
      # Example: larger icons on external monitor
      # tilesize = 64;
    };
  };
}

{ config, pkgs, hostname, ... }:

{
  # Personal Desktop configuration

  networking.hostName = hostname;
  networking.computerName = hostname;

  # Desktop-specific casks (in addition to shared ones)
  homebrew.casks = [
    # Add personal desktop-only apps here, e.g.:
    # "steam"
    # "nvidia-geforce-now"
  ];

  # Desktop-specific system settings
  system.defaults = {
    dock = {
      # Example: larger icons on external monitor
      # tilesize = 64;
    };
  };
}

{ config, pkgs, hostname, ... }:

{
  # Work Laptop configuration

  networking.hostName = hostname;
  networking.computerName = hostname;

  # Work laptop-specific casks (in addition to shared ones)
  homebrew.casks = [
    # Add work laptop-only apps here, e.g.:
    # "microsoft-teams"
    # "citrix-workspace"
  ];

  # Laptop-specific system settings
  system.defaults = {
    dock = {
      # Smaller dock icons for laptop screen
      # tilesize = 36;
    };

    trackpad = {
      ActuationStrength = 0; # Silent clicking
    };
  };
}

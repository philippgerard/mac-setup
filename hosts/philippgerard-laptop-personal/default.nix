{ config, pkgs, hostname, ... }:

{
  # Personal Laptop configuration

  networking.hostName = hostname;
  networking.computerName = hostname;

  # Laptop-specific casks (in addition to shared ones)
  homebrew.casks = [
    "nvidia-geforce-now"
    "steam"
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

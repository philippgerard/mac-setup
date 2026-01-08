{ config, pkgs, hostname, ... }:

{
  # Personal Desktop configuration

  networking.hostName = hostname;
  networking.computerName = hostname;

  # Desktop-specific casks (in addition to shared ones)
  homebrew.casks = [
    "nvidia-geforce-now"
    "steam"
  ];

  # Desktop-specific system settings
  system.defaults = {
    dock = {
      # Example: larger icons on external monitor
      # tilesize = 64;
    };

    # Hide WiFi from menu bar on desktops (wired connection)
    CustomUserPreferences = {
      "com.apple.controlcenter" = {
        "NSStatusItem Visible WiFi" = false;
      };
    };
  };
}

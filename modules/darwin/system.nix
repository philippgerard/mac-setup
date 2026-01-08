{ config, pkgs, ... }:

{
  # macOS system preferences
  system.defaults = {
    # Dock settings
    dock = {
      autohide = false;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.2;
      expose-animation-duration = 0.2;
      tilesize = 52;
      static-only = false;
      show-recents = false;
      show-process-indicators = true;
      orientation = "bottom";
    };

    # Finder settings
    finder = {
      AppleShowAllFiles = false;
      FXPreferredViewStyle = "Nlsv"; # List view
    };

    # Global settings
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      AppleInterfaceStyle = "Dark";

      # Keyboard
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      ApplePressAndHoldEnabled = false;

      # Mouse/Trackpad
      "com.apple.mouse.tapBehavior" = 1;
      "com.apple.swipescrolldirection" = true;

      # Window behavior
      NSAutomaticWindowAnimationsEnabled = false;
      NSWindowResizeTime = 0.001;

      # Disable auto-correct annoyances
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };

    # Trackpad
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = false;
    };

    # Login window
    loginwindow = {
      GuestEnabled = false;
      DisableConsoleAccess = true;
    };

    # Screensaver
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };

    # Menu bar
    menuExtraClock = {
      ShowDate = 2;
      ShowDayOfWeek = true;
    };

    # Spaces
    spaces.spans-displays = false;

    # Custom user preferences
    CustomUserPreferences = {
      # Prevent Photos from opening when devices are connected
      "com.apple.ImageCapture" = {
        disableHotPlug = true;
      };
      # Expand save panel by default
      NSGlobalDomain = {
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
      };
      # Hide system clock from menu bar (using Dato instead)
      "com.apple.controlcenter" = {
        "NSStatusItem Visible Clock" = false;
      };
    };
  };

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Keyboard settings
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = false;
  };
}

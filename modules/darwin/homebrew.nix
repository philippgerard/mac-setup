{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;

    # Behavior on activation
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Zap: removes all casks not listed here
      cleanup = "zap";
    };

    # Homebrew taps
    taps = [
      "homebrew/services"
    ];

    # CLI tools from Homebrew (when not available in nixpkgs or need Homebrew integration)
    brews = [
      "mas" # Mac App Store CLI (required for masApps)

      # Ruby (chruby + ruby-install for version management)
      # "chruby"
      # "chruby-fish"
      # "ruby-install"

      # PHP
      # "composer"
      # "php"

      # Languages & Runtimes
      # "go"

      # Git
      # "git-lfs"

      # Dev Tools
      # "mailpit"        # Local email testing
      # "mole"           # System cleanup tool
      # "tidy-html5"     # HTML formatter
      # "yamllint"       # YAML linter

      # Other
      # "pinentry-mac"   # GPG pin entry
    ];

    # GUI applications via Homebrew Cask
    casks = [
      # Essential
      "1password"
      "1password-cli"
      "raycast"

      # Fonts
      "font-fira-code-nerd-font"

      # Browsers
      "google-chrome"

      # Development
      "cyberduck"
      "figma"
      "ghostty"
      "orbstack"
      "tableplus"
      "tower"
      "zed"

      # AI
      "aqua-voice"
      "claude"

      # Communication
      "beeper"
      "notion"
      "zoom"

      # Microsoft Office
      "microsoft-office"
      "microsoft-auto-update"

      # Utilities
      "adguard"
      "appcleaner"
      "choosy"
      "jordanbaird-ice"
      "kap"
      "latest"
      "netnewswire"
      "replacicon"
      "shottr"
      "spamsieve"
      "timemachinestatus"

      # Hardware
      "monitorcontrol"

      # Media
      "spotify"

      # Network
      "tailscale"
    ];

    # Mac App Store applications
    # Get app IDs with: mas search <app name>
    # Or from the App Store URL: https://apps.apple.com/app/id<APP_ID>
    masApps = {

      # Browser Extensions
      "1Password for Safari" = 1569813296;
      "Kagi for Safari" = 1622835804;
      "StopTheMadness Pro" = 6471380298;

      # Utilities
      "Battery Indicator" = 1206020918;
      "Command X" = 6448461551;
      "Dato" = 1470584107;
      "Folder Preview" = 6698876601;
      "HacKit" = 1549557075;
      "Little Snitch Mini" = 1629008763;
      "Lungo" = 1263070803;
      "pullBar" = 1601913905;

      # Media
      "Infuse" = 1136220934;

      # Development
      #"TestFlight" = 899247664;
      #"Xcode" = 497799835;
    };
  };
}

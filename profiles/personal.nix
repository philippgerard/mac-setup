{ localConfig, ... }:

{
  home-manager.users.${localConfig.username}.imports = [
    ../modules/home/filen-menubar.nix
  ];

  # Only this cask is trusted; other code in the tap is not authorized.
  homebrew.taps = [{ name = "philippgerard/tap"; trusted = false; }];
  homebrew.casks = [
    { name = "philippgerard/tap/filen-menubar"; trusted = true; }
    "beeper"
    "imageoptim"
    "netnewswire"
    "spotify"
  ];

  homebrew.masApps = {
    "Consent-O-Matic" = 1606897889;
    "Infuse" = 1136220934;
    "Keka" = 470158793;
    "Kindle" = 302584613;
    "PDFScanner" = 410968114;
  };
}

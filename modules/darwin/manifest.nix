{ config, lib, localConfig, ... }:

let
  home = config.home-manager.users.${localConfig.username};
  packageNames = map lib.getName home.home.packages;
in
{
  # Public generation metadata supports previews and read-only diagnostics.
  environment.etc."mac-setup/Brewfile".text = config.homebrew.brewfile;
  environment.etc."mac-setup/manifest.json".text = builtins.toJSON {
    schema = 1;
    development = home.programs.gh.enable;
    filen = builtins.elem "filen-menubar" packageNames;
    casks = map (cask: cask.name) config.homebrew.casks;
    brews = map (brew: brew.name) config.homebrew.brews;
    masApps = config.homebrew.masApps;
  };
}

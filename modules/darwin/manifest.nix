{ config, localConfig, ... }:

let
  home = config.home-manager.users.${localConfig.username};
  caskNames = map (cask: cask.name) config.homebrew.casks;
in
{
  # Public generation metadata supports previews and read-only diagnostics.
  environment.etc."mac-setup/Brewfile".text = config.homebrew.brewfile;
  environment.etc."mac-setup/manifest.json".text = builtins.toJSON {
    schema = 1;
    development = home.programs.gh.enable;
    filen = (home.launchd.agents.filen-menubar.enable or false) &&
      builtins.elem "philippgerard/tap/filen-menubar" caskNames;
    casks = caskNames;
    brews = map (brew: brew.name) config.homebrew.brews;
    masApps = config.homebrew.masApps;
  };
}

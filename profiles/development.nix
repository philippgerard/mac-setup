{ localConfig, ... }:

{
  home-manager.users.${localConfig.username}.imports = [
    ../modules/home/development.nix
  ];

  homebrew.casks = [
    "aqua-voice"
    "chatgpt"
    "claude"
    "codex"
    "orbstack"
    "zed"
  ];

  homebrew.masApps = {
    "TestFlight" = 899247664;
  };
}

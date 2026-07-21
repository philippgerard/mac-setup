{ localConfig, ... }:

{
  imports = [
    ../../profiles/base.nix
    ../../profiles/development.nix
    ../../profiles/desktop.nix
    ../../profiles/personal.nix
    ../../profiles/work.nix
    ../../profiles/gaming.nix
  ];

  networking.hostName = localConfig.hostName;
  networking.computerName = localConfig.hostName;
}

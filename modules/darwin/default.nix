{ localConfig, pkgs, ... }:

{
  imports = [
    ./fish.nix
    ./nix.nix
    ./system.nix
    ./homebrew.nix
    ./manifest.nix
  ];

  system.primaryUser = localConfig.username;
  system.stateVersion = 5;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages available to all users
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    duti  # Set default applications for file types
  ];

}

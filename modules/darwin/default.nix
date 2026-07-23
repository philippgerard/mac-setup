{ localConfig, pkgs, ... }:

{
  imports = [
    ./fish.nix
    ./nix.nix
    ./rosetta.nix
    ./system.nix
    ./homebrew.nix
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

  # Otty is the chosen terminal and script handler.
  system.activationScripts.postActivation.text = ''
    echo "Setting Otty as the default terminal for scripts..."
    ${pkgs.duti}/bin/duti -s io.appmakes.otty public.shell-script all
    ${pkgs.duti}/bin/duti -s io.appmakes.otty public.unix-executable all
    ${pkgs.duti}/bin/duti -s io.appmakes.otty com.apple.terminal.shell-script all 2>/dev/null || true
    ${pkgs.duti}/bin/duti -s io.appmakes.otty ssh all 2>/dev/null || true
  '';
}

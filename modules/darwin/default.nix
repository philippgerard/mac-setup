{ config, pkgs, ... }:

{
  imports = [
    ./nix.nix
    ./system.nix
    ./homebrew.nix
  ];

  # Enable nix-darwin
  services.nix-daemon.enable = true;

  # Required for nix-darwin
  system.stateVersion = 5;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Set fish as the default shell
  programs.fish.enable = true;
  users.users.philippgerard = {
    shell = pkgs.fish;
  };

  # System packages available to all users
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    duti  # Set default applications for file types
  ];

  # Set Ghostty as default terminal for shell scripts
  # Uses duti to configure file associations
  # https://github.com/moretension/duti
  system.activationScripts.postActivation.text = ''
    echo "Setting Ghostty as default terminal for scripts..."
    # Shell scripts
    ${pkgs.duti}/bin/duti -s com.mitchellh.ghostty public.shell-script all
    # Unix executables
    ${pkgs.duti}/bin/duti -s com.mitchellh.ghostty public.unix-executable all
    # .command files (macOS)
    ${pkgs.duti}/bin/duti -s com.mitchellh.ghostty com.apple.terminal.shell-script all 2>/dev/null || true
  '';
}

{ config, pkgs, ... }:

{
  nix = {
    # Enable flakes and new nix command
    settings = {
      experimental-features = [ "nix-command" "flakes" ];

      # Trusted users for remote builds
      trusted-users = [ "root" "philippgerard" ];

      # Avoid unwanted garbage collection when using nix-direnv
      keep-outputs = true;
      keep-derivations = true;

    };

    # Automatic garbage collection
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };

    # Optimize nix store on each build
    optimise.automatic = true;
  };
}

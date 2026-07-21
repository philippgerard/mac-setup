{ localConfig, ... }:

{
  determinateNix = {
    enable = true;

    customSettings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" localConfig.username ];
      keep-outputs = true;
      keep-derivations = true;
    };
  };
}

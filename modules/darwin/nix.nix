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

  # Let the first nix-darwin activation adopt the untouched placeholder
  # created by the Determinate Nix Installer. nix-darwin preserves it with a
  # .before-nix-darwin suffix before installing the managed configuration.
  environment.etc."nix/nix.custom.conf".knownSha256Hashes = [
    "3bd68ef979a42070a44f8d82c205cfd8e8cca425d91253ec2c10a88179bb34aa"
  ];
}

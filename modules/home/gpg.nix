{ lib, pkgs, ... }:

{
  home.activation.secureGnuPGHome = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 700 "$HOME/.gnupg"
  '';

  # Keep the agent configuration minimal and compatible with current GnuPG.
  # `use-agent` belongs in gpg.conf and is intentionally not written here.
  home.file.".gnupg/gpg-agent.conf" = {
    force = true;
    text = ''
      pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
      default-cache-ttl 600
      max-cache-ttl 7200
    '';
  };
}

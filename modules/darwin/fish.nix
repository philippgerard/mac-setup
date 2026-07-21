{ lib, localConfig, pkgs, ... }:

let
  fishExecutable = lib.getExe pkgs.fish;
  fishShell = "/run/current-system/sw/bin/fish";
  userRecord = "/Users/${localConfig.username}";
in
{
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  # Keep the primary user's home available to nix-darwin without taking
  # ownership of the existing macOS administrator account.
  users.users.${localConfig.username}.home = localConfig.homeDirectory;

  system.activationScripts.postActivation.text = lib.mkAfter ''
    if [[ ! -x ${lib.escapeShellArg fishExecutable} ]]; then
      echo "Fish executable is unavailable; refusing to change the login shell." >&2
      exit 1
    fi

    current_shell="$(/usr/bin/dscl . -read ${lib.escapeShellArg userRecord} UserShell 2>/dev/null || true)"
    current_shell="''${current_shell#UserShell: }"

    if [[ "$current_shell" != ${lib.escapeShellArg fishShell} ]]; then
      echo "Setting Fish as the default login shell..."
      /usr/bin/dscl . -create ${lib.escapeShellArg userRecord} UserShell ${lib.escapeShellArg fishShell}
    fi
  '';
}

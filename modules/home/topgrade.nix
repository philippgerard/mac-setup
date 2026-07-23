{ pkgs, ... }:

let
  topgradeConfig = ''
    # Don't ask for confirmation
    [misc]
    assume_yes = true
    no_retry = false
    cleanup = false
    no_self_update = true

    # The nix-darwin configuration, Home Manager, Topgrade, and global npm
    # tooling are managed outside Topgrade. Update the flake intentionally with
    # scripts/update; project Node dependencies remain project-owned.
    disable = ["nix", "home_manager", "node"]

    # Pre-commands (run before updates)
    # [pre_commands]
    # "Backup" = "echo 'Starting updates...'"

    # Post-commands (run after updates)
    # [post_commands]
    # "Cleanup" = "echo 'Updates complete!'"

    # macOS specific
    [brew]
    greedy_cask = false  # Don't update casks with auto-update

    # Git repos to pull (add your repos here)
    # [git]
    # repos = [
    #   "~/Projects/my-repo",
    # ]

    # Commands to run (custom update commands)
    # [commands]
    # "My Custom Update" = "echo 'Custom update command'"

    # Firmware updates (macOS)
    [firmware]
    upgrade = false  # Set to true to include firmware updates
  '';
  topgradeConfigSource = pkgs.writeText "topgrade.toml" topgradeConfig;
  validatedTopgradeConfig = pkgs.runCommand "validated-topgrade.toml" { } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    ${pkgs.topgrade}/bin/topgrade \
      --config ${topgradeConfigSource} \
      --dry-run \
      --only custom_commands \
      --no-ask-retry \
      --notify-end never \
      >/dev/null
    cp ${topgradeConfigSource} "$out"
  '';
in
assert builtins.isAttrs (builtins.fromTOML topgradeConfig);
{
  # Topgrade configuration
  # Config file location: ~/.config/topgrade.toml
  home.file.".config/topgrade.toml".source = validatedTopgradeConfig;
}

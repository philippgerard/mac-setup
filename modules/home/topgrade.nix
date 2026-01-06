{ config, pkgs, ... }:

{
  # Topgrade configuration
  # Config file location: ~/.config/topgrade.toml
  home.file.".config/topgrade.toml".text = ''
    # Don't ask for confirmation
    [misc]
    assume_yes = true
    no_retry = false
    cleanup = true

    # Disable sudo if not needed
    # sudo_command = "sudo"

    # Skip these steps (uncomment as needed)
    [misc]
    # disable = [
    #   "node",
    #   "nix",
    #   "mas",
    # ]

    # Pre-commands (run before updates)
    # [pre_commands]
    # "Backup" = "echo 'Starting updates...'"

    # Post-commands (run after updates)
    # [post_commands]
    # "Cleanup" = "echo 'Updates complete!'"

    # macOS specific
    [brew]
    greedy_cask = false  # Don't update casks with auto-update

    # Nix
    [nix]
    # self_update = false  # Don't update Nix itself

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
}

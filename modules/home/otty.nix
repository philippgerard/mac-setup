{ config, lib, pkgs, ... }:

let
  initialConfig = pkgs.writeText "otty-initial-config.toml" ''
    # GUI sessions can retain the pre-activation SHELL value until logout.
    command = "/run/current-system/sw/bin/fish"
    env = "SHELL=/run/current-system/sw/bin/fish"

    theme = "Paper"
    theme-dark = "Nord"

    foreground = "#1a1a1a"
    background = "#fcfbf9"
    palette-0 = "#1a1a1a"
    palette-1 = "#a33a3a"
    palette-2 = "#2b5a38"
    palette-3 = "#a85a20"
    palette-4 = "#4a7a8a"
    palette-5 = "#4a3a6a"
    palette-6 = "#3a7a6a"
    palette-7 = "#c1beb5"
    palette-8 = "#8c8a80"
    palette-9 = "#c36a6a"
    palette-10 = "#6b9a78"
    palette-11 = "#c88a50"
    palette-12 = "#7a9aaa"
    palette-13 = "#8a7a9a"
    palette-14 = "#6abaaa"
    palette-15 = "#ebebe6"

    on-launch = "new_window"
    details-panel-width = 250
    privilege-caffeinate-agent-processing = true
    dock-icon-animate-progress = true
    font-size = 14
    sidebar-width = 253
    copy-on-select = true
    clipboard-trim-trailing-spaces = true
    text-blink = true
    cursor-style = "bar"
  '';
in
{
  # A future xdg.configFile/home.file declaration would turn this back into a
  # read-only Nix-store link and break Otty's Settings UI.
  assertions = [
    {
      assertion = !(builtins.hasAttr ".config/otty/config.toml" config.home.file);
      message = "Otty config must remain a writable seed-once file";
    }
  ];

  # Otty writes appearance changes to config.toml itself. Seed a regular file
  # once instead of exposing an immutable Home Manager symlink into the Nix
  # store, then leave all user-owned appearance settings untouched.
  home.activation.configureOtty = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    otty_config_dir="$HOME/.config/otty"
    otty_config_file="$otty_config_dir/config.toml"
    otty_cli="/Applications/Otty.app/Contents/MacOS/otty-cli"
    otty_normalizer="${../../scripts/normalize-otty-config}"

    if [[ -e "$otty_config_dir" || -L "$otty_config_dir" ]]; then
      if [[ ! -d "$otty_config_dir" || -L "$otty_config_dir" || ! -O "$otty_config_dir" ]]; then
        echo "Otty config must be a user-owned directory, not a symlink" >&2
        exit 1
      fi
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 0700 "$otty_config_dir"
    else
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -d -m 0700 "$otty_config_dir"
    fi

    if [[ ! -e "$otty_config_file" && ! -L "$otty_config_file" ]]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0600 \
        ${initialConfig} "$otty_config_file"
    elif [[ -f "$otty_config_file" && ! -L "$otty_config_file" && -O "$otty_config_file" ]]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 0600 "$otty_config_file"
    elif [[ -v DRY_RUN && -L "$otty_config_file" ]]; then
      echo "Otty's managed config link would be replaced by a writable file"
    else
      echo "Otty config must be a user-owned regular file, not a symlink" >&2
      exit 1
    fi

    # Keep Fish as Otty's shell without resetting theme, font, or layout edits.
    if [[ -x "$otty_cli" && -f "$otty_config_file" && ! -L "$otty_config_file" ]]; then
      $DRY_RUN_CMD "$otty_cli" --config-file "$otty_config_file" \
        config set command /run/current-system/sw/bin/fish
    fi

    # Otty's CLI appends repeatable `env` keys. Normalize only SHELL so that
    # activation is idempotent while preserving every other user setting.
    if [[ -f "$otty_config_file" && ! -L "$otty_config_file" ]]; then
      $DRY_RUN_CMD "$otty_normalizer" \
        "$otty_config_file" /run/current-system/sw/bin/fish
    fi
  '';
}

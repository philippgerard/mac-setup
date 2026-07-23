{ config, lib, pkgs, ... }:

let
  # Keep these seed settings intentionally free of API keys and private paths.
  # Zed owns the resulting regular file after its first activation.
  initialSettings = pkgs.writeText "zed-initial-settings.json" (builtins.toJSON {
    project_panel.dock = "right";
    outline_panel.dock = "right";
    collaboration_panel.dock = "right";
    git_panel.dock = "right";

    use_system_window_tabs = true;
    title_bar = {
      show_branch_status_icon = true;
      show_menus = false;
    };

    buffer_font_size = 13.0;
    terminal.font_size = 12;

    base_keymap = "SublimeText";
    vim_mode = false;
    autosave = "on_focus_change";

    centered_layout = {
      left_padding = 0.1;
      right_padding = 0.1;
    };
    tabs = {
      file_icons = true;
      git_status = true;
    };
    preview_tabs = {
      enabled = true;
      enable_preview_from_file_finder = false;
      enable_keep_preview_on_code_navigation = false;
    };

    telemetry = {
      metrics = false;
      diagnostics = false;
    };
  });
in
{
  # A future xdg.configFile/home.file declaration would turn this back into a
  # read-only Nix-store link and break Zed's Settings UI.
  assertions = [
    {
      assertion = !(builtins.hasAttr ".config/zed/settings.json" config.home.file);
      message = "Zed settings must remain a writable seed-once file";
    }
  ];

  home.activation.configureZed = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    zed_config_dir="$HOME/.config/zed"
    zed_settings_file="$zed_config_dir/settings.json"

    if [[ -e "$zed_config_dir" || -L "$zed_config_dir" ]]; then
      if [[ ! -d "$zed_config_dir" || -L "$zed_config_dir" || ! -O "$zed_config_dir" ]]; then
        echo "Zed config must be a user-owned directory, not a symlink" >&2
        exit 1
      fi
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 0700 "$zed_config_dir"
    else
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -d -m 0700 "$zed_config_dir"
    fi

    if [[ ! -e "$zed_settings_file" && ! -L "$zed_settings_file" ]]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0600 \
        ${initialSettings} "$zed_settings_file"
    elif [[ -f "$zed_settings_file" && ! -L "$zed_settings_file" && -O "$zed_settings_file" ]]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 0600 "$zed_settings_file"
    elif [[ -v DRY_RUN && -L "$zed_settings_file" ]]; then
      echo "Zed's managed settings link would be replaced by a writable file"
    else
      echo "Zed settings must be a user-owned regular file, not a symlink" >&2
      exit 1
    fi
  '';
}

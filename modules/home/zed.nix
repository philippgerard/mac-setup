{ ... }:

{
  # Keep this file intentionally free of API keys and private project paths.
  xdg.configFile."zed/settings.json".text = builtins.toJSON {
    project_panel.dock = "right";
    outline_panel.dock = "right";
    collaboration_panel.dock = "right";
    git_panel.dock = "right";

    use_system_window_tabs = true;
    title_bar = {
      show_branch_status_icon = true;
      show_menus = false;
    };

    theme = {
      mode = "system";
      light = "Xcode Default Light";
      dark = "macOS Classic Dark";
    };
    icon_theme = "Colored Zed Icons Theme Light";
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
  };
}

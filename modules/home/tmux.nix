{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    # Use 256 colors
    terminal = "tmux-256color";

    # Start window numbering at 1
    baseIndex = 1;

    # Increase scrollback buffer
    historyLimit = 50000;

    # Enable mouse support
    mouse = true;

    # Reduce escape time (important for vim)
    escapeTime = 0;

    # Use vim keybindings in copy mode
    keyMode = "vi";

    # Prefix key (Ctrl+a instead of Ctrl+b)
    prefix = "C-a";

    # Additional settings
    extraConfig = ''
      # Enable true color support
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Renumber windows when one is closed
      set -g renumber-windows on

      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # New window in current path
      bind c new-window -c "#{pane_current_path}"

      # Switch panes using Alt+arrow without prefix
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Vim-style pane selection
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Resize panes with Prefix + Shift + hjkl
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Quick reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Don't rename windows automatically
      set -g allow-rename off

      # Activity monitoring
      setw -g monitor-activity on
      set -g visual-activity off

      # Status bar
      set -g status-position bottom
      set -g status-interval 1

      # Catppuccin-inspired colors (matches your fish theme)
      set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
      set -g pane-border-style "fg=#313244"
      set -g pane-active-border-style "fg=#89b4fa"
      set -g message-style "bg=#313244,fg=#cdd6f4"

      set -g status-left "#[bg=#89b4fa,fg=#1e1e2e,bold] #S #[bg=#1e1e2e] "
      set -g status-right "#[fg=#a6adc8] %Y-%m-%d #[fg=#cdd6f4]%H:%M "
      set -g status-left-length 30

      setw -g window-status-format "#[fg=#6c7086] #I:#W "
      setw -g window-status-current-format "#[fg=#89b4fa,bold] #I:#W "
    '';

    # Plugins (optional)
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];
  };
}

{ config, pkgs, lib, ... }:

{
  # Fish shell configuration
  programs.fish = {
    enable = true;

    # Plugins
    plugins = [
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
    ];

    # Shell aliases
    shellAliases = {
      # Replace ls with eza
      ls = "eza -al --color=always --group-directories-first --icons=always";
      la = "eza -a --color=always --group-directories-first --icons=always";
      ll = "eza -l --color=always --group-directories-first --icons=always";
      lt = "eza -aT --color=always --group-directories-first --icons=always";
      "l." = "eza -a | grep -e '^\\.'";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Common utilities
      grep = "grep --color=auto";
      tarnow = "tar -acf ";
      untar = "tar -zxvf ";
      wget = "wget -c ";

      # Git shortcuts
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      gco = "git checkout";
      gb = "git branch";
      glog = "git log --oneline --graph --decorate";

      # Nix/darwin shortcuts
      rebuild = "~/.config/mac-setup/scripts/rebuild switch";
      update = "~/.config/mac-setup/scripts/update";
    };

    # Shell abbreviations (expand on space, better than aliases for some cases)
    shellAbbrs = {
      # Quick edits
      fishconf = "zed ~/.config/mac-setup/modules/home/fish.nix";
      nixconf = "zed ~/.config/mac-setup";
    };

    # Interactive shell init
    interactiveShellInit = ''
      # Disable fish greeting (we use fastfetch)
      set -g fish_greeting

      # Format man pages with bat
      set -gx MANROFFOPT "-c"
      set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

      # Settings for done plugin
      set -U __done_min_cmd_duration 10000
      set -U __done_notification_urgency_level low

      # Homebrew settings
      set -gx HOMEBREW_NO_ENV_HINTS 1

      # 1Password SSH agent
      set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

      # Theme switcher - match macOS appearance
      function update_theme_to_appearance
          set -l appearance (defaults read -g AppleInterfaceStyle 2>/dev/null)
          if test "$appearance" = "Dark"
              fish_config theme choose "Catppuccin Mocha" 2>/dev/null
          else
              fish_config theme choose "Catppuccin Latte" 2>/dev/null
          end
      end
      update_theme_to_appearance
    '';

    # Shell init (runs for all shells, including non-interactive)
    shellInit = ''
      # Homebrew (must be early for other tools to be found)
      if test -f /opt/homebrew/bin/brew
          eval (/opt/homebrew/bin/brew shellenv)
      end

      # User-installed tools and pnpm globals
      set -gx PNPM_HOME "$HOME/Library/pnpm"
      fish_add_path "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/bin" "$PNPM_HOME"

      # fnm (Node version manager) with auto-switching
      if type -q fnm
          fnm env --use-on-cd --shell fish --version-file-strategy=recursive --resolve-engines | source
      end

      # OrbStack integration
      if test -f ~/.orbstack/shell/init.fish
          source ~/.orbstack/shell/init.fish
      end
      if test -f ~/.orbstack/shell/init2.fish
          source ~/.orbstack/shell/init2.fish
      end

    '';

    # Custom functions
    functions = {
      # Fish greeting with fastfetch
      fish_greeting = ''
        fastfetch
      '';

      # History with timestamps
      history = ''
        builtin history --show-time='%F %T '
      '';

      # Backup a file
      backup = ''
        if test (count $argv) -ne 1
            echo "usage: backup <path>" >&2
            return 2
        end

        set -l filename $argv[1]
        if not test -e "$filename"
            echo "backup: path does not exist" >&2
            return 1
        end

        command cp -- "$filename" "$filename.bak"
      '';

      # Smart copy for directories
      copy = ''
        if test (count $argv) = 2; and test -d "$argv[1]"
            set -l from (string trim --right --chars=/ -- "$argv[1]")
            command cp -R -- "$from" "$argv[2]"
        else
            command cp -- $argv
        end
      '';

      # !! and !$ support
      __history_previous_command = ''
        switch (commandline -t)
        case "!"
          commandline -t $history[1]; commandline -f repaint
        case "*"
          commandline -i !
        end
      '';

      __history_previous_command_arguments = ''
        switch (commandline -t)
        case "!"
          commandline -t ""
          commandline -f history-token-search-backward
        case "*"
          commandline -i '$'
        end
      '';
    };
  };

  # Starship prompt (shared config, works with fish)
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        symbol = " ";
      };

      git_status = {
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
      };

      nix_shell = {
        symbol = " ";
        format = "via [$symbol$state]($style) ";
      };

      nodejs = {
        symbol = " ";
      };

      python = {
        symbol = " ";
      };

      rust = {
        symbol = " ";
      };
    };
  };

  # Packages needed for the fish config
  home.packages = with pkgs; [
    fastfetch    # For greeting
  ];

  xdg.configFile."fish/themes/Catppuccin Latte.theme".text = ''
    # name: 'Catppuccin Latte'
    # url: 'https://github.com/catppuccin/fish'
    # preferred_background: eff1f5

    fish_color_normal 4c4f69
    fish_color_command 1e66f5
    fish_color_param dd7878
    fish_color_keyword 8839ef
    fish_color_quote 40a02b
    fish_color_redirection ea76cb
    fish_color_end fe640b
    fish_color_comment 8c8fa1
    fish_color_error d20f39
    fish_color_gray 9ca0b0
    fish_color_selection --background=ccd0da
    fish_color_search_match --background=ccd0da
    fish_color_option 40a02b
    fish_color_operator ea76cb
    fish_color_escape e64553
    fish_color_autosuggestion 9ca0b0
    fish_color_cancel d20f39
    fish_color_cwd df8e1d
    fish_color_user 179299
    fish_color_host 1e66f5
    fish_color_host_remote 40a02b
    fish_color_status d20f39
    fish_pager_color_progress 9ca0b0
    fish_pager_color_prefix ea76cb
    fish_pager_color_completion 4c4f69
    fish_pager_color_description 9ca0b0
  '';

  xdg.configFile."fish/themes/Catppuccin Mocha.theme".text = ''
    # name: 'Catppuccin Mocha'
    # url: 'https://github.com/catppuccin/fish'
    # preferred_background: 1e1e2e

    fish_color_normal cdd6f4
    fish_color_command 89b4fa
    fish_color_param f2cdcd
    fish_color_keyword cba6f7
    fish_color_quote a6e3a1
    fish_color_redirection f5c2e7
    fish_color_end fab387
    fish_color_comment 7f849c
    fish_color_error f38ba8
    fish_color_gray 6c7086
    fish_color_selection --background=313244
    fish_color_search_match --background=313244
    fish_color_option a6e3a1
    fish_color_operator f5c2e7
    fish_color_escape eba0ac
    fish_color_autosuggestion 6c7086
    fish_color_cancel f38ba8
    fish_color_cwd f9e2af
    fish_color_user 94e2d5
    fish_color_host 89b4fa
    fish_color_host_remote a6e3a1
    fish_color_status f38ba8
    fish_pager_color_progress 6c7086
    fish_pager_color_prefix f5c2e7
    fish_pager_color_completion cdd6f4
    fish_pager_color_description 6c7086
  '';
}

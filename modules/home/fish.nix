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
      rebuild = "darwin-rebuild switch --flake ~/.config/mac-setup";
      update = "nix flake update ~/.config/mac-setup && darwin-rebuild switch --flake ~/.config/mac-setup";
    };

    # Shell abbreviations (expand on space, better than aliases for some cases)
    shellAbbrs = {
      # Quick edits
      fishconf = "zed ~/.config/fish/config.fish";
      nixconf = "zed ~/.config/mac-setup";
    };

    # Interactive shell init
    interactiveShellInit = ''
      # Disable fish greeting (we use fastfetch)
      set -g fish_greeting

      # Initialize Starship prompt
      starship init fish | source

      # Format man pages with bat
      set -gx MANROFFOPT "-c"
      set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"

      # Settings for done plugin
      set -U __done_min_cmd_duration 10000
      set -U __done_notification_urgency_level low

      # Homebrew settings
      set -gx HOMEBREW_NO_ENV_HINTS 1

      # Build flags for SQLite and OpenSSL
      set -gx PKG_CONFIG_PATH "/opt/homebrew/opt/sqlite/lib/pkgconfig" "/opt/homebrew/opt/openssl/lib/pkgconfig"
      set -gx LDFLAGS "-L/opt/homebrew/opt/sqlite/lib"
      set -gx CPPFLAGS "-I/opt/homebrew/opt/sqlite/include"

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

      # PATH additions
      fish_add_path ~/.local/bin ~/.cargo/bin ~/bin
      fish_add_path ~/.composer/vendor/bin
      fish_add_path /opt/homebrew/opt/mysql-client/bin
      fish_add_path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

      # Bun
      set -gx BUN_INSTALL "$HOME/.bun"
      fish_add_path $BUN_INSTALL/bin

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

      # Ghostty shell integration
      if set -q GHOSTTY_RESOURCES_DIR
          source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
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
        set -l filename $argv[1]
        cp $filename $filename.bak
      '';

      # Smart copy for directories
      copy = ''
        set count (count $argv | tr -d \n)
        if test "$count" = 2; and test -d "$argv[1]"
            set from (echo $argv[1] | string trim --right --chars=/)
            set to (echo $argv[2])
            command cp -r $from $to
        else
            command cp $argv
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
    starship     # Prompt
  ];
}

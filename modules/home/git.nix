{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    # User info - update these!
    userName = "Philipp Gerard";
    userEmail = "philipp.gerard@zeitdenken.de";

    # Default branch
    extraConfig = {
      init.defaultBranch = "main";

      # Push behavior
      push = {
        autoSetupRemote = true;
        default = "current";
      };

      # Pull behavior
      pull.rebase = true;

      # Merge behavior
      merge.conflictstyle = "diff3";

      # Rebase behavior
      rebase = {
        autoStash = true;
        autoSquash = true;
      };

      # Diff settings
      diff = {
        colorMoved = "default";
        algorithm = "histogram";
      };

      # Core settings
      core = {
        editor = "vim";
        autocrlf = "input";
        whitespace = "trailing-space,space-before-tab";
        pager = "delta";
      };

      # Interactive settings
      interactive.diffFilter = "delta --color-only";

      # Delta (better diffs)
      delta = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
      };

      # Credential helper (1Password)
      credential.helper = "osxkeychain";

      # URL rewrites
      url = {
        "ssh://git@github.com/" = {
          insteadOf = "https://github.com/";
        };
      };

      # 1Password SSH commit signing
      user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPcBfsf9sqlr9zSADTjddaBPY77885alCguyAGM2HUzG";
      gpg.format = "ssh";
      "gpg \"ssh\"".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      commit.gpgsign = true;
    };

    # Git aliases
    aliases = {
      co = "checkout";
      br = "branch";
      ci = "commit";
      st = "status";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
      lg = "log --oneline --graph --decorate --all";
      amend = "commit --amend --no-edit";
      undo = "reset --soft HEAD~1";
      stash-all = "stash save --include-untracked";
      aliases = "config --get-regexp alias";
      branches = "branch -a";
      remotes = "remote -v";
      contributors = "shortlog --summary --numbered";
      cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -d";
    };

    # Global gitignore
    ignores = [
      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "._*"

      # Editor
      ".idea/"
      "*.swp"
      "*.swo"
      "*~"
      ".vscode/settings.json"

      # Environment
      ".env"
      ".env.local"
      ".envrc"

      # Nix
      "result"
      "result-*"

      # Node
      "node_modules/"

      # Python
      "__pycache__/"
      "*.pyc"
      ".venv/"

      # Misc
      "*.log"
      "*.bak"
      ".direnv/"
    ];
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };

  # Lazygit (Git TUI)
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        showIcons = true;
      };
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --paging=never";
        };
      };
    };
  };
}

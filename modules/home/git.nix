{ ... }:

{
  programs.git = {
    enable = true;

    # Identity and the SSH signing public key are injected locally from
    # 1Password by scripts/configure-git-identity. The public repository
    # intentionally contains no name, email address, or key material.
    includes = [
      { path = "~/.config/git/identity.inc"; }
      {
        condition = "gitdir:~/.config/mac-setup/";
        path = "~/.config/git/public-identity.inc";
      }
      {
        condition = "hasconfig:remote.*.url:**/mac-setup.git";
        path = "~/.config/git/public-identity.inc";
      }
    ];

    settings = {
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
        editor = "zed --wait";
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

      # 1Password SSH commit signing. user.signingKey comes from the private
      # include so public configuration cannot identify the key owner.
      user.useConfigOnly = true;
      gpg.format = "ssh";
      "gpg \"ssh\"".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      "gpg \"ssh\"".allowedSignersFile = "~/.config/git/allowed_signers";
      commit.gpgsign = true;
      tag.gpgsign = true;

      alias = {
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

      # Oh My Claude Code runtime state. Keep project-scoped skills visible so
      # repositories can opt into reviewing and sharing them.
      "!.omc/"
      ".omc/*"
      "!.omc/skills/"
      "!.omc/skills/**"

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

}

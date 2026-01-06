{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Core utilities
    coreutils
    findutils
    gnused
    gawk

    # Modern CLI tools
    ripgrep     # Better grep
    fd          # Better find
    eza         # Better ls
    bat         # Better cat
    fzf         # Fuzzy finder
    zoxide      # Better cd
    delta       # Better diff
    htop        # Process viewer
    btop        # Resource monitor
    tldr        # Simplified man pages
    jq          # JSON processor
    yq          # YAML processor

    # Development
    claude-code # AI coding assistant (from nixpkgs)
    gh          # GitHub CLI
    lazygit     # Git TUI
    httpie      # HTTP client
    neovim      # Editor
    tree        # Directory tree
    watch       # Run commands periodically
    direnv      # Per-directory environment
    just        # Command runner
    fnm         # Fast Node Manager

    # System tools
    pstree      # Process tree
    topgrade    # Update everything

    # Archive tools
    unzip
    p7zip

    # Networking
    curl
    wget
    nmap

    # Node.js (if needed - otherwise use fnm/nvm)
    # nodejs_22
    # pnpm

    # Python (if needed)
    # python312
    # python312Packages.pip

    # Rust (if needed)
    # rustup
  ];
}

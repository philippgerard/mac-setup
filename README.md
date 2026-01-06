# Mac Setup

Declarative macOS configuration using Nix, nix-darwin, and Home Manager.

## Features

- **Fully declarative**: Entire system configuration in code
- **Reproducible**: Same config = same system every time
- **Rollback**: Easy to undo changes with `darwin-rebuild --rollback`
- **Multi-host**: Support for multiple machines (desktop, laptop)
- **Homebrew integration**: Manage casks and Mac App Store apps via Nix

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/philippgerard/mac-setup/main/setup.sh | bash
```

## Prerequisites

- macOS (Apple Silicon or Intel)
- 1Password account (for SSH agent integration)

## What Gets Installed

### System Configuration (nix-darwin)
- Nix daemon with flakes enabled
- macOS system preferences (Dock, Finder, keyboard, etc.)
- Touch ID for sudo
- Automatic garbage collection

### User Environment (Home Manager)
- Zsh with autosuggestions and syntax highlighting
- Starship prompt
- Modern CLI tools (ripgrep, fd, eza, bat, fzf, etc.)
- Git with delta and lazygit
- Direnv for per-project environments

### Applications (Homebrew)
- 1Password & CLI
- Raycast, Arc, Firefox
- VS Code, Wezterm, Docker
- Slack, Zoom, Discord
- And more...

### Mac App Store (mas)
- Tailscale
- 1Password Safari Extension
- Amphetamine
- The Unarchiver

## Directory Structure

```
mac-setup/
├── flake.nix              # Entry point
├── flake.lock             # Locked dependencies
├── setup.sh               # Bootstrap script
├── hosts/
│   ├── desktop/           # Desktop-specific config
│   └── laptop/            # Laptop-specific config
└── modules/
    ├── darwin/            # System configuration
    │   ├── homebrew.nix   # Casks & mas apps
    │   ├── system.nix     # macOS preferences
    │   └── nix.nix        # Nix settings
    └── home/              # User configuration
        ├── shell.nix      # Zsh & prompt
        ├── git.nix        # Git settings
        └── packages.nix   # CLI tools
```

## Usage

### Rebuild after changes

```bash
darwin-rebuild switch --flake ~/.config/mac-setup#<hostname>
```

Or use the alias (after first rebuild):

```bash
rebuild
```

### Update all packages

```bash
nix flake update ~/.config/mac-setup
darwin-rebuild switch --flake ~/.config/mac-setup#<hostname>
```

Or use the alias:

```bash
update
```

### Rollback to previous generation

```bash
darwin-rebuild switch --rollback
```

### Add a new package

**Nix package (CLI tools):**
Edit `modules/home/packages.nix`:
```nix
home.packages = with pkgs; [
  your-package
];
```

**Homebrew cask (GUI apps):**
Edit `modules/darwin/homebrew.nix`:
```nix
casks = [
  "your-app"
];
```

**Mac App Store app:**
Edit `modules/darwin/homebrew.nix`:
```nix
masApps = {
  "App Name" = 123456789;  # App ID from App Store URL
};
```

### Add a new host

1. Create `hosts/<hostname>/default.nix`
2. Add to `flake.nix`:
   ```nix
   darwinConfigurations = {
     <hostname> = mkDarwinSystem { hostname = "<hostname>"; };
   };
   ```

## Configuration

### Update your email

Edit `modules/home/git.nix`:
```nix
userEmail = "your-email@example.com";
```

### Change hostnames

1. Rename the folder in `hosts/` to match your hostname (`hostname -s`)
2. Update the key in `flake.nix` under `darwinConfigurations`

### Customize system preferences

Edit `modules/darwin/system.nix` for Dock, Finder, keyboard settings, etc.

### Customize shell

Edit `modules/home/shell.nix` for aliases, environment variables, and prompt.

## Troubleshooting

### Nix command not found

Restart your terminal, or run:
```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### darwin-rebuild not found

Run the initial build:
```bash
nix run nix-darwin -- switch --flake ~/.config/mac-setup#<hostname>
```

### Homebrew packages not installing

Make sure Homebrew is in your PATH:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### mas apps hanging

This is a known issue on macOS Tahoe. Try:
1. Ensure you're signed into the Mac App Store
2. Comment out problematic apps in `masApps`
3. Install manually via App Store

### Uninstall Nix

```bash
/nix/nix-installer uninstall
```

## Resources

- [Determinate Nix](https://docs.determinate.systems/)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [Home Manager](https://nix-community.github.io/home-manager/)
- [nix-homebrew](https://github.com/zhaofengli/nix-homebrew)
- [Nixpkgs Search](https://search.nixos.org/packages)

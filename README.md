# Mac Setup

Declarative macOS configuration using Nix, nix-darwin, and Home Manager.

## Features

- **Fully declarative**: Entire system configuration in code
- **Reproducible**: Same config = same system every time
- **Rollback**: Easy to undo changes with `darwin-rebuild --rollback`
- **Multi-host**: Support for multiple machines with dynamic hostname generation
- **Homebrew integration**: Manage casks and Mac App Store apps via nix-darwin

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/philippgerard/mac-setup/main/setup.sh | bash
```

The setup script will:
1. Install Xcode Command Line Tools
2. Install Homebrew
3. Install Determinate Nix
4. Clone this repository
5. Prompt for device type (desktop/laptop) and purpose (personal/work)
6. Set the hostname and build the system

## Prerequisites

- macOS (Apple Silicon or Intel)
- 1Password account (for SSH agent and Git commit signing)

## What Gets Installed

### System Configuration (nix-darwin)
- Nix daemon with flakes enabled
- macOS system preferences (Dock, Finder, keyboard, trackpad)
- Touch ID for sudo
- Automatic garbage collection
- Fish as default shell

### User Environment (Home Manager)
- Fish shell with Catppuccin theme
- Starship prompt
- Modern CLI tools (ripgrep, fd, eza, bat, fzf, zoxide, etc.)
- Git with delta, lazygit, and 1Password SSH signing
- Tmux with Catppuccin colors
- Ghostty terminal configuration
- Topgrade for system updates

### Applications (Homebrew Casks)
- 1Password & CLI
- Raycast
- Development: Zed, Ghostty, OrbStack, TablePlus, Tower, Figma
- Communication: Zoom, Beeper, Notion (+ Slack, Teams, Cursor on work machines)
- Utilities: AdGuard, Ice, Shottr, AppCleaner, Choosy
- And more...

### Mac App Store (mas)
- 1Password for Safari
- Kagi for Safari, StopTheMadness Pro
- Dato, Lungo, Command X
- Little Snitch Mini, Battery Indicator
- And more...

## Directory Structure

```
mac-setup/
├── flake.nix                # Entry point
├── setup.sh                 # Bootstrap script
├── hosts/
│   ├── philippgerard-desktop-personal/
│   ├── philippgerard-desktop-work/
│   ├── philippgerard-laptop-personal/
│   └── philippgerard-laptop-work/
└── modules/
    ├── darwin/              # System configuration
    │   ├── default.nix      # Main darwin module
    │   ├── homebrew.nix     # Casks & mas apps
    │   ├── system.nix       # macOS preferences
    │   └── nix.nix          # Nix settings
    └── home/                # User configuration
        ├── default.nix      # Main home module
        ├── fish.nix         # Fish shell & Starship
        ├── git.nix          # Git settings
        ├── packages.nix     # CLI tools
        ├── tmux.nix         # Tmux configuration
        ├── ghostty.nix      # Terminal config
        └── topgrade.nix     # Update tool config
```

## Usage

### Rebuild after changes

```bash
darwin-rebuild switch --flake ~/.config/mac-setup
```

Or use the alias (after first rebuild):

```bash
rebuild
```

### Update all packages

```bash
nix flake update ~/.config/mac-setup
darwin-rebuild switch --flake ~/.config/mac-setup
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

## Configuration

### Hostname format

Hostnames are generated as `username-device-purpose`:
- `philippgerard-desktop-personal`
- `philippgerard-laptop-work`
- etc.

### Customize system preferences

Edit `modules/darwin/system.nix` for Dock, Finder, keyboard settings, etc.

### Customize shell

Edit `modules/home/fish.nix` for aliases, abbreviations, and shell functions.

### Update Git identity

Edit `modules/home/git.nix`:
```nix
userName = "Your Name";
userEmail = "your-email@example.com";
```

## Troubleshooting

### Nix command not found

Restart your terminal, or run:
```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### darwin-rebuild not found

Run the initial build:
```bash
nix run nix-darwin -- switch --flake ~/.config/mac-setup
```

### Homebrew packages not installing

Make sure Homebrew is in your PATH:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### mas apps hanging

Known issue on recent macOS versions. Try:
1. Ensure you're signed into the Mac App Store
2. Comment out problematic apps in `masApps`
3. Install manually via App Store

### Uninstall Nix

```bash
/nix/nix-installer uninstall
```

## Resources

- [Determinate Nix](https://determinate.systems/nix-installer/)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [Home Manager](https://nix-community.github.io/home-manager/)
- [Nixpkgs Search](https://search.nixos.org/packages)

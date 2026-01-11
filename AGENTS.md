# AGENTS.md - Coding Agent Guidelines

This document provides essential information for AI coding agents working in this repository.

## Project Overview

This is a **Nix-based macOS configuration** using:
- **nix-darwin**: Declarative macOS system configuration
- **Home Manager**: User environment management
- **Nix Flakes**: Modern dependency management

The project manages system settings, applications, shell configuration, and development tools for multiple macOS machines.

## Build/Apply Commands

### Apply Configuration Changes
```bash
# Standard rebuild (after making changes)
darwin-rebuild switch --flake ~/.config/mac-setup

# Or using the configured alias (available after first rebuild)
rebuild

# First-time installation (when darwin-rebuild is not available)
nix run nix-darwin -- switch --flake ~/.config/mac-setup
```

### Update Dependencies
```bash
# Update flake inputs and rebuild
nix flake update ~/.config/mac-setup
darwin-rebuild switch --flake ~/.config/mac-setup

# Or using the alias
update
```

### Rollback
```bash
darwin-rebuild switch --rollback
```

### Validate Nix Syntax
```bash
# Check flake for syntax errors
nix flake check

# Evaluate without building (quick syntax validation)
nix eval .#darwinConfigurations.philippgerard-desktop-personal.system
```

### Testing Changes

There are no automated tests. To verify changes:
1. Run `darwin-rebuild switch --flake ~/.config/mac-setup`
2. Verify the system behaves as expected
3. Use `darwin-rebuild switch --rollback` if issues arise

## Directory Structure

```
mac-setup/
├── flake.nix              # Entry point, defines all darwin configurations
├── setup.sh               # Bootstrap script for fresh installs
├── hosts/                 # Host-specific configurations
│   ├── philippgerard-desktop-personal/default.nix
│   ├── philippgerard-desktop-work/default.nix
│   ├── philippgerard-laptop-personal/default.nix
│   └── philippgerard-laptop-work/default.nix
└── modules/
    ├── darwin/            # System-level configuration (nix-darwin)
    │   ├── default.nix    # Main darwin module, imports others
    │   ├── homebrew.nix   # Homebrew casks and Mac App Store apps
    │   ├── nix.nix        # Nix daemon settings
    │   └── system.nix     # macOS system preferences
    └── home/              # User-level configuration (Home Manager)
        ├── default.nix    # Main home module, imports others
        ├── fish.nix       # Fish shell and Starship prompt
        ├── git.nix        # Git configuration
        ├── ghostty.nix    # Terminal configuration
        ├── packages.nix   # CLI tools
        ├── tmux.nix       # Tmux configuration
        └── topgrade.nix   # System updater config
```

## Code Style Guidelines

### Nix Expression Language

#### File Structure
- Each `.nix` file should have a clear, single responsibility
- Use `default.nix` as the entry point for directories
- Group imports at the top of files using the `imports` attribute

#### Function Parameters
```nix
# Standard parameter pattern for modules
{ config, pkgs, ... }:

# With additional parameters
{ config, pkgs, lib, hostname, ... }:
```

#### Formatting
- Use 2-space indentation (standard for Nix)
- Opening braces `{` on the same line as the declaration
- Closing braces `}` on their own line, aligned with the start of the block
- Semicolons at the end of attribute assignments
- One blank line between logical sections

#### Comments
```nix
# Single-line comments use hash
# Group related settings with section comments

# Dock settings
dock = {
  autohide = false;
  tilesize = 52;
};
```

#### Lists and Sets
```nix
# Lists - one item per line for readability
home.packages = with pkgs; [
  ripgrep     # Better grep
  fd          # Better find
  eza         # Better ls
];

# Attribute sets - grouped logically
system.defaults = {
  dock = {
    autohide = false;
    tilesize = 52;
  };
};
```

#### String Conventions
```nix
# Short strings: double quotes
userName = "Philipp Gerard";

# Multi-line strings: two single quotes
interactiveShellInit = ''
  # Disable fish greeting
  set -g fish_greeting
'';
```

### Naming Conventions

- **Hostnames**: `{username}-{device}-{purpose}` (e.g., `philippgerard-desktop-personal`)
- **Module files**: lowercase, descriptive names (e.g., `homebrew.nix`, `fish.nix`)
- **Nix attributes**: camelCase following nixpkgs conventions

### Adding New Packages

#### CLI Tools (Nix packages)
Edit `modules/home/packages.nix`:
```nix
home.packages = with pkgs; [
  your-package  # Brief description
];
```

#### GUI Apps (Homebrew casks)
Edit `modules/darwin/homebrew.nix`:
```nix
casks = [
  "your-app"
];
```

#### Mac App Store Apps
Edit `modules/darwin/homebrew.nix`:
```nix
masApps = {
  "App Name" = 123456789;  # App ID from App Store URL
};
```

### Adding Host-Specific Configuration

Create or edit `hosts/{hostname}/default.nix`:
```nix
{ config, pkgs, hostname, ... }:

{
  networking.hostName = hostname;
  networking.computerName = hostname;

  # Host-specific settings
  homebrew.casks = [
    "host-specific-app"
  ];
}
```

### Shell Script Style (setup.sh)

- Use `#!/bin/bash` shebang
- Enable strict mode: `set -e`
- Define colored output functions: `info()`, `warn()`, `error()`
- Use `[[ ]]` for conditionals (bash-specific)
- Quote variables: `"$VAR"` not `$VAR`
- Use meaningful section headers with echo statements

## Important Notes

1. **User hardcoded**: Configuration is for user `philippgerard` - update in `flake.nix` and `modules/home/default.nix` for other users

2. **1Password integration**: SSH agent and commit signing require 1Password setup

3. **Homebrew cleanup**: `onActivation.cleanup = "zap"` removes apps not in config - be careful when adding/removing casks

4. **No flake.lock**: This repo may not have a lock file; consider running `nix flake lock` to create one

5. **Unfree packages**: Enabled via `nixpkgs.config.allowUnfree = true`

## Common Tasks

### Add a new shell alias
Edit `modules/home/fish.nix`, add to `shellAliases`:
```nix
shellAliases = {
  myalias = "my-command";
};
```

### Modify macOS system preferences
Edit `modules/darwin/system.nix`, update `system.defaults`:
```nix
system.defaults = {
  dock.autohide = true;
};
```

### Add environment variable
Edit `modules/home/default.nix`:
```nix
home.sessionVariables = {
  MY_VAR = "value";
};
```

## Resources

- [nix-darwin options](https://daiderd.com/nix-darwin/manual/index.html)
- [Home Manager options](https://nix-community.github.io/home-manager/options.html)
- [Nixpkgs search](https://search.nixos.org/packages)
- [Nix language reference](https://nix.dev/manual/nix/stable/language/)

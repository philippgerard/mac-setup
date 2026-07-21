# AGENTS.md

## Purpose

This repository defines a public, PII-free macOS baseline using Determinate Nix, nix-darwin, Home Manager, Homebrew, and MAS.

## Hard constraints

- Never commit a real name, email address, SSH public key, GPG fingerprint, private hostname, absolute personal home path, token, credential, or private repository URL.
- Private account metadata lives in `.local/config.json`, which is generated and ignored.
- Private Git identity lives in `~/.config/git/identity.inc`, populated from 1Password.
- Private SSH hosts live below `~/.ssh/config.d/`.
- Do not add Chezmoi or another dotfile manager.
- Keep Homebrew activation cleanup set to `none`; destructive cleanup requires a separate reviewed dry-run.
- Do not automate `git reset`, deletion, or pulls in repository restoration.

## Repository structure

```text
flake.nix
hosts/mini/default.nix
profiles/*.nix
modules/darwin/*.nix
modules/home/*.nix
scripts/*
docs/*
```

`hosts/mini` selects profiles and the physical hostname only. Profiles own app sets and device/persona differences. Darwin modules own system policy; Home Manager modules own user tools and text configuration.

## Validation

Run before every handoff:

```bash
scripts/validate
```

When Nix is available, also run:

```bash
scripts/rebuild build
```

Never use `switch` as the first validation. Review the lock-file and package diff before activation.

## Style

- Use two-space indentation in Nix.
- Keep modules single-purpose.
- Prefer Nix for CLI tools and Homebrew/MAS for GUI/vendor applications.
- Pin flake inputs with `flake.lock` and update them intentionally.
- Use strict Bash (`set -euo pipefail`), quote expansions, and make reruns safe.
- Keep public configuration generic; obtain private values at runtime from 1Password or ignored local files.

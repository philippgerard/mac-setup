# Mac Setup

My repeatable Apple Silicon macOS setup, built with Determinate Nix,
nix-darwin, Home Manager, Homebrew, and the Mac App Store.

The repository contains the public machine configuration. Private identity,
account metadata, keys, and sync settings are restored from the dedicated
`Mac Setup` vault in 1Password and never stored in Git.

## Set up a fresh Mac

Before starting:

- finish macOS updates and enable FileVault;
- use the intended local administrator account;
- sign in to the Mac App Store; and
- make sure the required
  [1Password items](docs/private-state.md#1password-items) are recoverable.

### 1. Install and build

Open Terminal and paste this tested, revision-pinned bootstrap:

```bash
revision='037056b40b9633eaa2e3f8b16e52757e90dbe658'
/usr/bin/curl -qfsSL --proto '=https' --tlsv1.2 \
  "https://raw.githubusercontent.com/philippgerard/mac-setup/${revision}/setup.sh" \
  | /bin/bash -p -s -- --revision "$revision"
```

This requests the Command Line Tools and installs Homebrew and Determinate Nix
when needed, checks out the repository at `~/.config/mac-setup`, validates it,
and builds the configuration. It does not activate the build yet.

If macOS opens the Command Line Tools installer, finish it and run the same
bootstrap block again.

### 2. Activate and restore

After the build succeeds and its changes look right:

```bash
~/.config/mac-setup/setup.sh --provision
```

Follow the guided prompts. This activates the system, connects 1Password,
restores Git identity, personal Mail and configured DAV services, checks and
restores any missing declared S/MIME identities in the login keychain, restores
legacy GPG keys and Filen Menubar configuration, launches Filen Menubar, and
opens the macOS profiles that require approval. Filen authentication uses the
application's in-app Login flow when needed.

The flow is resumable. If macOS asks for App Management permission, enable the
terminal in **System Settings > Privacy & Security > App Management**, quit and
reopen Terminal, then run the same `--provision` command again. The same rule
applies if a profile approval or sign-in is interrupted.

That is the regular fresh-Mac setup.

## Optional accounts

Provisioning selects only `personal-mail` by default. To add another saved
account on this Mac, list every account you want:

```bash
~/.config/mac-setup/setup.sh --provision -- \
  --mail-account personal-mail --mail-account work-mail
```

Run `~/.config/mac-setup/scripts/finish-setup --help` for account, vault, and
skip options. See [Mail and account setup](docs/mail-accounts.md) for profile,
password, Microsoft 365, and migration details.

## What it restores

- macOS defaults, Fish, Git/SSH policy, tmux, Otty, and editable Zed settings
- the pinned CLI and development toolchain
- GUI and Mac App Store applications from the configured profiles
- Filen Menubar with its bundled patched sync backend and Node runtime
- private Git and GPG state, password-free Mail/DAV metadata, and Filen
  configuration from 1Password

The complete application policy is in
[the app inventory](docs/app-inventory.md). App Store and application sign-ins,
Apple privacy approvals, browser sessions, private repositories, and other
vendor-managed state still require their supported restore flows.

## Everyday use

From `~/.config/mac-setup`:

```bash
# Check the repository and configuration
scripts/validate

# Build without changing the live system
scripts/rebuild build

# Build and activate local changes
scripts/rebuild switch

# Intentionally update pinned Nix inputs and Filen Menubar, then build
scripts/update
```

Homebrew and Mac App Store application removal is never automatic. Review
`scripts/homebrew-dry-run` before removing software.

## More detail

- [Clean-install runbook](docs/restore-runbook.md) — extended setup, approvals,
  alternative flows, and interruption recovery
- [Mail and account setup](docs/mail-accounts.md) — IMAP/DAV, iCloud
  restrictions, Microsoft 365, MFA, and profile migration
- [Private state](docs/private-state.md) — 1Password items, Git/GPG identity,
  SSH hosts, and backup boundaries
- [Architecture and bootstrap safety](docs/architecture.md) — repository layout,
  revision pinning, source filtering, and activation design
- [Maintenance](docs/maintenance.md) — updates, Topgrade, Homebrew, and mutable
  application settings
- [Post-install verification](docs/restore-verification.md) — thorough automated
  and manual checks
- [Pre-wipe checklist](docs/pre-wipe-checklist.md) — required checks before
  erasing an existing Mac
- [Public release safety](docs/public-release.md) — PII and Git-history policy

# Clean-install restore runbook

The README contains the complete default path. This runbook covers preparation,
alternative flows, macOS approvals, and recovery when a step is interrupted.

## Before erasing

1. Complete the [pre-wipe checklist](pre-wipe-checklist.md).
2. Push the tested configuration revision and its `flake.lock`.
3. Verify a recent Time Machine backup by browsing it and restoring a test
   file.
4. Push or independently archive every local Git change and branch.
5. Dump and test any PostgreSQL database that must survive.
6. Run the GPG, Mail account, and Filen Menubar 1Password backup helpers and
   require their verified success results.
7. Confirm SSH access, 1Password recovery, code-signing identities, FileVault
   recovery, and Apple account access from another trusted device.

Container volumes on the old Mac are intentionally disposable and are not a
wipe gate.

## Prepare fresh macOS

1. Install macOS and create the intended local administrator account.
2. Apply operating-system updates and enable FileVault.
3. Sign in to the Mac App Store. Homebrew Bundle cannot install declared MAS
   applications without that session.
4. Have the 1Password recovery material available. The default restore expects
   the Git identity, Mail Accounts, GPG, and Filen Menubar items described in
   [Private state](private-state.md).
5. Use Terminal for the initial bootstrap.

The setup supports Apple Silicon only. The full Xcode application is not part
of the default stack.

## Build the tested revision

Use the exact revision-pinned block from the current public README. The first
run installs or requests prerequisites, creates `~/.config/mac-setup`,
validates the checkout, and builds without activation.

If Command Line Tools are missing, setup opens Apple's installer and exits.
Finish the installer and rerun the same bootstrap block.

If Determinate Nix was installed but is not yet visible to the current shell,
restart Terminal and rerun the same block.

The revision pin and transactional checkout behavior are explained in
[Architecture and bootstrap safety](architecture.md).

## Provision the Mac

After the build succeeds:

```bash
~/.config/mac-setup/setup.sh --provision
```

This rebuilds, activates nix-darwin, Home Manager, Homebrew, MAS applications,
and Rosetta when required, then starts the guided private restore.

The default flow:

1. selects the configured 1Password account, prompting when there is more than
   one;
2. ensures CLI integration and the SSH agent are enabled;
3. opens and verifies the iCloud service restrictions profile;
4. restores private and public Git identities;
5. restores Mail/DAV metadata and configures `personal-mail`;
6. checks the complete declared S/MIME identity history and imports only
   missing identities from 1Password into the login keychain;
7. restores legacy GPG keys and ownertrust;
8. restores Filen Menubar configuration;
9. authenticates the Filen CLI when needed; and
10. launches Filen Menubar.

The command is resumable. Rerun the same `--provision` command after an
interrupted approval or sign-in, unless setup specifically asks for
`--update-profiles` after detecting a different installed profile.

## Required approvals

macOS and vendors intentionally keep these steps interactive:

- enter the administrator password when bootstrap or activation requests it;
- sign in to 1Password, enable **Settings > Developer > Integrate with
  1Password CLI**, and enable the 1Password SSH agent;
- review and approve the iCloud restrictions profile and every selected
  IMAP/DAV profile in **System Settings > General > Device Management**;
- enter the corresponding Mail and DAV application passwords;
- approve 1Password or Keychain access if macOS requests it while missing
  S/MIME identities are restored, then manually test current and historical
  Mail decryption;
- complete Microsoft native OAuth/MFA for a selected Exchange account, then
  type `configured` when setup asks for confirmation;
- quit Filen Menubar from its menu if setup pauses before restoring its
  configuration; and
- authenticate the Filen CLI.

If Home Manager stops at `checkAppManagementPermission`, enable the terminal in
**System Settings > Privacy & Security > App Management**, quit and reopen that
terminal, then rerun
`~/.config/mac-setup/setup.sh --provision`. The failed activation stops before
Home Manager changes user files.

Other privacy permissions such as Full Disk Access, Accessibility, Input
Monitoring, Screen Recording, microphone, camera, notifications, Automation,
login items, and system extensions remain app-specific manual reviews.

Mail/DAV passwords, optional account selection, iCloud restrictions, Microsoft
security-key troubleshooting, and profile migration are documented in
[Mail and account setup](mail-accounts.md).

## Alternative flows

### Select accounts

The first explicit `--mail-account` replaces the `personal-mail` default.
Repeat it for every account wanted:

```bash
~/.config/mac-setup/setup.sh --provision -- \
  --mail-account personal-mail --mail-account work-mail
```

### Select a 1Password account or vault

Options after `--` are passed to the private restore:

```bash
~/.config/mac-setup/setup.sh --provision -- \
  --op-account account-shorthand --vault 'Vault Name'
```

The equivalent environment variables are `MAC_SETUP_1PASSWORD_ACCOUNT` and
`MAC_SETUP_1PASSWORD_VAULT`. Explicit selection is not inferred from ambient
`OP_*` variables.

### Activate only the public base

```bash
~/.config/mac-setup/setup.sh --apply
```

This activates the base and opens the iCloud restrictions profile if needed.
Run `~/.config/mac-setup/scripts/finish-setup` later for the guided private
restore.

### Use another checkout

```bash
./setup.sh --config-dir "$PWD" --provision
```

An existing checkout is never pulled, reset, or changed automatically. Review
and update it yourself first.

### Skip unavailable private state

If a default 1Password backup item does not exist, skip that component rather
than weakening the restore:

```bash
~/.config/mac-setup/setup.sh --provision -- \
  --skip-gpg --skip-filen
```

Run `~/.config/mac-setup/scripts/finish-setup --help` for every account, vault,
skip, dry-run, and profile-update option.

## Complete the restore

Restore private SSH host files below `~/.ssh/config.d/` and private repository
manifests without automated pulls, resets, or deletion. Sign in to browsers,
licensed applications, and other sync providers through their supported flows.
Restore user data from its authoritative remote source and import any required
database dumps.

Then follow [Post-install verification](restore-verification.md). Do not rely
on the rebuilt Mac until Mail/DAV, Filen sync, Git signing, GPG fingerprints,
and representative project builds have been checked.

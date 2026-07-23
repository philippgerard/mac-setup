# Clean-install restore runbook

## Before erasing

1. Complete `docs/pre-wipe-checklist.md`.
2. Push the tested configuration revision and its `flake.lock`.
3. Verify a recent Time Machine backup by browsing it and restoring a test file.
4. Push or independently archive every local Git change and branch.
5. Dump and test any PostgreSQL database that must survive.
6. Run `scripts/backup-gpg-to-1password` and verify the success result.
7. Run `scripts/backup-mail-accounts-to-1password` and verify the success result.
8. Run `scripts/backup-filen-menubar-to-1password` and verify the success result.
9. Confirm SSH access, 1Password recovery, code-signing identities, FileVault recovery, and Apple account access from another trusted device.

Container volumes on the old Mac are intentionally disposable and are not a wipe gate.

## Fresh macOS

1. Install macOS and create the intended local account.
2. Apply operating-system updates and enable FileVault.
3. Sign into the App Store so the declared MAS applications can be installed during activation.
4. Run `setup.sh` in build-only mode from a tested revision.
5. Review the build and package changes, then run `setup.sh --provision`.
6. Follow the guided prompts. The command selects a 1Password account, restores Git identity, serializes the iCloud and personal IMAP/DAV profile approvals, restores GPG and Filen state, authenticates the Filen CLI, and launches Filen Menubar. It is safe to rerun after an interrupted approval.
7. Enter the Mailbox email-client app password for the Mail prompt. Enter the same **Calendar and address book client (CalDAV/CardDAV)** app password for both DAV prompts when macOS asks separately.
8. Select an optional work or PEC account only when this Mac needs it. The default guided flow installs only `personal-mail`; explicit account options replace that default and must be repeated for every desired account. IMAP/DAV selections use generated profiles. A Microsoft 365 selection reports the state of Microsoft's optional Company Portal/MDM/Enterprise SSO broker, then opens **System Settings > Internet Accounts > Add Account > Microsoft Exchange**. Missing broker components are diagnostic rather than a blocker because the exact Apple authentication surface is not documented.
9. Restore private SSH host files and the private repository manifest without automated pulls, resets, or deletion.
10. Sign into the browser, other sync providers, and licensed applications.
11. Restore user data from its authoritative remote source and import any required PostgreSQL dumps.

Use `setup.sh --apply` for a base-only activation. Run `scripts/finish-setup`
later to perform the same guided private restore. Use
`scripts/finish-setup --help` for explicit account, vault, optional Mail
account, and skip controls.

Pass private-restore options through the one-command flow after `--`:

```bash
# Personal plus work Mail
setup.sh --provision -- \
  --mail-account personal-mail --mail-account work-mail

# An older combined or otherwise different profile
setup.sh --provision -- --update-profiles
```

## Manual macOS approvals

Review the iCloud restrictions profile and each selected IMAP/DAV profile before
approving them in Device Management. Add a selected Microsoft 365 account only
through the native Internet Accounts flow. The broker diagnostic reports
Company Portal, its Microsoft SSO extension, MDM enrollment, and the
organization's corresponding SSO payload. Installing Company Portal alone is
insufficient to activate that broker, but a missing broker does not prove that
Apple's authentication session cannot use the key.

Test the key before a password in a private Safari or Chrome session. If that
works but Internet Accounts offers only Authenticator number matching, cancel
and ask the administrator to inspect the exact native-client sign-in and its
Conditional Access result; an organization-managed Microsoft broker is one
possible remediation. A missing browser option means the administrator must
inspect the account registration and authentication policy. If the organization
uses a PIV certificate on the YubiKey, ask for its certificate-based
authentication setup instead.

Grant App Management to the terminal emulator running Home Manager when macOS
requests it, then reopen that terminal and rerun activation. Also review Full
Disk Access, Accessibility, Input Monitoring, Screen Recording, microphone,
camera, notifications, Automation, login items, and network/system extensions.
These approvals are intentionally documented rather than bypassed.

If an older setup installed a managed Exchange profile, first verify that the
account has no local-only mail or unsent messages. Remove the old profile in
**System Settings > General > Device Management** before adding the native
Exchange account. Removing it also removes the account and services it manages,
so setup does not automate this migration.

## Smoke tests

- `git commit -S` succeeds and reports an SSH signature.
- Git name and email come from the private include.
- The removable iCloud restrictions profile is visible in Device Management; iCloud Mail, Calendar, and Contacts are unavailable, and the profile contains no restriction for iCloud Reminders or unrelated iCloud services.
- Every selected IMAP/DAV profile is visible in Device Management; each restored Mail account can send and receive; and CalDAV/CardDAV calendars, reminders, and contacts appear where configured.
- Every selected Microsoft 365 account is visible in Internet Accounts, its required Apple apps are enabled, and native OAuth with the organization's approved FIDO2 broker or PIV/certificate method has completed.
- `fnm`, `gh`, `codex`, `claude`, `tmux`, `gpg`, `ssh`, Cargo, rustc,
  rustfmt, Clippy, rust-analyzer, Erlang's `erl`, Elixir's `mix`, and Mole's
  `mo` command start.
- `filen --version` reports the pinned CLI and Filen Menubar starts at login.
- `/Applications/Microsoft Teams.app` exists when the work setup is selected.
- `dscl . -read "/Users/$(id -un)" UserShell` reports `/run/current-system/sw/bin/fish`.
- After restoring the project-selected Node version through `fnm`, `node`, `corepack`, and `pnpm` start.
- `pnpm bin -g` succeeds and `topgrade --dry-run --only pnpm` completes without an error.
- An Intel executable can run through Rosetta. If Xcode was installed manually,
  its reviewed, explicit `sudo /usr/bin/xcodebuild -runFirstLaunch` completed
  and `/usr/bin/xcodebuild -checkFirstLaunchStatus` succeeds.
- Otty handles shell scripts and SSH URLs; its config is a writable regular file and appearance changes survive an app restart. Zed handles Markdown, its settings file is a writable regular file, and UI changes survive an app restart.
- 1Password, Mail, browser sync, Filen Menubar sync, and App Store installs have completed.
- Representative personal and work repositories build successfully.
- A second `scripts/rebuild build` has no unexpected effect.

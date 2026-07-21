# Clean-install restore runbook

## Before erasing

1. Complete `docs/pre-wipe-checklist.md`.
2. Push the tested configuration revision and its `flake.lock`.
3. Verify a recent Time Machine backup by browsing it and restoring a test file.
4. Push or independently archive every local Git change and branch.
5. Dump and test any PostgreSQL database that must survive.
6. Run `scripts/backup-gpg-to-1password` and verify the success result.
7. Run `scripts/backup-filen-menubar-to-1password` and verify the success result.
8. Confirm SSH access, 1Password recovery, code-signing identities, FileVault recovery, and Apple account access from another trusted device.

Container volumes on the old Mac are intentionally disposable and are not a wipe gate.

## Fresh macOS

1. Install macOS and create the intended local account.
2. Apply operating-system updates and enable FileVault.
3. Run `setup.sh` in build-only mode from a tested revision.
4. Review the build result, then rerun with `--apply`.
5. Sign in to 1Password and enable CLI integration and the SSH agent.
6. Run `scripts/configure-git-identity` and make a signed test commit.
7. Run `scripts/restore-gpg-from-1password` and verify fingerprints.
8. Run `scripts/restore-filen-menubar-from-1password`.
9. Run `filen` once to authenticate, then reopen Filen Menubar and verify sync.
10. Sign into the App Store, browser, other sync providers, and licensed applications.
11. Restore private SSH host files and the private repository manifest.
12. Restore or clone user data from its authoritative remote source.
13. Import PostgreSQL dumps if required.

## Manual macOS approvals

Review Full Disk Access, Accessibility, Input Monitoring, Screen Recording, microphone, camera, notifications, Automation, login items, and network/system extensions. These approvals are intentionally documented rather than bypassed.

## Smoke tests

- `git commit -S` succeeds and reports an SSH signature.
- Git name and email come from the private include.
- `fnm`, `gh`, `codex`, `claude`, `tmux`, `gpg`, and `ssh` start.
- `filen --version` reports the pinned CLI and Filen Menubar starts at login.
- After restoring the project-selected Node version through `fnm`, `node`, `corepack`, and `pnpm` start.
- Otty handles shell scripts and SSH URLs; Zed handles Markdown.
- 1Password, browser sync, Filen Menubar sync, and App Store installs have completed.
- Representative personal and work repositories build successfully.
- A second `scripts/rebuild build` has no unexpected effect.

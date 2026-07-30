# Pre-wipe checklist

Do not erase the Mac until every final gate is green.

## Configuration

- [ ] `flake.lock` is committed and pushed.
- [ ] `scripts/validate` passes.
- [ ] `scripts/rebuild build` succeeds twice without an unexpected second change.
- [ ] Bootstrap was rehearsed in build-only mode.
- [ ] Homebrew cleanup remains `none`, or a cleanup dry-run has been reviewed line by line.
- [ ] Every required app/tool is declared or documented as a manual/vendor-synced restore.
- [ ] No Chezmoi dependency or restore step remains.

## Public-repository safety

- [ ] `scripts/check-public-safety` passes.
- [ ] The exact public history passes `scripts/check-history-safety`, or the sanitized tree will be published from a new root/repository.
- [ ] No real name, email, SSH/GPG identifier, private hostname, private repository URL, absolute personal path, or credential is present in Git history for the new revision.
- [ ] Live editor/AI configuration was not copied without explicit token scrubbing.

## Source code and files

- [ ] All Git remotes were fetched before evaluating ahead/behind state.
- [ ] Every dirty working tree is committed, pushed, or independently archived.
- [ ] Every local-only and detached commit is reachable remotely or included in a verified Git bundle.
- [ ] Cloud file-sync providers report complete sync and representative files open from another device.
- [ ] `scripts/backup-mail-accounts-to-1password` completes and verifies the password-free private Mail/DAV metadata.
- [ ] `scripts/backup-filen-menubar-to-1password` completes and verifies the private sync config.

## Backup and stateful data

- [ ] A recent Time Machine backup is browsable and a file restore was tested.
- [ ] Critical files have an independent copy beyond the source disk.
- [ ] Required PostgreSQL databases have tested logical dumps.
- [ ] Unsynced application data and licenses have documented restore paths.

Container and Docker volumes on this Mac are intentionally excluded.

## Identity and access

- [ ] 1Password recovery works from another trusted device.
- [ ] Every setup-owned 1Password item is tagged `mac-setup` and stored in the dedicated `Mac Setup` vault; no vault or item ID is present in the public repository.
- [ ] The `Mac Setup Git Identity` item contains private identity fields plus the exact public repository-owner name, GitHub noreply address, and SSH signing key for public-repository commits.
- [ ] The 1Password SSH agent can authenticate and sign a test commit.
- [ ] `scripts/backup-gpg-to-1password` completes and verifies every local secret key plus ownertrust.
- [ ] Required IMAP and CalDAV/CardDAV app passwords are stored as dedicated `mac-setup`-tagged Login items in the `Mac Setup` vault; Microsoft 365 browser sign-in with the registered YubiKey works; any Company Portal, MDM, Enterprise SSO, or PIV/certificate prerequisites used by Apple Internet Accounts are documented by the organization; and the desired account selection for each Mac is known.
- [ ] Code-signing identities/private keys are independently recoverable.
- [ ] Every current and historical S/MIME PKCS#12/PFX identity is attached to its own correctly tagged 1Password Login item with the standard account ID, period, status, test-date fields, and that file's distinct import password; the automated restore reports every identity present, each current certificate is valid, and retained encrypted mail from every certificate period decrypts successfully using identities in the login keychain.
- [ ] Apple account, FileVault recovery, and important recovery codes are accessible.
- [ ] Private SSH hosts and repository manifests are stored outside the public repository.

## Final gates

- [ ] The tested configuration revision is available remotely.
- [ ] The private recovery manifest has no unverified item, including the `Mac Setup Mail Accounts` document.
- [ ] All local work and required stateful data have independent restore paths.
- [ ] The clean-install runbook has been rehearsed without destructive cleanup.

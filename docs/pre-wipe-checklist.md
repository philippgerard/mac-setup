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
- [ ] `scripts/backup-filen-menubar-to-1password` completes and verifies the private sync config.

## Backup and stateful data

- [ ] A recent Time Machine backup is browsable and a file restore was tested.
- [ ] Critical files have an independent copy beyond the source disk.
- [ ] Required PostgreSQL databases have tested logical dumps.
- [ ] Unsynced application data and licenses have documented restore paths.

Container and Docker volumes on this Mac are intentionally excluded.

## Identity and access

- [ ] 1Password recovery works from another trusted device.
- [ ] The `Mac Setup Git Identity` item contains private identity fields plus a pseudonymous name, GitHub noreply address, and SSH signing key for public-repository commits.
- [ ] The 1Password SSH agent can authenticate and sign a test commit.
- [ ] `scripts/backup-gpg-to-1password` completes and verifies every local secret key plus ownertrust.
- [ ] Code-signing identities/private keys are independently recoverable.
- [ ] Apple account, FileVault recovery, and important recovery codes are accessible.
- [ ] Private SSH hosts and repository manifests are stored outside the public repository.

## Final gates

- [ ] The tested configuration revision is available remotely.
- [ ] The private recovery manifest has no unverified item.
- [ ] All local work and required stateful data have independent restore paths.
- [ ] The clean-install runbook has been rehearsed without destructive cleanup.

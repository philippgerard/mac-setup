# Private state

The public repository defines behavior but must not identify the user or contain secrets.

Setup keeps two ignored host-local records below `.local/`, and the filtered
flake source categorically excludes that directory: `config.json` contains the
local account/home/host selectors, while `bootstrap-revision` contains only the
40-character public commit used for later verification. Neither file is a
backup; setup regenerates them on the target Mac. Local builds accept exactly
the `username`, `homeDirectory`, and `hostName` string fields, compare them with
the current account and the selected `mini` host, and use one validated private
snapshot for both build and activation.

## 1Password items

### Mac Setup Git Identity

Create a Secure Note or Login item with the unique title `Mac Setup Git Identity` and these fields:

- `name`
- `email`
- `signing_key` — the complete SSH public key held by the 1Password SSH agent
- `public_name` — exactly the owner segment of this public repository's GitHub
  URL, which is the only display name accepted by the history-safety gate
- `public_email` — this repository owner's GitHub noreply address, in either
  the owner-only or standard numeric-ID-plus-owner form
- `public_signing_key` — the SSH signing public key used for public-repository commits

`scripts/configure-git-identity` reads these fields and atomically writes:

- `~/.config/git/identity.inc`
- `~/.config/git/public-identity.inc`
- `~/.config/git/allowed_signers`

All files are mode `0600`, local only, and intentionally absent from Nix and Git. Conditional Git includes prevent the private default identity from being used for this public repository.

By default, the guided restore asks which configured 1Password account to use
and lets that account select its default vault. Use `--op-account` and `--vault`
with `scripts/finish-setup`, or set `MAC_SETUP_1PASSWORD_ACCOUNT` and
`MAC_SETUP_1PASSWORD_VAULT`, when either must be selected noninteractively. Set
`MAC_SETUP_GIT_IDENTITY_ITEM` to select another item title, or
`MAC_SETUP_GIT_IDENTITY_REF` when an explicit `op://Vault/Item` reference is
preferable. Every private helper clears inherited `OP_*` session, backend,
service-account, default-vault, and config-directory variables before applying
these explicit selections, so unrelated shell state cannot redirect a restore
or backup.

For example:

```bash
MAC_SETUP_GIT_IDENTITY_ITEM='Other Item' scripts/configure-git-identity
MAC_SETUP_1PASSWORD_VAULT='Vault Name' scripts/configure-git-identity
MAC_SETUP_GIT_IDENTITY_REF='op://Vault/Item' scripts/configure-git-identity
```

Git commits and tags use SSH signing through the 1Password application's
`op-ssh-sign` program. OpenPGP is retained only for legacy keys and decryption,
not for Git signing.

Backup upserts first list Documents in the selected account and optional vault,
then require the configured title to be absent or match exactly one item. A
1Password lookup error or duplicate title aborts the backup instead of creating
another ambiguous recovery item. Set `MAC_SETUP_1PASSWORD_VAULT` to narrow the
lookup when needed, and resolve duplicate titles before retrying.

### GPG documents

`scripts/backup-gpg-to-1password` keeps the OpenPGP export in process memory and sends it to these 1Password documents without writing plaintext to disk:

- `Mac Setup GPG Secret Keys`
- `Mac Setup GPG Ownertrust`

Both documents are downloaded through pipes and compared byte-for-byte by
SHA-256 before success is reported. No plaintext export file is created.

Restore with `scripts/restore-gpg-from-1password`, then verify locally:

```bash
gpg --list-secret-keys --keyid-format long
```

### Mail account config

Account names, addresses, login names, account types, Mail/DAV server settings,
and stable identifiers belong in
`~/Library/Application Support/mac-setup/mail-accounts.json`, outside the Git
checkout. The schema contains no passwords, app passwords, access tokens, or
OAuth refresh tokens.

Schema version 3 stores an `accounts` array. Keep each account's lowercase
hyphenated `id` stable. For IMAP/DAV accounts, also keep the profile and payload
identifiers stable because macOS uses them to recognize an update. Generate new
UUIDs only for a genuinely new profile or payload. Run
`scripts/validate-mail-accounts-config` after every edit; it rejects unknown
fields and credential-shaped keys.

Back up the validated JSON as the `Mac Setup Mail Accounts` 1Password Document:

```bash
scripts/backup-mail-accounts-to-1password
```

The helper upserts the document and verifies its SHA-256 digest after download.
Keep email and DAV app passwords in separate 1Password Login items rather than
adding them to the metadata document.

Restore the metadata and regenerate the derived, password-free profiles with:

```bash
scripts/restore-mail-accounts-from-1password
```

The helper validates and atomically restores the JSON with mode `0600`, then
generates one `.mobileconfig` per IMAP/DAV account below
`~/Library/Application Support/mac-setup/mail-profiles/`. Private directories
use mode `0700`; metadata and profiles use mode `0600`. A different existing
metadata file is preserved with a timestamp. These files remain outside the
checkout and must never be committed or copied into a flake source.

Older revisions kept the same metadata and profiles below the checkout's
ignored `.local/` directory. `scripts/flake-source` excludes that entire
directory, including legacy copies, before adding source code to the Nix store.
After restoring and verifying the external copy, review and remove only the
legacy `.local/mail-accounts.json` and `.local/mail-profiles/` copies. Keep
`.local/config.json`, which local host builds still require. Existing Nix-store
source copies from older runs can remain readable until a separately reviewed
garbage collection; no setup helper deletes them automatically.

Set `MAC_SETUP_PRIVATE_STATE_DIR` only to an absolute directory outside the
repository. The lower-level `MAC_SETUP_MAIL_CONFIG_FILE` and
`MAC_SETUP_MAIL_PROFILE_DIR` overrides follow the same rule: they must be
absolute, contain no control characters, and resolve outside the checkout.
Setup helpers reject `..` and symlink traversal that would resolve back into the
repository.

The guided selection flow, profile passwords, CalDAV/CardDAV behavior, iCloud
restrictions, Microsoft OAuth/MFA, and migration procedures live in
[Mail and account setup](mail-accounts.md).

### Filen Menubar config

`scripts/backup-filen-menubar-to-1password` stores the live `config.json` as the `Mac Setup Filen Menubar Config` document and verifies its SHA-256 digest after download. The document contains private local and remote sync paths and must remain outside Git.

Restore it with `scripts/restore-filen-menubar-from-1password`. The helper validates the schema and atomically installs the file with mode `0600` at the path used by the pinned app version. If a different config already exists, it is preserved beside the restored file with a pre-restore timestamp. `syncPairs.json` is regenerated by the app, so it is not backed up separately.

The Filen CLI login session is a credential and is intentionally not copied.
The guided provisioner authenticates it interactively after a clean install and
restricts the local state directory and saved-login file to user-only access.

### Private recovery manifest

Keep a separate 1Password item that records:

- Apple account and FileVault recovery routes;
- code-signing certificate recovery;
- GPG document names and last verification date;
- Mail account document name and last verification date;
- Filen Menubar config document name and last verification date;
- private repository-manifest document name;
- manually licensed applications;
- any vendor-sync account that must be checked after restore.

The manifest describes where state lives; it must not be copied into this repository.

## SSH hosts

The public SSH config owns only the 1Password agent and safe connection defaults. Restore private host entries into `~/.ssh/config.d/`. Avoid putting private hostnames or identity-file paths in the public module.

Home Manager creates or verifies `~/.ssh` and `~/.ssh/config.d` as owned,
non-symlink directories with mode `0700`. Each top-level private host entry must
be an owned regular file; activation refuses symlinks or directories and sets
the files to mode `0600` without following links.

On first activation, an existing `~/.ssh/config` is preserved as
`~/.ssh/config.before-home-manager`. Review that backup and move any private
host blocks into separate files below `~/.ssh/config.d/`.

## Application credentials

Do not copy live Zed, AI-agent, browser, or package-manager settings wholesale.
Live files can contain access tokens even when most of the file is harmless.
The public Zed module only seeds non-secret defaults when no settings file
exists; its live user-owned file is preserved locally. Credentials are restored
through 1Password or the application's supported sign-in flow.

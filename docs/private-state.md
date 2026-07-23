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
`MAC_SETUP_GIT_IDENTITY_REF` when an explicit `op://Vault/Item` reference is
preferable. Every private helper clears inherited `OP_*` session, backend,
service-account, default-vault, and config-directory variables before applying
these explicit selections, so unrelated shell state cannot redirect a restore
or backup.

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
identifiers/UUIDs stable: macOS uses them to recognize an update. Generate new
UUIDs with `uuidgen` only when adding a genuinely new profile or payload. IMAP
accounts define incoming and outgoing TLS endpoints and may add CalDAV/CardDAV
service payloads. Microsoft 365 accounts use the `exchange_oauth` type; their
metadata remains in this document for guided selection, but setup does not
generate a managed Exchange profile. Run
`scripts/validate-mail-accounts-config` after every edit; it rejects unknown
fields and credential-shaped keys.

Back up the validated JSON as the `Mac Setup Mail Accounts` 1Password Document:

```bash
scripts/backup-mail-accounts-to-1password
```

The helper upserts the document and verifies its SHA-256 digest after download.
Keep email and DAV app passwords in separate 1Password Login items rather than
adding them to the metadata document.

Restore the private metadata and generate the derived configuration profiles
with:

```bash
scripts/restore-mail-accounts-from-1password
```

The helper validates the document, atomically restores it with mode `0600`, and
generates one password-free `.mobileconfig` per IMAP/DAV account below
`~/Library/Application Support/mac-setup/mail-profiles/`. The private state and
profile directories have mode `0700`, and the metadata and generated files have
mode `0600`. A different existing metadata file is preserved with a timestamp
before replacement. These files remain outside the checkout and must never be
committed or copied into a flake source.

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

The restore helper opens the generated profile directory by default. Install
only the IMAP/DAV profiles wanted on that Mac, reviewing each manually in
**System Settings > General > Device Management**. Interactive IMAP installation
prompts for its email app password; optional CalDAV and CardDAV payloads prompt
for DAV credentials.

For a selected `exchange_oauth` account, the guided setup instead opens
**System Settings > Internet Accounts > Add Account > Microsoft Exchange**.
Before opening it, setup reports whether this Mac has Microsoft's documented
native-app broker stack: Company Portal, its registered Enterprise SSO plug-in,
MDM enrollment, and the corresponding Microsoft Extensible SSO profile.
Installing Company Portal by itself is insufficient to activate that broker,
and this public baseline does not enroll the Mac into an organization's
device-management system. The diagnostic is advisory because neither vendor
documents whether every Apple Internet Accounts authentication session requires
or can use that broker.

Test the registered security key in a private Safari or Chrome session first. A
key that works in the browser but not in Internet Accounts means the account and
key are usable but the native client or its policy needs administrator
investigation; the managed broker is one possible remediation. If the browser
also lacks the security-key option, the administrator must check registration
and tenant authentication policy. A YubiKey used as a PIV smart card instead
requires a provisioned certificate and Microsoft Entra certificate-based
authentication; it is not the same as FIDO2.

The OAuth tokens created by a successful Internet Accounts flow remain in the
macOS account and Keychain infrastructure and are not exported to 1Password.
No extra password or configuration-profile field can select an MFA method.

As of July 2026, Apple still documents macOS Exchange accounts as using EWS,
which Microsoft will begin disabling in Exchange Online in October 2026 and
fully disable in April 2027. Monitor both vendors' migration guidance and keep
Outlook or the web applications available rather than treating this Apple
account path as permanent.

The Mailbox.org service bundle uses one CalDAV payload for Calendar and
Reminders/VTODO discovery and one CardDAV payload for Contacts. Its
**Calendar and address book client (CalDAV/CardDAV)** application password can
be used for both prompts. Reminders availability still depends on server task
discovery and must be verified after installation.

Each IMAP/DAV profile owns only its corresponding managed account bundle and can
be installed or removed independently. Removing it also removes every service
in that bundle, so do not delete a profile casually.

If an older revision installed a managed Exchange profile, first verify that
the account contains no local-only mail or unsent messages. Remove that profile
in **System Settings > General > Device Management** before adding the native
Exchange account. Profile removal also removes the account and all services it
manages, so setup does not automate this migration.

For migration from an older combined managed profile, the standalone personal
profile preserves that profile's identity. Keep the combined profile installed,
review the generated replacement, then run
`scripts/finish-setup --update-profiles` so macOS can process it as an explicit
update. Install any other desired standalone IMAP/DAV profiles afterward. If
macOS refuses, verify that affected accounts contain no local-only mail or
unsent messages before removing the combined profile and installing the desired
standalone profiles. Removing the combined profile also removes every account
it manages.

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

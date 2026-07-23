# Mac Setup

A repeatable Apple Silicon macOS baseline built with Determinate Nix, nix-darwin, Home Manager, Homebrew, and the Mac App Store.

The repository is intentionally public and contains no private personal identity, email address, signing key, private hostname, credentials, or private repository URLs. Its public GitHub locator is the sole account identifier required for bootstrap; Git records the desired machine configuration while 1Password and data-sync systems restore private state.

The public `main` branch must contain only the sanitized history verified by
`scripts/check-history-safety origin/main`. See
[docs/public-release.md](docs/public-release.md) for the limits of history
replacement: old clones and GitHub's unreachable-object caches can outlive a
force-push.

Chezmoi is not used.

## What this restores

- macOS defaults, Fish, Git policy, SSH client defaults, tmux, Otty settings,
  and editable Zed starter settings
- pinned Nix inputs and a curated CLI toolchain
- GUI applications and MAS applications grouped into composable profiles
- a generic development and project directory structure
- pinned Filen Menubar and standalone Filen CLI releases, plus login startup
- separate, optional, password-free configuration profiles for IMAP and selected
  CalDAV/CardDAV services, plus guided native Microsoft 365 account setup from
  private metadata in 1Password
- a removable public profile that disables iCloud Mail, Calendar, and Contacts without affecting other iCloud services
- helper scripts for validation, Git SSH signing, GPG/config backup and restore, and private repository restoration

It does not try to copy caches, logs, browser sessions, private repositories, credentials, Apple privacy approvals, or application databases into Git.

## Architecture

```text
flake.nix                 Pinned flake and the mini output
hosts/mini/               Physical machine composition
profiles/                 Base, development, desktop, personal, work, gaming
modules/darwin/           Nix, Homebrew policy, system defaults
modules/home/             Shell, Git, SSH, terminal, editor, packages
configuration-profiles/   Public, removable macOS policy profiles
scripts/                  Bootstrap, validation, private-state helpers
docs/                     Restore and maintenance runbooks
.local/config.json        Generated host metadata; ignored and excluded from flake sources
.local/bootstrap-revision Generated commit record for restore verification; ignored
$HOME/Library/Application Support/mac-setup/
                          Private account metadata and generated IMAP/DAV profiles
```

The `mini` host composes all currently selected profiles. Homebrew cleanup, auto-update, and upgrade are disabled during activation; package removal is always a separate reviewed operation.

## Fresh-machine bootstrap

The bootstrap defaults to build-only. Use the full SHA of a tested commit rather than a moving branch. This runbook currently targets the configuration tested at `42d0a1e9dcb10549d5c2dd4b9ad4d35023d99084`:

Always copy this bootstrap block from the current public `main` README, not from
a previously pinned local checkout: a commit cannot contain its own future SHA.
Setup records the commit actually used in ignored
`.local/bootstrap-revision`, which is authoritative for that run and avoids a
self-referential verification pin.

```bash
revision='42d0a1e9dcb10549d5c2dd4b9ad4d35023d99084'
/usr/bin/curl -qfsSL --proto '=https' --tlsv1.2 \
  "https://raw.githubusercontent.com/philippgerard/mac-setup/${revision}/setup.sh" \
  | /bin/bash -p -s -- --revision "$revision"
```

On the initial clone, the SHA selects both the downloaded bootstrap script and
the repository revision it checks out. A pre-existing checkout is never changed
automatically. When `--revision` is explicit, its current `HEAD` must match that
revision and its tracked files/index must be clean, or setup exits; inspect and
update the checkout yourself first. Untracked files do not affect this pin
check, but the filtered Nix source excludes them. A direct
`./setup.sh --provision` without an explicit revision deliberately uses the
existing checkout as-is. If macOS opens the Command Line Tools installer,
complete it and then rerun the same block; `setup.sh` intentionally exits after
requesting the tools.

The script:

1. verifies macOS and Apple Silicon;
2. installs Command Line Tools, Homebrew, and Determinate Nix when absent;
3. clones the public repository without silently pulling an existing checkout;
4. creates ignored local account metadata;
5. runs public-safety and syntax checks;
6. builds `darwinConfigurations.mini.system` without activating it.

The full Xcode app is not installed by this setup; install it from the App Store
only when needed. The smaller Command Line Tools remain a bootstrap prerequisite.
Setup deliberately does not execute an application from the user-modifiable
`/Applications` directory during privileged activation. After installing Xcode,
review it and complete Apple's first-launch and license steps manually before a
Homebrew run that needs them:

```bash
sudo /usr/bin/xcodebuild -runFirstLaunch
```

On Apple Silicon activation installs Rosetta 2 when absent, which is required
by Intel-only vendor packages such as SecureSafe. Rosetta installation does not
run during a build.

Home Manager preserves a pre-existing file that it needs to manage by appending
`.before-home-manager` rather than overwriting it. Activation fails safely if
that backup path already exists, so backups are never replaced implicitly.

Before activation, open the App Store and sign in. Homebrew Bundle cannot install
the declared Mac App Store applications on a fresh Mac without that session.
After reviewing the build and package changes, complete the regular fresh-Mac
flow with one guided command:

```bash
~/.config/mac-setup/setup.sh --provision
```

`--provision` activates the system, authenticates the selected 1Password
account, restores Git identity, restores only `personal-mail` by default,
serializes the required iCloud and IMAP/DAV profile approvals, restores legacy
GPG state and Filen configuration, authenticates the Nix-managed Filen CLI, and
opens Filen Menubar. A selected Microsoft 365 account instead uses the native
Internet Accounts setup after reporting whether Microsoft's optional
organization-managed native-app broker is configured. That diagnostic is
advisory because neither vendor documents the exact authentication surface used
by every Internet Accounts flow. The command is resumable: rerun it if an
approval or sign-in is interrupted. It never sets up optional work or PEC
accounts unless they are selected explicitly.

When intentionally provisioning from a different existing checkout, keep using
that same directory explicitly:

```bash
./setup.sh --config-dir "$PWD" --provision
```

Options after `--` are passed to the private restore. For example, select a
specific 1Password account and vault with:

```bash
~/.config/mac-setup/setup.sh --provision -- \
  --op-account account-shorthand --vault 'Vault Name'
```

The equivalent environment variables are `MAC_SETUP_1PASSWORD_ACCOUNT` and
`MAC_SETUP_1PASSWORD_VAULT`. An explicit account selection is never inferred
from unrelated ambient `OP_*` variables: private helpers clear inherited CLI
sessions, service-account and Connect credentials, default vaults, and custom
config directories before applying only the explicit selection.

Use `--apply` instead when only the public base configuration should be
activated. After a base-only activation, the private restore can be run later
with `scripts/finish-setup`.

On the first activation, Home Manager may stop at
`checkAppManagementPermission`. Open **System Settings > Privacy & Security >
App Management**, enable the terminal emulator that launched setup, then quit
and reopen that terminal and rerun the same `--provision` command. The failed
activation stops before Home Manager changes user files, so the rerun is safe.
This privacy approval is intentionally not bypassed.

Local Nix commands first create an immutable, Git-aware source with
`scripts/flake-source`. It copies working-tree files only for paths already
listed in the Git index and categorically rejects `.local` plus every
case-insensitive spelling of that private path. The public-safety gate scans
regular and binary content, filenames, and live symlink targets in both the
working and staged/index snapshots. Once a real staged tree change exists, its
raw bytes, types, and executable modes must match the working tree exactly, so
a corrected working copy cannot hide a bad staged commit. Intent-to-add files
remain available for iterative work. Before validating a new public file, mark
it for addition with `git add -N <path>` or stage it.

The filtered source is first copied to a mode-`0700` temporary directory and
scanned there with Gitleaks. Only a passing copy enters the world-readable Nix
store. If validation tools are missing, they are obtained directly from the
exact Nixpkgs revision and hash in `flake.lock`; the local checkout is not used
to bootstrap that shell. Arbitrary untracked or ignored private state therefore
cannot enter a flake source. The minimal host config is read explicitly from
`.local/config.json` during an impure local evaluation; pure checks use
`local.example.nix`. Before a local build, its exact three-field schema and its
username, home directory, and host values are checked against the current Mac.
Build and activation then share one permission-restricted validated snapshot,
so an old or malformed local file cannot silently target another account.

## Private Git identity and SSH signing

Git policy is public, but identity is not. Create a uniquely named 1Password item called `Mac Setup Git Identity` with these fields:

- `name`
- `email`
- `signing_key` containing the complete SSH public key managed by the 1Password SSH agent
- `public_name` exactly matching the owner segment of this public repository's
  GitHub URL
- `public_email` containing this repository owner's GitHub noreply address, in
  either the owner-only or standard numeric-ID-plus-owner form
- `public_signing_key` containing the public-repository SSH signing key

Then enable the 1Password CLI and SSH agent and run:

```bash
scripts/configure-git-identity
```

The helper writes private identity, public-repository identity, and
`allowed_signers` files with mode `0600`. None is managed by Nix or Git.
Conditional Git includes use the repository-owner identity for this public
repository. Git commits and tags are signed through
`/Applications/1Password.app/Contents/MacOS/op-ssh-sign`.

Use a different item, vault, or full secret reference without editing the repository:

```bash
MAC_SETUP_GIT_IDENTITY_ITEM='Other Item' scripts/configure-git-identity
MAC_SETUP_1PASSWORD_VAULT='Vault Name' scripts/configure-git-identity
MAC_SETUP_GIT_IDENTITY_REF='op://Vault/Item' scripts/configure-git-identity
```

## GPG backup in 1Password

OpenPGP is retained for legacy keys and decryption, not Git signing. Back up every local secret key and ownertrust into 1Password without writing a plaintext export to disk:

```bash
scripts/backup-gpg-to-1password
```

The command upserts and verifies two documents in the account's default vault. Set `MAC_SETUP_1PASSWORD_VAULT` to target another vault. Restore them on a new Mac with:

```bash
scripts/restore-gpg-from-1password
```

See [docs/private-state.md](docs/private-state.md) for the complete boundary and verification steps.

## Mail, Calendar, Reminders, and Contacts recovery

The regular `setup.sh --provision` flow performs this recovery and selects only
`personal-mail` by default. The commands below are the manual and
troubleshooting interface.

The first explicit `--mail-account` replaces that default rather than adding to
it. Repeat the option for every account wanted on the Mac. `--mail-profile`
remains a compatibility alias:

```bash
# Personal plus work
~/.config/mac-setup/setup.sh --provision -- \
  --mail-account personal-mail --mail-account work-mail

# Work only
~/.config/mac-setup/setup.sh --provision -- --mail-account work-mail
```

Mail addresses, login names, server settings, account types, and stable
identifiers are private. Their canonical local copy is
`~/Library/Application Support/mac-setup/mail-accounts.json`, outside the Git
checkout and every flake source. It deliberately contains no passwords or OAuth
tokens; keep email and DAV app passwords in separate 1Password Login items.
Microsoft 365 metadata is also retained there and in 1Password, but its
credentials and OAuth tokens remain with Microsoft's and macOS's authentication
infrastructure.

### Back up account metadata

After creating or changing the local metadata, validate it, regenerate the
derived IMAP/DAV profiles, and back up the JSON to the
`Mac Setup Mail Accounts` 1Password Document:

```bash
scripts/validate-mail-accounts-config
scripts/generate-mail-account-profiles
op signin
scripts/backup-mail-accounts-to-1password
```

The backup helper creates or updates the document, downloads it again, and
compares its SHA-256 digest with the local file. Do not consider the backup
complete unless it prints `backed up and verified in 1Password`. The helper
fails closed on a 1Password lookup error or duplicate exact document titles;
select an explicit vault or resolve duplicates before retrying.

### Restore accounts on a fresh Mac

After a base-only `setup.sh --apply`, sign in to the 1Password app and enable
its CLI integration. Then run:

```bash
op signin
scripts/restore-mail-accounts-from-1password
```

The restore helper:

1. downloads and validates the private JSON;
2. preserves a different local copy with a `pre-restore` timestamp;
3. writes the JSON with mode `0600` and generates one password-free
   `.mobileconfig` per IMAP/DAV account below
   `~/Library/Application Support/mac-setup/mail-profiles/`; and
4. opens that directory by default for manual profile installation.

For each selected IMAP/DAV account, the guided flow presents its generated
profile for review. When installing one manually:

1. open the `.mobileconfig` file;
2. review and install it in **System Settings > General > Device Management**;
3. enter each requested email or DAV app password; and
4. verify every service included in that profile.

macOS may label each IMAP account's single prompt as an **SMTP password**. The
profile explicitly tells macOS to use that same credential for both incoming
IMAP and outgoing SMTP, so do not expect a second IMAP-labelled prompt.

An account can optionally include CalDAV and CardDAV payloads in the same
profile. CalDAV supplies Calendar and can expose VTODO task lists to Reminders;
CardDAV supplies Contacts. There is no separate Reminders payload. macOS may ask
for the CalDAV and CardDAV password separately even when both use the same
credential. For Mailbox.org, create an application password using the
**Calendar and address book client (CalDAV/CardDAV)** preset and enter it for
both DAV prompts. Verify Reminders after installation because it appears only
when the server advertises a compatible task service, and advanced or recurring
task features may not map perfectly between providers.

Each installed IMAP/DAV profile owns only its account bundle. It can be installed
or removed independently, but removing it also removes every managed service in
that profile. Do not delete a profile merely to troubleshoot an individual
service.

An `exchange_oauth` account deliberately does not produce or install a managed
Exchange profile. The guided flow opens **System Settings > Internet Accounts >
Add Account > Microsoft Exchange** instead. Before opening it, setup reports
whether this Mac has Microsoft's Company Portal broker prerequisites; their
absence produces guidance but does not block the native attempt.

Apple Internet Accounts is a native app authentication surface, not an ordinary
Safari session, and neither Apple nor Microsoft guarantees FIDO2 parity for
this flow. Microsoft documents the current Company Portal, MDM enrollment, and
an organization-deployed Enterprise SSO configuration as its broker path for
native macOS apps. Installing Company Portal alone does not activate that
broker, so this repository does not install or enroll it automatically. Its
absence is a useful clue, not proof that Apple Internet Accounts cannot use a
system authentication session. Outlook and other Microsoft applications can
also support passkeys through their own authentication stack.

The decisive first test is the registered key in a private Safari or Chrome
window. At the Microsoft sign-in page, choose **Sign-in options > Face,
fingerprint, PIN, or security key** before entering a password. If the key works
there but Internet Accounts offers only Authenticator number matching, cancel
the native flow and ask the organization's administrator to inspect the exact
sign-in, client, authentication method, and Conditional Access result. An
organization-managed Microsoft SSO broker is one possible remediation, not
something this repository can infer. If the security-key choice is absent in
the browser too, review
[Security info](https://mysignins.microsoft.com/security-info) and ask the
administrator to verify the account's passkey registration, authentication
method policy, and Conditional Access result.

A YubiKey used for PIV/certificate authentication is a different method. Its
Microsoft prompt is **Use a certificate or smart card**, and the organization
must provision the certificate and enable Microsoft Entra certificate-based
authentication. Do not reset or reprovision a key merely to troubleshoot this
setup.

The advisory broker check follows Microsoft's
[passkey compatibility matrix](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-fido2-compatibility)
and
[Enterprise SSO plug-in requirements](https://learn.microsoft.com/en-us/entra/identity-platform/apple-sso-plugin).

There is also a time-sensitive compatibility risk. As of July 2026,
[Apple documents macOS Exchange integration as using EWS](https://support.apple.com/guide/deployment/integrate-with-microsoft-exchange-dep158966b23/web),
while Microsoft plans to
[start disabling EWS in Exchange Online in October 2026 and finish in April 2027](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/deprecation-of-ews-exchange-online).
Until Apple or Microsoft documents a replacement for this client path, treat
native Exchange in Mail, Calendar, Contacts, and Reminders as transitional and
keep Outlook or the web applications as a fallback.

If an older setup installed a managed Exchange profile, first verify that the
account has no local-only mail or unsent messages. Remove that old profile in
**System Settings > General > Device Management** before adding the native
Exchange account. Removing it also removes the account and services it manages,
so this migration is intentionally not automated.

### Migrate from the older combined profile

The standalone personal profile preserves the identity of the older combined
profile. Install it first while the combined profile is still present so macOS
can treat it as an update. This replaces the combined profile with the selected
personal Mail/DAV service bundle. Install other desired IMAP/DAV profiles
afterward, and add any Microsoft 365 account through the native Internet
Accounts flow described above.

The guided restore stops when it detects the older payload rather than silently
presenting a replacement. After reviewing the generated profile, explicitly
allow the update:

```bash
~/.config/mac-setup/setup.sh --provision -- --update-profiles
```

The same flag is required whenever an installed iCloud or IMAP/DAV profile has
the same identity but different effective settings.

If macOS refuses the update, first verify that no affected account contains
local-only mail or unsent messages. Then remove the combined profile and install
only the standalone profiles wanted on that Mac. Removing the combined profile
also removes every account it manages, so do not use this fallback until that
mail check is complete.

Use `scripts/restore-mail-accounts-from-1password --no-open` when only the local
files should be regenerated. The schema validator rejects unknown keys,
including accidental password fields.

Older revisions placed these files below the checkout's ignored `.local/`
directory. Current Nix commands exclude that entire directory even when those
legacy copies remain. After the external copy has been restored and verified,
review and remove only the legacy `.local/mail-accounts.json` and
`.local/mail-profiles/` copies. Keep `.local/config.json`: local builds still
require that host metadata. Setup never deletes private state.
Do not run Nix directly against `path:` followed by the raw checkout, because
that bypasses the source filter. Nix-store source copies created by older runs
can persist until a separately reviewed garbage collection; setup does not
remove them automatically.

## Disable selected iCloud services

Apple exposes iCloud Mail, Calendar, and Contacts as independent restrictions.
The public, credential-free profile in
`configuration-profiles/disable-icloud-mail-calendar-contacts.mobileconfig`
sets exactly those three services to unavailable for the current user. It does
not restrict iCloud Drive, Keychain, Photos, Notes, Find My, Reminders, or any
Mailbox.org service.

During `setup.sh --provision`, the guided restore validates this profile, opens
it only when its exact effective content is not already installed, waits for its
approval, and verifies the result before configuring the selected account. A
base-only `setup.sh --apply` also opens it when missing. Review and install it
in **System Settings > General > Device Management**.

To open it manually, or to present an updated copy again, run:

```bash
scripts/open-icloud-service-restrictions-profile
```

Apple requires this manual approval on an unmanaged Mac; setup does not attempt
an unsupported silent installation.

This is an enforced restriction rather than a one-time default. While the
profile is installed, the three iCloud services remain disabled and their
toggles cannot be used to turn them back on. Remove the standalone profile in
Device Management whenever those services should become available again.

## Otty

Home Manager seeds `~/.config/otty/config.toml` as a normal user-owned file on
the first activation. It is intentionally not a Nix-store symlink: Otty writes
theme, color, font, and layout changes directly to this file. Later activations
leave those appearance choices untouched, update only the shell command, and
normalize the repeatable `SHELL` environment entry to one Fish value.

This makes Otty settings editable and persistent across configuration rebuilds,
but the resulting file is private mutable state rather than a Git-managed
dotfile. Quit and reopen Otty once after migrating from an older activation.

## Zed

Home Manager seeds `~/.config/zed/settings.json` as a normal user-owned file on
the first activation. Zed can then save changes made through its Settings UI,
including extension and theme preferences. Later activations preserve that
file instead of replacing it with an immutable Nix-store link.

Zed's installed extensions and other runtime state remain in its normal
user-writable directory below `~/Library/Application Support/Zed`. The live
settings file is private mutable state and is intentionally not copied into
Git. When migrating from the older managed link, review
`~/.config/zed/settings.json.before-home-manager` and merge only wanted,
non-secret settings into the new writable file. Quit and reopen Zed afterward.

## Filen Menubar

The Apple Silicon app bundle is installed from a checksum-pinned GitHub release.
Its CLI dependency is the upstream-recommended stable release from the pinned
Nix package collection, built as a standalone Apple Silicon executable, so it
does not require Node or npm. Its launcher disables the CLI's self-updater
because version changes are reviewed in this repository and forces the modern
macOS state directory even if a legacy `~/.filen-cli` directory remains. Home
Manager copies a real, Spotlight-searchable bundle to
`~/Applications/Home Manager Apps/Filen Menubar.app`, and it starts at user
login.

Machines activated by an older revision may still have the former npm-global
copy. The generated Fish path deliberately keeps the pinned launcher in
`~/.local/bin` ahead of `fnm` globals, so the old package can remain without
being selected. After activating this revision, confirm `filen --version`
reports `v0.0.36`; then, if desired, review `type -a filen` and remove the
obsolete npm copy once:

```bash
fnm exec --using 24.18.0 npm uninstall --global @filen/cli
```

The live config contains private local and remote sync paths, so it is never stored in Git. Back it up from the old Mac and verify the 1Password document with:

```bash
scripts/backup-filen-menubar-to-1password
```

After signing in to 1Password on a new Mac, restore it with:

```bash
scripts/restore-filen-menubar-from-1password
open "$HOME/Applications/Home Manager Apps/Filen Menubar.app"
```

The generated `syncPairs.json` is derived from that config and does not need a
separate backup. The Filen CLI session is also excluded; the guided provisioner
authenticates it after each clean install and restricts its local state directory
and saved login to modes `0700` and `0600` respectively.

## Ordered restore verification

Run these checks after `setup.sh --provision` completes, or after the equivalent
base activation and manual restores. Start `/bin/bash`, then paste the complete
block; the parentheses keep a failed check from closing the parent shell.

```bash
(
  set -euo pipefail

  cd "$HOME/.config/mac-setup"
  expected_revision="$(<.local/bootstrap-revision)"
  [[ "$expected_revision" =~ ^[0-9a-f]{40}$ ]]
  test "$(/usr/bin/stat -f '%Lp' .local/bootstrap-revision)" = 600
  private_state_dir="$HOME/Library/Application Support/mac-setup"
  mail_config="$private_state_dir/mail-accounts.json"
  mail_profile_dir="$private_state_dir/mail-profiles"

  if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  # 1. Confirm the immutable checkout and public repository safety.
  test "$(git rev-parse HEAD)" = "$expected_revision"
  test -z "$(git status --porcelain)"
  scripts/validate
  scripts/check-history-safety HEAD
  filtered_source="$(scripts/flake-source)"
  test ! -e "$filtered_source/.local"

  # 2. Prove the configuration builds repeatedly and the package inventory is present.
  scripts/rebuild build
  scripts/rebuild build
  scripts/homebrew-dry-run
  brew list --versions mole
  mo --version

  # 3. Verify 1Password, SSH access, private files, and signed Git commits.
  export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  op account get >/dev/null
  ssh-add -L >/dev/null
  git ls-remote https://github.com/philippgerard/mac-setup.git HEAD >/dev/null

  for identity_file in identity.inc public-identity.inc allowed_signers; do
    identity_path="$HOME/.config/git/$identity_file"
    test -s "$identity_path"
    test "$(/usr/bin/stat -f '%Lp' "$identity_path")" = 600
  done
  git config --get user.email | grep -q '@users\.noreply\.github\.com$'
  test -n "$(git config --get user.signingKey)"
  test "$(/usr/bin/stat -f '%Lp' "$HOME/.ssh")" = 700
  test "$(/usr/bin/stat -f '%Lp' "$HOME/.ssh/config.d")" = 700
  while IFS= read -r -d '' private_ssh_host; do
    test -f "$private_ssh_host"
    test ! -L "$private_ssh_host"
    test "$(/usr/bin/stat -f '%Lp' "$private_ssh_host")" = 600
  done < <(find "$HOME/.ssh/config.d" -mindepth 1 -maxdepth 1 -print0)

  signing_test_repo="$(mktemp -d "${TMPDIR:-/tmp}/mac-setup-signing.XXXXXX")"
  git -C "$signing_test_repo" init -q
  git -C "$signing_test_repo" commit --allow-empty -S -m 'SSH signing verification' >/dev/null
  git -C "$signing_test_repo" verify-commit HEAD

  # 4. Verify the restored legacy GPG material.
  gpg --list-secret-keys --with-colons | grep -q '^sec:'
  gpg --list-secret-keys --keyid-format long
  gpgconf --list-dirs agent-socket >/dev/null

  # 5. Verify the private account metadata and generated password-free IMAP/DAV profiles.
  test -s "$mail_config"
  test "$(/usr/bin/stat -f '%Lp' "$mail_config")" = 600
  test -d "$mail_profile_dir"
  test "$(/usr/bin/stat -f '%Lp' "$mail_profile_dir")" = 700
  mail_profile_count="$(find "$mail_profile_dir" -maxdepth 1 -type f -name '*.mobileconfig' | wc -l | tr -d '[:space:]')"
  test "$mail_profile_count" -ge 1
  while IFS= read -r -d '' mail_profile; do
    test "$(/usr/bin/stat -f '%Lp' "$mail_profile")" = 600
    plutil -lint "$mail_profile" >/dev/null
  done < <(find "$mail_profile_dir" -maxdepth 1 -type f -name '*.mobileconfig' -print0)

  test "$(scripts/configuration-profile-state \
    configuration-profiles/disable-icloud-mail-calendar-contacts.mobileconfig)" = exact
  selected_profile_accounts=(personal-mail) # Include only selected IMAP/DAV account IDs.
  for profile_id in "${selected_profile_accounts[@]}"; do
    profile_file="$mail_profile_dir/$profile_id.mobileconfig"
    scripts/validate-mail-account-profile \
      "$profile_id" "$mail_config" "$profile_file" >/dev/null
    test "$(scripts/configuration-profile-state "$profile_file")" = exact
  done

  # 6. Verify GUI tools own writable configs rather than immutable Nix links.
  otty_config="$HOME/.config/otty/config.toml"
  test -f "$otty_config"
  test ! -L "$otty_config"
  test -w "$otty_config"
  zed_settings="$HOME/.config/zed/settings.json"
  test -f "$zed_settings"
  test ! -L "$zed_settings"
  test -w "$zed_settings"

  # 7. Verify the standalone Filen CLI and login agent.
  filen_config="$HOME/Library/Application Support/filen-menubar/config.json"
  test -s "$filen_config"
  test "$(/usr/bin/stat -f '%Lp' "$filen_config")" = 600
  filen --version | grep -q 'v0\.0\.36'
  test "$(/usr/bin/stat -f '%Lp' "$HOME/Library/Application Support/filen-cli")" = 700
  filen_credential="$HOME/Library/Application Support/filen-cli/.filen-cli-keep-me-logged-in"
  test ! -e "$filen_credential" || test "$(/usr/bin/stat -f '%Lp' "$filen_credential")" = 600
  test -d "$HOME/Applications/Home Manager Apps/Filen Menubar.app"
  test ! -L "$HOME/Applications/Home Manager Apps/Filen Menubar.app"
  launchctl print "gui/$(id -u)/org.nix-community.home.filen-menubar" >/dev/null
  test -d '/Applications/Microsoft Teams.app'

  # 8. Exercise the remaining command-line entry points.
  fnm --version
  pnpm --version
  test "$(erl -noshell -eval 'io:format("OTP ~s", [erlang:system_info(otp_release)]), halt().')" = 'OTP 29'
  elixir --version | grep -q 'Elixir 1\.20\.2'
  mix --version | grep -q 'Mix 1\.20\.2'
  cargo --version
  rustc --version
  rustfmt --version
  cargo clippy --version
  rust-analyzer --version
  gh --version
  gh auth status
  codex --version
  claude --version
  tmux -V
  ssh -V
  test "$(dscl . -read "/Users/$(id -un)" UserShell)" = 'UserShell: /run/current-system/sw/bin/fish'

  printf 'Automated restore verification passed.\n'
  printf 'The disposable signing-test repository is at %s\n' "$signing_test_repo"
)
```

Finally verify every installed Mail account can send and receive, each selected
CalDAV/CardDAV profile exposes the intended calendars, reminders, and contacts,
and every selected Microsoft account was added in Internet Accounts and
completed native OAuth with the required MFA method. Also verify Filen is
syncing the intended paths, representative repositories build, browser and
application sync has completed, and required macOS privacy permissions are
granted. Erlang
29 and Elixir 1.20 are provisioned declaratively for BEAM projects. The Rust
compiler, Cargo, formatter, Clippy, and rust-analyzer come from the same pinned
Nix package collection. Project Node versions remain selected through `fnm`; no
system Node package is installed.

## Normal operation

```bash
# Validate public safety, shell syntax, TOML, and Nix evaluation
scripts/validate

# Build without activation
scripts/rebuild build

# Build, then activate
scripts/rebuild switch

# Intentionally update flake.lock and build for review
scripts/update

# Compare the live Homebrew/MAS state without removing anything
scripts/homebrew-dry-run
```

`scripts/validate` automatically enters the pinned validation shell when the
active generation does not yet provide one of its required tools, so it also
works before the first activation of a newly added validator.

`topgrade` updates supported user tools and package managers, including pnpm.
It deliberately skips Nix, Home Manager, npm-global tools, and its own
self-update because those are repository- or project-managed; use
`scripts/update` for an intentional flake-lock update and build. pnpm 11 global
executables live below `$PNPM_HOME/bin`, which activation creates and Fish adds
to `PATH`; do not run `pnpm setup` to mutate shell configuration.

Do not run `brew bundle cleanup --force` or enable activation cleanup until a dry-run has been reviewed against the current machine.

## Wipe readiness

The Mac is ready to erase only after [docs/pre-wipe-checklist.md](docs/pre-wipe-checklist.md) is completely green. In particular:

- the committed `flake.lock` builds successfully;
- all local Git work exists remotely or in an independent archive;
- Time Machine has a browsable, restore-tested backup;
- PostgreSQL data that matters has a tested dump;
- SSH access, Git SSH signing, GPG and Mail documents, code-signing identities, and recovery codes are recoverable;
- the manual privacy/license checklist is recorded.

The reset sequence is documented in [docs/restore-runbook.md](docs/restore-runbook.md).

## Upstream documentation

- [Determinate Nix with nix-darwin](https://docs.determinate.systems/guides/nix-darwin/)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [Home Manager](https://nix-community.github.io/home-manager/)
- [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile)

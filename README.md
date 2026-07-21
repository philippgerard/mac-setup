# Mac Setup

A repeatable Apple Silicon macOS baseline built with Determinate Nix, nix-darwin, Home Manager, Homebrew, and the Mac App Store.

The repository is intentionally public and contains no private personal identity, email address, signing key, private hostname, credentials, or private repository URLs. Its public GitHub locator is the sole account identifier required for bootstrap; Git records the desired machine configuration while 1Password and data-sync systems restore private state.

The published `main` branch starts from a sanitized root commit. See [docs/public-release.md](docs/public-release.md) for the remaining limits of history replacement: old clones and GitHub's unreachable-object caches can outlive a force-push.

Chezmoi is not used.

## What this restores

- macOS defaults, Fish, Git policy, SSH client defaults, tmux, Otty, and Zed settings
- pinned Nix inputs and a curated CLI toolchain
- GUI applications and MAS applications grouped into composable profiles
- a generic development and project directory structure
- a pinned Filen Menubar release, its `fnm`-managed CLI dependency, and login startup
- helper scripts for validation, Git SSH signing, GPG/config backup and restore, and private repository restoration

It does not try to copy caches, logs, browser sessions, private repositories, credentials, Apple privacy approvals, or application databases into Git.

## Architecture

```text
flake.nix                 Pinned flake and the mini output
hosts/mini/               Physical machine composition
profiles/                 Base, development, desktop, personal, work, gaming
modules/darwin/           Nix, Homebrew policy, system defaults
modules/home/             Shell, Git, SSH, terminal, editor, packages
scripts/                  Bootstrap, validation, private-state helpers
docs/                     Restore and maintenance runbooks
.local/config.json        Generated private host metadata; ignored by Git
```

The `mini` host composes all currently selected profiles. Homebrew cleanup, auto-update, and upgrade are disabled during activation; package removal is always a separate reviewed operation.

## Fresh-machine bootstrap

The bootstrap defaults to build-only. Use the full SHA of a tested commit rather than a moving branch. This runbook currently targets the configuration tested at `42d0a1e9dcb10549d5c2dd4b9ad4d35023d99084`:

```bash
revision='42d0a1e9dcb10549d5c2dd4b9ad4d35023d99084'
curl -fsSL "https://raw.githubusercontent.com/philippgerard/mac-setup/${revision}/setup.sh" \
  | bash -s -- --revision "$revision"
```

The SHA selects both the downloaded bootstrap script and the repository revision it checks out. If macOS opens the Command Line Tools installer, complete it and then rerun the same block; `setup.sh` intentionally exits after requesting the tools.

The script:

1. verifies macOS and Apple Silicon;
2. installs Command Line Tools, Homebrew, and Determinate Nix when absent;
3. clones the public repository without silently pulling an existing checkout;
4. creates ignored local account metadata;
5. runs public-safety and syntax checks;
6. builds `darwinConfigurations.mini.system` without activating it.

Before Homebrew runs, activation completes Xcode's required first-launch setup
when Xcode is present, including license acceptance. On Apple Silicon it also
installs Rosetta 2 when absent, which is required by Intel-only vendor packages
such as SecureSafe. These apply-time prerequisites do not run during a build.

Home Manager preserves a pre-existing file that it needs to manage by appending
`.before-home-manager` rather than overwriting it. Activation fails safely if
that backup path already exists, so backups are never replaced implicitly.

After reviewing the result, activate explicitly:

```bash
~/.config/mac-setup/setup.sh --apply
```

All local builds use an explicit `path:` flake reference so the ignored `.local/config.json` is available without committing it.

## Private Git identity and SSH signing

Git policy is public, but identity is not. Create a uniquely named 1Password item called `Mac Setup Git Identity` with these fields:

- `name`
- `email`
- `signing_key` containing the complete SSH public key managed by the 1Password SSH agent
- `public_name` containing the pseudonymous public commit name
- `public_email` containing the GitHub noreply address for the public repository
- `public_signing_key` containing the public-repository SSH signing key

Then enable the 1Password CLI and SSH agent and run:

```bash
scripts/configure-git-identity
```

The helper writes private identity, public-repository identity, and `allowed_signers` files with mode `0600`. Neither is managed by Nix or Git. Conditional Git includes use the pseudonymous identity for this public repository. Git commits and tags are signed through `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`.

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

## Filen Menubar

The Apple Silicon app bundle is installed from a checksum-pinned GitHub release and starts at user login. Home Manager copies a real, Spotlight-searchable bundle to `~/Applications/Home Manager Apps/Filen Menubar.app`. Its Filen CLI dependency is isolated behind an `fnm` launcher using pinned Node 24 LTS during `setup.sh --apply`; no system Node package is used and the user's default Node version is left alone.

The live config contains private local and remote sync paths, so it is never stored in Git. Back it up from the old Mac and verify the 1Password document with:

```bash
scripts/backup-filen-menubar-to-1password
```

After signing in to 1Password on a new Mac, restore it with:

```bash
scripts/restore-filen-menubar-from-1password
open "$HOME/Applications/Home Manager Apps/Filen Menubar.app"
```

The generated `syncPairs.json` is derived from that config and does not need a separate backup. The Filen CLI session is also excluded; run `filen` once to authenticate after each clean install.

## Ordered restore verification

Run these checks after `setup.sh --apply`, 1Password sign-in, Git identity configuration, GPG restore, Filen Menubar config restore, and Filen CLI authentication. Start `/bin/bash`, then paste the complete block; the parentheses keep a failed check from closing the parent shell.

```bash
(
  set -euo pipefail

  expected_revision='42d0a1e9dcb10549d5c2dd4b9ad4d35023d99084'
  cd "$HOME/.config/mac-setup"

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
    test "$(stat -f '%Lp' "$identity_path")" = 600
  done
  git config --get user.email | grep -q '@users\.noreply\.github\.com$'
  test -n "$(git config --get user.signingKey)"

  signing_test_repo="$(mktemp -d "${TMPDIR:-/tmp}/mac-setup-signing.XXXXXX")"
  git -C "$signing_test_repo" init -q
  git -C "$signing_test_repo" commit --allow-empty -S -m 'SSH signing verification' >/dev/null
  git -C "$signing_test_repo" verify-commit HEAD

  # 4. Verify the restored legacy GPG material.
  gpg --list-secret-keys --with-colons | grep -q '^sec:'
  gpg --list-secret-keys --keyid-format long
  gpgconf --list-dirs agent-socket >/dev/null

  # 5. Verify Filen, its isolated Node runtime, and login agent.
  filen_config="$HOME/Library/Application Support/filen-menubar/config.json"
  test -s "$filen_config"
  test "$(stat -f '%Lp' "$filen_config")" = 600
  filen --version | grep -q 'v0\.0\.39'
  fnm exec --using 24.18.0 node --version | grep -q '^v24\.18\.0$'
  fnm exec --using 24.18.0 corepack --version >/dev/null
  test -d "$HOME/Applications/Home Manager Apps/Filen Menubar.app"
  test ! -L "$HOME/Applications/Home Manager Apps/Filen Menubar.app"
  launchctl print "gui/$(id -u)/org.nix-community.home.filen-menubar" >/dev/null

  # 6. Exercise the remaining command-line entry points.
  fnm --version
  pnpm --version
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

Finally verify Filen is syncing the intended paths, representative repositories build, browser and application sync has completed, and required macOS privacy permissions are granted. Project Node versions remain project-selected through `fnm`; no system Node package is installed.

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

Do not run `brew bundle cleanup --force` or enable activation cleanup until a dry-run has been reviewed against the current machine.

## Wipe readiness

The Mac is ready to erase only after [docs/pre-wipe-checklist.md](docs/pre-wipe-checklist.md) is completely green. In particular:

- the committed `flake.lock` builds successfully;
- all local Git work exists remotely or in an independent archive;
- Time Machine has a browsable, restore-tested backup;
- PostgreSQL data that matters has a tested dump;
- SSH access, Git SSH signing, GPG documents, code-signing identities, and recovery codes are recoverable;
- the manual privacy/license checklist is recorded.

The reset sequence is documented in [docs/restore-runbook.md](docs/restore-runbook.md).

## Upstream documentation

- [Determinate Nix with nix-darwin](https://docs.determinate.systems/guides/nix-darwin/)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [Home Manager](https://nix-community.github.io/home-manager/)
- [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile)

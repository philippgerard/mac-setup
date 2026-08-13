# Post-install verification

The complete block verifies the regular full restore: Git identity, GPG, the
default Mail/DAV account, Filen, and the configured application profiles. Run
it after `setup.sh --provision` completes, or after a base activation followed
by every equivalent manual restore.

If a component was intentionally skipped, omit its numbered section rather
than treating that expected absence as a failure. The
`selected_profile_accounts` value assumes `personal-mail`; change it to the
IMAP/DAV account IDs selected for this Mac.

Start `/bin/bash`, then paste the complete block. The parentheses keep a failed
check from closing the parent shell.

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
  GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null git ls-remote \
    https://github.com/philippgerard/mac-setup.git HEAD >/dev/null

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
  selected_profile_accounts=(personal-mail)
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
  filen --version
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
  pnpm bin -g
  topgrade --dry-run --only pnpm
  erl -noshell -eval 'io:format("OTP ~s~n", [erlang:system_info(otp_release)]), halt().'
  elixir --version
  mix --version
  cargo --version
  rustc --version
  rustfmt --version
  cargo clippy --version
  rust-analyzer --version
  gh --version
  gh auth status
  codex --version
  claude --version
  omc --version
  tmux -V
  ssh -V
  test "$(dscl . -read "/Users/$(id -un)" UserShell)" = 'UserShell: /run/current-system/sw/bin/fish'
  /usr/bin/arch -x86_64 /usr/bin/true

  printf 'Automated restore verification passed.\n'
  printf 'The disposable signing-test repository is at %s\n' "$signing_test_repo"
)
```

## Manual checks

The automated block confirms declared S/MIME certificate/private-key pairs are
present in the login keychain, but cannot prove certificate trust or Mail
decryption. Verify:

- every installed Mail account can send and receive;
- every S/MIME identity is in the login keychain, the current certificate is
  valid, and retained encrypted mail from every historical certificate period
  decrypts successfully;
- each selected CalDAV/CardDAV account exposes the intended calendars,
  reminders, and contacts;
- each selected Microsoft account completed native OAuth with the required MFA
  method and exposes only the wanted Apple services;
- Filen Menubar is syncing the intended local and remote paths;
- a signed Git commit succeeds with the intended identity;
- restored GPG fingerprints match the trusted backup;
- browser and application sync is complete;
- required macOS privacy permissions are granted; and
- representative personal and work repositories build successfully.

Erlang/Elixir and Rust are provisioned declaratively. Project Node versions
remain selected through `fnm`; restore the project-selected version before
testing `node`, `corepack`, and `pnpm`.

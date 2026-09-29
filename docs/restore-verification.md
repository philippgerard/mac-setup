# Post-install verification

## After a major macOS upgrade

- Run `scripts/validate`, `scripts/rebuild build`, and
  `scripts/homebrew-dry-run` before activation. Inspect the dependency diff.
- Confirm `xcrun --sdk macosx --show-sdk-version` and the selected compiler
  work; bootstrap now rejects an unusable SDK even when Git works.
- In System Settings > Menu Bar, verify Wi-Fi is hidden on the desktop profile,
  the system clock uses the compact analog style alongside Dato, and configure
  native app-item visibility. Thaw is intentionally no longer installed.
- Open a Finder window and a save sheet to assess animation behavior. The
  legacy window-animation preferences are best-effort app settings; their
  stored values do not prove that every macOS 27 application honours them.
- Launch Safari Technology Preview and check for its updates through Software
  Update. A missing Homebrew receipt does not mean the app bundle is absent.

## Read-only checks

After provisioning, run from the selected checkout:

```bash
scripts/doctor
scripts/doctor --json
```

The command reports PASS, FAIL, or SKIP for each check, includes a repair step
for failures, and returns nonzero when a selected check fails. It checks the
active generation's metadata, local host selectors, login shell, declared app
receipts, writable settings, file handlers, private-file permissions, selected
Mail profiles, and enabled development/Filen components. A receipt does not
prove an app still launches; the manual checks below remain necessary.

Match intentional omissions and account selection to the restore you performed:

```bash
scripts/doctor --skip gpg --skip filen
scripts/doctor --mail-account personal-mail --mail-account work-mail
scripts/doctor --only configs
```

Components are `system`, `apps`, `configs`, `git`, `ssh`, `gpg`, `mail`, `filen`,
and `development`. The first explicit Mail account replaces `personal-mail`.
Development and Filen checks use the active generation's selected features.
Before the first activation of a generation with metadata, the system check
fails and optional feature checks are skipped; that is not a complete restore.

Doctor performs no signing, authentication, restore, activation, or cleanup.
Git and GPG checks establish file presence and permissions, not key usability.
The account-profile check may create private temporary query files, which its
existing helper removes. It never imports identities or approves profiles.

## Interactive smoke checks

These checks can prompt, authenticate, start an agent, or create disposable
state, so they are deliberately separate from doctor. Run them in Bash after
restoring the components you intend to use:

```bash
op account get >/dev/null
ssh-add -L >/dev/null

git_test_dir="$(mktemp -d "${TMPDIR:-/tmp}/mac-setup-signing.XXXXXX")"
git -C "$git_test_dir" init -q
git -C "$git_test_dir" commit --allow-empty -S -m 'SSH signing verification'
git -C "$git_test_dir" verify-commit HEAD

gpg --list-secret-keys --keyid-format long
gpgconf --list-dirs agent-socket

gh auth status
omc --version
fnm --version
pnpm --version
pnpm bin -g
erl -noshell -eval 'io:format("OTP ~s~n", [erlang:system_info(otp_release)]), halt().'
elixir --version
mix --version
cargo --version
rustc --version
```

Compare GPG fingerprints with the trusted backup. Follow the S/MIME checks in
[Mail and account setup](mail-accounts.md); doctor does not prove certificate
trust, private-key usability, or decryption. Remove the disposable signing test
repository after inspecting its result.

For clean-install confidence, complete the separate
[disposable-Mac rehearsal](restore-rehearsal.md), including interrupted restore
and repeated activation. Keep its logs and private evidence outside Git.

## Manual checks

Verify the behavior of the restored applications and identities:

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

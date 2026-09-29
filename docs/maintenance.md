# Maintenance

Run these commands from the repository checkout.

## Validate, build, and activate

```bash
# Validate public safety, shell syntax, TOML, and Nix evaluation
scripts/validate

# Build without changing the live system
scripts/rebuild build

# Build and show package, closure-size, and Homebrew/MAS declaration changes
scripts/rebuild preview

# Build and activate
scripts/rebuild switch

# Update flake.lock, Filen Menubar, and OMC pins, then build for review
scripts/update

# Compare declared Homebrew/MAS state with the live Mac
scripts/homebrew-dry-run

# Read-only post-install checks (use --json for a machine-readable report)
scripts/doctor
```

`scripts/validate` enters the pinned validation shell automatically when the
active generation does not yet provide a required tool. It therefore also
works before the first activation of a newly added validator.

`scripts/rebuild preview` compares the candidate with `/run/current-system`.
Each new generation saves its Brewfile under `etc/mac-setup/`; when the active
generation predates this metadata, the first preview prints all candidate
declarations. This compares intended app selection, not vendor-managed GUI
application versions. The same built output can be inspected again with
`scripts/preview-system ./result` without repeating validation or the build.

`scripts/update` prepares all three pin files in a temporary, filtered candidate
checkout, then validates and builds it once. Only a successful candidate whose
original checkout and host selectors remain unchanged is promoted. Failed
downloads, hashing, or builds leave the working pins unchanged. Promotion saves
an ignored recovery journal and restores its own changes on a catchable failure.
An uncatchable interruption can leave `.local/update-recovery.*`; inspect its
`original/` and `candidate/` files before resuming. Concurrent edits are preserved.
Check that no update is active before removing a stale `.local/update.lock`.
If the pins were already staged, restage their reviewed changes to satisfy index
and working-tree parity. No updated pins are committed or activated automatically.

## Rollback and recovery

List generations before choosing a rollback:

```bash
sudo darwin-rebuild --list-generations
```

After reviewing the target, restore the previous generation with:

```bash
sudo darwin-rebuild --rollback
```

For a particular listed generation, use
`sudo darwin-rebuild --switch-generation NUMBER`. This runs that generation's
activation. It restores Nix-managed packages and configuration, but does not
reverse vendor app updates, Homebrew/MAS installations, seeded writable settings,
1Password restores, keychain imports, or manual profile approvals. Its Homebrew
activation may install missing apps declared by that older generation.
Do not garbage-collect the known-good generation until recovery is verified.
After rollback, diagnose the checkout before applying it again; rollback does
not change Git files or dependency pins.

If Fish or the normal terminal is unavailable, use Terminal.app with `/bin/zsh`
and invoke `/run/current-system/sw/bin/darwin-rebuild` explicitly.

## CI and restore rehearsal

The macOS Actions workflow runs `scripts/ci`: the repository suite and all flake
checks, including the complete public system build and profile-composition
assertions. It uses Apple Silicon macOS, a pinned Determinate installer action,
full Git history, and read-only repository permissions. It never activates or
requires private state. Run it locally with `scripts/ci` when changing CI checks.
The hosted build uses macOS 26; it does not certify macOS 27 GUI behavior.

Use the [disposable-Mac rehearsal](restore-rehearsal.md) for activation,
interruption/resume, vendor approvals, and repeated activation.

## Checkout location and shortcuts

Setup and successful switching record the selected checkout outside Git at
`~/Library/Application Support/mac-setup/checkout`. The `mac-setup` launcher and
Fish's `rebuild`, `update`, `fishconf`, and `nixconf` use this private record.
`MAC_SETUP_CONFIG_DIR` overrides it for one invocation; the default remains
`~/.config/mac-setup` when no record exists. Candidate builds never change it.

## Release pin review

`scripts/update` queries GitHub for Filen Menubar's latest published stable
release. When a newer version exists, it requires the expected Apple Silicon
DMG, verifies the downloaded bytes against GitHub's release-asset SHA-256
digest, and atomically updates the tracked version and Nix hash. An unchanged
version with different bytes is rejected rather than silently repinned.

Review `flake.lock`, `modules/home/filen-menubar-release.json`,
`modules/home/oh-my-claudecode-release.json`, and the package
diff before every activation. Do not run
`brew bundle cleanup --force` or enable activation cleanup until
`scripts/homebrew-dry-run` has been reviewed line by line. Omitted applications
remain installed until they are removed deliberately.

The Homebrew dry-run closes cleanup's standard input, because Homebrew 7 can
otherwise offer an interactive removal prompt without `--force`. An exit
status of 1 can mean undeclared installed software remains even when the
dependency check says everything is satisfied; read both sections. The helper
never accepts cleanup, and separately installed apps can remain intentional.

## Topgrade and Node tools

`topgrade` updates supported user tools and package managers, including pnpm.
It deliberately skips Nix, Home Manager, npm-global packages, and its own
self-update because those have repository or project owners. Use
`scripts/update` for Nix inputs. Docker/container image updates are also disabled.

pnpm global executables live below `$PNPM_HOME/bin`, which activation creates
and Fish adds to `PATH`. Do not run `pnpm setup`; it would mutate shell
configuration that this repository already owns.

Project Node versions are selected with `fnm`. No system Node package is
installed.

Oh My Claude Code is built from its pinned npm source and exposed as `omc` and
`oh-my-claudecode`; it does not depend on an `fnm`-managed Node installation or
the Claude Code marketplace. On first activation, Home Manager runs
`omc setup --quiet --no-plugin` only when Claude's configuration directory is
empty. The guard accepts a completed interactive setup or the complete npm
installation witness, so it does not run again on later activations or over an
existing OMC setup. Ambiguous or unrelated Claude state is left untouched and
reported for manual review because the terminal setup command has no preserve
mode.

`scripts/update` also refreshes OMC's GitHub source and npm dependency hashes.
To target a specific newer stable version independently, run
`scripts/update-oh-my-claudecode VERSION`, then `scripts/rebuild build`.
The updater refuses downgrades or changed bytes for an already-pinned version.
OMC 5.5's SQLite and Darwin filesystem addons are built for the Nix platform
and exercised during the package install check, alongside first-run setup and
the HUD. A successful build does not rerun setup on an existing Claude profile.

For a standalone npm setup, later activations only reconcile OMC-owned hook,
HUD, and Node runtime paths with the current Nix closure. This does not rerun
setup or replace user-authored Claude configuration, and it prevents old store
paths from breaking after Nix garbage collection.

Package updates do not force setup to run again. Invoke `omc setup` manually if
an upstream release explicitly requires a configuration refresh.

OMC runtime state below `.omc/` is globally ignored, except for
`.omc/skills/**`. That exception follows upstream's policy so repositories can
review and commit project-scoped OMC skills deliberately.

## Writable application settings

### Otty

Home Manager seeds `~/.config/otty/config.toml` as a normal user-owned file on
the first activation. Otty writes theme, color, font, and layout changes
directly to it. Later activations preserve those choices, update only the shell
command, and normalize the repeatable `SHELL` environment entry to Fish.

The file is private mutable state rather than a Git-managed dotfile. Quit and
reopen Otty once after migrating from an older activation.

### Zed

Home Manager seeds `~/.config/zed/settings.json` as a writable user-owned file
when it does not exist. Zed can then save settings, extension preferences, and
themes normally. Its installed extensions and runtime state stay below
`~/Library/Application Support/Zed`.

When migrating from the older managed link, review
`~/.config/zed/settings.json.before-home-manager` and merge only wanted,
non-secret settings into the writable file. Quit and reopen Zed afterward.

Do not copy a live editor or AI-agent configuration into Git without reviewing
it for tokens, private paths, and account identifiers.

## Filen

Filen Menubar is installed from a checksum-pinned Apple Silicon release.
`scripts/update` advances that pin to GitHub's latest stable release and builds
it without activation so the version and hash change remain reviewable. Home
Manager copies a real, Spotlight-searchable application bundle to
`~/Applications/Home Manager Apps/Filen Menubar.app` and starts it at login.

The signed application bundle contains the patched sync backend and its pinned
Node runtime. mac-setup does not install `pkgs.filen-cli`, a system Node
runtime, or a separate `filen` command. The backend cannot self-update; it is
updated only when the checksum-pinned Filen Menubar release changes. The app
copy validator also verifies the bundled Node helper, native keyring addon,
runtime SBOM, and license notices against the pinned application.

After activating this migration, verify that Home Manager removed the former
managed launcher:

```bash
test ! -e "$HOME/.local/bin/filen"
```

A separately installed npm-global `@filen/cli` may remain elsewhere in `PATH`,
but Filen Menubar neither discovers nor requires it. Remove it only after
confirming that no other workflow uses the command.

The bundled backend keeps a pre-existing legacy `~/.filen-cli` state directory
when one exists; otherwise it uses
`~/Library/Application Support/filen-cli`. On a clean install, authenticate
through Filen Menubar's in-app Login flow. The guided provisioner protects the
selected state directory with user-only permissions before launching the app.

Private Filen sync paths and login state are intentionally outside Git. See
[Private state](private-state.md#filen-menubar-config) for backup and restore.

## Application drift

Application selection and migration notes live in
[the application inventory](app-inventory.md). Homebrew activation cleanup
remains `none`; use the inventory and dry-run together when deciding whether an
old application should be removed.

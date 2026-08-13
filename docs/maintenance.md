# Maintenance

Run these commands from the repository checkout.

## Validate, build, and activate

```bash
# Validate public safety, shell syntax, TOML, and Nix evaluation
scripts/validate

# Build without changing the live system
scripts/rebuild build

# Build and activate
scripts/rebuild switch

# Update flake.lock and the Filen Menubar release pin, then build for review
scripts/update

# Compare declared Homebrew/MAS state with the live Mac
scripts/homebrew-dry-run
```

`scripts/validate` enters the pinned validation shell automatically when the
active generation does not yet provide a required tool. It therefore also
works before the first activation of a newly added validator.

`scripts/update` queries GitHub for Filen Menubar's latest published stable
release. When a newer version exists, it requires the expected Apple Silicon
DMG, verifies the downloaded bytes against GitHub's release-asset SHA-256
digest, and atomically updates the tracked version and Nix hash. An unchanged
version with different bytes is rejected rather than silently repinned.

Review `flake.lock`, `modules/home/filen-menubar-release.json`, and the package
diff before every activation. Do not run
`brew bundle cleanup --force` or enable activation cleanup until
`scripts/homebrew-dry-run` has been reviewed line by line. Omitted applications
remain installed until they are removed deliberately.

## Topgrade and Node tools

`topgrade` updates supported user tools and package managers, including pnpm.
It deliberately skips Nix, Home Manager, npm-global packages, and its own
self-update because those have repository or project owners. Use
`scripts/update` for Nix inputs.

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

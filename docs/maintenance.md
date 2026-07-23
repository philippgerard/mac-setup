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

# Intentionally update flake.lock and build the result for review
scripts/update

# Compare declared Homebrew/MAS state with the live Mac
scripts/homebrew-dry-run
```

`scripts/validate` enters the pinned validation shell automatically when the
active generation does not yet provide a required tool. It therefore also
works before the first activation of a newly added validator.

Review `flake.lock` and the package diff before every activation. Do not run
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

Filen Menubar is installed from a checksum-pinned Apple Silicon release. Home
Manager copies a real, Spotlight-searchable application bundle to
`~/Applications/Home Manager Apps/Filen Menubar.app` and starts it at login.

The Filen CLI comes from the pinned Nix package collection as a standalone
Apple Silicon executable. It does not need Node or npm, and its self-updater is
disabled so upgrades remain reviewed repository changes. The launcher selects
the protected modern macOS state directory even when a legacy
`~/.filen-cli` directory exists.

An older Mac may still have the former npm-global `@filen/cli`. After activation:

```bash
type -a filen
filen --version
```

The first result must be the pinned launcher in `~/.local/bin`. Once that is
confirmed, remove the obsolete npm-global package from the historical
fnm-managed Node version that installed it:

```bash
fnm exec --using 24.18.0 npm uninstall --global @filen/cli
```

If `fnm list` shows that the old global was installed under another Node
version, use that version instead.

Private Filen sync paths and login state are intentionally outside Git. See
[Private state](private-state.md#filen-menubar-config) for backup and restore.

## Application drift

Application selection and migration notes live in
[the application inventory](app-inventory.md). Homebrew activation cleanup
remains `none`; use the inventory and dry-run together when deciding whether an
old application should be removed.

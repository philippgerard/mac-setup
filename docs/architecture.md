# Architecture and bootstrap safety

This repository defines a public, repeatable macOS baseline. Git stores the
desired machine behavior; 1Password and application-specific sync systems
restore private state.

## Repository layout

```text
flake.nix                 Pinned flake and the mini output
hosts/mini/               Physical machine composition
profiles/                 Base, development, desktop, personal, work, gaming
modules/darwin/           Nix, Homebrew policy, system defaults
modules/home/             Shell, Git, SSH, terminal, editor, packages
configuration-profiles/   Public, removable macOS policy profiles
scripts/                  Bootstrap, validation, and private-state helpers
docs/                     Restore and maintenance runbooks
.local/config.json        Generated host metadata; ignored and source-excluded
.local/bootstrap-revision Generated bootstrap record; ignored and source-excluded
~/Library/Application Support/mac-setup/
                          Private account metadata and generated profiles
```

The `mini` host composes the currently selected profiles. Darwin modules own
system policy, Home Manager owns user tools and text configuration, and
Homebrew/MAS provide GUI and vendor applications. Homebrew cleanup, automatic
updates, and upgrades are disabled during activation; removal is always a
separate reviewed operation.

Chezmoi and other dotfile managers are intentionally not part of this design.

## Bootstrap model

The public README uses a full, tested Git commit rather than a moving branch.
That revision selects both the downloaded `setup.sh` and the repository tree
that the script checks out.

A commit cannot contain its own future SHA, so the README may be newer than the
configuration revision in its bootstrap block. Always copy the block from the
current public `main` README. Setup records the commit it actually used in the
ignored, mode-`0600` `.local/bootstrap-revision`; that file is authoritative
for the individual restore.

The default bootstrap is build-only:

1. verify macOS and Apple Silicon;
2. request the Command Line Tools when missing;
3. install Homebrew and Determinate Nix when missing;
4. create a transactional checkout at the requested revision;
5. generate ignored local host metadata;
6. run public-safety, syntax, and evaluation checks; and
7. build `darwinConfigurations.mini.system` without activating it.

The reviewed second run uses `setup.sh --provision` to activate the system and
start the guided private-state restore. `--apply` activates only the public base
and leaves `scripts/finish-setup` for later.

## Existing checkouts

Bootstrap never silently pulls, resets, or changes a pre-existing checkout.
With an explicit `--revision`, the checkout's `HEAD` must match that revision
and its tracked files and index must be clean. Untracked files do not affect the
pin check, but they are excluded from the Nix source.

A direct `./setup.sh --provision` without an explicit revision deliberately
uses the current checkout as-is. When working from a non-default directory, keep
selecting it explicitly:

```bash
./setup.sh --config-dir "$PWD" --provision
```

## Public source boundary

Private host selectors live in `.local/config.json`. The file contains exactly
the local username, home directory, and `mini` host selector. It is ignored,
excluded from every flake source, validated against the current Mac, and never
treated as a backup.

Local Nix commands use `scripts/flake-source` instead of evaluating the raw
checkout:

1. copy only paths already listed in the Git index;
2. categorically exclude every case-insensitive spelling of `.local`;
3. require staged and working-tree bytes, types, and executable modes to match
   once a real staged change exists;
4. place the candidate source in a mode-`0700` temporary directory;
5. scan it with the pinned Gitleaks tooling; and
6. allow only the passing copy to enter the world-readable Nix store.

The public-safety gate scans regular and binary content, filenames, live
symlink targets, and both working and index snapshots. Before validating a new
public file, mark it with `git add -N <path>` or stage it so the filtered source
can include it.

Validation tools come from the exact Nixpkgs revision and hash in `flake.lock`
when they are not already available. This prevents the unvalidated local
checkout from selecting its own scanner.

Do not run Nix directly against a raw `path:` checkout. That bypasses this
source filter. Nix-store copies from older runs may remain until a separately
reviewed garbage collection; setup never removes them automatically.

## Activation behavior

The full Xcode application is intentionally omitted. Install it from the App
Store only when needed. After reviewing an Xcode installation, complete its
first-launch and license steps before a Homebrew operation that requires them:

```bash
sudo /usr/bin/xcodebuild -runFirstLaunch
```

Home Manager preserves a pre-existing file that it needs to manage by adding
`.before-home-manager`. Activation stops rather than replacing an existing
backup with the same name.

macOS may require App Management permission for the terminal running Home
Manager. This approval is intentionally manual: enable it in System Settings,
quit and reopen the terminal, and rerun the same activation command.

Setup never executes a user-modifiable application from `/Applications` during
privileged activation.

## Upstream documentation

- [Determinate Nix with nix-darwin](https://docs.determinate.systems/guides/nix-darwin/)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [Home Manager](https://nix-community.github.io/home-manager/)
- [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile)

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

The public README downloads `setup.sh` from `main`, and setup checks out the
current `main` commit. This keeps the normal fresh-Mac path simple and current
for this owner-controlled repository. The raw script download and Git clone are
separate reads, so a push between them can put the running script and checkout
on different commits. That small moving-`main` window is accepted here. Setup
records the checkout's exact `HEAD` in the ignored, mode-`0600`
`.local/bootstrap-revision`; the record is an audit and verification aid, not
an argument required by later setup commands.

An explicit `--revision <git-ref>` remains available when deliberately
reproducing or rolling back to a branch, tag, or commit. It is optional and is
not part of the regular bootstrap or resume flow.

The default bootstrap is build-only:

1. verify macOS and Apple Silicon;
2. open the Command Line Tools installer when needed, wait for the tools, and
   continue in the same process;
3. create a transactional checkout at the current `main` commit, or at an
   explicitly requested revision;
4. install Homebrew interactively and install Determinate Nix when missing,
   then wait for the Nix daemon;
5. generate ignored local host metadata;
6. run public-safety, syntax, and evaluation checks; and
7. build `darwinConfigurations.mini.system` without activating it.

The streamed bootstrap keeps its own standard input separate from Homebrew's
prompts by attaching the installer to the controlling Terminal. Once the
checkout exists, prerequisite failures print a local resume command that keeps
the selected mode, forwarded options, and any non-default checkout path.

The reviewed second run uses `setup.sh --provision` from the existing checkout
to run one validation, build, and switch pass, then start the guided
private-state restore. It does not repeat the build-only pass first. `--apply`
activates only the public base and leaves `scripts/finish-setup` for later. An
activation error resumes with the printed setup command; after activation
succeeds, a private restore error resumes directly with the printed
`scripts/finish-setup` command.

## Existing checkouts

Bootstrap never silently pulls, resets, or changes a pre-existing checkout.
With an explicit `--revision`, the checkout's `HEAD` must match that revision
and its tracked files and index must be clean. Untracked files do not affect the
explicit-revision check, but they are excluded from the Nix source.

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
quit and reopen the terminal, and run the setup command printed with the error.

Setup never executes a user-modifiable application from `/Applications` during
privileged activation.

## Upstream documentation

- [Determinate Nix with nix-darwin](https://docs.determinate.systems/guides/nix-darwin/)
- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [Home Manager](https://nix-community.github.io/home-manager/)
- [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile)

#!/bin/bash

set -euo pipefail

REPO_URL="https://github.com/philippgerard/mac-setup.git"
CONFIG_DIR="${MAC_SETUP_CONFIG_DIR:-$HOME/.config/mac-setup}"
HOST="mini"
REVISION="${MAC_SETUP_REVISION:-main}"
APPLY=0

usage() {
  cat <<'EOF'
Usage: setup.sh [--apply] [--revision <git-ref>] [--config-dir <path>]

The default is safe: install prerequisites, create private local host metadata,
validate the repository, and build the mini configuration without activating it.

Options:
  --apply              Activate only after the build succeeds.
  --revision <git-ref> Clone a tested branch, tag, or commit (default: main).
  --config-dir <path>  Override the checkout directory.
  -h, --help           Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=1
      shift
      ;;
    --revision)
      [[ $# -ge 2 ]] || { echo "missing value for --revision" >&2; exit 2; }
      REVISION="$2"
      shift 2
      ;;
    --config-dir)
      [[ $# -ge 2 ]] || { echo "missing value for --config-dir" >&2; exit 2; }
      CONFIG_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

info() { printf '[INFO] %s\n' "$1"; }
die() { printf '[ERROR] %s\n' "$1" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || die "This bootstrap supports macOS only."
[[ "$(uname -m)" == "arm64" ]] || die "The mini configuration currently supports Apple Silicon only."

USERNAME="$(id -un)"
[[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "The local account name contains unsupported characters."
[[ "$HOST" =~ ^[a-zA-Z0-9-]+$ ]] || die "The hostname contains unsupported characters."

if ! xcode-select -p >/dev/null 2>&1; then
  info "Requesting Xcode Command Line Tools installation."
  xcode-select --install
  die "Complete the Command Line Tools installation, then rerun setup.sh."
fi

if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew from the official installer."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
command -v brew >/dev/null 2>&1 || die "Homebrew is not available on PATH."

if ! command -v nix >/dev/null 2>&1; then
  info "Installing Determinate Nix from the official installer."
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
fi

if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
command -v nix >/dev/null 2>&1 || die "Nix is not available on PATH. Restart the terminal and rerun setup.sh."

if [[ -e "$CONFIG_DIR" ]]; then
  [[ -d "$CONFIG_DIR/.git" ]] || die "The config path exists but is not a Git checkout: $CONFIG_DIR"
  info "Using the existing checkout without pulling or changing revisions."
else
  info "Cloning the public configuration repository."
  git clone "$REPO_URL" "$CONFIG_DIR"
  git -C "$CONFIG_DIR" checkout "$REVISION"
fi

LOCAL_DIR="$CONFIG_DIR/.local"
LOCAL_CONFIG="$LOCAL_DIR/config.json"
mkdir -p "$LOCAL_DIR"
chmod 700 "$LOCAL_DIR"

if [[ ! -f "$LOCAL_CONFIG" ]]; then
  umask 077
  plutil -create xml1 "$LOCAL_CONFIG"
  plutil -insert username -string "$USERNAME" "$LOCAL_CONFIG"
  plutil -insert homeDirectory -string "$HOME" "$LOCAL_CONFIG"
  plutil -insert hostName -string "$HOST" "$LOCAL_CONFIG"
  plutil -convert json "$LOCAL_CONFIG"
  chmod 600 "$LOCAL_CONFIG"
  info "Created private local host metadata outside Git tracking."
fi

"$CONFIG_DIR/scripts/validate"
"$CONFIG_DIR/scripts/rebuild" build

if [[ "$APPLY" -eq 1 ]]; then
  "$CONFIG_DIR/scripts/rebuild" switch
  "$CONFIG_DIR/scripts/install-filen-cli"
else
  info "Build succeeded. Re-run with --apply when the result has been reviewed."
fi

cat <<EOF

Private post-activation steps:
  1. Sign in to 1Password and enable its CLI and SSH agent.
  2. Run: $CONFIG_DIR/scripts/configure-git-identity
  3. Restore Filen Menubar config: $CONFIG_DIR/scripts/restore-filen-menubar-from-1password
  4. Run 'filen' once to authenticate the CLI, then reopen Filen Menubar.
  5. Restore legacy GPG keys with: $CONFIG_DIR/scripts/restore-gpg-from-1password

No name, email address, signing key, or private host configuration is stored in Git.
EOF

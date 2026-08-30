#!/bin/bash -p

set -euo pipefail

if [[ ! -o privileged ]]; then
  builtin printf '%s\n' \
    '[ERROR] Run setup.sh directly, or pipe it to /bin/bash -p; protected Bash mode is required.' >&2
  builtin exit 1
fi

# Protected mode ignores BASH_ENV, but inherited functions and an ambient PATH
# are still unnecessary inputs during a machine bootstrap.
while IFS= builtin read -r environment_entry; do
  case "$environment_entry" in
    BASH_FUNC_*%%=*)
      builtin printf '%s\n' \
        '[ERROR] Refusing an environment containing exported Bash functions.' >&2
      builtin exit 1
      ;;
  esac
done < <(/usr/bin/env)
while IFS= builtin read -r function_name; do
  builtin unset -f "$function_name"
done < <(builtin compgen -A function)
builtin unset BASH_ENV ENV CDPATH GLOBIGNORE || true
IFS=$' \t\n'
PATH="/usr/bin:/bin:/usr/sbin:/sbin"
export IFS PATH

REPO_URL="https://github.com/philippgerard/mac-setup.git"
CONFIG_DIR="${MAC_SETUP_CONFIG_DIR:-$HOME/.config/mac-setup}"
HOST="mini"
REVISION="main"
REVISION_EXPLICIT=0
if [[ -n "${MAC_SETUP_REVISION+x}" ]]; then
  REVISION="$MAC_SETUP_REVISION"
  REVISION_EXPLICIT=1
fi
APPLY=0
PROVISION=0
FINISH_SETUP_ARGS=()
TEST_CHECKOUT_ONLY="${MAC_SETUP_TEST_CHECKOUT_ONLY:-0}"
COMMAND_LINE_TOOLS_POLL_SECONDS=5
COMMAND_LINE_TOOLS_WAIT_SECONDS=7200
NIX_POLL_SECONDS=2
NIX_WAIT_SECONDS=60
CHECKOUT_READY=0

usage() {
  cat <<'EOF'
Usage: setup.sh [--apply|--provision] [--revision <git-ref>] [--config-dir <path>]
                [-- <finish-setup options>]

The default is safe: install prerequisites, create private local host metadata,
validate the repository, and build the mini configuration without activating it.

Options:
  --apply              Activate only after the build succeeds.
  --provision          Activate, then run the guided private-state restore.
                       Use this for the second, reviewed fresh-machine run.
  --revision <git-ref> Use a specific branch, tag, or commit (default: main).
  --config-dir <path>  Override the checkout directory.
  --                    Forward all remaining options to scripts/finish-setup.
                        This is valid only together with --provision.
                        Preview that step directly with
                        scripts/finish-setup --dry-run instead.
  -h, --help           Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=1
      shift
      ;;
    --provision)
      APPLY=1
      PROVISION=1
      shift
      ;;
    --revision)
      [[ $# -ge 2 ]] || { echo "missing value for --revision" >&2; exit 2; }
      REVISION="$2"
      REVISION_EXPLICIT=1
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
    --)
      shift
      FINISH_SETUP_ARGS=("$@")
      break
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "${#FINISH_SETUP_ARGS[@]}" -gt 0 && "$PROVISION" -ne 1 ]]; then
  echo "finish-setup options require --provision" >&2
  usage >&2
  exit 2
fi
if [[ "${#FINISH_SETUP_ARGS[@]}" -gt 0 ]]; then
  for finish_setup_argument in "${FINISH_SETUP_ARGS[@]}"; do
    if [[ "$finish_setup_argument" == "--dry-run" ]]; then
      echo "setup does not forward --dry-run after activation" >&2
      echo "preview the private restore directly with scripts/finish-setup --dry-run" >&2
      exit 2
    fi
  done
fi

info() { printf '[INFO] %s\n' "$1"; }

print_setup_command() {
  local requested_mode="${1:-current}"
  local argument

  printf '  %q' "$CONFIG_DIR/setup.sh"
  if [[ "$REVISION_EXPLICIT" -eq 1 ]]; then
    printf ' --revision %q' "$REVISION"
  fi
  if [[ "$CONFIG_DIR" != "$HOME/.config/mac-setup" ]]; then
    printf ' --config-dir %q' "$CONFIG_DIR"
  fi
  case "$requested_mode" in
    current)
      if [[ "$PROVISION" -eq 1 ]]; then
        printf ' --provision'
      elif [[ "$APPLY" -eq 1 ]]; then
        printf ' --apply'
      fi
      ;;
    provision) printf ' --provision' ;;
    apply) printf ' --apply' ;;
    build) ;;
    *) return 2 ;;
  esac
  if [[ "${#FINISH_SETUP_ARGS[@]}" -gt 0 && \
    "$requested_mode" != "build" && "$requested_mode" != "apply" ]]; then
    printf ' --'
    for argument in "${FINISH_SETUP_ARGS[@]}"; do
      printf ' %q' "$argument"
    done
  fi
  printf '\n'
}

print_finish_setup_command() {
  local argument

  printf '  %q' "$CONFIG_DIR/scripts/finish-setup"
  if [[ "${#FINISH_SETUP_ARGS[@]}" -gt 0 ]]; then
    for argument in "${FINISH_SETUP_ARGS[@]}"; do
      printf ' %q' "$argument"
    done
  fi
  printf '\n'
}

die() {
  printf '[ERROR] %s\n' "$1" >&2
  if [[ "$CHECKOUT_READY" -eq 1 ]]; then
    printf '%s\n' 'Resume safely with:' >&2
    print_setup_command current >&2
  fi
  exit 1
}

unexpected_failure() {
  local status="$1"

  trap - ERR
  printf '[ERROR] Setup stopped unexpectedly with status %s.\n' "$status" >&2
  printf '%s\n' 'Resume safely with:' >&2
  print_setup_command current >&2
  exit "$status"
}

safe_git() {
  /usr/bin/env -i \
    HOME="$HOME" \
    PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
    TMPDIR="${TMPDIR:-/tmp}" \
    LC_ALL=C \
    GIT_CONFIG_NOSYSTEM=1 \
    GIT_CONFIG_GLOBAL=/dev/null \
    GIT_NO_REPLACE_OBJECTS=1 \
    GIT_OPTIONAL_LOCKS=0 \
    GIT_PAGER=/usr/bin/cat \
    GIT_TERMINAL_PROMPT=0 \
    /usr/bin/git \
      -c core.fsmonitor=false \
      -c core.hooksPath=/dev/null \
      "$@"
}

[[ "$TEST_CHECKOUT_ONLY" == "0" || "$TEST_CHECKOUT_ONLY" == "1" ]] || \
  die "MAC_SETUP_TEST_CHECKOUT_ONLY must be 0 or 1."
[[ "$REVISION" =~ ^[a-zA-Z0-9][a-zA-Z0-9._/-]*$ && \
  "$REVISION" != *..* && "$REVISION" != */./* ]] || \
  die "The requested revision contains unsupported characters."

while [[ "$CONFIG_DIR" != "/" && "$CONFIG_DIR" == */ ]]; do
  CONFIG_DIR="${CONFIG_DIR%/}"
done

USER_ID="$(/usr/bin/id -u)"
HOME_MODE=""
[[ "$USER_ID" != "0" ]] || \
  die "Run setup.sh as the signed-in desktop user; it requests sudo internally when needed."
[[ -n "$HOME" && "$HOME" == /* && -d "$HOME" && ! -L "$HOME" && -O "$HOME" ]] || \
  die "HOME must be an owned, physical directory for the signed-in desktop user."
HOME_MODE="$(/usr/bin/stat -f '%Lp' "$HOME")"
[[ "$HOME_MODE" =~ ^[0-7]{3,4}$ && $((8#$HOME_MODE & 8#22)) -eq 0 ]] || \
  die "HOME must not be writable by group or other users."

checkout_is_exact_root() {
  local checkout_root
  local physical_config_dir

  [[ "$(safe_git -C "$CONFIG_DIR" rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]] || \
    return 1
  checkout_root="$(safe_git -C "$CONFIG_DIR" rev-parse --show-toplevel 2>/dev/null)" || \
    return 1
  physical_config_dir="$(cd "$CONFIG_DIR" && pwd -P)" || return 1
  checkout_root="$(cd "$checkout_root" && pwd -P)" || return 1
  [[ "$checkout_root" == "$physical_config_dir" ]]
}

fail_checkout_path() {
  local reason="$1"
  local relative_path="$2"

  builtin printf '%s: ' "$reason" >&2
  builtin printf '%q\n' "$relative_path" >&2
  return 1
}

verify_checkout_entries() {
  local ancestor_path
  local expected_mode
  local index_hash
  local index_mode
  local metadata
  local metadata_extra
  local object_type
  local record
  local relative_path
  local source_path
  local working_hash
  local working_permissions

  while IFS= builtin read -r -d '' record; do
    [[ "$record" == *$'\t'* ]] || {
      echo "Git returned an invalid checkout-tree entry" >&2
      return 1
    }
    metadata="${record%%$'\t'*}"
    relative_path="${record#*$'\t'}"
    index_mode=""
    object_type=""
    index_hash=""
    metadata_extra=""
    IFS=' ' builtin read -r \
      index_mode object_type index_hash metadata_extra <<<"$metadata"
    [[ "$index_mode" =~ ^(100644|100755|120000)$ && \
      "$object_type" == "blob" && "$index_hash" =~ ^[0-9a-f]{40}$ && \
      -z "$metadata_extra" ]] || {
      fail_checkout_path \
        "unsupported object type or mode in the pinned checkout" \
        "$relative_path"
      return 1
    }

    case "$relative_path" in
      ''|/*|..|../*|*/..|*/../*)
        fail_checkout_path \
          "Git returned an unsafe checkout-tree path" "$relative_path"
        return 1
        ;;
    esac

    source_path="$CONFIG_DIR/$relative_path"
    ancestor_path="$(/usr/bin/dirname "$source_path")"
    while [[ "$ancestor_path" != "$CONFIG_DIR" ]]; do
      [[ "$ancestor_path" == "$CONFIG_DIR"/* && \
        -d "$ancestor_path" && ! -L "$ancestor_path" ]] || {
        fail_checkout_path \
          "checkout path has a missing, non-directory, or symlinked ancestor" \
          "$relative_path"
        return 1
      }
      ancestor_path="$(/usr/bin/dirname "$ancestor_path")"
    done

    [[ -e "$source_path" || -L "$source_path" ]] || {
      fail_checkout_path \
        "pinned checkout path is missing from the working tree" "$relative_path"
      return 1
    }

    case "$index_mode:$object_type" in
      100644:blob|100755:blob)
        [[ -f "$source_path" && ! -L "$source_path" ]] || {
          fail_checkout_path \
            "pinned regular file has a different working-tree type" \
            "$relative_path"
          return 1
        }
        working_permissions="$(/usr/bin/stat -f '%Lp' -- "$source_path")" || {
          fail_checkout_path \
            "could not read pinned working-tree permissions" "$relative_path"
          return 1
        }
        [[ "$working_permissions" =~ ^[0-7]{3,4}$ ]] || {
          fail_checkout_path \
            "pinned working-tree permissions have an unexpected format" \
            "$relative_path"
          return 1
        }
        if (( (8#$working_permissions & 8#100) != 0 )); then
          expected_mode="100755"
        else
          expected_mode="100644"
        fi
        [[ "$index_mode" == "$expected_mode" ]] || {
          fail_checkout_path \
            "pinned executable mode differs from the working tree" \
            "$relative_path"
          return 1
        }
        working_hash="$(safe_git -C "$CONFIG_DIR" \
          hash-object --no-filters -- "$relative_path")" || {
          fail_checkout_path \
            "could not hash a pinned working-tree file" "$relative_path"
          return 1
        }
        ;;
      120000:blob)
        [[ -L "$source_path" ]] || {
          fail_checkout_path \
            "pinned symlink has a different working-tree type" "$relative_path"
          return 1
        }
        working_hash="$(
          /usr/bin/readlink -n -- "$source_path" |
            safe_git -C "$CONFIG_DIR" \
              hash-object --no-filters --stdin
        )" || {
          fail_checkout_path \
            "could not hash a pinned working-tree symlink" "$relative_path"
          return 1
        }
        ;;
      *)
        fail_checkout_path \
          "unsupported object type or mode in the pinned checkout" \
          "$relative_path"
        return 1
        ;;
    esac

    [[ "$working_hash" == "$index_hash" ]] || {
      fail_checkout_path \
        "pinned checkout bytes differ from the working tree" "$relative_path"
      return 1
    }
  done
}

verify_explicit_checkout() {
  local head_tree

  [[ -z "$(safe_git -C "$CONFIG_DIR" ls-files --unmerged)" ]] || {
    echo "The explicitly pinned checkout has unresolved index entries." >&2
    return 1
  }
  head_tree="$(safe_git -C "$CONFIG_DIR" \
    rev-parse --verify 'HEAD^{tree}')" || {
    echo "The explicitly pinned checkout has no valid HEAD tree." >&2
    return 1
  }
  [[ "$head_tree" =~ ^[0-9a-f]{40}$ ]] || {
    echo "The explicitly pinned checkout returned an invalid HEAD tree ID." >&2
    return 1
  }
  # Compare only the canonical tree and index. Unlike `git status` or
  # `git write-tree`, this cached comparison never needs to clean live files.
  # Explicitly disable external diff and textconv helpers from local config.
  safe_git -C "$CONFIG_DIR" diff-index \
    --cached \
    --quiet \
    --no-ext-diff \
    --no-textconv \
    "$head_tree" -- || {
    echo "The explicitly pinned checkout index differs from HEAD." >&2
    return 1
  }

  if ! safe_git -C "$CONFIG_DIR" ls-tree -r -z "$head_tree" |
    verify_checkout_entries; then
    echo "The explicitly pinned checkout differs from its canonical tree." >&2
    return 1
  fi
}

prepare_checkout_parent() {
  local checkout_parent="$1"
  local created_parent=0
  local parent_mode

  if [[ -e "$checkout_parent" || -L "$checkout_parent" ]]; then
    [[ -d "$checkout_parent" && ! -L "$checkout_parent" && -O "$checkout_parent" ]] || \
      die "The config parent is not a safe, user-owned directory: $checkout_parent"
  else
    umask 077
    # shellcheck disable=SC2174 # Only the final config parent requires mode 0700.
    /bin/mkdir -p -m 700 "$checkout_parent"
    created_parent=1
  fi

  [[ -d "$checkout_parent" && ! -L "$checkout_parent" && -O "$checkout_parent" ]] || \
    die "The config parent is not a safe, user-owned directory: $checkout_parent"
  parent_mode="$(/usr/bin/stat -f '%Lp' "$checkout_parent")"
  [[ "$parent_mode" =~ ^[0-7]{3,4}$ && $((8#$parent_mode & 8#22)) -eq 0 ]] || \
    die "The config parent must not be writable by group or other users: $checkout_parent"
  if [[ "$created_parent" -eq 1 && "$parent_mode" != "700" ]]; then
    die "A newly created config parent did not receive mode 0700: $checkout_parent"
  fi
}

clone_requested_revision() {
  local checkout_parent
  local checkout_tmp=""
  local expected_revision=""
  local actual_revision

  checkout_parent="$(/usr/bin/dirname "$CONFIG_DIR")"
  prepare_checkout_parent "$checkout_parent"
  umask 077
  checkout_tmp="$(/usr/bin/mktemp -d "$checkout_parent/.mac-setup-checkout.XXXXXX")"
  cleanup_checkout() {
    if [[ -n "${checkout_tmp:-}" && -d "$checkout_tmp" && ! -L "$checkout_tmp" && \
      "$checkout_tmp" == "$checkout_parent"/.mac-setup-checkout.* ]]; then
      /bin/rm -rf -- "$checkout_tmp" >/dev/null 2>&1 || true
    fi
  }
  trap cleanup_checkout EXIT

  info "Cloning the public configuration repository."
  safe_git clone --no-checkout "$REPO_URL" "$checkout_tmp"
  expected_revision="$(safe_git -C "$checkout_tmp" \
    rev-parse --verify "${REVISION}^{commit}" 2>/dev/null || true)"
  if [[ -z "$expected_revision" ]]; then
    expected_revision="$(safe_git -C "$checkout_tmp" \
      rev-parse --verify "refs/remotes/origin/${REVISION}^{commit}" 2>/dev/null || true)"
  fi
  [[ "$expected_revision" =~ ^[0-9a-f]{40}$ ]] || \
    die "The requested revision does not resolve to a commit: $REVISION"

  safe_git -c advice.detachedHead=false -C "$checkout_tmp" \
    checkout --detach "$expected_revision"
  actual_revision="$(safe_git -C "$checkout_tmp" rev-parse HEAD)"
  [[ "$actual_revision" == "$expected_revision" ]] || \
    die "The checked-out revision does not match the requested commit."

  [[ ! -e "$CONFIG_DIR" && ! -L "$CONFIG_DIR" ]] || \
    die "The config path appeared while the repository was being prepared: $CONFIG_DIR"
  /usr/bin/env -u DEVELOPER_DIR -u SDKROOT \
    /usr/bin/python3 -I -S - "$checkout_tmp" "$CONFIG_DIR" <<'PY'
import os
import sys

source, destination = sys.argv[1:]
if os.path.lexists(destination):
    raise SystemExit("destination appeared before transactional checkout publish")
os.rename(source, destination)
PY
  checkout_tmp=""
  trap - EXIT

  checkout_is_exact_root || \
    die "The published config path is not the expected Git checkout root: $CONFIG_DIR"
  [[ "$(safe_git -C "$CONFIG_DIR" rev-parse HEAD)" == "$expected_revision" ]] || \
    die "The published checkout no longer matches the requested commit."
}

ensure_config_checkout() {
  if [[ -e "$CONFIG_DIR" || -L "$CONFIG_DIR" ]]; then
    local checkout_mode
    local existing_expected_revision=""
    local existing_head
    prepare_checkout_parent "$(/usr/bin/dirname "$CONFIG_DIR")"
    [[ -d "$CONFIG_DIR" && ! -L "$CONFIG_DIR" && -O "$CONFIG_DIR" ]] || \
      die "The config path exists but is not a safe directory: $CONFIG_DIR"
    checkout_mode="$(/usr/bin/stat -f '%Lp' "$CONFIG_DIR")"
    [[ "$checkout_mode" =~ ^[0-7]{3,4}$ && \
      $((8#$checkout_mode & 8#22)) -eq 0 ]] || \
      die "The config checkout must not be writable by group or other users: $CONFIG_DIR"
    checkout_is_exact_root || \
      die "The config path exists but is not exactly a Git checkout root: $CONFIG_DIR"
    if [[ "$REVISION_EXPLICIT" -eq 1 ]]; then
      existing_expected_revision="$(safe_git -C "$CONFIG_DIR" \
        rev-parse --verify "${REVISION}^{commit}" 2>/dev/null || true)"
      if [[ -z "$existing_expected_revision" ]]; then
        existing_expected_revision="$(safe_git -C "$CONFIG_DIR" \
          rev-parse --verify "refs/remotes/origin/${REVISION}^{commit}" \
          2>/dev/null || true)"
      fi
      [[ "$existing_expected_revision" =~ ^[0-9a-f]{40}$ ]] || \
        die "The requested revision is not present in the existing checkout; update it manually first."
      existing_head="$(safe_git -C "$CONFIG_DIR" rev-parse HEAD)"
      [[ "$existing_head" == "$existing_expected_revision" ]] || \
        die "The existing checkout does not match the explicitly requested revision; it was left unchanged."
      verify_explicit_checkout || \
        die "The explicitly pinned checkout has tracked, index, type, or mode changes; it was left unchanged."
    fi
    info "Using the existing checkout without pulling or changing revisions."
  else
    clone_requested_revision
  fi
}

developer_tools_ready() {
  local developer_dir

  developer_dir="$(/usr/bin/xcode-select -p 2>/dev/null)" || return 1
  [[ "$developer_dir" == /* && -d "$developer_dir" ]] || return 1
  /usr/bin/xcrun --find git >/dev/null 2>&1
}

request_command_line_tools() {
  /usr/bin/xcode-select --install
}

graphical_session_ready() {
  [[ "$(/bin/launchctl managername 2>/dev/null)" == "Aqua" ]]
}

wait_for_command_line_tools_tick() {
  /bin/sleep "$COMMAND_LINE_TOOLS_POLL_SECONDS"
}

ensure_command_line_tools() {
  local request_status=0
  local waited_seconds=0

  if developer_tools_ready; then
    info "Command Line Tools are ready."
    return
  fi

  graphical_session_ready || \
    die "Command Line Tools installation requires a logged-in graphical macOS session. Open Terminal on the Mac and repeat the bootstrap command."

  info "Opening Apple's Command Line Tools installer."
  request_command_line_tools || request_status=$?
  if [[ "$request_status" -ne 0 ]]; then
    info "The installer may already be open; waiting for the tools to become ready."
  fi
  info "Finish the installer and leave Terminal open; setup will continue automatically."
  info "Press Control-C to stop if you cancel the installer."

  while ! developer_tools_ready; do
    if [[ "$waited_seconds" -ge "$COMMAND_LINE_TOOLS_WAIT_SECONDS" ]]; then
      die "Command Line Tools did not become ready within two hours. Repeat the same bootstrap command to resume."
    fi
    wait_for_command_line_tools_tick
    waited_seconds=$((waited_seconds + COMMAND_LINE_TOOLS_POLL_SECONDS))
  done

  info "Command Line Tools installation completed; continuing setup."
}

homebrew_ready() {
  [[ -x /opt/homebrew/bin/brew ]] && \
    /opt/homebrew/bin/brew --version >/dev/null 2>&1
}

install_homebrew() {
  local installer

  [[ -r /dev/tty && -w /dev/tty ]] || \
    die "Homebrew installation requires an interactive Terminal."
  info "Installing Homebrew from the official installer."
  installer="$(/usr/bin/curl -qfsSL --proto '=https' --tlsv1.2 \
    --retry 3 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || \
    die "Could not download the Homebrew installer."
  /usr/bin/env -i \
    HOME="$HOME" \
    USER="$USERNAME" \
    LOGNAME="$USERNAME" \
    PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
    TMPDIR=/tmp \
    TERM="${TERM:-dumb}" \
    SHELL=/bin/bash \
    INTERACTIVE=1 \
    /bin/bash -p -c "$installer" </dev/tty || \
    die "Homebrew installation did not complete."
}

ensure_homebrew() {
  if homebrew_ready; then
    info "Homebrew is ready."
    return
  fi

  install_homebrew
  homebrew_ready || \
    die "The Homebrew installer completed without a usable /opt/homebrew/bin/brew."
  info "Homebrew installation completed."
}

nix_launcher_present() {
  [[ -x "$NIX_LAUNCHER" ]]
}

trusted_nix_launcher() (
  # shellcheck source=scripts/trusted-nix
  source "$CONFIG_DIR/scripts/trusted-nix"
  mac_setup_trusted_nix
)

nix_ready() {
  local nix_bin

  nix_bin="$(trusted_nix_launcher 2>/dev/null)" || return 1
  "$nix_bin" store info --store daemon >/dev/null 2>&1
}

install_determinate_nix() {
  [[ -r /dev/tty && -w /dev/tty ]] || \
    die "Determinate Nix installation requires an interactive Terminal."
  info "Installing Determinate Nix from the official installer."
  if ! /usr/bin/curl -qfsSL --proto '=https' --tlsv1.2 \
    --retry 3 https://install.determinate.systems/nix | \
    /usr/bin/env -i \
      HOME="$HOME" \
      USER="$USERNAME" \
      LOGNAME="$USERNAME" \
      PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
      TMPDIR=/tmp \
      TERM="${TERM:-dumb}" \
      SHELL=/bin/sh \
      /bin/sh -s -- install --no-confirm; then
    die "Determinate Nix installation did not complete."
  fi
}

wait_for_nix_tick() {
  /bin/sleep "$NIX_POLL_SECONDS"
}

ensure_determinate_nix() {
  local waited_seconds=0

  if ! nix_launcher_present; then
    install_determinate_nix
  fi
  nix_launcher_present || \
    die "The Determinate installer completed without the expected Nix launcher."
  trusted_nix_launcher >/dev/null || \
    die "The Determinate Nix launcher failed its ownership, permission, or immutable-store checks."

  while ! nix_ready; do
    if [[ "$waited_seconds" -ge "$NIX_WAIT_SECONDS" ]]; then
      die "Determinate Nix is installed, but its daemon did not become ready within one minute. Run sudo /nix/nix-installer repair --no-confirm, then use the resume command below."
    fi
    if [[ "$waited_seconds" -eq 0 ]]; then
      info "Waiting for the Nix daemon to become ready."
    fi
    wait_for_nix_tick
    waited_seconds=$((waited_seconds + NIX_POLL_SECONDS))
  done
  info "Determinate Nix is ready."
}

if [[ "$TEST_CHECKOUT_ONLY" -eq 1 ]]; then
  [[ -n "${MAC_SETUP_TEST_REPO_URL:-}" ]] || \
    die "MAC_SETUP_TEST_REPO_URL is required in checkout test mode."
  REPO_URL="$MAC_SETUP_TEST_REPO_URL"
  ensure_config_checkout
  exit 0
fi

[[ "$(/usr/bin/uname -s)" == "Darwin" ]] || die "This bootstrap supports macOS only."
[[ "$(/usr/bin/uname -m)" == "arm64" ]] || die "The mini configuration currently supports Apple Silicon only."

USERNAME="$(/usr/bin/id -un)"
[[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "The local account name contains unsupported characters."
[[ "$HOST" =~ ^[a-zA-Z0-9-]+$ ]] || die "The hostname contains unsupported characters."

NIX_LAUNCHER="/nix/var/nix/profiles/default/bin/nix"

info "Step 1 of 5: checking Apple developer tools."
ensure_command_line_tools

info "Step 2 of 5: preparing the configuration checkout."
ensure_config_checkout
CHECKOUT_READY=1
trap 'unexpected_failure "$?"' ERR

info "Step 3 of 5: checking Homebrew."
ensure_homebrew

info "Step 4 of 5: checking Determinate Nix."
ensure_determinate_nix

LOCAL_DIR="$CONFIG_DIR/.local"
LOCAL_CONFIG="$LOCAL_DIR/config.json"
BOOTSTRAP_REVISION_FILE="$LOCAL_DIR/bootstrap-revision"
if [[ -e "$LOCAL_DIR" || -L "$LOCAL_DIR" ]]; then
  [[ -d "$LOCAL_DIR" && ! -L "$LOCAL_DIR" && -O "$LOCAL_DIR" ]] || \
    die "The private local metadata directory is unsafe: $LOCAL_DIR"
  /bin/chmod 700 "$LOCAL_DIR"
else
  /bin/mkdir -m 700 "$LOCAL_DIR"
fi

if [[ -e "$LOCAL_CONFIG" || -L "$LOCAL_CONFIG" ]]; then
  [[ -f "$LOCAL_CONFIG" && ! -L "$LOCAL_CONFIG" && -O "$LOCAL_CONFIG" ]] || \
    die "The private local host metadata file is unsafe: $LOCAL_CONFIG"
  /bin/chmod 600 "$LOCAL_CONFIG"
else
  umask 077
  local_config_tmp="$(/usr/bin/mktemp "$LOCAL_DIR/.config.json.XXXXXX")"
  cleanup_local_config() {
    if [[ -n "${local_config_tmp:-}" && -f "$local_config_tmp" && ! -L "$local_config_tmp" ]]; then
      /bin/rm -f -- "$local_config_tmp" >/dev/null 2>&1 || true
    fi
  }
  trap cleanup_local_config EXIT
  /usr/bin/plutil -create xml1 "$local_config_tmp"
  /usr/bin/plutil -insert username -string "$USERNAME" "$local_config_tmp"
  /usr/bin/plutil -insert homeDirectory -string "$HOME" "$local_config_tmp"
  /usr/bin/plutil -insert hostName -string "$HOST" "$local_config_tmp"
  /usr/bin/plutil -convert json "$local_config_tmp"
  /bin/chmod 600 "$local_config_tmp"
  /bin/mv "$local_config_tmp" "$LOCAL_CONFIG"
  local_config_tmp=""
  trap - EXIT
  info "Created private local host metadata outside Git tracking."
fi

"$CONFIG_DIR/scripts/validate-local-config" \
  "$LOCAL_CONFIG" "$USERNAME" "$HOME" "$HOST" >/dev/null || \
  die "The private local host metadata does not match this Mac."

if [[ -e "$BOOTSTRAP_REVISION_FILE" || -L "$BOOTSTRAP_REVISION_FILE" ]]; then
  [[ -f "$BOOTSTRAP_REVISION_FILE" && ! -L "$BOOTSTRAP_REVISION_FILE" && \
    -O "$BOOTSTRAP_REVISION_FILE" ]] || \
    die "The recorded bootstrap revision file is unsafe: $BOOTSTRAP_REVISION_FILE"
fi
bootstrap_revision="$(safe_git -C "$CONFIG_DIR" rev-parse HEAD)"
[[ "$bootstrap_revision" =~ ^[0-9a-f]{40}$ ]] || \
  die "The checkout did not report a full commit revision."
umask 077
bootstrap_revision_tmp="$(/usr/bin/mktemp "$LOCAL_DIR/.bootstrap-revision.XXXXXX")"
cleanup_bootstrap_revision() {
  if [[ -n "${bootstrap_revision_tmp:-}" && -f "$bootstrap_revision_tmp" && \
    ! -L "$bootstrap_revision_tmp" ]]; then
    /bin/rm -f -- "$bootstrap_revision_tmp" >/dev/null 2>&1 || true
  fi
}
trap cleanup_bootstrap_revision EXIT
printf '%s\n' "$bootstrap_revision" >"$bootstrap_revision_tmp"
/bin/chmod 600 "$bootstrap_revision_tmp"
/bin/mv "$bootstrap_revision_tmp" "$BOOTSTRAP_REVISION_FILE"
bootstrap_revision_tmp=""
trap - EXIT
if [[ "$REVISION_EXPLICIT" -eq 1 ]]; then
  REVISION="$bootstrap_revision"
fi

info "Step 5 of 5: validating and building the system configuration."
if [[ "$APPLY" -eq 1 ]]; then
  info "macOS may request App Management permission for this terminal; grant it, reopen the terminal, and rerun if activation stops."
  "$CONFIG_DIR/scripts/rebuild" switch || \
    die "The configuration did not activate completely."
  if [[ "$PROVISION" -eq 1 ]]; then
    info "Starting the guided private-state restore. If it stops, use the direct resume command setup prints."
    if [[ "${#FINISH_SETUP_ARGS[@]}" -gt 0 ]]; then
      if ! "$CONFIG_DIR/scripts/finish-setup" "${FINISH_SETUP_ARGS[@]}"; then
        printf '%s\n' \
          '[ERROR] Base activation completed, but the guided private-state restore stopped.' \
          'Resume only the private restore with:' >&2
        print_finish_setup_command >&2
        exit 1
      fi
    else
      if ! "$CONFIG_DIR/scripts/finish-setup"; then
        printf '%s\n' \
          '[ERROR] Base activation completed, but the guided private-state restore stopped.' \
          'Resume only the private restore with:' >&2
        print_finish_setup_command >&2
        exit 1
      fi
    fi
  else
    info "Opening the iCloud service restrictions profile when it is not already installed."
    "$CONFIG_DIR/scripts/open-icloud-service-restrictions-profile" --if-needed || \
      die "The base activated, but the iCloud restrictions profile could not be opened."
  fi
else
  "$CONFIG_DIR/scripts/rebuild" build || \
    die "The configuration did not build successfully."
  info "Build succeeded. After review, re-run with --provision for the regular fresh-machine flow."
fi

if [[ "$PROVISION" -eq 1 ]]; then
  cat <<'EOF'

Provisioning completed. Verify Mail/DAV and Filen sync, a signed Git commit,
and restored GPG fingerprints before relying on this Mac.
EOF
elif [[ "$APPLY" -eq 1 ]]; then
  cat <<'EOF'

Base activation completed. To restore the regular private state in one guided,
resumable flow, open a terminal and run:
EOF
  print_finish_setup_command
else
  cat <<'EOF'

The reviewed build is ready. For a regular fresh-machine setup, run:
EOF
  print_setup_command provision
  cat <<'EOF'

Use --apply instead only when the base configuration should be activated
without restoring private state.
EOF
fi

trap - ERR
echo
echo "No name, email address, signing key, or private host configuration is stored in Git."

# Application inventory policy

## Declared baseline

The `mini` host composes:

- `base`: security, browser, terminal, window, update, sync, and core utility apps;
- `development`: editor, AI tools, Xcode/TestFlight, OrbStack, and database tooling;
- `desktop`: external-display support and desktop menu-bar behavior;
- `personal`: communication, news, media, archive, and document utilities;
- `work`: Office, Teams, Slack, and Notion;
- `gaming`: GeForce NOW.

The package lists intentionally replace Ghostty with Otty, Ice with Barbee, Latest with Updatest, and the old Tailscale token with `tailscale-app`.

Filen Menubar is the explicit exception to the Homebrew-first GUI policy: its Apple Silicon DMG is checksum-pinned in Nix because no stable cask exists. Its Node-based Filen CLI is isolated under a pinned `fnm` LTS runtime without changing the user's default Node, and its private sync paths restore from 1Password.

## Intentionally omitted

- stale registered apps whose bundles are absent;
- GUI editors superseded by Zed;
- Steam when cloud gaming is the selected restore path;
- laptop-only battery utilities on the desktop host;
- deprecated or unused third-party taps and terminal editors;
- package-manager globals without recent evidence or a declared owner.

## Manual/private restore

- vendor applications unavailable through a stable Homebrew or MAS identifier;
- private repository lists and private SSH host entries;
- custom commands installed by unauthenticated `curl | sh` scripts until they have a pinned package/checksum;
- app preferences containing credentials or private project paths.

Homebrew activation never removes omitted software. Use a separate dry-run to review drift before any manual cleanup.

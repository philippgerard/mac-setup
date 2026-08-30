# Application inventory policy

## Declared baseline

The `mini` host composes:

- `base`: security, browser, terminal, window, update, sync, and core utility apps;
- `development`: editor, AI tools, Safari Technology Preview, TestFlight, OrbStack,
  the pinned Erlang/OTP 29 plus Elixir 1.20 toolchain, and the pinned Rust
  compiler, Cargo, formatter, linter, and language server;
- `desktop`: external-display support and desktop menu-bar behavior;
- `personal`: communication, news, media, archive, and document utilities;
- `work`: individual Microsoft Office apps, Teams, and Slack;
- `gaming`: GeForce NOW.

The package lists intentionally replace Ghostty with Otty, Latest with
Updatest, and the old Tailscale token with `tailscale-app`.

Safari Technology Preview uses Homebrew's unversioned
[`safari-technology-preview`](https://formulae.brew.sh/cask/safari-technology-preview)
cask. The official cask selects Apple's package for the running macOS release,
including the separate macOS 26 and macOS 27 downloads, so this repository does
not duplicate that changing release logic.
Normal preview updates arrive through Software Update. Homebrew selects an OS
variant only when it installs or reinstalls the cask, so after a major macOS
upgrade prefer Software Update. Before a reviewed one-time reinstall, compare
the platform-specific version from `brew info --cask safari-technology-preview`
with [Apple's current download](https://developer.apple.com/safari/resources/);
an individual Homebrew platform branch can lag when Apple changes its asset
URL.

The 1Password desktop app remains a Homebrew cask, while its CLI is installed
from the pinned Nix collection so private restore helpers resolve an immutable
executable before any user-writable Homebrew path. An existing Mac can retain
the former `1password-cli` cask because activation cleanup is disabled; after
confirming the Nix `op` works with desktop integration, review that cask for
manual removal.

Filen Menubar is the explicit exception to the Homebrew-first GUI policy: its
Apple Silicon DMG is checksum-pinned in Nix because no stable cask exists. The
reviewed maintenance workflow automatically refreshes that pin from the latest
stable GitHub release and verifies the release-asset digest before building.
The signed app bundle contains its patched sync backend and pinned Node runtime;
no standalone Filen CLI, npm package, or system Node runtime is declared. The
backend cannot self-update independently of the reviewed application release.
It retains a pre-existing legacy `~/.filen-cli` state directory when present
and otherwise uses the protected modern macOS path. Private sync paths restore
from 1Password, while authentication remains an interactive in-app step.

Microsoft Teams remains an explicit work-profile cask. Homebrew considers a
cask installed from its receipt even if its application bundle was deleted. If
`brew list --cask microsoft-teams` succeeds but
`/Applications/Microsoft Teams.app` is absent, repair that stale receipt with
`brew reinstall --cask microsoft-teams`; future clean installations use the
declared cask normally.

### Migrating a legacy Microsoft Office installation

The combined `microsoft-office` cask conflicts with the individual Word,
Excel, PowerPoint, and Outlook casks declared by the work profile. On an
existing Mac, first run `scripts/homebrew-dry-run` and confirm that the
combined cask is the installed legacy package. Homebrew cleanup remains
disabled: provisioning will not remove or replace that cask automatically.

After quitting the Office applications and reviewing any locally stored data,
remove the legacy receipt and applications explicitly:

```bash
brew uninstall --cask microsoft-office
scripts/rebuild switch
```

The switch installs the declared individual casks. Verify that Word, Excel,
PowerPoint, Outlook, and Microsoft Teams launch and are licensed before
considering the migration complete.

Treat unwanted applications from the combined bundle separately. Check
whether Defender, OneDrive, or OneNote and any related background components
remain, and use Microsoft's documented uninstall procedure for each product
you choose to remove. In particular, verify that OneDrive has finished syncing
before its removal. Do not turn this review into automatic Homebrew cleanup or
delete application/data directories wholesale.

## Intentionally omitted

- stale registered apps whose bundles are absent;
- GUI editors superseded by Zed;
- Microsoft Defender, OneDrive, and OneNote, which are bundled by the combined
  `microsoft-office` cask but are not required here;
- Conductor and Deliveries, which are not part of the selected baseline;
- Barbee, Collections, Core Tunnel, HazeOver, Notion, Nova, Paperparrot,
  PDF Squeezer, Raycast, Remind Me Faster, Replacicon, SecureSafe, TablePlus,
  Trace, Whatcable, WiFi Signal, and Zipic, which are no longer part of the
  selected baseline;
- Xcode, which is installed manually from the App Store only when needed, and
  XcodeBuildMCP, which is omitted with its Xcode dependency;
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

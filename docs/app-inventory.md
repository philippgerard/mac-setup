# Application inventory policy

## Declared baseline

The `mini` host composes:

- `base`: security, browser, terminal, window, update, sync, and core utility apps;
- `development`: editor, AI tools, TestFlight, OrbStack, database tooling,
  the pinned Erlang/OTP 29 plus Elixir 1.20 toolchain, and the pinned Rust
  compiler, Cargo, formatter, linter, and language server;
- `desktop`: external-display support and desktop menu-bar behavior;
- `personal`: communication, news, media, archive, and document utilities;
- `work`: individual Microsoft Office apps, Teams, Slack, and Notion;
- `gaming`: GeForce NOW.

The package lists intentionally replace Ghostty with Otty, Ice with Barbee, Latest with Updatest, and the old Tailscale token with `tailscale-app`.

The 1Password desktop app remains a Homebrew cask, while its CLI is installed
from the pinned Nix collection so private restore helpers resolve an immutable
executable before any user-writable Homebrew path. An existing Mac can retain
the former `1password-cli` cask because activation cleanup is disabled; after
confirming the Nix `op` works with desktop integration, review that cask for
manual removal.

Filen Menubar is the explicit exception to the Homebrew-first GUI policy: its
Apple Silicon DMG is checksum-pinned in Nix because no stable cask exists. The
pinned Nix package collection builds its stable CLI as a standalone Apple
Silicon executable; it requires no Node runtime and has self-updates disabled.
The launcher also fixes its state directory to the protected modern macOS path,
so a leftover `~/.filen-cli` directory cannot change credential precedence.
Private sync paths restore from 1Password.

SecureSafe's vendor package requires Rosetta 2. The switch workflow installs
Rosetta when absent before Homebrew activation.

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
- Collections, Paperparrot, Raycast, Remind Me Faster, Replacicon, Trace,
  Whatcable, and WiFi Signal, which are no longer part of the selected baseline;
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

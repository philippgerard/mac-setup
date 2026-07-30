# Mail and account setup

The guided `setup.sh --provision` flow restores password-free account metadata
from 1Password and configures only the accounts selected for this Mac.
`personal-mail` is the default. Work and PEC accounts are opt-in.

## Select accounts

The first explicit `--mail-account` replaces the default; it does not add to
it. Repeat the option for every account wanted on the Mac:

```bash
# Personal plus work
~/.config/mac-setup/setup.sh --provision -- \
  --mail-account personal-mail --mail-account work-mail

# Work only
~/.config/mac-setup/setup.sh --provision -- --mail-account work-mail
```

Use `--no-mail` to skip account restoration. `--mail-profile` remains a
compatibility alias for `--mail-account`.

Two account types are supported:

- `imap` produces one password-free macOS configuration profile for the
  account's selected Mail, CalDAV, and CardDAV services.
- `exchange_oauth` opens Apple's native Microsoft Exchange Internet Accounts
  flow and never stores a password or OAuth token in a profile.

An account that uses S/MIME must also declare `"smime": true` in the private
Mail metadata. This is intentionally a boolean rather than certificate data:
private keys, certificate fingerprints, 1Password item IDs, and PKCS#12
passwords never belong in the public repository or in the password-free Mail
configuration profile.

## Private metadata and backup

Mail addresses, login names, server settings, account types, and stable profile
identifiers are private. Their canonical local copy is:

```text
~/Library/Application Support/mac-setup/mail-accounts.json
```

The file deliberately contains no passwords, app passwords, access tokens, or
OAuth refresh tokens. Keep email and DAV app passwords in separate 1Password
Login items.

After creating or changing the metadata:

```bash
scripts/validate-mail-accounts-config
scripts/generate-mail-account-profiles
op signin
scripts/backup-mail-accounts-to-1password
```

The backup helper stores the JSON as the `Mac Setup Mail Accounts` 1Password
Document, downloads it again, and compares its SHA-256 digest. Do not consider
the backup complete unless it reports that the document was backed up and
verified. Lookup errors and duplicate exact document titles fail closed.

The schema, stable identifier rules, file permissions, and private-path
constraints are documented in [Private state](private-state.md#mail-account-config).

## IMAP, Calendar, Reminders, and Contacts

The guided flow downloads and validates the metadata, preserves a different
existing copy with a timestamp, and generates one file per IMAP/DAV account:

```text
~/Library/Application Support/mac-setup/mail-profiles/<account-id>.mobileconfig
```

For each selected account:

1. review the profile that setup opens;
2. install it in **System Settings > General > Device Management**;
3. enter the requested email and DAV application passwords; and
4. verify every service included in the profile.

macOS may label the IMAP account's single prompt as an **SMTP password**. The
profile instructs macOS to reuse that credential for incoming IMAP and outgoing
SMTP, so there is no separate IMAP-labelled prompt.

CalDAV supplies Calendar and can expose VTODO task lists to Reminders. CardDAV
supplies Contacts. There is no separate Reminders payload. macOS may ask for
CalDAV and CardDAV credentials separately even when both use the same
application password.

For Mailbox.org, create an application password using its **Calendar and
address book client (CalDAV/CardDAV)** preset and enter it for both DAV prompts.
Verify Reminders after installation because task availability depends on server
discovery, and advanced or recurring task features may not map perfectly.

Each profile owns only its account bundle and can be installed or removed
independently. Removing it also removes every Mail, Calendar, Reminders, and
Contacts service managed by that profile. Do not remove a profile merely to
troubleshoot one service.

## S/MIME identity history

S/MIME identities are separate from the generated Mail/DAV configuration
profiles. Apple Mail discovers a personal certificate by matching its email
address to an identity in the keychain. Import each `.p12` or `.pfx` identity
into the **login** keychain, never the System keychain. A System-keychain
private key can cause macOS to request administrator credentials whenever Mail
decrypts a message.

Keep the current identity and every historical private key that may have been
used to encrypt retained mail. Expired or revoked certificates must not be
used to sign new messages, but their private keys can still be necessary to
decrypt older messages. Public `.cer`, `.crt`, `.pem`, or `.p7b` files alone
are not substitutes for the corresponding private key.

Use one 1Password **Login** item per identity so a file can never be paired
with another identity's password:

- title: `Mac Setup S-MIME <account-id> <certificate-period>`;
- username: the exact private Mail account ID;
- password: that exact PKCS#12/PFX file's import password;
- attachment: exactly one matching `.p12` or `.pfx` identity file;
- fields: certificate period, certificate status (`current`, `historical`, or
  `revoked`), and last successful decryption-test date or `pending`; and
- tags: `mac-setup` and `smime`.

For every account with `"smime": true`, guided setup:

1. finds the matching tagged Login items in the explicitly selected 1Password
   account and optional vault;
2. rejects duplicates, malformed fields, missing passwords, public-only
   certificate files, more than one attachment, and any set without exactly
   one current identity;
3. downloads each attachment into a private temporary directory;
4. streams that item's password directly from 1Password through an anonymous
   pipe to a native Security-framework helper;
5. decodes the PKCS#12 data in memory, matches the certificate digest against
   certificate/private-key identities in the **login** keychain, and skips an
   identity already present even when its certificate is expired or revoked;
6. imports only missing identities into the login keychain with access scoped
   to Mail; and
7. removes every temporary attachment and compiled helper on exit.

The PKCS#12 password is never a command argument, environment variable,
terminal prompt, log value, or file. Setup never targets the System keychain
and never uses `security import -P`.

Do not replace separate items with one shared-password archive: historical
files can have different import passwords. Do not attach public-only
certificate files as identity backups. The standardized titles, tags, and
fields form the private recovery manifest without placing item IDs,
fingerprints, names, or addresses in this repository.

Automatic presence detection proves that the certificate and associated
private key exist in the login keychain. It cannot prove certificate trust,
Mail signing behavior, or decryption of retained messages. After restore,
manually confirm the current certificate is valid, send a newly encrypted
message, and decrypt a retained message from every historical certificate
period. A fresh Mac may ask for 1Password biometric approval or a macOS
Keychain authorization, but no PKCS#12 password needs to be typed.

Do not embed a PKCS#12 payload in the generated profile: Apple documents that
a manually installed profile is obfuscated, not encrypted, so its identity and
any embedded password can be extracted.

To regenerate the local files without opening them:

```bash
scripts/restore-mail-accounts-from-1password --no-open
```

## Microsoft 365 and hardware-key MFA

An `exchange_oauth` account deliberately does not generate a managed Exchange
profile. Setup reports the state of Microsoft's optional native-app broker
prerequisites, opens **System Settings > Internet Accounts > Add Account >
Microsoft Exchange**, and waits for the user to confirm that the account and
wanted services are visible.

Choose **Sign In**, not **Configure Manually**. For FIDO2/passkey
authentication, choose **Sign-in options** and the security-key option on
Microsoft's first sign-in page before entering a password. Cancel if the flow
reaches Authenticator number matching without offering the required key. No
password or configuration-profile field can force Microsoft to select a
particular MFA method.

Test the registered key first in a private Safari or Chrome window:

- If the key works in the browser but Internet Accounts offers only
  Authenticator number matching, cancel the native flow and ask the
  organization's administrator to inspect the exact client sign-in,
  authentication method, and Conditional Access result.
- If the security-key option is absent in the browser too, review
  [Microsoft Security info](https://mysignins.microsoft.com/security-info) and
  ask the administrator to verify the key registration, authentication-method
  policy, and Conditional Access result.

Apple Internet Accounts is a native application surface, not an ordinary
Safari session. Microsoft documents Company Portal, MDM enrollment, and an
organization-deployed Enterprise SSO configuration as its broker path for
native macOS applications. Installing Company Portal alone does not activate
that broker, so this repository does not install or enroll it automatically.
The local broker diagnostic is advisory because neither vendor documents the
exact authentication surface used by every Internet Accounts flow.

A YubiKey used for PIV/certificate authentication is a different method. Its
Microsoft choice is **Use a certificate or smart card**; the organization must
provision the certificate and enable Microsoft Entra certificate-based
authentication. Do not reset or reprovision a key merely to troubleshoot this
setup.

Relevant vendor guidance:

- [Microsoft passkey compatibility](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-fido2-compatibility)
- [Microsoft Enterprise SSO plug-in requirements](https://learn.microsoft.com/en-us/entra/identity-platform/apple-sso-plugin)

There is also a time-sensitive compatibility risk. As of July 2026,
[Apple documents macOS Exchange integration as using EWS](https://support.apple.com/guide/deployment/integrate-with-microsoft-exchange-dep158966b23/web),
while Microsoft plans to
[start disabling EWS in Exchange Online in October 2026 and finish in April 2027](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/deprecation-of-ews-exchange-online).
Until either vendor documents a replacement for this client path, treat native
Exchange in Mail, Calendar, Contacts, and Reminders as transitional and keep
Outlook or the web applications available.

## iCloud Mail, Calendar, and Contacts

The public profile at
`configuration-profiles/disable-icloud-mail-calendar-contacts.mobileconfig`
disables exactly iCloud Mail, Calendar, and Contacts for the current user. It
does not affect iCloud Drive, Keychain, Photos, Notes, Find My, Reminders, or
third-party accounts.

During `setup.sh --provision`, setup validates the profile, opens it when the
exact effective content is not already installed, waits for approval, and
verifies the result before continuing. Approve it in **System Settings >
General > Device Management**.

To present it manually:

```bash
scripts/open-icloud-service-restrictions-profile
```

Apple requires manual approval on an unmanaged Mac. This is an enforced,
removable restriction rather than a one-time default: while installed, the
three services remain disabled and their toggles cannot re-enable them. Remove
the standalone profile in Device Management when those iCloud services should
be available again.

## Profile migration

If an older setup installed a managed Exchange profile, first verify that the
account contains no local-only mail or unsent messages. Remove the profile in
**System Settings > General > Device Management**, then add the account through
the native Internet Accounts flow. Removing the profile also removes the
account and every service it manages, so setup does not automate this.

The standalone personal profile preserves the identity of the older combined
profile. Keep the combined profile installed, review the generated
replacement, and explicitly allow the update:

```bash
~/.config/mac-setup/setup.sh --provision -- --update-profiles
```

Install other wanted profiles afterward. If macOS refuses the update, first
verify that no affected account has local-only mail or unsent messages. Only
then remove the combined profile and install the desired standalone profiles.

The guided restore also requires `--update-profiles` whenever an installed
iCloud or IMAP/DAV profile has the same identity but different effective
settings. It never silently replaces a different profile.

Older revisions placed Mail metadata and generated profiles below the
checkout's ignored `.local/` directory. Current Nix commands exclude that
directory. After verifying the external copy, review and remove only the legacy
`.local/mail-accounts.json` and `.local/mail-profiles/` copies. Keep
`.local/config.json`, which local builds still require.

# Disposable-Mac restore rehearsal

Use a spare Apple Silicon Mac or a disposable macOS VM on Apple hardware.
Take a VM snapshot where supported. Perform this rehearsal on macOS 27 or newer
before relying on a clean restore. CI covers public builds, not interactive
macOS activation or vendor authentication.

Keep results outside the public repository: exact Git revision, macOS version,
chosen profiles/accounts, commands used, observed failures, and recovery steps.
Do not publish private account identifiers, machine paths, or authentication logs.

1. Follow the README's fresh-Mac prerequisites and build-only bootstrap. For an
   unpublished candidate, copy a reviewed public checkout and use its `setup.sh
   --config-dir` option. Record `git rev-parse HEAD` plus any uncommitted diff.
   Use `scripts/rebuild preview` to inspect the candidate before proceeding.
2. Run `./setup.sh --config-dir "$PWD" --apply` inside that checkout. Complete
   App Management approval if needed and use the exact printed resume command.
   Confirm Fish is the login shell and double-click a harmless test shell script
   from Finder. Verify that an `ssh://` link opens Otty without initiating a
   connection to an unreviewed host.
3. Run `scripts/doctor --skip git --skip ssh --skip gpg --skip mail --skip filen`.
   Confirm selected baseline checks pass and intentionally omitted private
   components are reported as skipped. Run `mac-setup doctor` from outside the
   checkout to exercise the recorded location and Fish shortcuts.
4. Start `scripts/finish-setup` with the account/skip options appropriate for the
   rehearsal. Stop at a private-restore approval or sign-in prompt. Resume using
   the exact `scripts/finish-setup` command printed by setup, or the same direct
   invocation if interrupted with Control-C. Verify completed steps remain
   intact; do not rerun the public activation to resume private restore.
5. Complete the selected restores and run `scripts/doctor` with matching
   `--mail-account` and `--skip` options. Follow the separate interactive checks
   in [post-install verification](restore-verification.md), including signed
   Git commits, GPG fingerprints, S/MIME decryption, and representative sync.
6. Change an Otty appearance setting and a Zed setting. Run
   `scripts/rebuild switch` again, then rerun doctor. Confirm those edits survive,
   no duplicate profiles appear, Filen's agent remains loaded, and OMC setup has
   not replaced existing user configuration. Check file and URL handlers again.
7. List generations and rehearse the documented rollback on this disposable
   machine. Verify what Nix restores and record vendor or mutable state that
   remains. Keep a known-good generation until these checks pass.

A rehearsal is complete only when the actual activation, interruption/resume,
and second activation have been observed. A passing CI job or two cached builds
alone does not complete it. Record any skipped components explicitly.

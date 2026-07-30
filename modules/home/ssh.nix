{ lib, ... }:

{
  # A custom vault is not part of 1Password's implicit SSH-agent allowlist.
  # Keep the setup signing key first, then retain the built-in vault behavior
  # across personal and work accounts without embedding any private account or
  # item identifiers.
  xdg.configFile."1Password/ssh/agent.toml".text = ''
    [[ssh-keys]]
    item = "Mac Setup Git Signing"
    vault = "Mac Setup"

    [[ssh-keys]]
    vault = "Personal"

    [[ssh-keys]]
    vault = "Private"

    [[ssh-keys]]
    vault = "Employee"
  '';

  home.file.".ssh/config".text = ''
    Include ~/.ssh/config.d/*
    Include ~/.orbstack/ssh/config

    Host *
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      ServerAliveInterval 60
      ServerAliveCountMax 3
  '';

  # Private host entries are restored locally and never committed. The
  # activation refuses symlinked/foreign-owned state before restricting it.
  home.activation.secureSshPrivateState = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD ${../../scripts/secure-ssh-private-state}
  '';
}

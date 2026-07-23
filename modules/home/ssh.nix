{ lib, ... }:

{
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

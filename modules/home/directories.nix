{ lib, ... }:

{
  home.activation.createWorkspaceDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p \
      "$HOME/Developer" \
      "$HOME/Projects" \
      "$HOME/Sites/Personal" \
      "$HOME/Sites/Work"
  '';
}

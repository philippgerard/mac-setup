{ lib, ... }:

{
  home.activation.createWorkspaceDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p \
      "$HOME/Developer" \
      "$HOME/Projects" \
      "$HOME/Library/pnpm/bin" \
      "$HOME/Sites/Personal" \
      "$HOME/Sites/Work"
  '';
}

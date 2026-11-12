{ ... }:

let
  executable = "/Applications/Filen Menubar.app/Contents/MacOS/filen-menubar";
in
{
  # Homebrew owns the signed bundle and its bundled sync backend/Node runtime.
  # A wrapper keeps this command stable across cask upgrades.
  home.file.".local/bin/filen-menubar" = {
    text = ''
      #!/bin/bash -p
      exec "${executable}" "$@"
    '';
    executable = true;
  };

  # Preserve the existing Home Manager application policy for other packages.
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;

  # A successful exit means the user intentionally quit; only crashes restart.
  launchd.agents.filen-menubar = {
    enable = true;
    config = {
      ProgramArguments = [ executable ];
      ProcessType = "Interactive";
      RunAtLoad = true;
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
    };
  };
}

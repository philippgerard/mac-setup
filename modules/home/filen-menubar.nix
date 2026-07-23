{ lib, pkgs, ... }:

let
  version = "0.1.26";

  # Upstream recommends this stable legacy release while its replacement is in
  # beta. nixpkgs builds it as a standalone Bun executable, avoiding the npm
  # package's obsolete exact-Node-23 engine declaration.
  filenCli = pkgs.filen-cli;

  filenMenubar = pkgs.stdenvNoCC.mkDerivation {
    pname = "filen-menubar";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/philippgerard/filen-menubar/releases/download/v${version}/Filen.Menubar_${version}_aarch64.dmg";
      hash = "sha256-RdL58mRZSpaywSdtoHV0QDk7kx8RrpTm7fUKG65t3L4=";
    };

    nativeBuildInputs = [ pkgs.undmg ];
    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      undmg "$src"
      mkdir -p "$out/Applications"
      cp -R "Filen Menubar.app" "$out/Applications/"

      runHook postInstall
    '';

    meta = {
      description = "Native menu-bar controller for Filen cloud sync";
      homepage = "https://github.com/philippgerard/filen-menubar";
      license = lib.licenses.mit;
      platforms = [ "aarch64-darwin" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };

  executable = "${filenMenubar}/Applications/Filen Menubar.app/Contents/MacOS/filen-menubar";
  filenCliLauncher = pkgs.writeShellScript "filen" ''
    # This executable is pinned by Nix, so suppress its built-in self-updater.
    # Force the modern macOS state directory: upstream otherwise prefers a
    # legacy ~/.filen-cli directory whenever one happens to exist.
    exec ${filenCli}/bin/filen \
      --skip-update \
      --data-dir "$HOME/Library/Application Support/filen-cli" \
      "$@"
  '';
in
{
  home.packages = [ filenMenubar ];

  # Finder-launched apps do not inherit the shell PATH. The app searches this
  # location explicitly, and the launcher supplies the pinned standalone CLI.
  home.file.".local/bin/filen" = {
    source = filenCliLauncher;
    executable = true;
  };
  home.file.".local/bin/filen-menubar" = {
    source = executable;
    executable = true;
  };

  # Copy a real bundle so Spotlight can find it after the menu-bar app quits.
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;

  # A successful exit means the user intentionally quit the app; only crashes restart.
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

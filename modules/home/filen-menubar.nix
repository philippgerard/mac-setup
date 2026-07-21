{ lib, pkgs, ... }:

let
  version = "0.1.24";
  filenNodeVersion = "24.18.0";

  filenMenubar = pkgs.stdenvNoCC.mkDerivation {
    pname = "filen-menubar";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/philippgerard/filen-menubar/releases/download/v${version}/Filen.Menubar_${version}_aarch64.dmg";
      hash = "sha256-/2xXeBuPonplMDDmZG6IyGzEBvgCRIw/PsguGL4J2eQ=";
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
    exec ${pkgs.fnm}/bin/fnm exec --using=${filenNodeVersion} filen "$@"
  '';
in
{
  home.packages = [ filenMenubar ];

  # Finder-launched apps do not inherit the shell PATH. The app searches this
  # location explicitly, and the launcher keeps its Node runtime inside fnm.
  home.file.".local/bin/filen" = {
    source = filenCliLauncher;
    executable = true;
  };

  # Keep the bundle discoverable in Finder as ~/Applications/Home Manager Apps.
  targets.darwin.linkApps.enable = true;

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

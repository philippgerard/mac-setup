{ lib, pkgs, ... }:

let
  release = builtins.fromJSON (
    builtins.readFile ./filen-menubar-release.json
  );
  version = release.version;

  filenMenubar = pkgs.stdenvNoCC.mkDerivation {
    pname = "filen-menubar";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/philippgerard/filen-menubar/releases/download/v${version}/Filen.Menubar_${version}_aarch64.dmg";
      inherit (release) hash;
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
      license = with lib.licenses; [ mit agpl3Only ];
      platforms = [ "aarch64-darwin" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };

  executable = "${filenMenubar}/Applications/Filen Menubar.app/Contents/MacOS/filen-menubar";
in
assert builtins.attrNames release == [ "hash" "version" ];
assert builtins.isString release.version;
assert builtins.match "[0-9]+\\.[0-9]+\\.[0-9]+" release.version != null;
assert builtins.isString release.hash;
assert builtins.match "sha256-[A-Za-z0-9+/]{43}=" release.hash != null;
{
  home.packages = [ filenMenubar ];

  # Keep a stable command for launching the pinned application. Its patched
  # sync backend and Node runtime are contained inside the signed app bundle.
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

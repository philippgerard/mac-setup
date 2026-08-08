{ lib, pkgs, ... }:

let
  version = "4.15.8";
  nodejs = pkgs.nodejs;

  ohMyClaudeCode = pkgs.buildNpmPackage {
    pname = "oh-my-claudecode";
    inherit version;
    inherit nodejs;

    src = pkgs.fetchFromGitHub {
      owner = "Yeachan-Heo";
      repo = "oh-my-claudecode";
      rev = "v${version}";
      hash = "sha256-0JWC9PBt8GywaNpGrhTTkEY5LcD4MK0vmCUhZYMd+88=";
    };

    npmDepsHash = "sha256-9UPhnDGEvQxd5rJxQMUDbToXPqpYanK0DTZZ2FgBgvU=";

    # The installed HUD resolves npm-style module roots at runtime. Exercise
    # that path in the package sandbox so a build cannot succeed with a CLI
    # whose generated status line is unusable from Nix.
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck

      export HOME="$TMPDIR/omc-install-check-home"
      export PATH="${nodejs}/bin:$PATH"
      mkdir -p "$HOME"
      (
        cd "$HOME"
        "$out/bin/omc" setup --quiet --no-plugin
      )

      hud_output="$(${pkgs.coreutils}/bin/printf '{}\n' | \
        OMC_PLUGIN_ROOT="$out/lib/node_modules/oh-my-claude-sisyphus" \
        ${nodejs}/bin/node "$HOME/.claude/hud/omc-hud.mjs")"
      [[ "$hud_output" == *"[OMC#${version}]"* ]] || {
        echo "Nix-installed OMC HUD could not resolve its runtime package" >&2
        exit 1
      }

      runHook postInstallCheck
    '';

    meta = {
      description = "Multi-agent orchestration for Claude Code";
      homepage = "https://github.com/Yeachan-Heo/oh-my-claudecode";
      license = lib.licenses.mit;
      mainProgram = "omc";
      platforms = lib.platforms.darwin;
    };
  };
  packageRoot = "${ohMyClaudeCode}/lib/node_modules/oh-my-claude-sisyphus";
in
{
  home.packages = [ ohMyClaudeCode ];

  # Install the standalone npm payload once. Later activations do not rerun
  # setup; they only keep npm-owned hook and HUD commands on the current Nix
  # Node/package closure. Existing interactive/plugin setup remains untouched.
  home.activation.setupOhMyClaudeCode = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD ${../../scripts/setup-oh-my-claudecode} \
      ${ohMyClaudeCode}/bin/omc \
      ${nodejs}/bin/node \
      ${packageRoot} \
      ${pkgs.jq}/bin/jq
  '';
}

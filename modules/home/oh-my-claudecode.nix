{ lib, pkgs, ... }:

let
  release = builtins.fromJSON (builtins.readFile ./oh-my-claudecode-release.json);
  version = release.version;
  nodejs = pkgs.nodejs;

  ohMyClaudeCode = pkgs.buildNpmPackage {
    pname = "oh-my-claudecode";
    inherit version;
    inherit nodejs;

    src = pkgs.fetchFromGitHub {
      owner = "Yeachan-Heo";
      repo = "oh-my-claudecode";
      rev = "v${version}";
      hash = release.hash;
    };

    npmDepsHash = release.npmDepsHash;
    nativeBuildInputs = [ pkgs.python3 ];
    npm_config_build_from_source = "true";
    # The normal build phase already runs the identical prepack build.
    npmPackFlags = [ "--ignore-scripts" ];

    # This package targets one Nix platform; upstream otherwise builds both
    # Darwin architectures using the host's Apple toolchain.
    postPatch = ''
      substituteInPlace scripts/build-contained-fs.mjs \
        --replace-fail "['arm64', 'x64']" "[process.arch]"
    '';

    # The installed HUD resolves npm-style module roots at runtime. Exercise
    # that path in the package sandbox so a build cannot succeed with a CLI
    # whose generated status line is unusable from Nix.
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck

      export HOME="$TMPDIR/omc-install-check-home"
      export PATH="${nodejs}/bin:${pkgs.git}/bin:$PATH"
      mkdir -p "$HOME"
      package_root="$out/lib/node_modules/oh-my-claude-sisyphus"
      ${nodejs}/bin/node -e \
        "const req = require('node:module').createRequire('$package_root/package.json'); const db = new (req('better-sqlite3'))(':memory:'); db.prepare('SELECT 1').get(); db.close(); req('$package_root/native/contained-fs-darwin-arm64.node');"
      (
        cd "$HOME"
        "$out/bin/omc" setup --quiet --no-plugin
      )

      # Exercise the actual activation guard against this release's payload,
      # including an idempotent second run without rewriting user settings.
      ${../../scripts/setup-oh-my-claudecode} \
        "$out/bin/omc" ${nodejs}/bin/node "$package_root" ${pkgs.jq}/bin/jq
      ${pkgs.jq}/bin/jq -e --arg root "$package_root" \
        '.macSetupNixRuntime.packageRoot == $root' "$HOME/.claude/.omc-config.json"
      cp "$HOME/.claude/settings.json" "$TMPDIR/settings-before-rerun.json"
      ${../../scripts/setup-oh-my-claudecode} \
        "$out/bin/omc" ${nodejs}/bin/node "$package_root" ${pkgs.jq}/bin/jq
      cmp "$HOME/.claude/settings.json" "$TMPDIR/settings-before-rerun.json"

      # OMC 5 validates the HUD's repository boundary with Git.
      ${pkgs.git}/bin/git init -q "$TMPDIR/hud-project"
      hud_output="$(
        cd "$TMPDIR/hud-project"
        ${pkgs.coreutils}/bin/printf '{}\n' | \
          OMC_PLUGIN_ROOT="$package_root" \
          ${nodejs}/bin/node "$HOME/.claude/hud/omc-hud.mjs"
      )"
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

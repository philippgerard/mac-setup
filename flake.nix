{
  description = "Mac Setup - nix-darwin configuration with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
  };

  outputs = inputs@{ nixpkgs, nix-darwin, home-manager, determinate, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
      # Local commands pass the ignored host config explicitly with --impure.
      # The filtered flake source never contains .local or other ignored state;
      # pure evaluation therefore keeps using the public generic fallback.
      localConfigPath = builtins.getEnv "MAC_SETUP_LOCAL_CONFIG";
      localConfig =
        if localConfigPath != ""
        then builtins.fromJSON (builtins.readFile localConfigPath)
        else import ./local.example.nix;

      mkDarwinSystem = { host, hostConfig ? localConfig, extraModules ? [] }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs; localConfig = hostConfig; };
          modules = [
            determinate.darwinModules.default
            ./hosts/${host}

            ./modules/darwin

            home-manager.darwinModules.home-manager
            {
              home-manager = {
                backupFileExtension = "before-home-manager";
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; localConfig = hostConfig; };
                users.${hostConfig.username} = import ./modules/home;
              };
            }
          ] ++ extraModules;
        };
      publicSystem = mkDarwinSystem {
        host = "mini";
        hostConfig = import ./local.example.nix;
      };
      baseSystem = mkDarwinSystem {
        host = "mini";
        hostConfig = import ./local.example.nix;
        extraModules = [{
          disabledModules = [
            ./profiles/development.nix
            ./profiles/personal.nix
            ./profiles/work.nix
            ./profiles/gaming.nix
            ./profiles/desktop.nix
          ];
        }];
      };
      packageNames = configuration:
        map nixpkgs.lib.getName configuration.config.home-manager.users.macuser.home.packages;
    in
    {
      darwinConfigurations = {
        mini = mkDarwinSystem { host = "mini"; };
      };

      checks.${system} = {
        system = publicSystem.system;
        profile-composition =
          assert builtins.elem "oh-my-claudecode" (packageNames publicSystem);
          assert builtins.elem "filen-menubar" (packageNames publicSystem);
          assert !(builtins.elem "oh-my-claudecode" (packageNames baseSystem));
          assert !(builtins.elem "filen-menubar" (packageNames baseSystem));
          assert !(builtins.elem "rustc" (packageNames baseSystem));
          assert !baseSystem.config.home-manager.users.macuser.programs.gh.enable;
          assert baseSystem.config.home-manager.users.macuser.home.sessionVariables.EDITOR == "vim";
          assert publicSystem.config.home-manager.users.macuser.home.sessionVariables.EDITOR == "zed --wait";
          pkgs.runCommand "profile-composition" {} "touch $out";
      };

      apps.${system}.darwin-rebuild = {
        type = "app";
        program = "${nix-darwin.packages.${system}.darwin-rebuild}/bin/darwin-rebuild";
      };

      devShells.${system}.validation = pkgs.mkShell {
        packages = with pkgs; [
          actionlint
          bash
          coreutils
          fish
          gitleaks
          jq
          ripgrep
          shellcheck
        ];
      };
    };
}

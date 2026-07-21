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
      localConfig =
        if builtins.pathExists ./.local/config.json
        then builtins.fromJSON (builtins.readFile ./.local/config.json)
        else if builtins.pathExists ./.local/config.nix
        then import ./.local/config.nix
        else import ./local.example.nix;

      mkDarwinSystem = { host }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs localConfig; };
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
                extraSpecialArgs = { inherit inputs localConfig; };
                users.${localConfig.username} = import ./modules/home;
              };
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        mini = mkDarwinSystem { host = "mini"; };
      };

      apps.${system}.darwin-rebuild = {
        type = "app";
        program = "${nix-darwin.packages.${system}.darwin-rebuild}/bin/darwin-rebuild";
      };
    };
}

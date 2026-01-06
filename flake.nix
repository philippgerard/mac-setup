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
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      # Shared configuration for all hosts
      mkDarwinSystem = { hostname, system ? "aarch64-darwin" }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs hostname; };
          modules = [
            # Host-specific configuration
            ./hosts/${hostname}

            # Shared darwin modules
            ./modules/darwin

            # Home Manager
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
                users.philippgerard = import ./modules/home;
              };
            }

          ];
        };
    in
    {
      darwinConfigurations = {
        # Personal configurations
        philippgerard-desktop-personal = mkDarwinSystem { hostname = "philippgerard-desktop-personal"; };
        philippgerard-laptop-personal = mkDarwinSystem { hostname = "philippgerard-laptop-personal"; };

        # Work configurations
        philippgerard-desktop-work = mkDarwinSystem { hostname = "philippgerard-desktop-work"; };
        philippgerard-laptop-work = mkDarwinSystem { hostname = "philippgerard-laptop-work"; };
      };
    };
}

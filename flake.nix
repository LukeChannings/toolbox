{
  description = "Luke's toolbox";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    devenv.url = "github:cachix/devenv";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
        inputs.treefmt-nix.flakeModule
        ./devenv.nix
      ];

      systems = [
        "aarch64-darwin"
        "x86_64-darwin"

        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        { config, pkgs, ... }:
        {
          packages = rec {
            mkalias = (pkgs.callPackage ./packages/mkalias { });
            link-apps = (pkgs.callPackage ./packages/link-apps { inherit mkalias; });
          };
        };

      flake = {

        # "toolbox" is an existing package...
        nixpkgs-namespace = "_2lbx";

        devenvModules = {
          vscode-workspace = ./modules/devenv/vscode-workspace;
        };

        darwinModules = {
          link-apps = import ./modules/darwin/link-apps { toolbox = self; };
        };
      };
    };
}

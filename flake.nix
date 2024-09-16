{
  description = "Luke's toolbox";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv-root.url = "file+file:///dev/null";
    devenv-root.flake = false;
    devenv.url = "github:cachix/devenv";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs = {
      nixpkgs.follows = "nixpkgs";
    };
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
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
    let
      flake = flake-parts.lib.mkFlake { inherit inputs; } {
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
            packages = (
              if pkgs.stdenv.isDarwin then
                rec {
                  mkalias = (pkgs.callPackage ./packages/mkalias { });
                  link-apps = (pkgs.callPackage ./packages/link-apps { inherit mkalias; });
                }
              else
                { }
            );
          };

        flake = rec {

          # "toolbox" is an existing package...
          nixpkgs-namespace = "_2lbx";

          modules.devenv = {
            vscode-workspace = ./modules/devenv/vscode-workspace;
          };

          modules.darwin = {
            link-apps = import ./modules/darwin/link-apps { toolbox = self; };
          };

          darwinModules = modules.darwin;
        };
      };
    in
    flake
    // {
      # Remove container packages from devenv because they break `nix flake check`.
      packages.aarch64-darwin = nixpkgs.lib.filterAttrs (
        key: pkg: key != "container-processes" && key != "container-shell"
      ) flake.packages.aarch64-darwin;
    };
}

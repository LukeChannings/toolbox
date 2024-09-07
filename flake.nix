{
  description = "Luke's toolbox";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs { inherit system; };
    in {
      packages = {
        mkalias = (pkgs.callPackage ./packages/mkalias {});
      };
    }) // {
      devenvModules = {
        vscode-workspace-extensions = (import ./modules/devenv/vscode-workspace-extensions {});
      };
    };
}

{
  description = "Luke's toolbox";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
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
        { pkgs, ... }:
        {
          treefmt = {
            projectRoot = ./.;
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.stylua.enable = true;
          };

          packages = {
            mkalias = (pkgs.callPackage ./packages/mkalias { });
          };
        };

      flake.devenvModules = {
        vscode-workspace-extensions = ./modules/devenv/vscode-workspace-extensions;
      };
    };
}

{ self, inputs, ... }:
{
  perSystem =
    {
      config,
      self',
      inputs',
      pkgs,
      lib,
      system,
      ...
    }:
    {
      treefmt = {
        projectRoot = ./.;
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        programs.biome = {
          enable = true;
          settings.formatter.indentStyle = "space";
        };
        programs.yamlfmt.enable = true;
      };

      devenv.shells.default = {
        devenv.root =
          let
            devenvRootFileContent = builtins.readFile inputs.devenv-root.outPath;
          in
          pkgs.lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;

        imports = [ self.modules.devenv.vscode-workspace ];

        devcontainer.enable = true;

        languages.shell.enable = true;

        packages = with pkgs; [
          nixVersions.latest # devenv likes to install an old version of nix
          shellcheck
          nil
          deno
        ];

        devcontainer.settings.customizations.vscode.extensions = [ "mkhl.direnv" ];
        devcontainer.settings.updateContentCommand = "direnv allow";

        vscode-workspace = {
          extensions = with inputs.vscode-extensions.extensions.${system}.vscode-marketplace; [
            jnoortheen.nix-ide
            denoland.vscode-deno
            ibecker.treefmt-vscode
          ];
          settings = {
            nix = {
              enableLanguageServer = true;
              serverPath = lib.getExe pkgs.nil;
            };

            deno = {
              enable = true;
              path = lib.getExe pkgs.deno;
            };

            treefmt = {
              command = lib.getExe config.treefmt.package;
              config = config.treefmt.build.configFile;
            };

            editor.defaultFormatter = "ibecker.treefmt-vscode";
          };
        };
      };
    };
}

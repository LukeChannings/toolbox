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
      };

      devenv.shells.default = {
        devenv.root =
          let
            devenvRootFileContent = builtins.readFile inputs.devenv-root.outPath;
          in
          pkgs.lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;

        imports = [ self.devenvModules.vscode-workspace ];

        languages.shell.enable = true;

        packages = with pkgs; [
          stylua
          shfmt
          shellcheck
          nixfmt-rfc-style
          nil
          nixVersions.latest
          deno
        ];

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

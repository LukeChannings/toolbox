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
        ];

        vscode-workspace = {
          extensions = with pkgs.vscode-extensions; [
            jnoortheen.nix-ide
            thenuprojectcontributors.vscode-nushell-lang
          ];
          settings = {
            nix = {
              enableLanguageServer = true;
              serverPath = lib.getExe pkgs.nil;
              serverSettings.nil.formatting.command = [(lib.getExe pkgs.nixfmt-rfc-style)];
            };
          };
        };
      };
    };
}

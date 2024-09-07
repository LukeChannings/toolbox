{ self, inputs, ... }:
{
  perSystem =
    {
      config,
      self',
      inputs',
      pkgs,
      system,
      ...
    }:
    {
      devenv.shells.default = {
        imports = [ self.devenvModules.vscode-workspace-extensions ];

        languages.shell.enable = true;

        packages = with pkgs; [
          stylua
          shfmt
          shellcheck
          nixfmt-rfc-style
          nil
          nixVersions.latest
        ];

        vscode-workspace-extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide
          thenuprojectcontributors.vscode-nushell-lang
        ];
      };
    };
}

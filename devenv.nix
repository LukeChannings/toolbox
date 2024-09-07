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

        vscode-workspace-extensions =
          let
            ext = pkgs.vscode-extensions;
          in
          [
            ext.jnoortheen.nix-ide
            ext.thenuprojectcontributors.vscode-nushell-lang
          ];
      };
    };
}

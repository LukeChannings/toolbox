# `vscode-workspace-extensions`

Specifies workspace extensions to be installed in the current workspace.

## Usage

```nix
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devenv.shells.default = {
        imports = [ inputs.toolbox.devenvModules.vscode-workspace-extensions ];

        vscode-workspace-extensions =
          let
            extension = pkgs.vscode-extensions;
          in
          [
            extension.jnoortheen.nix-ide
            extension.thenuprojectcontributors.vscode-nushell-lang
            extension.bmalehorn.vscode-fish
          ];
      };
    };
}
```

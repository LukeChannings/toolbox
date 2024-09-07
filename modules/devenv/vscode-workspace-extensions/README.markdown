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

        vscode-workspace-extensions = with pkgs.vscode-extensions; [
            jnoortheen.nix-ide
            thenuprojectcontributors.vscode-nushell-lang
            bmalehorn.vscode-fish
          ];
      };
    };
}
```

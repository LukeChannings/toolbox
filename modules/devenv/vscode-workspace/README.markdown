# `vscode-workspace`

Allows configuring VSCode workspace extensions and settings in devenv

## Usage

```nix
{ inputs, pkgs, lib, ... }: {
  imports = [ inputs.toolbox.devenvModules.vscode-workspace ];

  vscode-workspace = {
    extensions = with pkgs.vscode-extensions; [
      jnoortheen.nix-ide
      thenuprojectcontributors.vscode-nushell-lang
      bmalehorn.vscode-fish
    ];

    settings = {
      nix = {
        enableLanguageServer = true;
        serverPath = lib.getExe pkgs.nil;
        serverSettings.nil.formatting.command = [(lib.getExe pkgs.nixfmt-rfc-style)];
      };
    };
  };
}
```

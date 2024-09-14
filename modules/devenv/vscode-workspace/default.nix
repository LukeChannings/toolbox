{
  self,
  config,
  pkgs,
  lib,
  ...
}:
let
  fixupExtension =
    drv:
    drv.overrideAttrs {
      postInstall = ''
        extensionDir=$(realpath $out/share/vscode/extensions/*)
        main="$(${pkgs.jq}/bin/jq -r ".main" "$extensionDir/package.json")"

        # The main entrypoint exists, nothing to do.
        if [ -e "$extensionDir/$main" ]; then
          exit 0
        fi

        # The main entrypoint does not exist, but it looks like it's an extensionless path that we can link.
        if [ ! -e "$extensionDir/$main" ] && [ -e "$extensionDir/$main.js" ]; then
          echo "Linking $extensionDir/$main to $extensionDir/$main.js"
          ln -s "$extensionDir/$main.js" "$extensionDir/$main"
          exit 0
        fi

        # Error!
        echo "$extensionDir/$main and $extensionDir/$main.js don't exist. Can't fix this extension."
        exit 1
      '';
    };
  cfg = config.vscode-workspace;
  extensions = builtins.map fixupExtension cfg.extensions;
  jsonFormat = pkgs.formats.json { };
in
{
  options = {
    vscode-workspace = {
      extensions = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.package);
        default = null;
      };

      settings = lib.mkOption {
        type = jsonFormat.type;
        default = { };
        description = ''
          Configuration written to Visual Studio Code's
          {file}`settings.json`.
        '';
      };

      enableDevcontainerSync = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "If true and devcontainer is enabled the configured extensions will be added to the .devcontainer.json file.";
      };
    };
  };

  config = lib.mkIf (extensions != null) (
    let
      extensionsEnv = pkgs.buildEnv {
        name = "${self}-vscode-workspace-extensions";
        paths = extensions;
        pathsToLink = "/share/vscode";
      };
    in
    {
      enterShell =
        ''
          # ensure .vscode exists
          mkdir -p .vscode

          # error if .vscode/extensions exists and isn't a symlink
          if [ -e .vscode/extensions -a ! -L .vscode/extensions ]; then
            echo ".vscode/extensions already exists. Please delete it before continuing."
            exit 1
          fi

          if [ -e .vscode/extensions.json ]; then
            echo "Warning: .vscode/extensions.json cannot co-exist with workspace extensions"
          fi

          # remove the existing symlink and re-link
          rm "$(pwd)/.vscode/extensions"
          ln -fs "${extensionsEnv}/share/vscode/extensions" "$(pwd)/.vscode/extensions"
        ''
        + (
          if cfg.settings != { } then
            ''
              # error if .vscode/settings.json exists already
              if [ -e .vscode/settings.json ] && [ ! -L .vscode/settings.json ]; then
                echo ".vscode/settings.json already exists. Please delete it before continuing."
                exit 1
              fi

              ln -fs ${jsonFormat.generate "settings.json" cfg.settings} "$(pwd)/.vscode/settings.json"
            ''
          else
            ""
        );

      devcontainer =
        lib.mkIf (config.devcontainer.enable && config.vscode-workspace.enableDevcontainerSync)
          {
            settings.customizations.vscode.extensions = builtins.attrNames (
              builtins.readDir "${extensionsEnv}/share/vscode/extensions"
            );
          };
    }
  );
}

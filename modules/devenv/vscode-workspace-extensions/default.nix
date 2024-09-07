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
  extensions = builtins.map fixupExtension config.vscode-workspace-extensions;
in
{
  options = {
    vscode-workspace-extensions = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.package);
      default = null;
    };
  };

  config = lib.mkIf (extensions != null) {
    enterShell =
      let
        env = pkgs.buildEnv {
          name = "${self}-vscode-workspace-extensions";
          paths = extensions;
          pathsToLink = "/share/vscode";
        };
      in
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
        rm -f .vscode/extensions
        ln -fs "${env}/share/vscode/extensions" "$(pwd)/.vscode/extensions"
      '';
  };
}

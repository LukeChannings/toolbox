{ config, lib, ... }:
let
  extensions = config.vscode-workspace-extensions;
in
{
  options = {
    vscode-workspace-extensions = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.package);
      default = null;
    };
  };

  config = lib.mkIf (extensions != null) {
    enterShell = ''
      if [ ! -d .vscode/extensions ]; then
        echo "Installing VSCode workspace extensions..."

        mkdir -p .vscode/extensions

        ${
          builtins.concatStringsSep "\n" (
            map (extension: "cp -R ${extension}/share/vscode/extensions/* .vscode/extensions/") extensions
          )
        }

        chmod +rw -R .vscode/extensions

        for extension in $(ls .vscode/extensions); do
          extensionPath=".vscode/extensions/''${extension}"
          main="$(jq -r ".main" ''${extensionPath}/package.json)"

          if [ ! -e "''${extensionPath}/''${main}" ]; then
            echo "Fixing entry point for ''${extension}"
            tmp="$(mktemp)"
            jq ".main = \"''${main}.js\"" "''${extensionPath}/package.json" > $tmp
            cat $tmp > "''${extensionPath}/package.json"
          fi
        done
      fi
    '';
  };
}

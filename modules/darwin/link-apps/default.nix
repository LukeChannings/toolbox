{ toolbox }:
{
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
let
  inherit (builtins) substring filter readDir;
  linkApps = lib.getExe toolbox.packages.${pkgs.system}.link-apps;
  filterPackagesWithMacApps = filter (drv: (readDir drv.outPath).Applications or null == "directory");
  getInstallMethodPrefix = drv: (substring 0 1 (drv.meta.darwinInstallMethod or "alias"));
in
{
  disabledModules = [ "${modulesPath}/system/applications.nix" ];

  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {

    home-manager.sharedModules = [
      (
        {
          modulesPath,
          config,
          lib,
          ...
        }:
        {
          # Disable Home Manager's default app linking module.
          disabledModules = [ "${modulesPath}/targets/darwin/linkapps.nix" ];

          home.activation.applications =
            let
              hmApps = filterPackagesWithMacApps config.home.packages;
            in
            lib.mkIf ((builtins.length hmApps) > 0) (
              lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                ${linkApps} --destination '${config.home.homeDirectory}/Applications/Nix Apps' \
                ${lib.strings.concatStringsSep " " (
                  map (drv: "${getInstallMethodPrefix drv}:${drv.outPath}") hmApps
                )}
              ''
            );
        }
      )
    ];

    system.build.applications = pkgs.buildEnv {
      name = "system-applications";
      paths = [ ];
      pathsToLink = "/Applications";
    };

    system.activationScripts.applications.text =
      let
        systemApps = filterPackagesWithMacApps config.environment.systemPackages;
      in
      ''
        ${linkApps} --destination '/Applications/Nix Apps' \
        ${lib.strings.concatStringsSep " " (
          map (drv: "${getInstallMethodPrefix drv}:${drv.outPath}") systemApps
        )}
      '';
  };
}

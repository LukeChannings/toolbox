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
  inherit (lib) mkOption types getExe;
  inherit (lib.strings) concatStringsSep optionalString;
  cfg = config.toolbox.link-apps;

  withInstallationMethod =
    method: drv:
    assert lib.asserts.assertOneOf "method" method [
      "alias"
      "copy"
      "symlink"
    ];
    drv.overrideAttrs (_: _: { meta.darwinInstallMethod = method; });
  installByCopying = map (withInstallationMethod "copy");
  installBySymlinking = map (withInstallationMethod "symlink");
  installByAliasing = map (withInstallationMethod "alias");
  filterPackagesWithMacApps = filter (drv: (readDir drv.outPath).Applications or null == "directory");
  mkAppLinker =
    {
      packages,
      destination,
      verbose,
      dryRun,
    }:
    let
      getInstallMethodPrefix = drv: (substring 0 1 (drv.meta.darwinInstallMethod or "alias"));
      getAppDerivationPaths =
        apps: concatStringsSep " " (map (drv: "${getInstallMethodPrefix drv}:${drv.outPath}") apps);
    in
    ''
      ${getExe cfg.package} \
          ${optionalString verbose "--verbose"} \
          ${optionalString dryRun "--dry-run"} \
          --destination '${destination}' \
          ${getAppDerivationPaths (filterPackagesWithMacApps packages)}
    '';
in
{
  options.toolbox.link-apps = {
    package = mkOption {
      type = types.package;
      default = pkgs.${toolbox.nixpkgs-namespace}.link-apps;
    };
    verbose = mkOption {
      type = types.bool;
      description = "When true the link-apps command will log its execution plan and commands during activation";
      default = false;
    };
    dryRun = mkOption {
      type = types.bool;
      description = "When true the link-apps command will not execute its commands, only log its execution plan";
      default = false;
    };
    userAppPath = mkOption {
      type = types.str;
      description = "The path in the user's home directory where applications will be installed. e.g. apps found in home.packages";
      default = "/Applications/Nix Apps";
    };
    systemAppPath = mkOption {
      type = types.str;
      description = "The absolute path to install applications globally. e.g. apps found in environment.systemPackages";
      default = "/Applications/Nix Apps";
    };
  };

  # Disable nix-darwin's default app linking module
  disabledModules = [ "${modulesPath}/system/applications.nix" ];

  config = {
    nixpkgs.overlays = [
      (final: prev: {
        ${toolbox.nixpkgs-namespace} = {
          inherit (toolbox.packages.${final.system}) link-apps;
          lib = {
            inherit
              withInstallationMethod
              installByCopying
              installBySymlinking
              installByAliasing
              mkAppLinker
              filterPackagesWithMacApps
              ;
          };
        };
      })
    ];

    system.build.applications = pkgs.buildEnv {
      name = "system-applications";
      paths = [ ];
      pathsToLink = "/Applications";
    };

    system.activationScripts.applications.text = mkAppLinker {
      packages = config.environment.systemPackages;
      destination = cfg.systemAppPath;
      verbose = cfg.verbose;
      dryRun = cfg.dryRun;
    };

    home-manager.sharedModules = [
      (
        { modulesPath, config, ... }:
        {
          # Disable Home Manager's default app linking module.
          disabledModules = [ "${modulesPath}/targets/darwin/linkapps.nix" ];

          home.activation.applications = mkAppLinker {
            packages = config.home.packages;
            destination = "${config.home.homeDirectory}${cfg.userAppPath}";
            verbose = cfg.verbose;
            dryRun = cfg.dryRun;
          };
        }
      )
    ];
  };
}

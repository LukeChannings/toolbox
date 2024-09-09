export type StatusCode = number;

export interface Options {
  packages: Package[];
  destination: string;
  verbose?: boolean;
}

export interface Package {
  path: string;
  installationMethod: InstallationMethod;
}

export interface ResolvedPackage extends Package {
  realPath: string;
}

export type InstallationMethod = "alias" | "symlink" | "copy";

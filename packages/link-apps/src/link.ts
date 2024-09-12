import type {
  Options,
  StatusCode,
  InstallationMethod,
  ResolvedPackage,
} from "./types.ts";
import { realPath as getRealAliasPath } from "./macos_alias.ts";

export async function link({
  destination,
  packages,
  verbose,
}: Options): Promise<StatusCode> {
  await sanitiseDestinationPath(destination, true);
  const actions = await makePlan({ destination, packages });

  for await (const [cmd, ...args] of actionsToCommands(actions)) {
    if (verbose) {
      console.log([cmd, ...args].join(" "));
    }

    const command = new Deno.Command(cmd, {
      args,
      stdin: "piped",
      stdout: "piped",
    });

    const child = command.spawn();

    child.stdin.close();

    if ((await child.status).code > 0) {
      console.error(`Error running ${[cmd, ...args].join(" ")}`);
      return 1;
    }
  }

  return 0;
}

export async function linkDryRun({
  destination,
  packages,
}: Options): Promise<StatusCode> {
  const actions = await makePlan({ destination, packages });

  console.log(
    actionsToCommands(actions)
      .map((cmd) => cmd.join(" "))
      .join("\n"),
  );

  return 0;
}

type Action =
  | { type: "delete-link"; path: string }
  | { type: "delete-copy"; path: string }
  | { type: InstallationMethod; src: string; destination: string };

async function makePlan({ destination, packages }: Options) {
  // Get the state of the destination folder now
  const currentState = await getExistingDestinationState(destination);

  // Get the desired state of the destination folder
  const desiredState = await getDesiredState({ destination, packages });

  // Calculate the difference
  return computeActions(currentState ?? [], desiredState);
}

async function computeActions(
  currentPkgs: ResolvedPackage[],
  desiredPkgs: ResolvedPackage[],
) {
  const actions: Action[] = [];

  // Delete any packages that are in the current generation
  // but aren't in the desired generation.
  for (const pkg of currentPkgs) {
    if (!desiredPkgs.some(({ path }) => pkg.path === path)) {
      actions.push({
        type: pkg.installationMethod === "copy" ? "delete-copy" : "delete-link",
        path: pkg.path,
      });
    }
  }

  for (const pkg of desiredPkgs) {
    const currentPkg = currentPkgs.find(
      (currentPkg) => currentPkg.path === pkg.path,
    );

    // If the package is the same in the current
    // and new generation then do nothing.
    if (
      currentPkg?.realPath === pkg.realPath &&
      pkg.installationMethod === currentPkg.installationMethod
    ) {
      continue;
    }

    // If the package is going to be copied we can use the app's
    // code signature to determine if the current and desired
    // apps are the same.
    if (currentPkg?.installationMethod === "copy") {
      const [installedHash, desiredHash] = await Promise.all([
        getAppSignature(currentPkg.path),
        getAppSignature(pkg.path),
      ]);

      if (installedHash === desiredHash) {
        continue;
      }
    }

    // If the new generation has a new destination path or installation method
    // then delete the existing file
    if (
      currentPkg?.installationMethod !== pkg.installationMethod ||
      currentPkg?.realPath !== pkg.realPath
    ) {
      actions.push({
        type: pkg.installationMethod === "copy" ? "delete-copy" : "delete-link",
        path: pkg.path,
      });
    }

    // Create the new package
    actions.push({
      type: pkg.installationMethod,
      src: pkg.realPath,
      destination: pkg.path,
    });
  }

  return actions;
}

function actionsToCommands(actions: Action[]): string[][] {
  return actions.flatMap((action) => {
    switch (action.type) {
      case "delete-link":
        return [["rm", "-f", action.path]];
      case "delete-copy":
        return [["rm", "-rf", action.path]];
      case "symlink":
        return [["ln", "-sf", action.src, action.destination]];
      case "alias":
        return [["mkalias", action.src, action.destination]];
      case "copy":
        return [
          ["cp", "-R", action.src, action.destination],
          ["chmod", "-R", "ug+rwx", action.destination],
        ];
    }
  });
}

async function sanitiseDestinationPath(
  destination: string,
  overwrite: boolean,
) {
  try {
    const fileInfo = await Deno.lstat(destination);

    if (!fileInfo.isDirectory) {
      throw new Deno.errors.AlreadyExists("Already exists and is a file!");
    }
  } catch (err) {
    // Doesn't exist, create it.
    if (err instanceof Deno.errors.NotFound) {
      await Deno.mkdir(destination, { recursive: true });
    }

    if (err instanceof Deno.errors.AlreadyExists) {
      if (!overwrite) {
        throw new Error(
          `${destination} already exists and is not a directory.`,
        );
      }

      await Deno.remove(destination, { recursive: true });
      await Deno.mkdir(destination);
    }
  }
}

export async function getExistingDestinationState(destinationPath: string) {
  try {
    const pkgs: ResolvedPackage[] = [];

    for await (const entry of Deno.readDir(destinationPath)) {
      if (!entry.name.endsWith(".app")) {
        continue;
      }

      const path = `${destinationPath}/${entry.name}`;
      let realPath = path;

      let installationMethod: InstallationMethod;

      if (entry.isSymlink) {
        installationMethod = "symlink";
        realPath = await Deno.realPath(path);
      } else if (entry.isFile) {
        installationMethod = "alias";
        realPath = await getRealAliasPath(path);
      } else {
        installationMethod = "copy";
        realPath = path;
      }

      pkgs.push({
        path,
        realPath,
        installationMethod,
      });
    }
    return pkgs;
  } catch (err) {
    console.error(err);
  }
}

export async function getDesiredState({ destination, packages }: Options) {
  return (
    await Promise.all(
      packages.map(async (pkg) => {
        const appBundles = await getAppBundles(pkg.path);

        return appBundles.map(
          (appBundle) =>
            ({
              installationMethod: pkg.installationMethod,
              realPath: appBundle.realPath,
              path: `${destination}/${appBundle.name}`,
            }) as ResolvedPackage,
        );
      }),
    )
  ).flat();
}

async function getAppBundles(drvPath: string) {
  const appBundles: Array<{
    name: string;
    realPath: string;
  }> = [];

  for await (const dir of Deno.readDir(drvPath + "/Applications")) {
    if (dir.isDirectory && dir.name.endsWith(".app")) {
      appBundles.push({
        realPath: `${drvPath}/Applications/${dir.name}`,
        name: dir.name,
      });
    }
  }

  return appBundles;
}

async function getAppSignature(path: string): Promise<string | null> {
  const command = new Deno.Command("/usr/bin/codesign", {
    args: ["-dv", "--verbose=4", path],
  });
  const { code, stderr } = await command.output();

  const decoder = new TextDecoder();

  if (code !== 0) {
    console.error(`Failed to get a signature for ${path}`);
    return null;
  }

  const output = decoder.decode(stderr);

  const hash =
    output
      ?.split("\n")
      ?.find((line) => line.startsWith("CandidateCDHashFull"))
      ?.replace("CandidateCDHashFull ", "") ?? null;

  return hash;
}

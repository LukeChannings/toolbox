import { assert } from "@std/assert";
import { parseArgs } from "jsr:@std/cli/parse-args";
import type { Options, Package } from "./types.ts";

export type CLI =
  | { command: "help" | "version" }
  | { command: "link" | "link-dry-run"; options: Options };

export function processCLIArguments(args: string[]): CLI {
  try {
    const flags = parseArgs(args, {
      boolean: ["help", "verbose", "version", "dry-run"],
      alias: { help: "h", version: "v", "dry-run": "d" },
      string: ["destination"],
    });

    if (flags["help"]) {
      return { command: "help" };
    }

    if (flags["version"]) {
      return { command: "version" };
    }

    if (flags["destination"] || flags["_"].length) {
      const destination = flags["destination"];
      const paths = flags["_"].filter((p) => typeof p === "string") as string[];

      assert(destination != undefined, "A destination path is required");
      assert(paths.length > 0, "At least 1 derivation path must be passed");

      const command = flags["dry-run"] ? "link-dry-run" : "link";

      const options = {
        packages: paths.map((path) => parseDerivationPath(path)),
        destination,
        verbose: flags["verbose"],
      };

      return { command, options };
    }

    throw new Error("No command could be determined");
  } catch (err) {
    throw new Error(`Some flags could not be handled: ${err.message}`, {
      cause: err,
    });
  }
}

export function parseDerivationPath(drvPath: string): Package {
  const drvPathRe = /^(?:(?<method>a|s|c):)?(?<path>.+)$/;

  const match = drvPathRe.exec(drvPath);

  assert(
    match !== null && match.groups !== undefined,
    `Failed to parse derivation path: ${drvPath}`,
  );

  const { method = "a", path } = match.groups;

  const expandMethodPrefix = {
    a: "alias",
    c: "copy",
    s: "symlink",
  } as const;

  assert(
    method in expandMethodPrefix,
    `'${method}' is not a valid installation method prefix`,
  );

  return {
    path,
    installationMethod:
      expandMethodPrefix[method as keyof typeof expandMethodPrefix],
  };
}
import { expect } from "@std/expect";

import { processCLIArguments } from "./cli.ts";

Deno.test("handles help flag", () => {
  expect(processCLIArguments(["-h"])).toEqual({ command: "help" });
  expect(processCLIArguments(["--help"])).toEqual({ command: "help" });
});

Deno.test("Throws for malformed flags", () => {
  expect(() => processCLIArguments(["--verbose"])).toThrow();
});

Deno.test("Throws when drv paths are passed without destination", () => {
  expect(() =>
    processCLIArguments([
      "c:/nix/store/hch4cgcbqdd7da9drpbrabi3dmj97nq6-swish-1.10.3",
    ]),
  ).toThrow(/A destination path is required/);
});

Deno.test("Emits link-dry-run with --dry-run flag", () => {
  const options = {
    destination: "/Applications",
    packages: [
      {
        path: "/nix/store/hch4cgcbqdd7da9drpbrabi3dmj97nq6-swish-1.10.3",
        installationMethod: "alias",
      },
    ],
    verbose: false,
  };

  expect(
    processCLIArguments([
      "--destination",
      "/Applications",
      "--dry-run",
      "/nix/store/hch4cgcbqdd7da9drpbrabi3dmj97nq6-swish-1.10.3",
    ]),
  ).toEqual({
    command: "link-dry-run",
    options,
  });

  expect(
    processCLIArguments([
      "--destination=/Applications",
      "--dry-run",
      "/nix/store/hch4cgcbqdd7da9drpbrabi3dmj97nq6-swish-1.10.3",
    ]),
  ).toEqual({
    command: "link-dry-run",
    options,
  });

  expect(
    processCLIArguments([
      "--destination=/Applications",
      "/nix/store/hch4cgcbqdd7da9drpbrabi3dmj97nq6-swish-1.10.3",
    ]),
  ).toEqual({
    command: "link",
    options,
  });

  expect(
    processCLIArguments([
      "--verbose",
      "--destination=/Applications",
      "/nix/store/hch4cgcbqdd7da9drpbrabi3dmj97nq6-swish-1.10.3",
    ]),
  ).toEqual({
    command: "link",
    options: { ...options, verbose: true },
  });
});

import { processCLIArguments } from "./cli.ts";
import { help } from "./help.ts";
import { link, linkDryRun } from "./link.ts";

if (import.meta.main) {
  try {
    const cli = processCLIArguments(Deno.args);
    switch (cli.command) {
      case "link": {
        Deno.exit(await link(cli.options));
        break;
      }
      case "link-dry-run": {
        Deno.exit(await linkDryRun(cli.options));
        break;
      }
      case "help":
      default: {
        Deno.exit(help());
        break;
      }
    }
  } catch (err) {
    Deno.exit(help(err));
  }
}

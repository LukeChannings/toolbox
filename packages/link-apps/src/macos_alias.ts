// This is a heuristic - if it's more than 3kB it's probably not an alias file...
export const MAX_SIZE_BYTES = 3_000;

// Returns the path that a macOS alias file points to
export async function realPath(aliasPath: string) {
  const stat = await Deno.stat(aliasPath);

  if (!stat.isFile) {
    throw new AliasFileNotAFile(
      `The alias path "${aliasPath}" exists but is not a file`,
    );
  }

  if (stat.size > MAX_SIZE_BYTES) {
    throw new AliasTooBigError(
      `Alias file '${aliasPath}' is ${stat.size} bytes, but we don't expect alias files to be any bigger than ${MAX_SIZE_BYTES}`,
    );
  }

  const bytes = await Deno.readFile(aliasPath);

  if (!isAliasFile(bytes)) {
    throw new NotAnAliasFileError(`Not a valid macOS alias file`);
  }

  return extractPathStrings(bytes);
}

class AliasFileNotAFile extends Error {
  override name = "AliasFileNotAFile";
}

class AliasTooBigError extends Error {
  override name = "AliasTooBigError";
}

class NotAnAliasFileError extends Error {
  override name = "NotAnAliasFileError";
}

function isAliasFile(bytes: Uint8Array) {
  const header = [
    0x62, 0x6f, 0x6f, 0x6b, 0x00, 0x00, 0x00, 0x00, 0x6d, 0x61, 0x72, 0x6b,
    0x00, 0x00, 0x00, 0x00, 0x38, 0x00, 0x00, 0x00, 0x38, 0x00, 0x00, 0x00,
  ];

  return bytes
    .subarray(0, header.length - 1)
    .every((byte, index) => byte === header[index]);
}

function extractPathStrings(bytes: Uint8Array) {
  let finalPath = "";
  let path = "";

  for (const byte of bytes.subarray(50)) {
    if (byte >= 0x20 && byte <= 0x7e) {
      path += String.fromCharCode(byte);
    } else {
      // Assumption: The longest path is the real path
      if (path.startsWith("file:/") && path.length > finalPath.length) {
        finalPath = path;
      }
      path = "";
    }
  }

  return finalPath.replace("file://", "");
}

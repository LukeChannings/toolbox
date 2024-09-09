{
  lib,
  stdenv,
  unzip,
  deno,
  mkalias,
  autoPatchelfHook,
  makeBinaryWrapper,
}:
stdenv.mkDerivation rec {
  name = "link-apps";
  pname = name;

  src = ./.;

  nativeBuildInputs = [
    unzip
    deno
    autoPatchelfHook
    makeBinaryWrapper
  ];

  dontFixup = true;

  buildInputs = [ stdenv.cc.cc ];

  installPhase = ''
    # Create a temporary directory for Nix to cache dependencies
    export DENO_DIR="$TMPDIR"

    deno compile -A --lock=deno.lock --cached-only --output $out/bin/link-apps ./src/main.ts

    wrapProgram $out/bin/link-apps --prefix PATH : ${lib.makeBinPath [ mkalias ]}
  '';

  doCheck = true;

  checkPhase = ''
    export DENO_DIR="$TMPDIR"

    # Lint all source files
    deno lint src/

    # Typecheck the main program
    deno check src/main.ts

    # Run tests
    deno test -A src/
  '';

  doFixup = false;

  meta = {
    homepage = "https://github.com/lukechannings/toolbox/packages/link-apps";
    description = "A tool for installing Nix packages containing macOS apps";
    platforms = lib.platforms.darwin;
    mainProgram = "link-apps";
  };
}

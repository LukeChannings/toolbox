{
  lib,
  swift,
  swiftpm,
  swiftpm2nix,
  swiftPackages,
}:
let
  generated = swiftpm2nix.helpers ./nix;
in
swift.stdenv.mkDerivation {
  pname = "mkalias";
  version = "1.0.0";

  # Foundation.NSURL on Linux does not support aliases
  # https://github.com/apple/swift-corelibs-foundation/blob/main/Sources/Foundation/NSURL.swift#L1372
  meta.platforms = lib.platforms.darwin;

  src = ./.;

  # Including SwiftPM as a nativeBuildInput provides a buildPhase for you.
  # This by default performs a release build using SwiftPM, essentially:
  #   swift build -c release
  nativeBuildInputs = [
    swift
    swiftpm
  ];

  buildInputs = [ swiftPackages.Foundation ];

  # The helper provides a configure snippet that will prepare all dependencies
  # in the correct place, where SwiftPM expects them.
  configurePhase = generated.configure;

  installPhase = ''
    # This is a special function that invokes swiftpm to find the location
    # of the binaries it produced.
    binPath="$(swiftpmBinPath)"

    # Now perform any installation steps.
    mkdir -p $out/bin
    cp $binPath/mkalias $out/bin/
  '';
}

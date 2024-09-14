# `link-apps`

A replacement for the default [`buildEnv`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/buildenv/builder.pl) that's specialised to installing macOS .app files.

## Usage

```
link-apps --destination=<path> [<derivation-path> | a:<derivation-path> | c:<derivation-path> | s:<derivation-path>]

Arguments:

--destination=<path>  A folder where the applications will be installed.

                      This folder is entirely managed by this script,
                      and apps not listed in derivation paths will be
                      permanently deleted from the destination path!
  
<derivation-path>     A derivation output path, optionally prefixed with a letter
                      signifying the preferred installation method, followed by a colon.
                      If a prefix is not specified, the default installation method will be used.
  
                      Installation Methods:
  
                      - a: Alias (DEFAULT) - create a macOS Finder alias pointing to the Nix Store app bundle
                      - s: Symlink - create a symlink pointing to the Nix Store app bundle
                      - c: Copy - copy the app bundle into the destination path
  
                      Example:
                      
                      c:/nix/store/hch4cgcbqdd7da9drpbrabi3dmj97nq6-swish-1.10.3 /nix/store/xnncs09bxncyfv7jj4ddcl032v3mqcgl-maccy-1.0.0
                      
                      - swish will be copied
                      - maccy will be aliased (no prefix defaults to alias).
                      - no apps will be symlinked

Flags:  
  
--help -h              Display this help
--dry-run -d           Print the install plan but do not actually install
--verbose              Print debug messages
```

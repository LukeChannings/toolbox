# `link-apps`

Provides additional options to how macOS `.app` files are installed.

By default Nix likes to install things using symlinks.

Whilst this is a clean approach there are areas where it clashes with how things
work in macOS:

1. Spotlight will not index apps that are symlinks, and `/nix` is excluded from
   the Spotlight index
2. Some apps require being installed to `/Applications`. One difficult to ignore
   example is 1Password, which requires all web browsers it interfaces with to
   be installed to `/Applications` for security reasons.

## Implementation

This module overrides the default macos app linking mechanisms for nix-darwin and home-manager.

The replacement linker is implemented in [packages/link-apps](/packages/link-apps/), it:

- Makes macOS alias files by default
- Optionally copies an app to the destination when `drv.meta.darwinInstallMethod` is set to `copy`.

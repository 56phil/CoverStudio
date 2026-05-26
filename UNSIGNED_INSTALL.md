# Installing An Unsigned Build

CoverStudio test builds may be distributed before the app is signed and notarized
with Apple Developer ID. macOS will warn you because it cannot verify the
developer, not necessarily because anything is wrong with the app.

Only install unsigned builds if you trust the source.

## Install

1. Download the `CoverStudio-...dmg` file from GitHub Releases.
2. Open the DMG.
3. Drag `CoverStudio.app` into `Applications`.

## First Launch

If macOS blocks the first launch:

1. Open `Applications`.
2. Control-click or right-click `CoverStudio.app`.
3. Choose `Open`.
4. In the warning dialog, choose `Open` again.

After the first successful launch, CoverStudio should open normally.

## If macOS Still Blocks It

Open `System Settings > Privacy & Security`. Near the bottom of the page,
macOS may show a message that CoverStudio was blocked. Choose `Open Anyway`.

## Notes For Testers

- Unsigned builds are intended for early testing.
- Prefer downloading from the GitHub Releases page, not from random shared files.
- When signed and notarized builds become available, use those instead.

# Release Checklist

CoverStudio is intended to ship as a macOS DMG attached to a GitHub Release.

## First-Time Apple Setup

1. Join the Apple Developer Program.
2. Create or install a `Developer ID Application` certificate.
3. Create a notarytool keychain profile:

```sh
xcrun notarytool store-credentials coverstudio-notary
```

Use your Apple ID, team ID, and an app-specific password when prompted.

## Versioning

The version is declared once, in `Sources/CoverStudio/CLI.swift`:

```swift
let coverStudioVersion = "0.1.13"
```

`scripts/version.sh` reads that line, and `build-app.sh` and `package-release.sh`
both call it. So `CoverStudio --version`, the bundle's `CFBundleShortVersionString`,
and the DMG filename all come from the same string.

Bump that line to cut a release. Editing a version inside a built `.app` changes
nothing that ships, and a second copy of the number is how the CLI once drifted to
0.1.0 while the bundle moved on.

## Build A Local Test DMG

```sh
./scripts/package-release.sh
```

This creates:

```text
dist/CoverStudio-<version>.dmg
```

Unsigned DMGs are useful for your own testing, but they are not ideal for public users.
If you share one with testers, include `UNSIGNED_INSTALL.md` in the release notes.

## Build A Signed And Notarized DMG

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="coverstudio-notary" \
./scripts/package-release.sh
```

The script:

1. Builds `CoverStudio.app`, ad-hoc signed.
2. Re-signs the app with `SIGN_IDENTITY` when it is set.
3. Creates a drag-to-Applications DMG.
4. Signs the DMG.
5. Notarizes and staples the DMG when `NOTARY_PROFILE` is set.

## Publish On GitHub

1. Create a new GitHub Release, such as `v<version>`.
2. Attach `dist/CoverStudio-<version>.dmg`.
3. Mention the minimum macOS version and any notable changes.
4. Tell users to download the DMG from Releases, not the source ZIP.

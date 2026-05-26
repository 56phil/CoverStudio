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

## Build A Local Test DMG

```sh
./scripts/package-release.sh 0.1.0
```

This creates:

```text
dist/CoverStudio-0.1.0.dmg
```

Unsigned DMGs are useful for your own testing, but they are not ideal for public users.
If you share one with testers, include `UNSIGNED_INSTALL.md` in the release notes.

## Build A Signed And Notarized DMG

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="coverstudio-notary" \
./scripts/package-release.sh 0.1.0
```

The script:

1. Builds `CoverStudio.app`.
2. Signs the app when `SIGN_IDENTITY` is set.
3. Creates a drag-to-Applications DMG.
4. Signs the DMG.
5. Notarizes and staples the DMG when `NOTARY_PROFILE` is set.

## Publish On GitHub

1. Create a new GitHub Release, such as `v0.1.0`.
2. Attach `dist/CoverStudio-0.1.0.dmg`.
3. Mention the minimum macOS version and any notable changes.
4. Tell users to download the DMG from Releases, not the source ZIP.

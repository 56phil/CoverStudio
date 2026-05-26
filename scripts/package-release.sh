#!/bin/bash
# Build a release app bundle and package it as a DMG.
#
# Optional signing/notarization:
#   SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE="notarytool-profile-name" \
#   ./scripts/package-release.sh 0.1.0
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
APP_NAME="CoverStudio"
APP_BUNDLE="$PROJECT_DIR/.build/release/${APP_NAME}.app"
DIST_DIR="$PROJECT_DIR/dist"
STAGING_DIR="$DIST_DIR/${APP_NAME}-${VERSION}"
DMG_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.dmg"
VOLUME_NAME="${APP_NAME} ${VERSION}"

echo "=== Building ${APP_NAME} ${VERSION} ==="
VERSION="$VERSION" BUILD_NUMBER="$BUILD_NUMBER" "$PROJECT_DIR/build-app.sh"

echo "=== Preparing staging folder ==="
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"
ditto "$APP_BUNDLE" "$STAGING_DIR/${APP_NAME}.app"
ln -s /Applications "$STAGING_DIR/Applications"

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
    echo "=== Signing app ==="
    codesign --force --deep --options runtime --timestamp \
        --sign "$SIGN_IDENTITY" "$STAGING_DIR/${APP_NAME}.app"
else
    echo "=== Skipping signing; set SIGN_IDENTITY to sign the app ==="
fi

echo "=== Creating DMG ==="
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
    echo "=== Signing DMG ==="
    codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"
fi

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    echo "=== Notarizing DMG ==="
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait

    echo "=== Stapling notarization ticket ==="
    xcrun stapler staple "$DMG_PATH"
else
    echo "=== Skipping notarization; set NOTARY_PROFILE to notarize ==="
fi

echo "=== Release artifact ready ==="
echo "$DMG_PATH"

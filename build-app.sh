#!/bin/bash
# Build CoverStudio.app from the Swift package
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_DIR="$BUILD_DIR/CoverStudio.app"
BINARY="$BUILD_DIR/CoverStudio"
VERSION="${VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

echo "=== Building release binary ==="
cd "$PROJECT_DIR"
swift build -c release

echo "=== Assembling .app bundle ==="
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Binary
cp "$BINARY" "$APP_DIR/Contents/MacOS/CoverStudio"
chmod +x "$APP_DIR/Contents/MacOS/CoverStudio"

# Icon
cp "$PROJECT_DIR/Sources/CoverStudio/Resources/AppIcon.icns" \
   "$APP_DIR/Contents/Resources/AppIcon.icns"

# Resources bundle (Yams, etc.)
cp -R "$BUILD_DIR/CoverStudio_CoverStudio.bundle" \
      "$APP_DIR/Contents/Resources/" 2>/dev/null || true

# PkgInfo (required for proper .app identity)
echo -n "APPL????" > "$APP_DIR/Contents/PkgInfo"

# Info.plist
cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Cover Studio</string>
    <key>CFBundleExecutable</key>
    <string>CoverStudio</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.coverstudio.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Cover Studio</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSBackgroundOnly</key>
    <false/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
PLIST

echo "=== App bundle ready ==="
echo "$APP_DIR"
echo ""
echo "To install:"
echo "  cp -R $APP_DIR /Applications/"
echo ""
echo "To launch:"
echo "  open $APP_DIR"

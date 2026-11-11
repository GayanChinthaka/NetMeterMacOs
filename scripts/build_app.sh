#!/bin/bash
# Builds build/NetMeter.app.
#
# Optional environment variables (used by the release workflow):
#   UNIVERSAL=1          build for both Apple Silicon and Intel
#   APP_VERSION=1.2.3    stamp this version into the app's Info.plist
#   BUILD_NUMBER=42      stamp this build number into the app's Info.plist
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

if [ "${UNIVERSAL:-0}" = "1" ]; then
    # Build each architecture on its own and join them with lipo. A single
    # `swift build --arch arm64 --arch x86_64` needs full Xcode; this works with
    # just the Command Line Tools too.
    echo "🔨 Building NetMeter (Release, universal: arm64 + x86_64)..."
    SLICES=()
    for ARCH in arm64 x86_64; do
        echo "   • $ARCH"
        ARGS=(-c release --triple "$ARCH-apple-macosx13.0")
        swift build "${ARGS[@]}"
        SLICES+=("$(swift build "${ARGS[@]}" --show-bin-path)/NetMeter")
    done
    BIN_PATH="$PROJECT_DIR/.build/NetMeter-universal"
    lipo -create "${SLICES[@]}" -output "$BIN_PATH"
else
    echo "🔨 Building NetMeter (Release mode)..."
    swift build -c release
    BIN_PATH="$(swift build -c release --show-bin-path)/NetMeter"
fi

APP_DIR="$PROJECT_DIR/build/NetMeter.app"
PLIST="$APP_DIR/Contents/Info.plist"

echo "📦 Assembling NetMeter.app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/NetMeter"
chmod +x "$APP_DIR/Contents/MacOS/NetMeter"

cp "$PROJECT_DIR/Resources/Info.plist" "$PLIST"
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

if [ -n "${APP_VERSION:-}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$PLIST"
fi
if [ -n "${BUILD_NUMBER:-}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$PLIST"
fi

echo -n "APPL????" > "$APP_DIR/Contents/PkgInfo"

echo "🔏 Ad-hoc codesigning NetMeter.app..."
codesign --force --deep --sign - "$APP_DIR"

VERSION_STR="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
ARCHS="$(lipo -archs "$APP_DIR/Contents/MacOS/NetMeter")"
echo "✅ Build Successful! (version $VERSION_STR, $ARCHS)"
echo "📍 Location: $APP_DIR"

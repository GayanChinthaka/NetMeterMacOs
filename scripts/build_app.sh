#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "🔨 Building NetMeter (Release mode)..."
swift build -c release

BIN_PATH="$PROJECT_DIR/.build/release/NetMeter"
APP_DIR="$PROJECT_DIR/build/NetMeter.app"

echo "📦 Assembling NetMeter.app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/NetMeter"
chmod +x "$APP_DIR/Contents/MacOS/NetMeter"

cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

echo -n "APPL????" > "$APP_DIR/Contents/PkgInfo"

echo "🔏 Ad-hoc codesigning NetMeter.app..."
codesign --force --deep --sign - "$APP_DIR"

echo "✅ Build Successful!"
echo "📍 Location: $APP_DIR"


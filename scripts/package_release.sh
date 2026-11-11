#!/bin/bash
# Packages build/NetMeter.app into release files in dist/:
#   NetMeter-v<version>-macOS.dmg   drag-to-Applications disk image
#   NetMeter-v<version>-macOS.zip   zipped app
#   checksums-sha256.txt
#
# Run scripts/build_app.sh first.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$PROJECT_DIR/build/NetMeter.app"
DIST_DIR="$PROJECT_DIR/dist"

if [ ! -d "$APP_DIR" ]; then
    echo "❌ $APP_DIR not found. Run scripts/build_app.sh first." >&2
    exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist")"
BASE_NAME="NetMeter-v${VERSION}-macOS"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "🗜️  Creating $BASE_NAME.zip..."
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$DIST_DIR/$BASE_NAME.zip"

echo "💿 Creating $BASE_NAME.dmg..."
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP_DIR" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create \
    -volname "NetMeter $VERSION" \
    -srcfolder "$STAGING" \
    -fs HFS+ \
    -format UDZO \
    -ov \
    "$DIST_DIR/$BASE_NAME.dmg" >/dev/null

echo "🔐 Writing checksums..."
(cd "$DIST_DIR" && shasum -a 256 *.dmg *.zip > checksums-sha256.txt)

echo "✅ Release files:"
ls -lh "$DIST_DIR"

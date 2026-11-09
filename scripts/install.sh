#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_SRC="$PROJECT_DIR/build/NetMeter.app"
DEST_APP="/Applications/NetMeter.app"

echo "🔨 Building app..."
"$PROJECT_DIR/scripts/build_app.sh"

echo "🛑 Stopping any running NetMeter instance..."
killall NetMeter 2>/dev/null || true

echo "📂 Installing to /Applications/NetMeter.app..."
rm -rf "$DEST_APP"
cp -R "$APP_SRC" "$DEST_APP"

echo "🚀 Launching /Applications/NetMeter.app..."
open "$DEST_APP"

echo "🎉 NetMeter installed and running in your Menu Bar!"


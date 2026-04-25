#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Building qopen…"
swift build -c release

APP="build/QOpen.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

BIN="$(swift build -c release --show-bin-path)/qopen"
cp "$BIN" "$APP/Contents/MacOS/QOpen"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>QOpen</string>
    <key>CFBundleIdentifier</key>
    <string>com.qopen.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>QOpen</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>QOpen needs Accessibility access to monitor keyboard shortcuts and read the Dock layout.</string>
</dict>
</plist>
PLIST

echo "✓ Built: $APP"
echo "  Run with: open $APP"

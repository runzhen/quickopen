#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Building quickopen…"
swift build -c release

APP="build/QuickOpen.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

BIN="$(swift build -c release --show-bin-path)/quickopen"
cp "$BIN" "$APP/Contents/MacOS/QuickOpen"

# Build app icon from Image.png
ICONSET="build/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
sips -z 16 16     resources/icon.png --out "$ICONSET/icon_16x16.png"
sips -z 32 32     resources/icon.png --out "$ICONSET/icon_16x16@2x.png"
sips -z 32 32     resources/icon.png --out "$ICONSET/icon_32x32.png"
sips -z 64 64     resources/icon.png --out "$ICONSET/icon_32x32@2x.png"
sips -z 128 128   resources/icon.png --out "$ICONSET/icon_128x128.png"
sips -z 256 256   resources/icon.png --out "$ICONSET/icon_128x128@2x.png"
sips -z 256 256   resources/icon.png --out "$ICONSET/icon_256x256.png"
sips -z 512 512   resources/icon.png --out "$ICONSET/icon_256x256@2x.png"
sips -z 512 512   resources/icon.png --out "$ICONSET/icon_512x512.png"
sips -z 1024 1024 resources/icon.png --out "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>QuickOpen</string>
    <key>CFBundleIdentifier</key>
    <string>com.quickopen.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>QuickOpen</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>QuickOpen needs Accessibility access to monitor keyboard shortcuts and read the Dock layout.</string>
</dict>
</plist>
PLIST

echo "✓ Built: $APP"
echo "  Run with: open $APP"

#!/bin/bash
set -euo pipefail

REPO="runzhen/quickopen"
APP_NAME="QuickOpen"
INSTALL_DIR="/Applications"

echo "Installing $APP_NAME..."

# Get latest release tag
TAG=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | head -1 | cut -d'"' -f4)

if [ -z "$TAG" ]; then
    echo "Error: Could not find latest release." >&2
    exit 1
fi

echo "Latest version: $TAG"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

ZIP_URL="https://github.com/$REPO/releases/download/$TAG/$APP_NAME-$TAG.zip"
echo "Downloading $ZIP_URL..."
curl -sL "$ZIP_URL" -o "$TMPDIR/$APP_NAME.zip"

echo "Extracting..."
unzip -qo "$TMPDIR/$APP_NAME.zip" -d "$TMPDIR"

if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo "Removing previous installation..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi

echo "Installing to $INSTALL_DIR..."
mv "$TMPDIR/$APP_NAME.app" "$INSTALL_DIR/"

echo ""
echo "✓ $APP_NAME installed to $INSTALL_DIR/$APP_NAME.app"
echo ""
echo "To start: open -a $APP_NAME"
echo ""
echo "NOTE: On first launch, macOS will ask for Accessibility permission."
echo "      Go to System Settings → Privacy & Security → Accessibility and enable $APP_NAME."

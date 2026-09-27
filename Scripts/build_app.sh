#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/DynamicNotch.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🔨 Building Dynamic Notch (Release Mode)..."
cd "$PROJECT_DIR"
swift build -c release

echo "📦 Packaging DynamicNotch.app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp ".build/release/DynamicNotch" "$MACOS_DIR/DynamicNotch"
chmod +x "$MACOS_DIR/DynamicNotch"

# Copy Info.plist
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "✅ App bundle created successfully at:"
echo "   $APP_BUNDLE"
echo ""
echo "🚀 To run the application:"
echo "   open \"$APP_BUNDLE\""
echo "   or: $MACOS_DIR/DynamicNotch"

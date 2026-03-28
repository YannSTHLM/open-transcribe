#!/bin/bash
# Open Transcribe - Build macOS .dmg installer
# Usage: bash build-dmg.sh
# Prerequisites: Run build-app.sh first

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$APP_DIR/build"
APP_BUNDLE="$BUILD_DIR/Open Transcribe.app"
DMG_NAME="Open-Transcribe-macOS"
DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"

# Check that .app exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: .app bundle not found. Run build-app.sh first."
    exit 1
fi

echo "Building $DMG_NAME.dmg..."

# -------------------------------------------------------
# Create DMG using hdiutil (built into macOS)
# -------------------------------------------------------

# Remove existing DMG if present
rm -f "$DMG_PATH"

# Create a temporary folder for DMG contents
DMG_TEMP="$BUILD_DIR/dmg_temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy .app into temp folder
cp -R "$APP_BUNDLE" "$DMG_TEMP/"

# Create a symlink to /Applications for drag-and-drop install
ln -s /Applications "$DMG_TEMP/Applications"

# Create a simple README for the DMG
cat > "$DMG_TEMP/README - First Run.txt" << 'README'
Open Transcribe - First Run Instructions
=========================================

1. Drag "Open Transcribe" to the Applications folder
2. Open "Open Transcribe" from your Applications folder
3. On first launch, the app will install all required dependencies:
   - Python 3.12
   - Node.js 20
   - FFmpeg
   - Python and Node.js packages

   This may take a few minutes.

4. After setup completes, the app will open in your browser.

Note: If macOS blocks the app, go to
System Settings > Privacy & Security and click "Open Anyway".
README

# Build the DMG
echo "Creating DMG..."
hdiutil create \
    -volname "Open Transcribe" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

# Clean up temp folder
rm -rf "$DMG_TEMP"

# Get DMG size
DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)

echo ""
echo "✅ Built: $DMG_PATH ($DMG_SIZE)"
echo ""
echo "To install: Open the DMG and drag Open Transcribe to Applications."
echo ""
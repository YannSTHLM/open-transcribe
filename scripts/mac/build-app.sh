#!/bin/bash
# Open Transcribe - Build macOS .app bundle via PyInstaller
# Usage: bash build-app.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$APP_DIR/build"
APP_NAME="Open Transcribe"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building $APP_NAME.app..."

# -------------------------------------------------------
# 1. Clean and create build directory
# -------------------------------------------------------
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# -------------------------------------------------------
# 2. Build Frontend (React -> static files)
# -------------------------------------------------------
echo "Building frontend..."
cd "$APP_DIR/frontend"
npm install
npm run build

# -------------------------------------------------------
# 3. Build Backend using PyInstaller
# -------------------------------------------------------
echo "Bundling backend via PyInstaller..."
cd "$APP_DIR/backend"

# Ensure PyInstaller is installed in the current environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment for build..."
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r requirements.txt
pip install pyinstaller

# Run PyInstaller
pyinstaller --clean -y app.spec

# -------------------------------------------------------
# 4. Construct .app bundle
# -------------------------------------------------------
echo "Constructing .app bundle..."

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Move the single folder build from PyInstaller into MacOS
cp -r "dist/OpenTranscribe/" "$APP_BUNDLE/Contents/MacOS/OpenTranscribe_Core/"

# Create a small native launcher script inside MacOS
cat > "$APP_BUNDLE/Contents/MacOS/applet" << 'LAUNCHER'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/OpenTranscribe_Core/OpenTranscribe"
LAUNCHER
chmod +x "$APP_BUNDLE/Contents/MacOS/applet"

# -------------------------------------------------------
# 5. Application Icon
# -------------------------------------------------------
# Use system icon as placeholder if we don't have one
SYSTEM_ICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarUtilitiesFolderIcon.icns"
if [ -f "$SYSTEM_ICON" ]; then
    cp "$SYSTEM_ICON" "$APP_BUNDLE/Contents/Resources/applet.icns"
fi

# -------------------------------------------------------
# 6. Update Info.plist
# -------------------------------------------------------
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>applet</string>
    <key>CFBundleIdentifier</key>
    <string>com.opentranscribe.app</string>
    <key>CFBundleName</key>
    <string>Open Transcribe</string>
    <key>CFBundleDisplayName</key>
    <string>Open Transcribe</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>applet.icns</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 Open Transcribe. MIT License.</string>
</dict>
</plist>
PLIST

# -------------------------------------------------------
# 7. Ad-hoc code sign the app
# -------------------------------------------------------
echo "Code signing..."
# Sign all executables and frameworks first (deep signing)
find "$APP_BUNDLE/Contents/MacOS" -type f -exec codesign --force --sign - {} \; 2>/dev/null || true
# Sign the app bundle itself
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

echo ""
echo "✅ Built: $APP_BUNDLE"
echo ""
echo "To test: open \"$APP_BUNDLE\""
echo ""

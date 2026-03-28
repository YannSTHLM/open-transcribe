#!/bin/bash
# Open Transcribe - Build macOS .app bundle
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
# 2. Compile AppleScript to .app bundle (creates the bundle)
# -------------------------------------------------------
echo "Compiling AppleScript..."
osacompile -o "$APP_BUNDLE" "$SCRIPT_DIR/OpenTranscribe.applescript"

# -------------------------------------------------------
# 3. Copy project files into the .app bundle
# -------------------------------------------------------
echo "Copying project files..."

# Copy backend
rsync -a --exclude='venv/' \
       --exclude='__pycache__/' \
       --exclude='*.pyc' \
       --exclude='data/' \
       --exclude='.env' \
       "$APP_DIR/backend/" "$APP_BUNDLE/Contents/Resources/backend/"

# Copy frontend
rsync -a --exclude='node_modules/' \
       --exclude='dist/' \
       "$APP_DIR/frontend/" "$APP_BUNDLE/Contents/Resources/frontend/"

# Copy scripts
mkdir -p "$APP_BUNDLE/Contents/Resources/scripts/mac"
cp "$SCRIPT_DIR/install.sh" "$APP_BUNDLE/Contents/Resources/scripts/mac/"
cp "$SCRIPT_DIR/start.sh" "$APP_BUNDLE/Contents/Resources/scripts/mac/"
cp "$SCRIPT_DIR/stop.sh" "$APP_BUNDLE/Contents/Resources/scripts/mac/"

# Create .pids directory
mkdir -p "$APP_BUNDLE/Contents/Resources/.pids"

# Create .command launcher files (pre-built to avoid AppleScript quoting issues)
cat > "$APP_BUNDLE/Contents/Resources/setup.command" << 'LAUNCHER'
#!/bin/bash
# Navigate to the app bundle directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Welcome to Open Transcribe!"
echo "Installing dependencies..."
bash "$SCRIPT_DIR/scripts/mac/install.sh" && echo "" && echo "Setup complete! Starting Open Transcribe..." && bash "$SCRIPT_DIR/scripts/mac/start.sh"
LAUNCHER

cat > "$APP_BUNDLE/Contents/Resources/start.command" << 'LAUNCHER'
#!/bin/bash
# Navigate to the app bundle directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/scripts/mac/start.sh"
LAUNCHER

chmod +x "$APP_BUNDLE/Contents/Resources/setup.command"
chmod +x "$APP_BUNDLE/Contents/Resources/start.command"

# -------------------------------------------------------
# 4. Update Info.plist
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
    <string>applet</string>
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
# 5. Make scripts executable
# -------------------------------------------------------
chmod +x "$APP_BUNDLE/Contents/Resources/scripts/mac/install.sh"
chmod +x "$APP_BUNDLE/Contents/Resources/scripts/mac/start.sh"
chmod +x "$APP_BUNDLE/Contents/Resources/scripts/mac/stop.sh"

# -------------------------------------------------------
# 6. Create a simple app icon (using system icon as placeholder)
# -------------------------------------------------------
SYSTEM_ICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarUtilitiesFolderIcon.icns"
if [ -f "$SYSTEM_ICON" ]; then
    cp "$SYSTEM_ICON" "$APP_BUNDLE/Contents/Resources/applet.icns"
fi

# -------------------------------------------------------
# 7. Ad-hoc code sign the app (required to pass Gatekeeper)
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

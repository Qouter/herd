#!/usr/bin/env bash
# Herd - Build Script
# Compiles the app and creates a .app bundle for macOS

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
BUILD_DIR="$SCRIPT_DIR/build"
APP_NAME="Herd"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Building Herd...${NC}"
echo ""

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Compiling Swift package..."
cd "$APP_DIR"
swift build -c release

echo -e "${GREEN}✓${NC} Compiled successfully"
echo ""

# Create .app bundle
echo "Creating .app bundle..."

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

EXECUTABLE="$APP_DIR/.build/release/Herd"
if [[ ! -f "$EXECUTABLE" ]]; then
  echo -e "${RED}✗ Executable not found at $EXECUTABLE${NC}"
  exit 1
fi

cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Herd</string>
    <key>CFBundleIdentifier</key>
    <string>com.qouter.herd</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Herd</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

echo -e "${GREEN}✓${NC} Created .app bundle"
echo ""
echo -e "${GREEN}✓ Build complete!${NC}"
echo ""
echo "  $APP_BUNDLE"
echo ""
echo "To install:"
echo "  cp -r '$APP_BUNDLE' /Applications/"
echo "  ./install.sh"
echo "  open /Applications/$APP_NAME.app"

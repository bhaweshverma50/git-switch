#!/bin/bash

# Git Switch DMG Creator
# Usage: ./create-dmg.sh [path-to-app]

set -e

APP_NAME="Git Switch"
DMG_NAME="GitSwitch"
VERSION="1.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Git Switch DMG Creator           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if app path is provided
if [ -z "$1" ]; then
    # Try to find the app in common locations
    if [ -d "./build/Release/${APP_NAME}.app" ]; then
        APP_PATH="./build/Release/${APP_NAME}.app"
    elif [ -d "./${APP_NAME}.app" ]; then
        APP_PATH="./${APP_NAME}.app"
    elif [ -d "$HOME/Desktop/${APP_NAME}.app" ]; then
        APP_PATH="$HOME/Desktop/${APP_NAME}.app"
    else
        echo -e "${RED}Error: Please provide the path to ${APP_NAME}.app${NC}"
        echo ""
        echo "Usage: $0 /path/to/${APP_NAME}.app"
        echo ""
        echo "To build the app:"
        echo "  1. Open 'Git Switch.xcodeproj' in Xcode"
        echo "  2. Select Product → Archive"
        echo "  3. In Organizer, click 'Distribute App'"
        echo "  4. Choose 'Copy App' and export"
        echo "  5. Run this script with the exported .app path"
        exit 1
    fi
else
    APP_PATH="$1"
fi

# Verify the app exists
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: App not found at: $APP_PATH${NC}"
    exit 1
fi

echo -e "📦 Found app at: ${GREEN}$APP_PATH${NC}"

# Detect version from the built app's Info.plist (falls back to the default above)
PLIST="$APP_PATH/Contents/Info.plist"
if [ -f "$PLIST" ]; then
    DETECTED=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST" 2>/dev/null || true)
    [ -n "$DETECTED" ] && VERSION="$DETECTED"
fi
echo -e "🏷  Version: ${GREEN}${VERSION}${NC}"

# Best-effort signing / Gatekeeper check (a notarized Developer ID build is needed
# for friction-free distribution; an unsigned app triggers Gatekeeper warnings).
if codesign --verify --deep --strict "$APP_PATH" >/dev/null 2>&1; then
    echo -e "🔏 Code signature: ${GREEN}valid${NC}"
else
    echo -e "${RED}⚠  Not validly signed — recipients will hit Gatekeeper. Sign with Developer ID and notarize for distribution.${NC}"
fi

# Create temp directory (cleaned up on any exit)
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
DMG_DIR="$TEMP_DIR/dmg"
mkdir -p "$DMG_DIR"

echo "📁 Creating DMG structure..."

# Copy app to temp directory
cp -R "$APP_PATH" "$DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Create background folder and add instructions
mkdir -p "$DMG_DIR/.background"

# Output location (optional 2nd argument; defaults to the Desktop)
OUTPUT_DIR="${2:-$HOME/Desktop}"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DMG="$OUTPUT_DIR/${DMG_NAME}-${VERSION}.dmg"
TEMP_DMG="$TEMP_DIR/temp.dmg"

# Remove existing DMG if present
if [ -f "$OUTPUT_DMG" ]; then
    echo "🗑️  Removing existing DMG..."
    rm -f "$OUTPUT_DMG"
fi

echo "💿 Creating DMG..."

# Create DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDRW \
    "$TEMP_DMG" \
    > /dev/null

echo "🔧 Converting to compressed DMG..."

# Convert to compressed read-only DMG
hdiutil convert "$TEMP_DMG" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$OUTPUT_DMG" \
    > /dev/null

# Cleanup
rm -rf "$TEMP_DIR"

# Get file size
SIZE=$(du -h "$OUTPUT_DMG" | cut -f1)

echo ""
echo -e "${GREEN}✅ DMG created successfully!${NC}"
echo ""
echo -e "📍 Location: ${BLUE}$OUTPUT_DMG${NC}"
echo -e "📊 Size: ${SIZE}"
echo ""
echo "You can now distribute this DMG file!"
echo ""
echo "Next steps:"
echo "  1. Upload to GitHub Releases"
echo "  2. Share the download link"
echo "  3. Users drag Git Switch to Applications"

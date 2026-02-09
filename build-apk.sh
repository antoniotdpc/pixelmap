#!/bin/bash
# PixelMap Build Script for macOS (APK Only)
# Generates APK that you can transfer to Android manually

set -e

echo "🗺️  PixelMap Build Script"
echo "========================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="/data/.openclaw/workspace/pixelmap"
APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
DESKTOP_APK="$HOME/Desktop/PixelMap.apk"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Flutter
install_flutter() {
    echo -e "${YELLOW}⚠️  Flutter not found. Installing...${NC}"
    
    # Check if Homebrew is installed
    if ! command_exists brew; then
        echo -e "${YELLOW}Installing Homebrew first...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install Flutter via Homebrew
    echo -e "${BLUE}Installing Flutter...${NC}"
    brew install --cask flutter
    
    # Add to PATH for this session
    export PATH="$PATH:/usr/local/flutter/bin"
    
    echo -e "${GREEN}✓ Flutter installed${NC}"
    flutter --version | head -1
}

# Check Flutter
if command_exists flutter; then
    echo -e "${GREEN}✓ Flutter found${NC}"
    flutter --version | head -1
else
    install_flutter
fi

echo ""
echo -e "${BLUE}🔨 Building PixelMap...${NC}"

cd "$PROJECT_DIR"

echo -e "${BLUE}Getting dependencies...${NC}"
flutter pub get

echo -e "${BLUE}Generating code...${NC}"
flutter pub run build_runner build --delete-conflicting-outputs 2>/dev/null || true

echo -e "${BLUE}Building APK...${NC}"
flutter build apk --release

if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build successful!${NC}"
ls -lh "$APK_PATH"

# Copy to Desktop
echo ""
echo -e "${BLUE}📋 Copying to Desktop...${NC}"
cp "$APK_PATH" "$DESKTOP_APK"
echo -e "${GREEN}✓ APK saved to: $DESKTOP_APK${NC}"

echo ""
echo -e "${GREEN}🎉 Done!${NC}"
echo ""
echo -e "${BLUE}Transfer to your Android phone:${NC}"
echo "  Option 1: AirDrop (if you have AirDrop on Android)"
echo "  Option 2: Google Drive / Dropbox / iCloud"
echo "  Option 3: Email to yourself"
echo "  Option 4: USB cable + Android File Transfer"
echo ""
echo -e "${BLUE}After transferring:${NC}"
echo "  1. Open the APK file on your phone"
echo "  2. Allow 'Install from unknown sources' if prompted"
echo "  3. Install and open PixelMap"
echo "  4. Allow location permissions"
echo ""

# Generate QR code if qrencode is available
if command_exists qrencode; then
    QR_PATH="$HOME/Desktop/pixelmap-qr.png"
    echo -e "${BLUE}Generating QR code...${NC}"
    qrencode -s 10 -o "$QR_PATH" "file://$DESKTOP_APK"
    echo -e "${GREEN}✓ QR code saved to: $QR_PATH${NC}"
    echo "  (Scan with your phone to download)"
else
    echo -e "${YELLOW}💡 Tip: Install qrencode to generate QR codes:${NC}"
    echo "  brew install qrencode"
fi

#!/bin/bash
# PixelMap Install Script for macOS
# This script checks/installs Flutter, builds the app, and installs on Android

set -e

echo "🗺️  PixelMap Auto-Installer"
echo "============================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="/data/.openclaw/workspace/pixelmap"
APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"

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
    
    # Add to PATH
    export PATH="$PATH:/usr/local/flutter/bin"
    
    # Run flutter doctor
    echo -e "${BLUE}Running Flutter doctor...${NC}"
    flutter doctor
    
    echo -e "${GREEN}✓ Flutter installed${NC}"
}

# Function to check Android SDK
check_android_sdk() {
    if [ -z "$ANDROID_SDK_ROOT" ] && [ -z "$ANDROID_HOME" ]; then
        echo -e "${YELLOW}⚠️  Android SDK not detected${NC}"
        
        # Check common locations
        if [ -d "$HOME/Library/Android/sdk" ]; then
            export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
            export ANDROID_HOME="$HOME/Library/Android/sdk"
            export PATH="$PATH:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/platform-tools"
            echo -e "${GREEN}✓ Found Android SDK at $ANDROID_SDK_ROOT${NC}"
        else
            echo -e "${YELLOW}Please install Android Studio from: https://developer.android.com/studio${NC}"
            echo -e "${YELLOW}After installation, run this script again.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Android SDK found${NC}"
    fi
}

# Function to check connected Android device
check_android_device() {
    echo ""
    echo -e "${BLUE}📱 Checking Android device...${NC}"
    
    if ! command_exists adb; then
        echo -e "${RED}❌ ADB not found. Make sure Android SDK is installed.${NC}"
        exit 1
    fi
    
    # Check if device is connected
    DEVICES=$(adb devices | grep -v "List" | grep "device$" | wc -l)
    
    if [ "$DEVICES" -eq 0 ]; then
        echo -e "${RED}❌ No Android device detected!${NC}"
        echo ""
        echo -e "${YELLOW}Please:${NC}"
        echo "  1. Connect your Android phone with USB cable"
        echo "  2. Enable USB Debugging (Settings → Developer Options → USB Debugging)"
        echo "  3. Allow this computer when prompted on your phone"
        echo ""
        echo -e "${YELLOW}To check if device is detected, run:${NC} adb devices"
        echo ""
        read -p "Press Enter after connecting your device..."
        
        # Check again
        DEVICES=$(adb devices | grep -v "List" | grep "device$" | wc -l)
        if [ "$DEVICES" -eq 0 ]; then
            echo -e "${RED}❌ Still no device detected. Please check connection.${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✓ Android device connected${NC}"
    adb devices
}

# Function to build the app
build_app() {
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
        echo -e "${RED}❌ Build failed! APK not found.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Build successful!${NC}"
    ls -lh "$APK_PATH"
}

# Function to install on Android
install_on_android() {
    echo ""
    echo -e "${BLUE}📲 Installing on Android...${NC}"
    
    # Check if we should use flutter install or adb
    if flutter devices | grep -q "android"; then
        echo -e "${BLUE}Using Flutter install...${NC}"
        flutter install
    else
        echo -e "${BLUE}Using ADB install...${NC}"
        adb install -r "$APK_PATH"
    fi
    
    echo -e "${GREEN}✓ PixelMap installed!${NC}"
}

# Function to copy APK to Desktop
copy_to_desktop() {
    DESKTOP_PATH="$HOME/Desktop"
    if [ -d "$DESKTOP_PATH" ]; then
        cp "$APK_PATH" "$DESKTOP_PATH/PixelMap.apk"
        echo -e "${GREEN}✓ APK copied to Desktop: $DESKTOP_PATH/PixelMap.apk${NC}"
    fi
}

# Main execution
main() {
    echo ""
    
    # Step 1: Check Flutter
    if command_exists flutter; then
        echo -e "${GREEN}✓ Flutter found${NC}"
        flutter --version | head -1
    else
        install_flutter
    fi
    
    # Step 2: Check Android SDK
    check_android_sdk
    
    # Step 3: Check device
    check_android_device
    
    # Step 4: Build
    build_app
    
    # Step 5: Install
    install_on_android
    
    # Step 6: Copy to desktop as backup
    copy_to_desktop
    
    echo ""
    echo -e "${GREEN}🎉 Success! PixelMap is installed on your Android device.${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Open the PixelMap app on your phone"
    echo "  2. Allow location permissions"
    echo "  3. Set up Supabase backend (see DEPLOY.md)"
    echo ""
    echo -e "${YELLOW}If you want to generate a QR code to share the APK:${NC}"
    echo "  qrencode -o ~/Desktop/pixelmap-qr.png < ~/Desktop/PixelMap.apk"
}

# Run main function
main

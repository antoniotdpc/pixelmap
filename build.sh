#!/bin/bash
# PixelMap Android Build Script
# Run this on your local machine with Flutter installed

set -e

echo "🗺️  PixelMap Android Build"
echo "=========================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found!${NC}"
    echo "Install from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✓ Flutter found${NC}"
flutter --version

# Check Android SDK
if [ -z "$ANDROID_SDK_ROOT" ] && [ -z "$ANDROID_HOME" ]; then
    echo -e "${YELLOW}⚠️  Android SDK not detected${NC}"
    echo "Make sure ANDROID_SDK_ROOT or ANDROID_HOME is set"
fi

echo ""
echo "📦 Installing dependencies..."
flutter pub get

echo ""
echo "🔧 Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "🧪 Running tests..."
flutter test

echo ""
echo "📱 Building APK..."
flutter build apk --release

echo ""
echo "📱 Building App Bundle (for Play Store)..."
flutter build appbundle --release

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo "APK location:"
echo "  build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "App Bundle location:"
echo "  build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "To install on connected device:"
echo "  flutter install"
echo ""
echo "Or manually:"
echo "  adb install build/app/outputs/flutter-apk/app-release.apk"

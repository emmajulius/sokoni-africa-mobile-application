#!/usr/bin/env bash
# Build Sokoni Africa App for production

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "🏗️  Building Sokoni Africa App for production..."
echo "================================================="
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$REPO_ROOT"

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Clean previous builds
echo -e "${BLUE}Cleaning previous builds...${NC}"
flutter clean
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# Get dependencies
echo -e "${BLUE}Getting Flutter dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Build for web
echo -e "${BLUE}Building for web...${NC}"
flutter build web --release
echo -e "${GREEN}✓ Web build completed${NC}"
echo "   Output: build/web/"
echo ""

# Build for Android (if Android SDK is available)
if command -v adb &> /dev/null || [ -n "${ANDROID_HOME:-}" ]; then
    echo -e "${BLUE}Building for Android...${NC}"
    flutter build apk --release
    echo -e "${GREEN}✓ Android APK build completed${NC}"
    echo "   Output: build/app/outputs/flutter-apk/app-release.apk"
    echo ""
fi

# Build for iOS (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v xcodebuild &> /dev/null; then
        echo -e "${BLUE}Building for iOS...${NC}"
        flutter build ios --release --no-codesign
        echo -e "${GREEN}✓ iOS build completed${NC}"
        echo "   Output: build/ios/"
        echo ""
    fi
fi

echo -e "${GREEN}✅ Production build complete!${NC}"
echo ""
echo "Build outputs:"
echo "  - Web: build/web/"
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "  - Android: build/app/outputs/flutter-apk/app-release.apk"
fi
if [[ "$OSTYPE" == "darwin"* ]] && [ -d "build/ios" ]; then
    echo "  - iOS: build/ios/"
fi
echo ""


#!/bin/bash
# Fix permissions script for Sokoni Africa App

echo "🔧 Fixing permissions for Sokoni Africa App..."
echo ""

# Fix .dart_tool ownership
echo "Fixing .dart_tool permissions..."
sudo chown -R $(whoami):staff .dart_tool 2>/dev/null || echo "Note: Some .dart_tool files may need manual fix"

# Fix build directories
echo "Fixing build directories..."
sudo chown -R $(whoami):staff build 2>/dev/null || echo "No build directory found"
sudo chown -R $(whoami):staff android/build 2>/dev/null || echo "No android/build directory found"
sudo chown -R $(whoami):staff ios/build 2>/dev/null || echo "No ios/build directory found"

# Fix Gradle wrapper
echo "Fixing Gradle wrapper permissions..."
sudo chown -R $(whoami):staff android/.gradle 2>/dev/null || echo "No .gradle directory found"
sudo chown $(whoami):staff android/gradle/wrapper/gradle-wrapper.jar 2>/dev/null || echo "gradle-wrapper.jar already fixed"

# Fix pubspec.lock if needed
if [ -f "pubspec.lock" ]; then
    sudo chown $(whoami):staff pubspec.lock 2>/dev/null || echo "pubspec.lock already fixed"
fi

echo ""
echo "✅ Permission fixes applied!"
echo ""
echo "Next steps:"
echo "1. Run: flutter clean"
echo "2. Run: flutter pub get"
echo "3. Run: flutter run (without sudo!)"


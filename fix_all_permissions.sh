#!/bin/bash
# Comprehensive fix for Sokoni Africa App - Fix all permissions created by sudo flutter create

echo "🔧 Fixing ALL permissions for Sokoni Africa App..."
echo "This will fix ownership of all files created by 'sudo flutter create'"
echo ""

PROJECT_DIR="/Users/Mwaka/flutter/Practices/sokoni_africa_app"
USER=$(whoami)

echo "Project directory: $PROJECT_DIR"
echo "Changing ownership to: $USER:staff"
echo ""

# Fix entire project directory recursively
echo "⏳ Fixing ownership of entire project..."
sudo chown -R $USER:staff "$PROJECT_DIR"

if [ $? -eq 0 ]; then
    echo "✅ Successfully fixed all permissions!"
    echo ""
    echo "Verifying ownership..."
    ls -ld "$PROJECT_DIR" | awk '{print "Root directory: "$3":"$4}'
    ls -ld "$PROJECT_DIR/.dart_tool" 2>/dev/null | awk '{print ".dart_tool: "$3":"$4}'
    ls -ld "$PROJECT_DIR/pubspec.lock" 2>/dev/null | awk '{print "pubspec.lock: "$3":"$4}'
    ls -ld "$PROJECT_DIR/android/gradle/wrapper/gradle-wrapper.jar" 2>/dev/null | awk '{print "gradle-wrapper.jar: "$3":"$4}'
    echo ""
    echo "🎉 All files are now owned by $USER:staff"
    echo ""
    echo "Next steps:"
    echo "1. Run: flutter clean"
    echo "2. Run: flutter pub get"
    echo "3. Run: flutter run (without sudo!)"
else
    echo "❌ Failed to fix permissions. Please run manually:"
    echo "sudo chown -R $USER:staff $PROJECT_DIR"
fi


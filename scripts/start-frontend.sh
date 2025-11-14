#!/usr/bin/env bash
# Start Flutter frontend development server

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "📱 Starting Flutter frontend..."
echo "================================"
echo ""

cd "$REPO_ROOT"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Check if dependencies are installed
if [ ! -d "build" ] && [ ! -f "pubspec.lock" ]; then
    echo "⚠️  Dependencies not installed. Running 'flutter pub get'..."
    flutter pub get
fi

# Detect available devices
echo "🔍 Detecting available devices..."
DEVICES=$(flutter devices --machine | grep -c "device" || echo "0")

if [ "$DEVICES" -eq "0" ]; then
    echo "⚠️  No devices found. Starting in Chrome..."
    flutter run -d chrome --web-port=8080
else
    echo "Available devices:"
    flutter devices
    echo ""
    echo "Starting Flutter app on default device..."
    echo "To specify a device, use: flutter run -d <device-id>"
    flutter run
fi


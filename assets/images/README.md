# App Icon and Splash Screen Setup

## Instructions

1. **App Icon** (`app_icon.png`):
   - Place your app icon image here
   - Recommended size: **1024x1024 pixels**
   - Format: PNG (with transparency if needed)
   - The image will be automatically resized for all platforms (Android, iOS, Web, Windows, macOS)

2. **Splash Screen** (`splash.png`):
   - Place your splash screen image here
   - Recommended size: **1080x1920 pixels** (portrait) or **1920x1080 pixels** (landscape)
   - Format: PNG or JPG
   - This will be displayed when the app launches

## After Adding Images

Once you've placed both images in this folder, run:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

Or simply:
```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

This will automatically:
- Generate all required icon sizes for Android and iOS
- Create splash screens for all platforms
- Update all necessary configuration files

## Notes

- The app icon should be square (1:1 aspect ratio)
- The splash screen can be any aspect ratio, but portrait (9:16) is recommended for mobile apps
- Both images will be automatically optimized and resized for different screen densities


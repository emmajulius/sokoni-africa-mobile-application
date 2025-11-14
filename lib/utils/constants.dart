import 'package:flutter/foundation.dart';

class AppConstants {
  // === API BASE URL CONFIGURATION ===
  // Production URL (Render deployment)
  static const String defaultLanBaseUrl = 'https://sokoni-africa-app.onrender.com';
  static const String webLocalhostBaseUrl = 'https://sokoni-africa-app.onrender.com';
  // Development URLs (for local testing)
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000';
  static const String iosSimulatorBaseUrl = 'http://127.0.0.1:8000';
  static const String desktopLocalhostBaseUrl = 'http://127.0.0.1:8000';
  // Local development URL (uncomment to use local backend)
  // static const String defaultLanBaseUrl = 'http://192.168.1.186:8000';

  /// Toggle this to `true` when running on the Android emulator.
  /// For real devices keep it `false` so the LAN IP is used.
  static const bool useAndroidEmulatorBaseUrl = false;

  /// Returns the most appropriate base URL depending on the current platform.
  static String get baseUrl {
    if (kIsWeb) {
      if (webLocalhostBaseUrl.isNotEmpty) {
        return webLocalhostBaseUrl;
      }
      return defaultLanBaseUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (useAndroidEmulatorBaseUrl && androidEmulatorBaseUrl.isNotEmpty) {
          return androidEmulatorBaseUrl;
        }
        return defaultLanBaseUrl;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return iosSimulatorBaseUrl.isNotEmpty ? iosSimulatorBaseUrl : defaultLanBaseUrl;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return desktopLocalhostBaseUrl.isNotEmpty ? desktopLocalhostBaseUrl : defaultLanBaseUrl;
      default:
        return defaultLanBaseUrl;
    }
  }
  
  // App Info
  static const String appName = 'Sokoni Africa';
  static const String appTagline = 'Find, Inspect & Buy from African Sellers';
  
  // User Types
  static const String userTypeClient = 'client';
  static const String userTypeSupplier = 'supplier';
  static const String userTypeRetailer = 'retailer';
  
  // Languages
  static const String languageSwahili = 'swahili';
  static const String languageEnglish = 'english';
  
  // Genders
  static const String genderMale = 'male';
  static const String genderFemale = 'female';
  
  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserData = 'user_data';
  static const String keyLanguage = 'language';
  static const String keyGender = 'gender';
  static const String keyUserType = 'user_type';
  static const String keyIsOnboarded = 'is_onboarded';
  static const String keyIsDarkMode = 'is_dark_mode';
  
  // Currency
  static const String currency = 'Sokocoin';
  static const String currencySymbol = 'SOK';
  
  // Google Sign-In Client IDs
  static const String googleClientIdAndroid =
      '549625286375-sa4akmmoi6is8cve9emfqlusv4e2o0s3.apps.googleusercontent.com';
  static const String googleClientIdIOS =
      '549625286375-agaflcuma46b3h15mrm1ksmd3som22b0.apps.googleusercontent.com';
  // Web OAuth Client ID (for web-based OAuth flow in mobile apps)
  // Create a Web OAuth client in Google Cloud Console and paste the Client ID here
  static const String? googleClientIdWeb = null; // TODO: Add your Web OAuth Client ID
  
  // === CLOUDINARY CONFIGURATION ===
  // Direct uploads to Cloudinary for faster performance
  // Get credentials from: https://cloudinary.com/console
  // 
  // SETUP INSTRUCTIONS:
  // 1. Sign up at https://cloudinary.com (free tier: 25GB storage, 25GB bandwidth/month)
  // 2. Go to Dashboard → Settings → Upload → Create upload preset
  // 3. Set preset name to 'sokoni_africa' and mode to 'Unsigned'
  // 4. Copy your Cloud Name, API Key, and API Secret from dashboard
  // 5. Replace the values below
  // 
  // For detailed setup, see: CLOUDINARY_SETUP.md
  
  static const String cloudinaryCloudName = 'dcqiw1pfs';
  static const String cloudinaryApiKey = '922257936438572';
  static const String cloudinaryApiSecret = 'V5OSbtEUWzlPHFu8efBz2PAA8jY';
  static const String cloudinaryUploadPreset = 'sokoni_africa'; // Your upload preset name (create in dashboard)
  
  // Cloudinary folder organization (optional, helps organize files in Cloudinary)
  static const String cloudinaryProductsFolder = 'sokoni/products';
  static const String cloudinaryStoriesFolder = 'sokoni/stories';
  static const String cloudinaryProfilesFolder = 'sokoni/profiles';
}


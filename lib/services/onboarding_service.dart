import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static OnboardingService? _instance;
  SharedPreferences? _prefs;

  OnboardingService._internal();

  factory OnboardingService() {
    _instance ??= OnboardingService._internal();
    return _instance!;
  }

  /// Initialize the service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Check if onboarding has been completed
  Future<bool> isOnboardingComplete() async {
    await initialize();
    return _prefs!.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Mark onboarding as complete
  Future<void> setOnboardingComplete() async {
    await initialize();
    await _prefs!.setBool(_onboardingCompleteKey, true);
  }

  /// Reset onboarding status (useful for testing or if user wants to see onboarding again)
  Future<void> resetOnboarding() async {
    await initialize();
    await _prefs!.remove(_onboardingCompleteKey);
  }
}







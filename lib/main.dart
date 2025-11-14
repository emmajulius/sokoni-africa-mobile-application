import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'utils/app_theme.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart' show LanguageService, AppLocalizations;
import 'services/settings_service.dart';
import 'services/onboarding_service.dart';

Future<void> _initializeCoreServices() async {
  await Future.wait(
    [
      AuthService().initialize(),
      LanguageService().initialize(),
      SettingsService().initialize(),
      OnboardingService().initialize(),
    ],
    eagerError: true,
  );
}

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  
  // Preserve native splash to control when it's removed
  FlutterNativeSplash.preserve(widgetsBinding: binding as WidgetsFlutterBinding);

  // Initialize services in parallel (this happens while custom splash is showing)
  _initializeCoreServices().catchError((error) {
    print('⚠️ Error initializing services: $error');
  });

  runApp(const MyApp());
  
  // Remove native splash as early as possible - immediately after first frame
  binding.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LanguageService _languageService = LanguageService();
  final SettingsService _settingsService = SettingsService();
  final OnboardingService _onboardingService = OnboardingService();
  bool _isOnboardingComplete = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _settingsService.addListener(_onSettingsChanged);
    
    // Check onboarding status immediately (should be fast since services are already initialized)
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final isComplete = await _onboardingService.isOnboardingComplete();
    if (mounted) {
      setState(() {
        _isOnboardingComplete = isComplete;
      });
    }
  }

  void _onLanguageChanged() {
    // Force complete rebuild of MaterialApp when language changes
    // This ensures all screens get the new locale immediately
    if (mounted) {
      setState(() {});
    }
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  Widget _getHomeScreen() {
    // Show custom splash screen first, then navigate to appropriate screen
    if (_showSplash) {
      return SplashScreen(
        onComplete: _onSplashComplete,
        child: _isOnboardingComplete ? const LoginScreen() : const WelcomeScreen(),
      );
    }
    // If onboarding is complete, go directly to login screen
    // Otherwise, show welcome screen for first-time users
    return _isOnboardingComplete ? const LoginScreen() : const WelcomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    // Get current locale - MaterialApp will rebuild when this changes
    // This ensures the locale propagates to all Localizations widgets in the tree
    final currentLocale = _languageService.currentLocale;
    
    return MaterialApp(
      title: 'Sokoni Africa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _settingsService.darkMode ? ThemeMode.dark : ThemeMode.light,
      // MaterialApp will rebuild when locale changes, preserving navigation
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('sw'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // Always return the current locale from LanguageService
        // This ensures language changes are applied immediately to all screens
        // All screens will get the new locale via AppLocalizations.of(context)
        if (supportedLocales.contains(currentLocale)) {
          return currentLocale;
        }
        // Fallback to English if locale is not supported
        return const Locale('en');
      },
      home: _getHomeScreen(),
    );
  }
}

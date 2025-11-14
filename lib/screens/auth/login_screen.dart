import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/auth_service.dart';
import '../../services/auth_api_service.dart';
import '../../services/language_service.dart';
import '../../services/onboarding_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../../utils/http_exception.dart';
import '../main/main_navigation_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? gender;
  final String? language;
  
  const LoginScreen({
    super.key,
    this.gender,
    this.language,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isGoogleAvailable = true;
  bool _obscurePassword = true;
  final LanguageService _languageService = LanguageService();
  final OnboardingService _onboardingService = OnboardingService();
  GoogleSignIn? _googleSignIn;
  
  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _buttonAnimationController;
  
  // Animations
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<double> _buttonScaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _markOnboardingComplete(); // Mark onboarding as complete when login screen is shown
    try {
      _googleSignIn = _createGoogleSignIn();
    } catch (e) {
      _isGoogleAvailable = false;
      debugPrint('⚠️ Google Sign-In disabled: $e');
    }
    
    // Initialize animation controllers
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _formAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Header animations
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _headerScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    
    // Form animations
    _formFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );
    
    // Button animations
    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _buttonScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
      ),
    );
    
    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _formAnimationController.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _buttonAnimationController.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _headerAnimationController.dispose();
    _formAnimationController.dispose();
    _buttonAnimationController.dispose();
    _languageService.removeListener(_onLanguageChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingComplete() async {
    // Mark onboarding as complete when user reaches login screen
    // This ensures they won't see the welcome screen again
    try {
      await _onboardingService.setOnboardingComplete();
    } catch (e) {
      debugPrint('Error marking onboarding complete: $e');
    }
  }
  
  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  GoogleSignIn _createGoogleSignIn() {
    String? clientId;
    String? serverClientId;

    if (kIsWeb) {
      clientId = AppConstants.googleClientIdWeb;
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          clientId = AppConstants.googleClientIdIOS;
          break;
        case TargetPlatform.android:
          // Android requires serverClientId (OAuth 2.0 Web Client ID) for backend token verification
          // If Web Client ID is not configured, use Android Client ID as fallback
          // Note: For production, you should create a Web OAuth Client ID in Google Cloud Console
          serverClientId = AppConstants.googleClientIdWeb ?? AppConstants.googleClientIdAndroid;
          clientId = AppConstants.googleClientIdAndroid;
          break;
        default:
          clientId = AppConstants.googleClientIdAndroid;
          serverClientId = AppConstants.googleClientIdAndroid;
      }
    }

    if (clientId == null || clientId.isEmpty) {
      throw StateError(
        'Google Sign-In client ID is not configured for this platform.',
      );
    }

    // Android requires serverClientId (OAuth 2.0 Web Client ID from Google Cloud Console)
    // iOS uses clientId (iOS OAuth Client ID)
    if (defaultTargetPlatform == TargetPlatform.android && serverClientId != null) {
      return GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: serverClientId, // Required for Android
      );
    } else {
      return GoogleSignIn(
        scopes: const ['email', 'profile'],
        clientId: clientId, // Used for iOS and web
      );
    }
  }

  void _showGoogleConfigMessage() {
    final l10n = AppLocalizations(_languageService.currentLocale);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.googleSignInNotConfigured),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showGoogleFailureSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _handleGoogleSignIn() async {
    // Add immediate logging to confirm function is called
    debugPrint('🚀 ========== GOOGLE SIGN-IN STARTED ==========');
    debugPrint('🚀 _handleGoogleSignIn() called');
    debugPrint('🚀 _isGoogleAvailable: $_isGoogleAvailable');
    debugPrint('🚀 _googleSignIn is null: ${_googleSignIn == null}');
    
    if (!_isGoogleAvailable || _googleSignIn == null) {
      debugPrint('❌ Google Sign-In not available - showing config message');
      _showGoogleConfigMessage();
      return;
    }

    try {
      debugPrint('✅ Google Sign-In is available, setting loading state');
      setState(() => _isGoogleLoading = true);
      debugPrint('✅ Loading state set, calling signIn()...');
      
      // Show visual feedback that Google Sign-In is starting
      final l10n = AppLocalizations(_languageService.currentLocale);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.startingGoogleSignIn),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Check if Client ID is configured (for web, check meta tag; for mobile, check constant)
      // Note: For web, the meta tag is read automatically, but we can't check it easily
      // So we'll let Google Sign-In handle the error and show a helpful message
      
      // Sign in with Google
      debugPrint('📱 Calling GoogleSignIn.signIn()...');
      debugPrint('📱 GoogleSignIn clientId: ${_googleSignIn!.scopes}');
      debugPrint('📱 Platform: ${defaultTargetPlatform}');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn().catchError((error) {
        // Handle specific Google Sign-In errors
        final errorStr = error.toString();
        debugPrint('❌ ========== GOOGLE SIGN-IN ERROR ==========');
        debugPrint('❌ Google Sign-In error: $errorStr');
        debugPrint('❌ Error type: ${error.runtimeType}');
        
        // Handle PlatformException with error code 10 (DEVELOPER_ERROR)
        if (error is PlatformException) {
          final platformError = error;
          debugPrint('❌ PlatformException code: ${platformError.code}');
          debugPrint('❌ PlatformException message: ${platformError.message}');
          debugPrint('❌ PlatformException details: ${platformError.details}');
          
          if (platformError.code == 'sign_in_failed' || 
              platformError.code == '10' ||
              errorStr.contains('10') ||
              errorStr.contains('DEVELOPER_ERROR')) {
            throw Exception(
              'Google Sign-In Configuration Error (Code 10)\n\n'
              'This error usually means:\n'
              '1. SHA-1 certificate fingerprint is not registered in Google Cloud Console\n'
              '2. Package name doesn\'t match your OAuth client configuration\n'
              '3. OAuth client ID is incorrect\n\n'
              'To fix this:\n'
              '1. Get your app\'s SHA-1 fingerprint:\n'
              '   - Run: get_sha1_windows.bat (in project root)\n'
              '   - Or use: keytool -list -v -keystore %USERPROFILE%\\.android\\debug.keystore -alias androiddebugkey -storepass android -keypass android\n'
              '   - Or in Android Studio: Gradle > android > Tasks > android > signingReport\n'
              '2. Go to Google Cloud Console > APIs & Services > Credentials\n'
              '3. Edit your Android OAuth 2.0 Client ID (549625286375-...)\n'
              '4. Add the SHA-1 fingerprint from step 1\n'
              '5. Verify package name: com.example.sokoni_africa_app\n'
              '6. Save and wait 5-10 minutes for changes to propagate\n'
              '7. Rebuild the app: flutter clean && flutter run'
            );
          }
        }
        
        if (errorStr.contains('ClientID not set') || 
            errorStr.contains('client_id') ||
            errorStr.contains('400') ||
            errorStr.contains('malformed')) {
          throw Exception(
            'Google Sign-In is not properly configured.\n\n'
            'Please:\n'
            '1. Get your Google OAuth Client ID from: https://console.cloud.google.com/apis/credentials\n'
            '2. Make sure you have an Android OAuth 2.0 Client ID configured\n'
            '3. Add your SHA-1 certificate fingerprint\n'
            '4. Verify package name: com.example.sokoni_africa_app'
          );
        }
        
        // Re-throw the error so it can be handled by outer catch
        throw error;
      });
      
      debugPrint('📱 signIn() completed');
      debugPrint('📱 googleUser is null: ${googleUser == null}');
      
      if (googleUser == null) {
        // User cancelled the sign-in
        debugPrint('⚠️ User cancelled Google Sign-In');
        if (mounted) {
          setState(() => _isGoogleLoading = false);
        }
        return;
      }
      
      debugPrint('✅ Google user obtained: ${googleUser.email}');
      debugPrint('✅ Google user ID: ${googleUser.id}');
      debugPrint('✅ Google user display name: ${googleUser.displayName}');
      
      // Get authentication details
      debugPrint('🔐 Getting authentication details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      debugPrint('🔐 ========== GOOGLE AUTH DETAILS ==========');
      debugPrint('🔐 Google Sign-In - User: ${googleUser.email}');
      debugPrint('🔐 Google Sign-In - ID Token: ${googleAuth.idToken != null ? "Present (${googleAuth.idToken!.length} chars)" : "NULL"}');
      debugPrint('🔐 Google Sign-In - Access Token: ${googleAuth.accessToken != null ? "Present (${googleAuth.accessToken!.length} chars)" : "NULL"}');
      
      // Try to login with Google token
      try {
        final authApi = AuthApiService();
        // Use idToken (preferred) or accessToken as fallback
        String? googleToken = googleAuth.idToken;
        if (googleToken == null || googleToken.isEmpty) {
          debugPrint('⚠️ Google Sign-In - No ID token, trying access token');
          googleToken = googleAuth.accessToken;
          if (googleToken == null || googleToken.isEmpty) {
            debugPrint('❌ Google Sign-In - No ID token or access token available');
            final l10n = AppLocalizations(_languageService.currentLocale);
            throw Exception(l10n.failedToGetGoogleToken);
          }
          debugPrint('✅ Using access token as fallback');
        } else {
          debugPrint('✅ Using ID token');
        }
        
        debugPrint('🔐 Google Sign-In - Attempting login with token (length: ${googleToken.length})');
        final response = await authApi.login(
          email: googleUser.email,
          password: '', // Not needed for Google login
          google_token: googleToken,
        );
        
        debugPrint('🔐 Google Sign-In - Login response received');
        debugPrint('🔐 Response keys: ${response.keys.join(", ")}');

        if (mounted && response['access_token'] != null) {
          final authService = AuthService();
          final userData = response['user'] as Map<String, dynamic>;
          
          // IMPORTANT: Use user_type from database only - users cannot change their account type
          final userTypeFromDB = userData['user_type'] as String?;
          if (userTypeFromDB == null) {
            final l10n = AppLocalizations(_languageService.currentLocale);
            throw Exception(l10n.userTypeNotFound);
          }
          
          await authService.login(
            userData['id'].toString(),
            response['access_token'],
            userType: userTypeFromDB, // Always use the user_type from database
          );
          
          await authService.loadUserProfile();
          
          final l10n = AppLocalizations(_languageService.currentLocale);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.welcomeUser(googleUser.displayName ?? l10n.user)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Log the full error for debugging
        debugPrint('❌ ========== GOOGLE SIGN-IN LOGIN ERROR ==========');
        debugPrint('❌ Google Sign-In login error: $e');
        debugPrint('❌ Error type: ${e.runtimeType}');
        debugPrint('❌ Error toString: ${e.toString()}');
        
        // Check if user doesn't exist (404) or other error
        final errorStr = e.toString().toLowerCase();
        // Check status code if available (safely)
        int? statusCode;
        String? errorMessage;
        if (e is HttpException) {
          statusCode = e.statusCode;
          errorMessage = e.errorMessage?.toLowerCase();
        } else {
          // Try to extract from dynamic (for backwards compatibility)
          try {
            statusCode = (e as dynamic).statusCode as int?;
            errorMessage = (e as dynamic).errorMessage?.toString().toLowerCase();
          } catch (_) {
            // Ignore if statusCode doesn't exist
          }
        }
        debugPrint('❌ Error status code: $statusCode');
        debugPrint('❌ Error message: $errorMessage');
        
        final isUserNotFound = statusCode == 404 ||
                               errorStr.contains('not found') || 
                               errorStr.contains('404') ||
                               errorStr.contains('user not found') ||
                               errorStr.contains('please register') ||
                               (errorMessage?.contains('not found') ?? false) ||
                               (errorMessage?.contains('please register') ?? false);
        
        debugPrint('❌ Is user not found: $isUserNotFound');
        
        if (isUserNotFound) {
          // User doesn't exist, register them
          // For Google sign-in, we need to navigate to user type selection first
          // since registration requires a user_type
          if (mounted) {
            setState(() => _isGoogleLoading = false);
            
            // Show dialog to select user type for new Google users
            final l10n = AppLocalizations(_languageService.currentLocale);
            final userType = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                l10n.selectAccountType,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: Text(
                l10n.completeGoogleSignIn,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, AppConstants.userTypeClient),
                  child: Text(l10n.buyer),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, AppConstants.userTypeSupplier),
                  child: Text(l10n.seller),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, AppConstants.userTypeRetailer),
                  child: Text(l10n.both),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          );

          if (userType == null) {
            return; // User cancelled
          }

          setState(() => _isGoogleLoading = true);

          try {
            final authApi = AuthApiService();
            // Generate a unique username from email (remove @domain part)
            final baseUsername = googleUser.email.split('@')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
            // Ensure username is unique by appending a random number if needed
            String username = baseUsername;
            
            final response = await authApi.register(
              username: username,
              fullName: googleUser.displayName ?? googleUser.email.split('@')[0],
              email: googleUser.email,
              phone: '',
              password: '', // Empty password for Google users
              userType: userType,
              googleId: googleUser.id,
            );

            if (mounted && response['access_token'] != null) {
              final authService = AuthService();
              final userData = response['user'] as Map<String, dynamic>;
              
              // IMPORTANT: Use user_type from database only - users cannot change their account type
              final userTypeFromDB = userData['user_type'] as String?;
              if (userTypeFromDB == null) {
                final l10n = AppLocalizations(_languageService.currentLocale);
                throw Exception(l10n.userTypeNotFound);
              }
              
              await authService.login(
                userData['id'].toString(),
                response['access_token'],
                userType: userTypeFromDB, // Always use the user_type from database
              );
              
              await authService.loadUserProfile();
              
              final l10n = AppLocalizations(_languageService.currentLocale);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainNavigationScreen(),
                ),
              );
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.welcomeUser(googleUser.displayName ?? l10n.user)),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              // Registration failed - throw to outer catch
              final l10n = AppLocalizations(_languageService.currentLocale);
              throw Exception(l10n.registrationFailed);
            }
          } catch (regError) {
            // Re-throw to outer catch for unified error handling
            rethrow;
          }
          }
        } else {
          // Not a "user not found" error - rethrow to outer catch
          rethrow;
        }
      }
    } catch (error) {
      debugPrint('❌ ========== GOOGLE SIGN-IN OUTER CATCH ==========');
      debugPrint('❌ Error: $error');
      debugPrint('❌ Error type: ${error.runtimeType}');
      debugPrint('❌ Error toString: ${error.toString()}');
      
      // Print stack trace for better debugging
      if (error is Exception) {
        debugPrint('❌ Exception details: ${error.toString()}');
      }
      
      if (mounted) {
        final l10n = AppLocalizations(_languageService.currentLocale);
        String errorMessage = l10n.googleSignInFailed;
        final errorStr = error.toString().toLowerCase();
        
        debugPrint('❌ Google Sign-In Error (lowercase): $errorStr');
        
        // Check for specific error patterns
        if (errorStr.contains('already registered') || errorStr.contains('already exists')) {
          if (errorStr.contains('email')) {
            errorMessage = l10n.googleAccountAlreadyRegistered;
          } else if (errorStr.contains('username')) {
            errorMessage = l10n.usernameAlreadyTaken;
          } else {
            errorMessage = l10n.accountAlreadyExists;
          }
        } else if (errorStr.contains('user cancelled') || errorStr.contains('sign_in_canceled')) {
          if (mounted) {
            setState(() => _isGoogleLoading = false);
          }
          return;
        } else {
          errorMessage = l10n.googleSignInNetworkMessageSignIn;
        }

        _showGoogleFailureSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authApi = AuthApiService();
        final identifier = _usernameController.text.trim();
        final password = _passwordController.text;

        // Determine if identifier is email, phone, or username
        // Try to login with username first, then email, then phone
        Map<String, dynamic>? response;
        
        // Try as username first
        try {
          response = await authApi.login(
            username: identifier,
            password: password,
          );
        } catch (e) {
          print('🔐 Login attempt as username failed: $e');
          
          // Try as email if it contains @
          if (identifier.contains('@')) {
            try {
              print('🔐 Trying login as email: $identifier');
              response = await authApi.login(
                email: identifier,
                password: password,
              );
            } catch (e2) {
              print('🔐 Login attempt as email failed: $e2');
            }
          }
          
          // Try as phone if it's all digits
          if (response == null && RegExp(r'^\+?[\d\s-]+$').hasMatch(identifier)) {
            try {
              print('🔐 Trying login as phone: $identifier');
              response = await authApi.login(
                phone: identifier,
                password: password,
              );
            } catch (e3) {
              print('🔐 Login attempt as phone failed: $e3');
            }
          }
          
          // If all attempts failed, re-throw the last error
          if (response == null) {
            // Re-throw the original exception
            rethrow;
          }
        }

        if (mounted && response['access_token'] != null) {
          final authService = AuthService();
          final userData = response['user'] as Map<String, dynamic>;
          
          // IMPORTANT: Use user_type from database only - users cannot change their account type
          final userTypeFromDB = userData['user_type'] as String?;
          if (userTypeFromDB == null) {
            final l10n = AppLocalizations(_languageService.currentLocale);
            throw Exception(l10n.userTypeNotFound);
          }
          
          await authService.login(
            userData['id'].toString(),
            response['access_token'],
            userType: userTypeFromDB, // Always use the user_type from database
          );
          
          // Load user profile
          await authService.loadUserProfile();
          
          // Navigate to main app
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
          );
          
          final l10n = AppLocalizations(_languageService.currentLocale);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.loginSuccessful),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          
          // Extract error message
          final l10n = AppLocalizations(_languageService.currentLocale);
          String errorMessage = l10n.loginFailed;
          final errorStr = e.toString().toLowerCase();
          
          // Check status code if available (safely)
          int? statusCode;
          if (e is HttpException) {
            statusCode = e.statusCode;
          } else {
            // Try to extract from dynamic (for backwards compatibility)
            try {
              statusCode = (e as dynamic).statusCode as int?;
            } catch (_) {
              // Ignore if statusCode doesn't exist
            }
          }
          
          if (statusCode == 401 || errorStr.contains('401') || errorStr.contains('unauthorized')) {
            // Check for specific error messages
            if (errorStr.contains('no password') || errorStr.contains('doesn\'t have a password')) {
              errorMessage = l10n.accountDoesntHavePassword;
            } else {
              errorMessage = l10n.incorrectCredentials;
            }
          } else if (statusCode == 404 || errorStr.contains('404') || errorStr.contains('not found')) {
            errorMessage = l10n.userNotFound;
          } else if (statusCode == 403 || errorStr.contains('403') || errorStr.contains('forbidden')) {
            errorMessage = l10n.accountInactive;
          } else if (errorStr.contains('timeout') || errorStr.contains('connection')) {
            errorMessage = l10n.connectionTimeout;
          } else if (errorStr.contains('network') || errorStr.contains('failed to fetch')) {
            errorMessage = l10n.networkError;
          } else {
            // Try to extract detail from error message
            if (errorStr.contains('detail:')) {
              final detailMatch = RegExp(r'detail[:\s]+([^,\n]+)').firstMatch(errorStr);
              if (detailMatch != null) {
                errorMessage = detailMatch.group(1)?.trim() ?? l10n.loginFailed;
              } else {
                errorMessage = '${l10n.loginFailed}: ${e.toString().replaceAll('Exception: ', '')}';
              }
            } else {
              errorMessage = '${l10n.loginFailed}: ${e.toString().replaceAll('Exception: ', '')}';
            }
          }
          
          // Show error dialog for better visibility
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.loginFailedTitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                errorMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.ok,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                if (statusCode == 404 || errorStr.contains('not found'))
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: Text(
                      l10n.signUp,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header Section
              FadeTransition(
                opacity: _headerFadeAnimation,
                child: SlideTransition(
                  position: _headerSlideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _headerScaleAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]!.withOpacity(0.3)
                                  : const Color(0xFF2196F3).withOpacity(0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.2)
                                      : const Color(0xFF2196F3).withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.shopping_bag_rounded,
                              size: 48,
                              color: isDark ? Colors.white : const Color(0xFF2196F3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _titleFadeAnimation,
                          child: SlideTransition(
                            position: _titleSlideAnimation,
                            child: Text(
                              l10n.welcomeBack,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.blue[300] : const Color(0xFF2196F3),
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _subtitleFadeAnimation,
                          child: Text(
                            l10n.signInToContinueShopping,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.blue[300] : const Color(0xFF2196F3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Form Section
              FadeTransition(
                opacity: _formFadeAnimation,
                child: SlideTransition(
                  position: _formSlideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Username/Email/Phone Field
                          Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.blue[700]!.withOpacity(0.3)
                                : Colors.blue[100]!,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _usernameController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.usernameEmailOrPhone,
                            labelStyle: TextStyle(
                              color: isDark ? Colors.blue[300] : Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                            hintText: l10n.enterUsernameEmailOrPhone,
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF2196F3).withOpacity(0.2),
                                    const Color(0xFF1976D2).withOpacity(0.2),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                            border: InputBorder.none,
                          ),
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterUsernameEmailOrPhone;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Password Field
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.blue[700]!.withOpacity(0.3)
                                : Colors.blue[100]!,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          maxLength: 72,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            labelStyle: TextStyle(
                              color: isDark ? Colors.blue[300] : Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                            hintText: l10n.enterYourPassword,
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF2196F3).withOpacity(0.2),
                                    const Color(0xFF1976D2).withOpacity(0.2),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: isDark ? Colors.blue[300] : Colors.blue[700],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterYourPassword;
                            }
                            if (value.length < 6) {
                              return l10n.passwordMustBeAtLeast6;
                            }
                            if (value.length > 72) {
                              return l10n.passwordMustBe72OrLess;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2196F3),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          child: Text(
                            l10n.forgotPassword,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Login Button
                      FadeTransition(
                        opacity: _buttonFadeAnimation,
                        child: ScaleTransition(
                          scale: _buttonScaleAnimation,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2196F3),
                                  Color(0xFF1976D2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2196F3).withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isLoading ? null : _handleLogin,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              l10n.signIn,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Google Sign In Button
                      FadeTransition(
                        opacity: _buttonFadeAnimation,
                        child: ScaleTransition(
                          scale: _buttonScaleAnimation,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark 
                                    ? Colors.blue[700]!.withOpacity(0.3)
                                    : Colors.blue[200]!,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2196F3).withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isGoogleLoading
                                    ? null
                                    : () {
                                        if (!_isGoogleAvailable) {
                                          _showGoogleConfigMessage();
                                          return;
                                        }
                                        _handleGoogleSignIn();
                                      },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _isGoogleLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF2196F3),
                                                ),
                                              ),
                                            )
                                          : Padding(
                                              padding: const EdgeInsets.all(2),
                                              child: Image.asset(
                                                'assets/images/google_logo.png',
                                                width: 28,
                                                height: 28,
                                                fit: BoxFit.contain,
                                                semanticLabel: l10n.continueWithGoogle,
                                              ),
                                            ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _isGoogleAvailable
                                            ? l10n.continueWithGoogle
                                            : l10n.googleSignInUnavailable,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF2196F3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Divider
                      FadeTransition(
                        opacity: _buttonFadeAnimation,
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? Colors.blue[800]!.withOpacity(0.3)
                                    : Colors.blue[200]!,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                l10n.or,
                                style: TextStyle(
                                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark
                                    ? Colors.blue[800]!.withOpacity(0.3)
                                    : Colors.blue[200]!,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sign Up Link
                      FadeTransition(
                        opacity: _buttonFadeAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${l10n.dontHaveAccount} ',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 15,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignupScreen(
                                      gender: widget.gender,
                                      language: widget.language,
                                    ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2196F3),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              child: Text(
                                l10n.signUp,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Continue as Guest
                      FadeTransition(
                        opacity: _buttonFadeAnimation,
                        child: Center(
                          child: TextButton(
                            onPressed: () async {
                              try {
                                final authApi = AuthApiService();
                                final response = await authApi.loginAsGuest();
                                
                                if (mounted && response['access_token'] != null) {
                                  final authService = AuthService();
                                  final userData =
                                      response['user'] as Map<String, dynamic>;
                                  
                                  await authService.loginAsGuest(
                                    userType: userData['user_type'] ??
                                        AppConstants.userTypeClient,
                                  );
                                  
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MainNavigationScreen(),
                                    ),
                                  );
                                  
                                  final l10n = AppLocalizations(_languageService.currentLocale);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.loggedInAsGuest),
                                      backgroundColor: AppTheme.successColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  final l10n = AppLocalizations(_languageService.currentLocale);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${l10n.guestLoginFailed}: ${e.toString()}'),
                                      backgroundColor: AppTheme.errorColor,
                                      duration: const Duration(seconds: 4),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: isDark ? Colors.blue[300] : Colors.blue[700],
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: Text(
                              l10n.continueAsGuest,
                              style: TextStyle(
                                fontSize: 15,
                                decoration: TextDecoration.underline,
                                decorationColor: isDark ? Colors.blue[300] : Colors.blue[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

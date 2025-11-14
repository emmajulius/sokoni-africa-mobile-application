import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/auth_service.dart';
import '../../services/auth_api_service.dart';
import '../../services/language_service.dart';
import '../../utils/constants.dart';
import '../../utils/phone_validation_utils.dart';
import '../main/main_navigation_screen.dart';
import '../onboarding/user_type_selection_screen.dart';

class SignupScreen extends StatefulWidget {
  final String? gender;
  final String? language;
  
  const SignupScreen({
    super.key,
    this.gender,
    this.language,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isGoogleLoading = false;
  String _selectedCountryCode = '+255';
  final LanguageService _languageService = LanguageService();
  late final GoogleSignIn _googleSignIn;
  
  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _googleSignIn = _createGoogleSignIn();
  }
  
  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
          serverClientId = AppConstants.googleClientIdWeb ?? AppConstants.googleClientIdAndroid;
          clientId = AppConstants.googleClientIdAndroid;
          break;
        default:
          clientId = AppConstants.googleClientIdAndroid;
          serverClientId = AppConstants.googleClientIdAndroid;
      }
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
    try {
      setState(() => _isGoogleLoading = true);
      
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().catchError((error) {
        // Handle specific Google Sign-In errors
        final errorStr = error.toString();
        print('❌ Google Sign-In error: $errorStr');
        
        // Handle PlatformException with error code 10 (DEVELOPER_ERROR)
        if (error is PlatformException) {
          final platformError = error;
          print('❌ PlatformException code: ${platformError.code}, message: ${platformError.message}');
          
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
        throw error;
      });
      
      if (googleUser == null) {
        // User cancelled the sign-in
        if (mounted) {
          setState(() => _isGoogleLoading = false);
        }
        return;
      }
      
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Try to login first (in case user already exists)
      try {
        final authApi = AuthApiService();
        final response = await authApi.login(
          email: googleUser.email,
          password: '', // Not needed for Google login
          google_token: googleAuth.idToken ?? googleAuth.accessToken,
        );

        if (mounted && response['access_token'] != null) {
          final authService = AuthService();
          final userData = response['user'] as Map<String, dynamic>;
          
          // IMPORTANT: Use user_type from database only - users cannot change their account type
          final userTypeFromDB = userData['user_type'] as String?;
          if (userTypeFromDB == null) {
            throw Exception('User type not found in account. Please contact support.');
          }
          
          await authService.login(
            userData['id'].toString(),
            response['access_token'],
            userType: userTypeFromDB, // Always use the user_type from database
          );
          
          await authService.loadUserProfile();
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome, ${googleUser.displayName ?? 'User'}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // User doesn't exist, register them
        final authApi = AuthApiService();
        final response = await authApi.register(
          username: googleUser.email.split('@')[0],
          fullName: googleUser.displayName ?? 'Google User',
          email: googleUser.email,
          phone: '',
          password: '',
          googleId: googleUser.id,
        );

        if (mounted && response['access_token'] != null) {
          final authService = AuthService();
          final userData = response['user'] as Map<String, dynamic>;
          
          // IMPORTANT: Use user_type from database only - users cannot change their account type
          final userTypeFromDB = userData['user_type'] as String?;
          if (userTypeFromDB == null) {
            throw Exception('User type not found in account. Please contact support.');
          }
          
          await authService.login(
            userData['id'].toString(),
            response['access_token'],
            userType: userTypeFromDB, // Always use the user_type from database
          );
          
          await authService.loadUserProfile();
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome, ${googleUser.displayName ?? 'User'}!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Registration failed - throw to outer catch
          throw Exception('Failed to register with Google');
        }
      }
    } catch (error) {
      if (!mounted) return;

      final l10n = AppLocalizations(_languageService.currentLocale);
      String errorMessage = l10n.googleSignInNetworkMessageSignUp;
      final errorStr = error.toString().toLowerCase();

      if (errorStr.contains('already registered') || errorStr.contains('already exists')) {
        if (errorStr.contains('email')) {
          errorMessage = l10n.googleAccountAlreadyRegistered;
        } else if (errorStr.contains('username')) {
          errorMessage = l10n.usernameAlreadyTaken;
        } else {
          errorMessage = l10n.accountAlreadyExists;
        }
      } else if (errorStr.contains('user cancelled') || errorStr.contains('sign_in_canceled')) {
        return;
      }

      _showGoogleFailureSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      // Navigate to user type selection screen first
      // User must select their account type before registration
      final phoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserTypeSelectionScreen(
            language: widget.language ?? _languageService.currentLocale.languageCode,
            gender: widget.gender ?? AppConstants.genderMale,
            signupData: {
              'username': _usernameController.text.trim(),
              'fullName': _usernameController.text.trim(),
              'email': _emailController.text.trim(),
              'phone': phoneNumber,
              'password': _passwordController.text,
            },
          ),
        ),
      );
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
                  child: Column(
                    children: [
                      Container(
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
                          Icons.person_add_rounded,
                          size: 48,
                          color: isDark ? Colors.white : const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.createAccount,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.blue[300] : const Color(0xFF2196F3),
                          letterSpacing: -1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.joinSokoniAfricaToday,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.blue[300] : const Color(0xFF2196F3),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                  // Username Field
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
                        labelText: l10n.username,
                        labelStyle: TextStyle(
                          color: isDark ? Colors.blue[300] : Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: l10n.chooseUsername,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterUsername;
                        }
                        if (value.length < 3) {
                          return l10n.usernameTooShort;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Email Field
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
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        labelStyle: TextStyle(
                          color: isDark ? Colors.blue[300] : Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: l10n.enterEmail,
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
                            Icons.email_rounded,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterEmail;
                        }
                        final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return l10n.pleaseEnterValidEmail;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Phone Number Field
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark
                                ? Colors.blue[700]!.withOpacity(0.3)
                                : Colors.blue[100]!,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: isDark ? Colors.grey[800] : Colors.white,
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          underline: const SizedBox(),
                          dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                            fontSize: 14,
                          ),
                          items: const [
                            DropdownMenuItem(value: '+255', child: Text('🇹🇿 +255')),
                            DropdownMenuItem(value: '+212', child: Text('🇲🇦 +212')),
                            DropdownMenuItem(value: '+234', child: Text('🇳🇬 +234')),
                            DropdownMenuItem(value: '+254', child: Text('🇰🇪 +254')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCountryCode = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
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
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.grey[900],
                              fontSize: 15,
                            ),
                              decoration: InputDecoration(
                              labelText: l10n.phoneNumber,
                              labelStyle: TextStyle(
                                color: isDark ? Colors.blue[300] : Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                              hintText: l10n.enterPhoneNumber,
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
                                  Icons.phone_rounded,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                              border: InputBorder.none,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              return PhoneValidationUtils.validatePhoneNumber(value, _selectedCountryCode);
                            },
                          ),
                        ),
                      ),
                    ],
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
                        hintText: l10n.createPassword,
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
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterPassword;
                        }
                        if (value.length < 6) {
                          return l10n.passwordMustBeAtLeast6;
                        }
                        if (value.length > 72) {
                          return l10n.passwordTooLong;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Confirm Password Field
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
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      maxLength: 72,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.confirmPassword,
                        labelStyle: TextStyle(
                          color: isDark ? Colors.blue[300] : Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: l10n.confirmYourPassword,
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
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: isDark ? Colors.blue[300] : Colors.blue[700],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSignup(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseConfirmYourPassword;
                        }
                        if (value != _passwordController.text) {
                          return l10n.passwordsDoNotMatch;
                        }
                        if (value.length > 72) {
                          return l10n.passwordTooLong;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Sign Up Button
                  Container(
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
                        onTap: _isLoading ? null : _handleSignup,
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
                                      l10n.signUp,
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
                  const SizedBox(height: 16),
                  // Google Sign In Button
                  Container(
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
                        onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
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
                                l10n.continueWithGoogle,
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
                  const SizedBox(height: 24),
                  // Divider
                  Row(
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
                  const SizedBox(height: 24),
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${l10n.alreadyHaveAccount} ',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 15,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        child: Text(
                          l10n.signIn,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}



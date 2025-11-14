import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../screens/main/main_navigation_screen.dart';
import '../../screens/onboarding/user_type_selection_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../services/auth_service.dart';
import '../../services/auth_api_service.dart';
import '../../services/language_service.dart';
import '../../utils/constants.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  final LanguageService _languageService = LanguageService();
  
  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
  }
  
  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
  
  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _verifyOTP() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final authApi = AuthApiService();
    
    try {
      // Verify OTP with backend
      final response = await authApi.verifyOTP(widget.phoneNumber, code);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        print('📱 OTP Verification Response:');
        print('   Success: ${response['success']}');
        print('   Token: ${response['token']}');
        print('   User: ${response['user']}');
        print('   Message: ${response['message']}');
        
        if (response['success'] == true) {
          final authService = AuthService();
          
          // Check if user exists (login flow) or needs registration
          final hasToken = response.containsKey('token') && 
                          response['token'] != null && 
                          response['token'].toString().isNotEmpty;
          final hasUser = response.containsKey('user') && 
                         response['user'] != null;
          
          print('   Has Token: $hasToken (token value: ${response['token']})');
          print('   Has User: $hasUser (user value: ${response['user']})');
          
          if (hasToken && hasUser) {
            // User exists - login successful
            print('✅ User exists - logging in...');
            final userData = response['user'] as Map<String, dynamic>;
            final savedUserType = userData['user_type'] ?? authService.userType ?? AppConstants.userTypeClient;
            
            await authService.login(
              userData['id'].toString(),
              response['token'],
              userType: savedUserType,
            );
            
            // Load user profile data after login
            await authService.loadUserProfile();
            
            // Navigate to main app
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainNavigationScreen(),
              ),
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['message'] ?? 'Login successful'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // User doesn't exist - needs registration
            print('📝 New user - navigating to registration...');
            final languageService = LanguageService();
            final savedLanguage = languageService.currentLocale.languageCode;
            const savedGender = AppConstants.genderMale;
            
            try {
              // Navigate FIRST before showing snackbar
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UserTypeSelectionScreen(
                    language: savedLanguage,
                    gender: savedGender,
                    phoneNumber: widget.phoneNumber, // Pass phone number for registration
                  ),
                ),
              );
              
              // Show snackbar after navigation completes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message'] ?? 'Phone verified. Please select your account type.'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              });
            } catch (navError) {
              print('❌ Navigation error: $navError');
              // If navigation fails, try navigating to login as fallback
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _resendOTP() async {
    final authApi = AuthApiService();
    
    try {
      setState(() => _isLoading = true);
      final response = await authApi.sendOTP(widget.phoneNumber);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'OTP resent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend OTP: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weFlexSecurity),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              l10n.provideOTP,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sentTo(widget.phoneNumber),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => _onCodeChanged(index, value),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Resend OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.didntReceiveCode,
                  style: const TextStyle(fontSize: 14),
                ),
                TextButton(
                  onPressed: _resendOTP,
                  child: Text(l10n.resendOTP),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(l10n.changePhoneNumber),
            ),
            const SizedBox(height: 32),
            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.verifyPhone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


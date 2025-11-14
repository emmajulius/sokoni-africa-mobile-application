import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import '../../services/auth_api_service.dart';
import '../../services/language_service.dart';
import '../../services/onboarding_service.dart';
import '../auth/login_screen.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  final String language;
  final String gender;
  final String? phoneNumber; // Phone number for registration completion
  final Map<String, String>? signupData; // Signup data from signup screen

  const UserTypeSelectionScreen({
    super.key,
    required this.language,
    required this.gender,
    this.phoneNumber,
    this.signupData,
  });

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  String? selectedUserType;
  final LanguageService _languageService = LanguageService();
  final OnboardingService _onboardingService = OnboardingService();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
  }
  
  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }
  
  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleContinue(String userType) async {
    setState(() => _isLoading = true);
    
    // Save user type
    await AuthService().setUserType(userType);
    
    // If signup data is provided (from signup screen), complete registration
    if (widget.signupData != null) {
      try {
        final authApi = AuthApiService();
        
        // Register user with selected user type
        final response = await authApi.register(
          username: widget.signupData!['username']!,
          fullName: widget.signupData!['fullName']!,
          email: widget.signupData!['email']!,
          phone: widget.signupData!['phone']!,
          password: widget.signupData!['password']!,
          userType: userType, // IMPORTANT: User type is set during registration and cannot be changed
        );
        
        if (mounted && response['access_token'] != null) {
          // Mark onboarding as complete
          await _onboardingService.setOnboardingComplete();
          
          // Registration successful - navigate to login screen for user to sign in
          setState(() => _isLoading = false);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please sign in to continue.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          String errorMessage = 'Registration failed';
          final errorStr = e.toString();
          
          if (errorStr.contains('already registered')) {
            if (errorStr.contains('Username')) {
              errorMessage = 'Username already taken. Please choose a different username.';
            } else if (errorStr.contains('Email')) {
              errorMessage = 'Email already registered. Please use a different email or login instead.';
            } else if (errorStr.contains('Phone')) {
              errorMessage = 'Phone number already registered. Please use a different phone number or login instead.';
            }
          } else {
            errorMessage = 'Registration failed: $errorStr';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
    // If phone number is provided (from phone verification), complete registration
    else if (widget.phoneNumber != null) {
      try {
        final authApi = AuthApiService();
        
        // Generate a username from phone number
        final phoneDigits = widget.phoneNumber!.replaceAll(RegExp(r'[^0-9]'), '');
        final username = 'user_${phoneDigits.length > 8 ? phoneDigits.substring(phoneDigits.length - 8) : phoneDigits}';
        final fullName = 'User ${widget.phoneNumber!.length > 4 ? widget.phoneNumber!.substring(widget.phoneNumber!.length - 4) : widget.phoneNumber!}';
        
        // Complete registration
        final response = await authApi.registerWithPhone(
          phone: widget.phoneNumber!,
          username: username,
          fullName: fullName,
          userType: userType,
        );
        
        if (mounted && response['access_token'] != null) {
          // Mark onboarding as complete
          await _onboardingService.setOnboardingComplete();
          
          // Registration successful - navigate to login screen for user to sign in
          setState(() => _isLoading = false);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please sign in to continue.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } else {
      // No phone number or signup data - user is just selecting type, mark onboarding complete and navigate to login
      if (mounted) {
        // Mark onboarding as complete
        await _onboardingService.setOnboardingComplete();
        
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 32.0),
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
                        Icons.account_circle_rounded,
                        size: 48,
                        color: isDark ? Colors.white : const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.howToUseSokoni,
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
                      'Choose how you want to use Sokoni Africa',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.blue[300] : const Color(0xFF1976D2),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            // Client Option
            _buildUserTypeOption(
              title: l10n.sokoniClient,
              subtitle: l10n.clientDesc,
              value: AppConstants.userTypeClient,
              icon: Icons.shopping_cart_rounded,
            ),
            // Supplier Option
            _buildUserTypeOption(
              title: l10n.sokoniSupplier,
              subtitle: l10n.supplierDesc,
              value: AppConstants.userTypeSupplier,
              icon: Icons.store_rounded,
            ),
            // Retailer Option
            _buildUserTypeOption(
              title: l10n.sokoniRetailer,
              subtitle: l10n.retailerDesc,
              value: AppConstants.userTypeRetailer,
              icon: Icons.swap_horiz_rounded,
            ),
              const SizedBox(height: 24),
              // Continue Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: selectedUserType != null && !_isLoading
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF2196F3),
                            Color(0xFF1976D2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: selectedUserType == null || _isLoading
                      ? (isDark ? Colors.grey[800] : Colors.grey[300])
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: selectedUserType != null && !_isLoading
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: selectedUserType == null || _isLoading
                        ? null
                        : () async {
                            if (selectedUserType != null) {
                              await _handleContinue(selectedUserType!);
                            }
                          },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.continueText,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: selectedUserType != null
                                        ? Colors.white
                                        : (isDark ? Colors.grey[600] : Colors.grey[700]),
                                  ),
                                ),
                                if (selectedUserType != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedUserType == value;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedUserType = value;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? Colors.blue[800]!
                      : const Color(0xFF2196F3))
                  : (isDark ? Colors.grey[800] : Colors.white),
              border: Border.all(
                color: isSelected
                    ? (isDark
                        ? Colors.blue[600]!
                        : const Color(0xFF2196F3))
                    : (isDark
                        ? Colors.blue[700]!.withOpacity(0.3)
                        : Colors.blue[100]!),
                width: isSelected ? 2.5 : 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? Colors.blue[600]!
                            : Colors.white.withOpacity(0.3))
                        : (isDark
                            ? Colors.blue[900]!.withOpacity(0.3)
                            : const Color(0xFF2196F3).withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.blue[300] : const Color(0xFF2196F3)),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.grey[900]),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? Colors.white.withOpacity(0.9)
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.blue[300]
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: isDark
                          ? Colors.blue[900]
                          : const Color(0xFF2196F3),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


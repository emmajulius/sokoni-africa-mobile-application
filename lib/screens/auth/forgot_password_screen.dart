import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_api_service.dart';
import '../../services/language_service.dart';
import '../../utils/phone_validation_utils.dart';
import '../auth/login_screen.dart';

enum ResetMethod { phone, email }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedCountryCode = '+255';
  bool _isLoading = false;
  ResetMethod _resetMethod = ResetMethod.phone;
  final LanguageService _languageService = LanguageService();
  
  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
  }
  
  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleSendOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final phoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';
      final authApi = AuthApiService();
      final l10n = AppLocalizations(_languageService.currentLocale);

      try {
        final response = await authApi.forgotPassword(phoneNumber);

        if (mounted) {
          setState(() => _isLoading = false);

          if (response['success'] == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PasswordResetScreen(
                  phoneNumber: phoneNumber,
                ),
              ),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['message'] ?? l10n.otpSentSuccessfully),
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
              content: Text('${l10n.failedToSendOTP}: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleSendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final authApi = AuthApiService();
      final l10n = AppLocalizations(_languageService.currentLocale);

      try {
        final response = await authApi.forgotPasswordByEmail(email);

        if (mounted) {
          setState(() => _isLoading = false);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PasswordResetScreen(
                email: email,
              ),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ??
                    l10n.resetEmailSentSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);

          final errorText = e.toString();
          String friendlyMessage = l10n.failedToSendResetEmail;

          if (errorText.contains('Not Found')) {
            friendlyMessage = l10n.thisEmailNotRegistered;
          } else if (errorText.contains('Email reset endpoint not available')) {
            friendlyMessage = l10n.emailResetNotAvailable;
          } else {
            friendlyMessage = '${l10n.failedToSendResetEmail}: $errorText';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendlyMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _handleSubmit() {
    if (_resetMethod == ResetMethod.phone) {
      _handleSendOTP();
    } else {
      _handleSendResetEmail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final instructionText = _resetMethod == ResetMethod.phone
        ? l10n.enterPhoneToReceiveOTP
        : l10n.enterEmailToReceiveCode;

    final actionLabel = _resetMethod == ResetMethod.phone ? l10n.sendOTP : l10n.sendResetEmail;

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
                          Icons.lock_reset_rounded,
                          size: 48,
                          color: isDark ? Colors.white : const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.resetPassword,
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
                        instructionText,
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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark
                        ? Colors.blue[900]!.withOpacity(0.1)
                        : Colors.blue[50],
                    border: Border.all(
                      color: isDark
                          ? Colors.blue[700]!.withOpacity(0.2)
                          : Colors.blue[100]!,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMethodOption(
                          method: ResetMethod.phone,
                          title: l10n.phoneOTP,
                          subtitle: l10n.receiveCodeBySMS,
                          icon: Icons.sms_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMethodOption(
                          method: ResetMethod.email,
                          title: l10n.email,
                          subtitle: l10n.receiveCodeViaEmail,
                          icon: Icons.email_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                  if (_resetMethod == ResetMethod.phone)
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
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleSubmit(),
                              validator: (value) {
                                if (_resetMethod != ResetMethod.phone) return null;
                                return PhoneValidationUtils.validatePhoneNumber(value, _selectedCountryCode);
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  else
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
                          labelText: l10n.emailAddress,
                          labelStyle: TextStyle(
                            color: isDark ? Colors.blue[300] : Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                          hintText: l10n.youExampleCom,
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
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleSubmit(),
                        validator: (value) {
                          if (_resetMethod != ResetMethod.email) return null;
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseEnterEmail;
                          }
                          final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return l10n.enterValidEmail;
                          }
                          return null;
                        },
                      ),
                    ),
                  const SizedBox(height: 32),
                  // Send Button
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
                        onTap: _isLoading ? null : _handleSubmit,
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
                                      actionLabel,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Back to Login
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2196F3),
                      ),
                      child: Text(
                        l10n.backToLogin,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildMethodOption({
    required ResetMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = _resetMethod == method;
    return InkWell(
      onTap: () {
        if (_resetMethod != method) {
          setState(() {
            _resetMethod = method;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          border: Border.all(
            color: isSelected
                ? (isDark
                    ? Colors.blue[400]!.withOpacity(0.5)
                    : const Color(0xFF2196F3).withOpacity(0.8))
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? Colors.blue[400]!
                        : const Color(0xFF2196F3))
                    : (isDark
                        ? Colors.blue[800]!.withOpacity(0.2)
                        : Colors.blue[100]!),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 22,
                color: isSelected
                    ? (isDark
                        ? Colors.white
                        : Colors.white)
                    : (isDark
                        ? Colors.blue[300]
                        : const Color(0xFF2196F3)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF2196F3))
                          : (isDark ? Colors.grey[300] : Colors.grey[700]),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? (isDark ? Colors.grey[300] : Colors.blue[700])
                          : (isDark ? Colors.grey[500] : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: isDark
                    ? Colors.blue[300]
                    : const Color(0xFF2196F3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// Password Reset Screen (after OTP verification)
class PasswordResetScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? email;

  const PasswordResetScreen({
    super.key,
    this.phoneNumber,
    this.email,
  }) : assert(phoneNumber != null || email != null, 'Either phoneNumber or email must be provided');

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _otpVerified = false;
  final LanguageService _languageService = LanguageService();

  bool get _isPhoneFlow => widget.phoneNumber != null;
  String get _contactValue => widget.phoneNumber ?? widget.email!;
  String get _contactDescription =>
      _isPhoneFlow ? 'phone number $_contactValue' : 'email $_contactValue';
  
  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
  }
  
  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _verifyOTP() async {
    final l10n = AppLocalizations(_languageService.currentLocale);
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnter6DigitOTP),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Just mark as verified locally - actual verification happens in reset password
      setState(() {
        _otpVerified = true;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.otpEntered),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations(_languageService.currentLocale);
    if (_formKey.currentState!.validate()) {
      // Validate OTP if not already verified
      if (!_otpVerified) {
        if (_otpController.text.length != 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.pleaseEnter6DigitOTP),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      setState(() => _isLoading = true);

      try {
        final authApi = AuthApiService();
        await authApi.resetPassword(
          phone: widget.phoneNumber,
          email: widget.email,
          code: _otpController.text,
          newPassword: _passwordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.resetPasswordSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to login screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.failedToResetPassword}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resetPassword),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // OTP Verification Section
              if (!_otpVerified) ...[
                Text(
                  l10n.enterOTP,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.weSentVerificationCode(_contactDescription),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '000000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return l10n.pleaseEnter6DigitOTP;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      // Verify OTP, then proceed to password reset
                      _verifyOTP();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            l10n.verifyOTP,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                // Password Reset Section
                const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.enterNewPassword,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.createNewPassword,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // OTP Field (still needed for reset password endpoint)
                if (!_otpVerified)
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: l10n.enterOTPCode,
                      hintText: '000000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: '',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.length != 6) {
                        return l10n.pleaseEnter6DigitOTP;
                      }
                      return null;
                    },
                  ),
                if (!_otpVerified) const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  maxLength: 72, // Bcrypt has 72-byte limit
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    hintText: l10n.createNewPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '', // Hide character counter
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
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  maxLength: 72, // Bcrypt has 72-byte limit
                  decoration: InputDecoration(
                    labelText: l10n.confirmNewPassword,
                    hintText: l10n.confirmYourPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '', // Hide character counter
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _resetPassword(),
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
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            l10n.resetPassword,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


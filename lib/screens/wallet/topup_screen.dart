import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/wallet_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../utils/phone_validation_utils.dart';
import 'flutterwave_payment_screen.dart';

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final WalletService _walletService = WalletService();
  final LanguageService _languageService = LanguageService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCurrency = 'TZS';
  String _selectedPaymentMethod = 'card';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _prefillPhoneNumber();
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  final List<String> _currencies = ['TZS', 'KES', 'NGN'];
  final List<String> _paymentMethods = ['card', 'mobile_money', 'bank_transfer'];


  Future<void> _prefillPhoneNumber() async {
    final authService = AuthService();
    await authService.initialize();
    final phone = authService.phone;
    if (mounted && phone != null && phone.isNotEmpty) {
      _phoneController.text = phone;
    }
  }

  bool get _requiresPhone => _selectedPaymentMethod == 'mobile_money';

  Future<void> _initializeTopup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final amount = double.parse(_amountController.text);
      final authService = AuthService();
      await authService.initialize();

      final normalizedPhone = _requiresPhone
          ? _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : (authService.phone ?? '').trim()
          : null;

      if (_requiresPhone && (normalizedPhone == null || normalizedPhone.isEmpty)) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.pleaseEnterMobileMoneyPhone ?? 'Please enter the mobile money phone number.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final result = await _walletService.initializeTopup(
        amount: amount,
        currency: _selectedCurrency,
        paymentMethod: _selectedPaymentMethod,
        email: authService.email,
        fullName: authService.fullName,
        phoneNumber: normalizedPhone,
      );

      if (result['success'] == true) {
        final paymentUrl = result['payment_url'] as String?;
        final transactionId = result['transaction_id'] as int?;

        if (paymentUrl != null && transactionId != null) {
          if (kIsWeb) {
            await _handleWebPayment(paymentUrl, transactionId);
          } else {
            // Navigate to WebView payment screen instead of external browser
            final paymentResult = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => FlutterwavePaymentScreen(
                  paymentUrl: paymentUrl,
                  transactionId: transactionId,
                ),
              ),
            );

            // Handle payment result
            if (paymentResult == true && mounted) {
              // Payment was successful
              final l10n = AppLocalizations.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n?.paymentCompletedSuccessfully ?? 'Payment completed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, true);
            } else if (mounted && paymentResult == false) {
              // Payment was cancelled or failed
              final l10n = AppLocalizations.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n?.paymentNotCompleted ?? 'Payment not completed.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? (l10n?.topUpCompletedTestMode ?? 'Top-up completed in test mode.')),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? (l10n?.failedToInitializePayment ?? 'Failed to initialize payment')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Extract the actual error message
        String errorMessage = e.toString();
        
        // Remove the "Exception: " prefix if present
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        
        // Show user-friendly error dialog
        final l10n = AppLocalizations.of(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n?.paymentError ?? 'Payment Error'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                const SizedBox(height: 16),
                Text(
                  l10n?.possibleCauses ?? 'Possible causes:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('• ${l10n?.paymentGatewayNotConfigured ?? 'Payment gateway not configured'}'),
                Text('• ${l10n?.networkConnectionIssue ?? 'Network connection issue'}'),
                Text('• ${l10n?.invalidPaymentDetails ?? 'Invalid payment details'}'),
                const SizedBox(height: 16),
                Text(
                  l10n?.pleaseTryAgainOrContactSupport ?? 'Please try again or contact support if the issue persists.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n?.ok ?? 'OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.grey[850]!,
                          Colors.grey[900]!,
                        ]
                      : [
                          const Color(0xFFF5F7FA),
                          const Color(0xFFE8ECF1),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_circle_rounded,
                      size: 32,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.topUpWallet ?? 'Top Up Wallet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark 
                          ? Colors.white 
                          : Colors.grey[900],
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue[900]!.withOpacity(0.2)
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.blue[700]!.withOpacity(0.3)
                              : Colors.blue[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF2196F3),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n?.topUpWalletInfo ?? 'Top up your wallet with Sokocoin using Flutterwave payment gateway.',
                              style: TextStyle(
                                color: isDark 
                                    ? Colors.grey[300] 
                                    : Colors.blue[900],
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Amount Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                        decoration: InputDecoration(
                          labelText: l10n?.amount ?? 'Amount',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          hintText: l10n?.enterAmount ?? 'Enter amount',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.attach_money_rounded,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          suffixText: _selectedCurrency,
                          suffixStyle: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n?.pleaseEnterAmount ?? 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return l10n?.pleaseEnterValidAmount ?? 'Please enter a valid amount';
                          }
                          if (amount < 100) {
                            return l10n?.minimumAmountIs100 ?? 'Minimum amount is 100';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Currency Selection
                    Text(
                      l10n?.currency ?? 'Currency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currencies.map((currency) {
                        final isSelected = _selectedCurrency == currency;
                        return FilterChip(
                          label: Text(
                            currency,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.grey[900]),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                          selectedColor: const Color(0xFF4CAF50),
                          checkmarkColor: Colors.white,
                          onSelected: (_) {
                            setState(() {
                              _selectedCurrency = currency;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Payment Method Selection
                    Text(
                      l10n?.paymentMethod ?? 'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: _paymentMethods.map((method) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                                  width: method != _paymentMethods.last ? 1 : 0,
                                ),
                              ),
                            ),
                            child: RadioListTile<String>(
                              title: Text(
                                _getPaymentMethodLabel(method, l10n),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.grey[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: method,
                              groupValue: _selectedPaymentMethod,
                              activeColor: const Color(0xFF4CAF50),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMethod = value!;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    if (_requiresPhone) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 5,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                          decoration: InputDecoration(
                            labelText: l10n?.mobileMoneyPhoneNumber ?? 'Mobile Money Phone Number',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            hintText: _selectedCurrency == 'TZS'
                                ? (l10n?.examplePhoneNumber ?? 'e.g. 2557XXXXXXXX')
                                : (l10n?.enterPhoneWithCountryCode ?? 'Enter phone number with country code'),
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.phone_rounded,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            helperText: _selectedCurrency == 'TZS'
                                ? (l10n?.usePhoneRegisteredWallet ?? 'Use the phone number registered to your Tanzanian mobile wallet.')
                                : (l10n?.ensurePhoneMatchesWallet ?? 'Ensure the phone number matches your mobile money account.'),
                            helperStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (!_requiresPhone) {
                              return null;
                            }
                            // Phone number may include country code (e.g., 2557XXXXXXXX for Tanzania)
                            // Use generic validation with wider range for international format
                            return PhoneValidationUtils.validatePhoneNumberGeneric(
                              value,
                              minLength: 9, // Minimum local number length
                              maxLength: 15, // Maximum international format length (with country code)
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _initializeTopup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n?.continueToPayment ?? 'Continue to Payment',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentMethodLabel(String method, AppLocalizations? l10n) {
    switch (method) {
      case 'card':
        return l10n?.creditDebitCard ?? 'Credit/Debit Card';
      case 'mobile_money':
        return l10n?.mobileMoney ?? 'Mobile Money';
      case 'bank_transfer':
        return l10n?.bankTransfer ?? 'Bank Transfer';
      default:
        return method;
    }
  }

  Future<void> _handleWebPayment(String paymentUrl, int transactionId) async {
    final uri = Uri.tryParse(paymentUrl);
    if (uri == null) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.invalidPaymentURL ?? 'Invalid payment URL received.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!launched) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.couldNotOpenPaymentPage ?? 'Could not open payment page.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    final shouldVerify = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isVerifying = false;
        String? error;

        return StatefulBuilder(
          builder: (context, setState) {
            final l10n = AppLocalizations.of(context);
            Future<void> verifyWithSetState() async {
              if (isVerifying) return;
              setState(() {
                isVerifying = true;
                error = null;
              });
              final success = await _verifyTopupTransaction(transactionId);
              if (!mounted) return;
              if (success) {
                Navigator.of(context).pop(true);
              } else {
                setState(() {
                  isVerifying = false;
                  error = l10n?.paymentNotVerifiedYet ?? 'Payment not verified yet. Please complete the payment and try again.';
                });
              }
            }

            return AlertDialog(
              title: Text(l10n?.completePayment ?? 'Complete Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.newTabOpenedFlutterwave ?? 'A new tab has been opened with the Flutterwave checkout. Complete the payment there, then click "Verify Payment" below.',
                  ),
                  const SizedBox(height: 12),
                  if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: isVerifying ? null : verifyWithSetState,
                  child: isVerifying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n?.verifyPayment ?? 'Verify Payment'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldVerify == true && mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.paymentCompletedSuccessfully ?? 'Payment completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<bool> _verifyTopupTransaction(int transactionId) async {
    try {
      final result = await _walletService.verifyTopup(transactionId);
      return result['success'] == true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}


import 'package:flutter/material.dart';
import '../../services/wallet_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../models/wallet_model.dart';
import '../../utils/phone_validation_utils.dart';

class CashoutScreen extends StatefulWidget {
  const CashoutScreen({super.key});

  @override
  State<CashoutScreen> createState() => _CashoutScreenState();
}

class _CashoutScreenState extends State<CashoutScreen> {
  final WalletService _walletService = WalletService();
  final LanguageService _languageService = LanguageService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();

  String _selectedCurrency = 'TZS';
  String _selectedPayoutMethod = 'mobile_money';
  WalletModel? _wallet;
  bool _isLoading = false;
  bool _isLoadingWallet = true;
  double? _convertedAmount;

  // Country codes mapping - automatically matches currency
  final Map<String, String> _countryCodes = {
    'TZS': '+255', // Tanzania
    'KES': '+254', // Kenya
    'NGN': '+234', // Nigeria
  };

  static const Map<String, double> _exchangeRates = {
    'TZS': 1000.0,  // 1 SOK = 1000 TZS
    'KES': 52.7,    // 1 SOK = 52.7 KES (1 TZS = 0.0527 KES)
    'NGN': 587.0,   // 1 SOK = 587 NGN (1 TZS = 0.587 NGN)
  };

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _amountController.addListener(_updateConversion);
    _loadWallet();
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    _amountController.removeListener(_updateConversion);
    _amountController.dispose();
    _accountController.dispose();
    _bankNameController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadWallet() async {
    try {
      final wallet = await _walletService.getWalletBalance();
      setState(() {
        _wallet = wallet;
        _isLoadingWallet = false;
      });
      _updateConversion();
    } catch (e) {
      setState(() {
        _isLoadingWallet = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n?.errorLoadingWallet ?? 'Error loading wallet'}: $e')),
        );
      }
    }
  }

  void _updateConversion() {
    final amount = double.tryParse(_amountController.text);
    final rate = _exchangeRates[_selectedCurrency];
    double? newValue;
    if (amount != null && rate != null) {
      newValue = amount * rate;
    }
    if (newValue == null && _convertedAmount == null) {
      return;
    }
    if (newValue != null &&
        _convertedAmount != null &&
        (newValue - _convertedAmount!).abs() < 0.0001) {
      return;
    }
    setState(() {
      _convertedAmount = newValue;
    });
  }

  String _formatLocalAmount(double amount, String currency) {
    final decimals = amount >= 1 ? 2 : 4;
    final sign = amount < 0 ? '-' : '';
    final fixed = amount.abs().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    final decimalPart =
        decimals > 0 && parts.length > 1 ? '.${parts[1]}' : '';
    return '$sign$currency $integer$decimalPart';
  }

  Future<void> _initiateCashout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sokocoinAmount = double.parse(_amountController.text);

      if (_wallet == null || _wallet!.sokocoinBalance < sokocoinAmount) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.insufficientSokocoinBalance ?? 'Insufficient Sokocoin balance'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final authService = AuthService();
      await authService.initialize();

      // Combine country code with phone number for mobile money
      // Always use the country code that matches the selected currency
      String payoutAccount = _accountController.text.trim();
      if (_selectedPayoutMethod == 'mobile_money') {
        // Get the correct country code for the selected currency
        final correctCountryCode = _countryCodes[_selectedCurrency] ?? '+255';
        payoutAccount = '$correctCountryCode$payoutAccount';
      }

      final result = await _walletService.initiateCashout(
        sokocoinAmount: sokocoinAmount,
        payoutMethod: _selectedPayoutMethod,
        payoutAccount: payoutAccount,
        currency: _selectedCurrency,
        fullName: authService.fullName ?? _accountNameController.text,
        bankName: _bankNameController.text.isEmpty ? null : _bankNameController.text,
        accountName: _accountNameController.text.isEmpty ? null : _accountNameController.text,
      );

      if (result['success'] == true) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.cashoutInitiatedSuccessfully ?? 'Cashout initiated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          // Extract error message
          String errorMessage = result['message'] ?? result['detail'] ?? (l10n?.failedToInitiateCashout ?? 'Failed to initiate cashout');
          
          // Show user-friendly error dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n?.cashoutError ?? 'Cashout Error'),
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
                  Text('• ${l10n?.invalidPayoutAccountDetails ?? 'Invalid payout account details'}'),
                  Text('• ${l10n?.networkConnectionIssue ?? 'Network connection issue'}'),
                  Text('• ${l10n?.paymentGatewayConfigurationIssue ?? 'Payment gateway configuration issue'}'),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.pleaseCheckPayoutDetails ?? 'Please check your payout details and try again.',
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
            title: Text(l10n?.cashoutError ?? 'Cashout Error'),
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
                Text('• ${l10n?.invalidPayoutAccountDetails ?? 'Invalid payout account details'}'),
                Text('• ${l10n?.networkConnectionIssue ?? 'Network connection issue'}'),
                Text('• ${l10n?.paymentGatewayConfigurationIssue ?? 'Payment gateway configuration issue'}'),
                const SizedBox(height: 16),
                Text(
                  l10n?.pleaseCheckPayoutDetailsOrContact ?? 'Please check your payout details and try again or contact support if the issue persists.',
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
    
    if (_isLoadingWallet) {
      return Scaffold(
        backgroundColor: isDark 
            ? const Color(0xFF121212)
            : const Color(0xFFF5F7FA),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    final balance = _wallet?.sokocoinBalance ?? 0.0;

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
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      size: 32,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.cashoutTitle ?? 'Cashout',
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
                    // Balance Card
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF4CAF50).withOpacity(0.1),
                            const Color(0xFF66BB6A).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          width: 1.5,
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
                          Text(
                            l10n?.availableBalance ?? 'Available Balance',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${balance.toStringAsFixed(2)} SOK',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.green[300] : Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sokocoin Amount Input
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
                          labelText: l10n?.sokocoinAmount ?? 'Sokocoin Amount',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          hintText: l10n?.enterAmountToCashout ?? 'Enter amount to cashout',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Color(0xFFFF9800),
                            ),
                          ),
                          suffixText: 'SOK',
                          suffixStyle: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n?.pleaseEnterAmountToCashout ?? 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return l10n?.pleaseEnterValidAmountToCashout ?? 'Please enter a valid amount';
                          }
                          if (amount > balance) {
                            return l10n?.amountExceedsBalance ?? 'Amount exceeds available balance';
                          }
                          if (amount < 10) {
                            return l10n?.minimumCashoutIs10 ?? 'Minimum cashout is 10 SOK';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_convertedAmount != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.swap_horiz_rounded,
                                size: 18,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                l10n != null 
                                    ? l10n.willBeWithdrawn.replaceAll('{amount}', _formatLocalAmount(_convertedAmount!, _selectedCurrency))
                                    : '≈ ${_formatLocalAmount(_convertedAmount!, _selectedCurrency)} will be withdrawn.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark 
                                      ? Colors.grey[300] 
                                      : Colors.blue[900],
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Payout Method Selection
                    Text(
                      l10n?.payoutMethod ?? 'Payout Method',
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
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: RadioListTile<String>(
                              title: Text(
                                l10n?.mobileMoney ?? 'Mobile Money',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.grey[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: 'mobile_money',
                              groupValue: _selectedPayoutMethod,
                              activeColor: const Color(0xFFFF9800),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPayoutMethod = value!;
                                });
                              },
                            ),
                          ),
                          RadioListTile<String>(
                            title: Text(
                              l10n?.bankTransfer ?? 'Bank Transfer',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.grey[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            value: 'bank_transfer',
                            groupValue: _selectedPayoutMethod,
                            activeColor: const Color(0xFFFF9800),
                            onChanged: (value) {
                              setState(() {
                                _selectedPayoutMethod = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Account Input (Phone for Mobile Money, Account Number for Bank)
                    if (_selectedPayoutMethod == 'mobile_money') ...[
                      // Phone Number with Country Code Selector
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Country Code Dropdown (locked to currency)
                          Flexible(
                            flex: 2,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 90, maxWidth: 110),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[700] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _countryCodes[_selectedCurrency] ?? '+255',
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.grey[900],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  size: 20,
                                ),
                                isExpanded: true,
                                // Only show the country code that matches the selected currency
                                items: [
                                  DropdownMenuItem<String>(
                                    value: _countryCodes[_selectedCurrency] ?? '+255',
                                    child: Text(
                                      _countryCodes[_selectedCurrency] ?? '+255',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.grey[900],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: null, // Disable manual selection - it's locked to currency
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Phone Number Input
                          Flexible(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                                controller: _accountController,
                                keyboardType: TextInputType.phone,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.grey[900],
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  labelText: l10n?.phoneNumber ?? 'Phone Number',
                                  labelStyle: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  hintText: '7XXXXXXXX',
                                  hintStyle: TextStyle(
                                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF9800).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.phone_rounded,
                                        color: Color(0xFFFF9800),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                  validator: (value) {
                                    // Get the country code based on selected currency
                                    final countryCode = _countryCodes[_selectedCurrency] ?? '+255';
                                    return PhoneValidationUtils.validatePhoneNumber(value, countryCode);
                                  },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Helper text showing the full number format
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          l10n != null
                              ? l10n.formatPhoneNumber.replaceAll('{code}', _countryCodes[_selectedCurrency] ?? '+255')
                              : 'Format: ${_countryCodes[_selectedCurrency] ?? '+255'}XXXXXXXX',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else ...[
                      // Bank Account Number
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
                          controller: _accountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                          decoration: InputDecoration(
                            labelText: l10n?.accountNumber ?? 'Account Number',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            hintText: l10n?.enterAccountNumber ?? 'Enter account number',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_rounded,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n?.pleaseEnterAccountNumber ?? 'Please enter account number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],

                    // Bank Name (only for bank transfer)
                    if (_selectedPayoutMethod == 'bank_transfer') ...[
                      const SizedBox(height: 16),
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
                          controller: _bankNameController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                          decoration: InputDecoration(
                            labelText: l10n?.bankName ?? 'Bank Name',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            hintText: l10n?.enterBankName ?? 'Enter bank name',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.business_rounded,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (_selectedPayoutMethod == 'bank_transfer' &&
                                (value == null || value.isEmpty)) {
                              return l10n?.pleaseEnterBankName ?? 'Please enter bank name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],

                    // Account Name (only for bank transfer)
                    if (_selectedPayoutMethod == 'bank_transfer') ...[
                      const SizedBox(height: 16),
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
                          controller: _accountNameController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                          decoration: InputDecoration(
                            labelText: l10n?.accountName ?? 'Account Name',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            hintText: l10n?.enterAccountHolderName ?? 'Enter account holder name',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (_selectedPayoutMethod == 'bank_transfer' &&
                                (value == null || value.isEmpty)) {
                              return l10n?.pleaseEnterAccountName ?? 'Please enter account name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],

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
                      alignment: WrapAlignment.start,
                      children: ['TZS', 'KES', 'NGN'].map((currency) {
                        final isSelected = _selectedCurrency == currency;
                        return FilterChip(
                          label: Text(
                            currency,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.grey[900]),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          selected: isSelected,
                          backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                          selectedColor: const Color(0xFFFF9800),
                          checkmarkColor: Colors.white,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCurrency = currency;
                              // Country code automatically matches currency via _countryCodes map
                              _updateConversion();
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _initiateCashout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
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
                                l10n?.initiateCashout ?? 'Initiate Cashout',
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
}


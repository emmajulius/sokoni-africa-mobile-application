import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../services/auth_service.dart';
import '../../services/wallet_service.dart';
import '../../services/language_service.dart';
import '../../models/wallet_model.dart';
import '../auth/login_screen.dart';
import 'topup_screen.dart';
import 'cashout_screen.dart';
import 'transaction_history_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  final LanguageService _languageService = LanguageService();
  WalletModel? _wallet;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _checkGuestAccess();
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

  Future<void> _checkGuestAccess() async {
    final authService = AuthService();
    await authService.initialize();
    
    if (authService.isGuest) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final wallet = await _walletService.getWalletBalance();
      setState(() {
        _wallet = wallet;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // Provide more user-friendly error messages
        final l10n = AppLocalizations.of(context);
        String errorMessage = e.toString();
        if (errorMessage.contains('Failed to fetch') || 
            errorMessage.contains('Connection refused') ||
            errorMessage.contains('timeout')) {
          errorMessage = l10n?.unableToConnectToServer ?? 'Unable to connect to server. Please check your internet connection and ensure the backend server is running.';
        } else if (errorMessage.contains('404') || errorMessage.contains('Not Found')) {
          errorMessage = l10n?.walletEndpointNotFound ?? 'Wallet endpoint not found. Please ensure the backend server is updated.';
        } else if (errorMessage.contains('500') || errorMessage.contains('Internal Server Error')) {
          errorMessage = l10n?.serverErrorWalletTables ?? 'Server error. The wallet tables may not be created. Please run the database migration.';
        } else if (errorMessage.contains('not authenticated') || errorMessage.contains('401')) {
          errorMessage = l10n?.pleaseLogInAgainWallet ?? 'Please log in again to access your wallet.';
        }
        _error = errorMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    // Show loading indicator while checking guest access or loading wallet
    if (_isLoading) {
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

    final authService = AuthService();
    if (authService.isGuest) {
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
                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 32,
                        color: Color(0xFF4A90E2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Wallet',
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
              // Guest Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.grey[800] 
                            : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: isDark ? Colors.grey[400] : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n?.walletPaymentMethods ?? 'Wallet & Payment Methods',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.walletPaymentMethodsOnlyRegistered ?? 'Wallet and payment methods are only available for registered users.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          l10n?.signInToContinue ?? 'Sign In to Continue',
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
            ],
          ),
        ),
      );
    }

    if (_error != null) {
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
                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 32,
                        color: Color(0xFF4A90E2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Wallet',
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
              // Error Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red[50]!.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: isDark ? Colors.red[300] : Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n?.errorLoadingWallet ?? 'Error loading wallet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loadWallet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          l10n?.retry ?? 'Retry',
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
            ],
          ),
        ),
      );
    }

    return _buildWalletContent(l10n);
  }

  Widget _buildWalletContent(AppLocalizations? l10n) {
    final balance = _wallet?.sokocoinBalance ?? 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _loadWallet,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 32,
                              color: Color(0xFF4A90E2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n?.wallet ?? 'Wallet',
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
                    IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: isDark ? Colors.white : Colors.grey[700],
                      ),
                      onPressed: _loadWallet,
                    ),
                  ],
                ),
              ),
            ),
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Sokocoin Balance Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n?.sokocoinBalance ?? 'Sokocoin Balance',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'SOK',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            balance.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n?.keepGrowingYourBalance ?? 'Keep growing your SOK balance to unlock more opportunities.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TopupScreen(),
                                  ),
                                ).then((_) => _loadWallet());
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              label: Text(
                                l10n?.topUp ?? 'Top Up',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CashoutScreen(),
                                  ),
                                ).then((_) => _loadWallet());
                              },
                              icon: const Icon(Icons.arrow_upward_rounded),
                              label: Text(
                                l10n?.cashout ?? 'Cashout',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9800),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Statistics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: l10n?.totalEarned ?? 'Total Earned',
                            value: _wallet?.totalEarned ?? 0.0,
                            icon: Icons.trending_up_rounded,
                            color: const Color(0xFF4CAF50),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: l10n?.totalSpent ?? 'Total Spent',
                            value: _wallet?.totalSpent ?? 0.0,
                            icon: Icons.trending_down_rounded,
                            color: Colors.red,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Transaction History Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.recentTransactions ?? 'Recent Transactions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                        Flexible(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TransactionHistoryScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n?.viewAll ?? 'View All',
                                style: const TextStyle(
                                  color: Color(0xFF4A90E2),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<WalletTransactionModel>>(
                      future: _walletService.getTransactions(limit: 5),
                      builder: (context, snapshot) {
                        final builderL10n = AppLocalizations.of(context);
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                builderL10n?.errorLoadingTransactions ?? 'Error loading transactions',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ),
                          );
                        }

                        final transactions = snapshot.data ?? [];

                        if (transactions.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  builderL10n?.noTransactionsYet ?? 'No transactions yet',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: transactions
                              .map((transaction) => _buildTransactionItem(transaction, isDark, builderL10n))
                              .toList(),
                        );
                      },
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

  Widget _buildStatCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransactionModel transaction, bool isDark, AppLocalizations? l10n) {
    final isDebit = transaction.transactionType == WalletTransactionType.purchase ||
        transaction.transactionType == WalletTransactionType.cashout ||
        transaction.transactionType == WalletTransactionType.fee;
    final isCompleted = transaction.status == WalletTransactionStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDebit
                  ? Colors.red[50]!.withOpacity(isDark ? 0.2 : 1)
                  : Colors.green[50]!.withOpacity(isDark ? 0.2 : 1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDebit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isDebit ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTransactionTitle(transaction, l10n),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isCompleted 
                        ? (isDark ? Colors.white : Colors.grey[900])
                        : (isDark ? Colors.grey[500] : Colors.grey),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Helpers.formatDate(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.orange[900]!.withOpacity(0.3)
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.orange[300] : Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${isDebit ? '-' : '+'}${transaction.sokocoinAmount.toStringAsFixed(2)} SOK',
            style: TextStyle(
              color: isDebit ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _getTransactionTitle(WalletTransactionModel transaction, AppLocalizations? l10n) {
    switch (transaction.transactionType) {
      case WalletTransactionType.topup:
        return l10n?.topUpTransaction ?? 'Top-up';
      case WalletTransactionType.cashout:
        return l10n?.cashoutTransaction ?? 'Cashout';
      case WalletTransactionType.purchase:
        return l10n?.purchaseTransaction ?? 'Purchase';
      case WalletTransactionType.earn:
        return l10n?.earnedTransaction ?? 'Earned';
      case WalletTransactionType.refund:
        return l10n?.refundTransaction ?? 'Refund';
      case WalletTransactionType.fee:
        return l10n?.feeTransaction ?? 'Fee';
    }
  }
}

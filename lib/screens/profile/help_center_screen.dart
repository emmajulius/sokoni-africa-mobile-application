import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import 'report_problem_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();
  static const String _supportEmail = 'emmajulius2512@gmail.com';

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<FAQItem> get _allFAQs {
    return [
      // Getting Started
      FAQItem(
        category: 'Getting Started',
        question: 'How to create an account?',
        answer: '''
To create an account on Sokoni Africa:

1. Tap on "Create Account" or "Sign Up" from the welcome screen
2. Enter your email address, phone number, username, and password
3. Verify your phone number using the OTP code sent to you
4. Select your account type (Client, Supplier, or Retailer)
5. Complete your profile information

You can also sign up using your Google account for faster registration.
        ''',
      ),
      FAQItem(
        category: 'Getting Started',
        question: 'How to add products?',
        answer: '''
To add products as a seller:

1. Go to Profile > Settings > My Inventory
2. Tap the "+" button or "Add Product"
3. Select product images (up to 10 images)
4. Fill in product details:
   - Product title
   - Description
   - Price
   - Category
   - Unit type (piece, kg, liter, etc.)
5. Set product features (warranty, private mode, etc.)
6. Tap "Create Product"

Your product will be visible to buyers immediately after creation.
        ''',
      ),
      FAQItem(
        category: 'Getting Started',
        question: 'How to make a purchase?',
        answer: '''
To make a purchase:

1. Browse products on the home feed or search for specific items
2. Tap on a product to view details
3. Tap "Add to Cart" to add items to your cart
4. Go to your Cart and review items
5. Tap "Checkout" to proceed with payment
6. Select your payment method and shipping address
7. Confirm your order

You'll receive order updates via notifications and can track your order status.
        ''',
      ),
      // Account & Settings
      FAQItem(
        category: 'Account & Settings',
        question: 'How to update profile?',
        answer: '''
To update your profile:

1. Go to Profile > Settings
2. Tap "Update Profile" under Personal Information
3. Edit your information:
   - Full name
   - Username
   - Email
   - Phone number
   - Profile picture
4. Tap "Save" to update your profile

Changes are saved immediately and reflected across the app.
        ''',
      ),
      FAQItem(
        category: 'Account & Settings',
        question: 'How to change language?',
        answer: '''
To change your language:

1. Go to Profile > Settings > Appearance & Preferences
2. Tap "Language & Region"
3. Select your preferred language (English or Swahili)
4. The language will change immediately without restarting the app

You can also change language during onboarding when you first use the app.
        ''',
      ),
      FAQItem(
        category: 'Account & Settings',
        question: 'How to verify my account?',
        answer: '''
To verify your account:

1. Go to Profile > Settings > Account & Support
2. Tap "KYC & Account Verification"
3. Follow the verification steps:
   - Provide your ID document
   - Upload a clear photo
   - Complete identity verification
4. Wait for approval (usually within 24-48 hours)

Verified accounts have a verification badge and access to additional features.
        ''',
      ),
      // Orders & Payments
      FAQItem(
        category: 'Orders & Payments',
        question: 'How to track my orders?',
        answer: '''
To track your orders:

1. Go to Profile > Settings > My Orders
2. You'll see all your orders listed
3. Tap on any order to view details:
   - Order status
   - Shipping information
   - Estimated delivery date
   - Order items

For sellers: Go to "Customer Orders" to see orders from your customers.
        ''',
      ),
      FAQItem(
        category: 'Orders & Payments',
        question: 'Payment methods accepted',
        answer: '''
Sokoni Africa accepts various payment methods:

1. Mobile Money (M-Pesa, Tigo Pesa, Airtel Money)
2. Bank Transfer
3. Credit/Debit Cards
4. Digital Wallet

You can add multiple payment methods in Settings > Wallet & Payment Methods.

All transactions are secure and encrypted. We never store your payment credentials.
        ''',
      ),
      FAQItem(
        category: 'Orders & Payments',
        question: 'How to request a refund?',
        answer: '''
To request a refund:

1. Go to Profile > Settings > My Orders
2. Find the order you want to refund
3. Tap on the order to view details
4. Tap "Request Refund" or "Return Item"
5. Select reason for refund
6. Submit your request

Refund requests are reviewed within 24-48 hours. Refunds are processed to your original payment method within 5-7 business days.

For sellers: You can process refunds from Customer Orders section.
        ''',
      ),
      // Seller Support
      FAQItem(
        category: 'Seller Support',
        question: 'How to manage inventory?',
        answer: '''
To manage your inventory:

1. Go to Profile > Settings > My Inventory
2. View all your products in one place
3. Tap on any product to:
   - Edit product details
   - Update price
   - Change stock quantity
   - Delete product
4. Use filters to organize products by category or status

You can add new products anytime by tapping the "+" button.
        ''',
      ),
      FAQItem(
        category: 'Seller Support',
        question: 'How to handle customer orders?',
        answer: '''
To handle customer orders:

1. Go to Profile > Settings > Customer Orders
2. View all orders from your customers
3. For each order, you can:
   - Accept or reject the order
   - Update order status
   - Mark as shipped
   - Process refunds if needed
   - Communicate with customer via Messages

You'll receive notifications for new orders. Respond promptly to maintain good seller ratings.
        ''',
      ),
      FAQItem(
        category: 'Seller Support',
        question: 'Sales analytics explained',
        answer: '''
Sales Analytics provides insights into your business:

1. Go to Profile > Settings > Sales Analytics
2. View key metrics:
   - Total sales
   - Revenue trends
   - Top-selling products
   - Customer statistics
   - Order completion rates

Use analytics to:
- Identify best-selling products
- Optimize pricing strategies
- Understand customer behavior
- Track business growth

Data is updated in real-time and available for different time periods.
        ''',
      ),
    ];
  }

  List<FAQItem> get _filteredFAQs {
    final normalizedQuery = _normalizeQuery(_searchQuery);
    if (normalizedQuery.isEmpty) {
      return _allFAQs;
    }

    final queryTokens = normalizedQuery.split(' ').where((token) => token.isNotEmpty).toList();
    if (queryTokens.isEmpty) {
      return _allFAQs;
    }

    return _allFAQs.where((faq) {
      final searchableText = _normalizeQuery('${faq.category} ${faq.question} ${faq.answer}');
      return queryTokens.every((token) => searchableText.contains(token));
    }).toList();
  }

  String _normalizeQuery(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  Map<String, List<FAQItem>> get _groupedFAQs {
    final Map<String, List<FAQItem>> grouped = {};
    for (var faq in _filteredFAQs) {
      if (!grouped.containsKey(faq.category)) {
        grouped[faq.category] = [];
      }
      grouped[faq.category]!.add(faq);
    }
    return grouped;
  }

  Future<void> _composeSupportEmail({
    required String subject,
    String? body,
    String fallbackMessage = 'Could not open an email app.',
  }) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': subject,
        if (body != null && body.isNotEmpty) 'body': body,
      },
    );

    try {
      final launched = await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      final l10n = AppLocalizations.of(context);
      if (!launched) {
        await Clipboard.setData(const ClipboardData(text: _supportEmail));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n != null ? l10n.couldNotOpenEmailApp : fallbackMessage} ${l10n != null ? l10n.emailAddressCopiedToClipboard.replaceAll('{email}', _supportEmail) : 'Email address copied to clipboard: $_supportEmail'}'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.openingEmailApp ?? 'Opening your email app...'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      await Clipboard.setData(const ClipboardData(text: _supportEmail));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fallbackMessage (${e.toString()}). Email address copied to clipboard.'),
          ),
        );
      }
    }
  }

  Future<void> _launchEmail() async {
    await _authService.initialize();
    final name = _authService.fullName ?? _authService.username ?? 'Sokoni Africa user';
    final emailBody = 'Hi Sokoni Africa Support,\n\n'
        'I need help with...\n\n'
        'Best,\n$name';
    await _composeSupportEmail(
      subject: 'Sokoni Africa Support Request',
      body: emailBody,
      fallbackMessage: 'Could not open an email app.',
    );
  }

  Future<void> _launchPhone() async {
    const supportNumber = '+255756556768';
    final telUri = Uri(scheme: 'tel', path: supportNumber);

    try {
      final launched = await launchUrl(
        telUri,
        mode: LaunchMode.externalApplication,
      );

      final l10n = AppLocalizations.of(context);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n != null ? l10n.couldNotOpenDialer.replaceAll('{number}', supportNumber) : 'Could not open the dialer. Support number copied: $supportNumber',
            ),
          ),
        );
        await Clipboard.setData(const ClipboardData(text: supportNumber));
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n != null ? l10n.unableToMakeCall.replaceAll('{error}', e.toString()).replaceAll('{number}', supportNumber) : 'Unable to make a call (${e.toString()}). Support number copied: $supportNumber',
            ),
          ),
        );
      }
      await Clipboard.setData(const ClipboardData(text: supportNumber));
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
      appBar: AppBar(
        title: Text(l10n?.helpCenter ?? 'Help Center'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Compact Header with Gradient
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
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    size: 32,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.helpCenter ?? 'Help Center',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark 
                        ? Colors.white 
                        : Colors.grey[900],
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n?.findAnswersCommonQuestions ?? 'Find answers to common questions',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark 
                        ? Colors.grey[400] 
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // Modern Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.grey[850]!.withOpacity(0.5)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark 
                          ? Colors.grey[800]!
                          : Colors.grey[200]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey[900],
                      fontSize: 15,
                    ),
              decoration: InputDecoration(
                hintText: l10n?.searchForHelp ?? 'Search for help...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(left: 8, right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF2196F3),
                          size: 20,
                        ),
                      ),
                      border: InputBorder.none,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
                  ),
                ),
              ],
            ),
          ),
          // FAQ Categories
          Expanded(
            child: _filteredFAQs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.grey[800] : Colors.grey[200])!.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.noResultsFound ?? 'No results found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n?.trySearchingDifferentKeywords ?? 'Try searching with different keywords',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      ..._groupedFAQs.entries.map((entry) {
                        return _buildCategorySection(
                          title: entry.key,
                          items: entry.value,
                        );
                      }),
                      const SizedBox(height: 16),
                      // Contact Support Card
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    Colors.blue[900]!.withOpacity(0.3),
                                    Colors.blue[800]!.withOpacity(0.2),
                                  ]
                                : [
                                    Colors.blue[50]!,
                                    Colors.blue[100]!.withOpacity(0.5),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.blue[800]!.withOpacity(0.5)
                                : Colors.blue[200]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.support_agent_rounded,
                                    color: Color(0xFF2196F3),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                l10n?.stillNeedHelp ?? 'Still need help?',
                                style: TextStyle(
                                  fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : Colors.grey[900],
                                ),
                              ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                              Text(
                                l10n?.contactSupportTeam ?? 'Contact our support team for personalized assistance',
                                style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                                height: 1.4,
                                ),
                              ),
                            const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark 
                                          ? Colors.grey[850]!.withOpacity(0.5)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark 
                                            ? Colors.grey[700]!
                                            : Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _launchEmail,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.email_rounded,
                                                size: 20,
                                                color: isDark ? Colors.white : Colors.grey[900],
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n?.email ?? 'Email',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white : Colors.grey[900],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _launchPhone,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.phone_rounded,
                                                size: 20,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n?.call ?? 'Call',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                    ),
                                  ),
                                ],
                                          ),
                                        ),
                                      ),
                                      ),
                                    ),
                              ),
                            ],
                          ),
                            ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required List<FAQItem> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Assign colors based on category
    Color categoryColor;
    if (title.contains('Getting Started')) {
      categoryColor = const Color(0xFF2196F3);
    } else if (title.contains('Account')) {
      categoryColor = const Color(0xFF9C27B0);
    } else if (title.contains('Orders') || title.contains('Payments')) {
      categoryColor = const Color(0xFF4CAF50);
    } else if (title.contains('Seller')) {
      categoryColor = const Color(0xFFFF9800);
    } else {
      categoryColor = const Color(0xFF667EEA);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(title),
                  color: categoryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[900],
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey[850]!.withOpacity(0.5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                      ? Colors.grey[800]!
                      : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FAQDetailScreen(faq: item),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getQuestionIcon(item.question),
                            color: categoryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.question,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.grey[900],
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
        const SizedBox(height: 8),
      ],
    );
  }
  
  IconData _getCategoryIcon(String category) {
    if (category.contains('Getting Started')) {
      return Icons.rocket_launch_rounded;
    } else if (category.contains('Account')) {
      return Icons.account_circle_rounded;
    } else if (category.contains('Orders') || category.contains('Payments')) {
      return Icons.shopping_bag_rounded;
    } else if (category.contains('Seller')) {
      return Icons.store_rounded;
    } else {
      return Icons.help_outline_rounded;
    }
  }
  
  IconData _getQuestionIcon(String question) {
    final q = question.toLowerCase();
    if (q.contains('create') || q.contains('account') || q.contains('sign up')) {
      return Icons.person_add_rounded;
    } else if (q.contains('add') || q.contains('product')) {
      return Icons.add_shopping_cart_rounded;
    } else if (q.contains('purchase') || q.contains('buy')) {
      return Icons.shopping_cart_rounded;
    } else if (q.contains('update') || q.contains('profile')) {
      return Icons.edit_rounded;
    } else if (q.contains('language') || q.contains('change')) {
      return Icons.language_rounded;
    } else if (q.contains('verify') || q.contains('kyc')) {
      return Icons.verified_user_rounded;
    } else if (q.contains('track') || q.contains('order')) {
      return Icons.local_shipping_rounded;
    } else if (q.contains('payment') || q.contains('method')) {
      return Icons.payment_rounded;
    } else if (q.contains('refund')) {
      return Icons.assignment_return_rounded;
    } else if (q.contains('inventory') || q.contains('manage')) {
      return Icons.inventory_2_rounded;
    } else if (q.contains('customer') || q.contains('handle')) {
      return Icons.people_rounded;
    } else if (q.contains('analytics') || q.contains('sales')) {
      return Icons.analytics_rounded;
    } else {
      return Icons.help_outline_rounded;
    }
  }
}

class FAQItem {
  final String category;
  final String question;
  final String answer;

  FAQItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}

class FAQDetailScreen extends StatelessWidget {
  final FAQItem faq;

  const FAQDetailScreen({super.key, required this.faq});

  Color _getCategoryColor(String category) {
    if (category.contains('Getting Started')) {
      return const Color(0xFF2196F3);
    } else if (category.contains('Account')) {
      return const Color(0xFF9C27B0);
    } else if (category.contains('Orders') || category.contains('Payments')) {
      return const Color(0xFF4CAF50);
    } else if (category.contains('Seller')) {
      return const Color(0xFFFF9800);
    } else {
      return const Color(0xFF667EEA);
    }
  }

  Widget _buildFormattedAnswer(String answer, bool isDark) {
    final categoryColor = _getCategoryColor(faq.category);
    // Split answer into lines
    final lines = answer.split('\n');
    final widgets = <Widget>[];
    bool inNestedList = false;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();
      
      if (trimmedLine.isEmpty) {
        continue;
      }
      
      // Check if it's a numbered list item (starts with number and period)
      final numberedMatch = RegExp(r'^(\d+)\.\s*(.+)$').firstMatch(trimmedLine);
      if (numberedMatch != null) {
        inNestedList = false;
        final number = numberedMatch.group(1)!;
        final text = numberedMatch.group(2)!;
        
        // Check if next line starts with a dash (nested list)
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.startsWith('-') || nextLine.startsWith('   -')) {
            inNestedList = true;
          }
        }
        
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: inNestedList ? 8 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: categoryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: isDark ? Colors.grey[200] : Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }
      
      // Check if it's a bullet point (starts with dash or bullet, possibly with leading spaces)
      // Also handle lines that are indented sub-items
      final isBullet = trimmedLine.startsWith('-') || 
                       trimmedLine.startsWith('•') ||
                       (line.trimLeft() != line && (line.contains('-') || line.contains('•')));
      
      if (isBullet) {
        // Remove leading spaces, dashes, and bullets
        final text = trimmedLine.replaceAll(RegExp(r'^[\s\-\•]+'), '').trim();
        if (text.isEmpty) continue;
        
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 46),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }
      
      // Regular text paragraph
      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: 14,
            top: widgets.isEmpty ? 0 : 4,
          ),
          child: Text(
            trimmedLine,
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: isDark ? Colors.grey[200] : Colors.grey[800],
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _getCategoryColor(faq.category);
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n?.faq ?? 'FAQ'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Compact Header with Question Icon
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          color: categoryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: categoryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            faq.category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    faq.question,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.grey[900],
                      letterSpacing: -0.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Answer Card with Icon
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.grey[850]!.withOpacity(0.7),
                                Colors.grey[850]!.withOpacity(0.5),
                              ]
                            : [
                                Colors.white,
                                Colors.grey[50]!,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark 
                            ? Colors.grey[800]!
                            : Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with icon
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: categoryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
            Text(
                                l10n?.answer ?? 'Answer',
              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: categoryColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Answer content with formatted text
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: _buildFormattedAnswer(faq.answer, isDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Feedback Card with Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.grey[850]!.withOpacity(0.7),
                                Colors.grey[850]!.withOpacity(0.5),
                              ]
                            : [
                                Colors.white,
                                Colors.grey[50]!,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark 
                            ? Colors.grey[800]!
                            : Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.feedback_rounded,
                                size: 20,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n?.wasThisHelpful ?? 'Was this helpful?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      final l10n = AppLocalizations.of(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Text(l10n?.thankYouForYourFeedback ?? 'Thank you for your feedback!'),
                                            ],
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.thumb_up_rounded,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n?.yesHelpful ?? 'Yes, Helpful',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? Colors.grey[800]!.withOpacity(0.5)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark 
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ReportProblemScreen(),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.thumb_down_rounded,
                                            size: 20,
                                            color: isDark ? Colors.white : Colors.grey[900],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n?.notHelpful ?? 'Not Helpful',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : Colors.grey[900],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
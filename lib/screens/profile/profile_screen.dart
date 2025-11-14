import 'package:flutter/material.dart';
import 'profile_settings_screen.dart';
import '../inventory/inventory_screen.dart';
import '../orders/my_orders_screen.dart';
import '../orders/customer_orders_screen.dart';
import '../wallet/wallet_screen.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../auth/login_screen.dart';
import 'addresses_screen.dart';
import 'followers_list_screen.dart';
import '../../services/auth_api_service.dart';
import '../../utils/helpers.dart';
import '../../services/api_service.dart';
import '../../models/product_model.dart';
import 'user_posts_screen.dart';
import 'sold_products_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final LanguageService _languageService = LanguageService();
  int _followersCount = 0;
  int _soldProductsCount = 0;
  bool _isLoadingStats = true;
  List<ProductModel> _userProducts = [];
  bool _isLoadingProducts = false;
  int _profileImageVersion = DateTime.now().millisecondsSinceEpoch;
  
  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _loadProfile();
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

  Future<void> _loadProfile() async {
    await _authService.initialize();
    if (_authService.isAuthenticated && _authService.authToken != null) {
      try {
        await _authService.loadUserProfile();
        _profileImageVersion = DateTime.now().millisecondsSinceEpoch;
        await _loadUserStats();
        await _loadUserProducts();
      } catch (e) {
        print('Error loading profile: $e');
      }
      if (mounted) {
        setState(() {});
      }
    } else {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadUserProducts() async {
    if (!_authService.isAuthenticated || _authService.authToken == null) {
      return;
    }

    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final userId = int.parse(_authService.userId ?? '0');
      final products = await _apiService.getProducts(sellerId: userId);
      
      if (mounted) {
        setState(() {
          _userProducts = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      print('Error loading user products: $e');
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
  }

  Future<void> _loadUserStats() async {
    if (!_authService.isAuthenticated || _authService.authToken == null) {
      setState(() {
        _isLoadingStats = false;
      });
      return;
    }

    try {
      final authApiService = AuthApiService();
      final profileData = await authApiService.getCurrentUserProfile(_authService.authToken!);
      
      setState(() {
        _followersCount = profileData['followers_count'] ?? 0;
        _soldProductsCount = profileData['sold_products_count'] ?? 0;
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Error loading user stats: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  String? get _profileImageUrl {
    final url = _authService.profileImage;
    if (url == null || url.isEmpty) {
      return null;
    }
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=$_profileImageVersion';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    final isGuest = _authService.isGuest;
    final canBuy = _authService.canBuy;
    final canSell = _authService.canSell;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Allow normal back navigation - don't logout
        if (didPop) {
          // Screen was popped, do nothing special
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.profile),
          automaticallyImplyLeading: false, // No back button for tab screen
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: isGuest
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.settingsOnlyForRegisteredUsers),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  : () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSettingsScreen(),
                        ),
                      );
                      // Refresh profile if returning from settings
                      if (result == true && mounted) {
                        await _loadProfile();
                      }
                    },
            ),
          ],
        ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Compact Profile Header with Gradient
            Container(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
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
                  // Profile Avatar with border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[800] 
                          : Colors.grey[200],
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _authService.profileImage == null
                          ? Icon(
                              Icons.person,
                              size: 40,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[400] 
                                  : Colors.grey[600],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isGuest 
                        ? l10n.guestUser 
                        : (_authService.fullName ?? 'User'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.grey[900],
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isGuest 
                        ? l10n.browseAsGuest 
                        : '@${_authService.username ?? 'user'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[400] 
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isGuest && _authService.userType != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]!.withOpacity(0.5)
                            : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getUserTypeDisplayName(_authService.userType!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[300] 
                              : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                  if (isGuest) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2196F3) // Use explicit blue color in dark mode
                            : Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        l10n.signInToContinue,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white, // Explicit white text color
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          context,
                          value: _isLoadingStats ? '...' : Helpers.formatNumber(_followersCount),
                          label: l10n.followers,
                          icon: Icons.people_rounded,
                          color: const Color(0xFF4CAF50),
                          onTap: () {
                            if (_authService.isAuthenticated && !_authService.isGuest) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowersListScreen(
                                    userId: int.parse(_authService.userId ?? '0'),
                                    username: _authService.username ?? 'User',
                                  ),
                                ),
                              ).then((_) {
                                _loadUserStats();
                              });
                            }
                          },
                        ),
                        if (canSell)
                          _buildStatCard(
                            context,
                            value: _isLoadingProducts ? '...' : Helpers.formatNumber(_userProducts.length),
                            label: l10n.posts,
                            icon: Icons.grid_view_rounded,
                            color: const Color(0xFF2196F3),
                            onTap: () {
                              if (_authService.isAuthenticated && !_authService.isGuest) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserPostsScreen(
                                      userId: int.parse(_authService.userId ?? '0'),
                                      username: _authService.username ?? 'User',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        if (canSell)
                          _buildStatCard(
                            context,
                            value: _isLoadingStats ? '...' : Helpers.formatNumber(_soldProductsCount),
                            label: l10n.soldProducts,
                            icon: Icons.shopping_cart_checkout_rounded,
                            color: const Color(0xFFFF9800),
                            onTap: () {
                              if (_authService.isAuthenticated && !_authService.isGuest) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SoldProductsScreen(
                                      sellerId: int.parse(_authService.userId ?? '0'),
                                    ),
                                  ),
                                ).then((value) {
                                  if (value == true) {
                                    _loadUserStats();
                                    _loadUserProducts();
                                  }
                                });
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Content area with modern card design
            Container(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF121212)
                  : const Color(0xFFF5F7FA),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  if (!isGuest) ...[
                    // Inventory - only for sellers (suppliers and retailers)
                    if (canSell)
                      _buildMenuItem(
                        context,
                        icon: Icons.inventory_2,
                        title: l10n.myInventory,
                        subtitle: l10n.inventoryDesc,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InventoryScreen(),
                            ),
                          );
                        },
                      ),
                    // Customer Orders - only for sellers (suppliers and retailers)
                    if (canSell)
                      _buildMenuItem(
                        context,
                        icon: Icons.store,
                        title: l10n.customerOrders,
                        subtitle: l10n.customerOrdersDesc,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomerOrdersScreen(),
                            ),
                          );
                        },
                      ),
                    // My Orders - only for buyers (clients and retailers), not guests
                    if (canBuy && !isGuest)
                      _buildMenuItem(
                        context,
                        icon: Icons.shopping_bag,
                        title: l10n.myOrders,
                        subtitle: l10n.myOrdersDesc,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyOrdersScreen(),
                            ),
                          );
                        },
                      ),
                    // Wallet - not for guests
                    if (!isGuest)
                      _buildMenuItem(
                        context,
                        icon: Icons.account_balance_wallet,
                        title: l10n.walletPayment,
                        subtitle: l10n.walletDesc,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WalletScreen(),
                            ),
                          );
                        },
                      ),
                    // Addresses - not for guests
                    if (!isGuest)
                      _buildMenuItem(
                        context,
                        icon: Icons.location_on,
                        title: l10n.myAddresses,
                        subtitle: l10n.addressesDesc,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddressesScreen(),
                            ),
                          );
                        },
                      ),
                  ],
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: l10n.settings,
                    subtitle: l10n.settingsDesc,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  if (isGuest) ...[
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]!.withOpacity(0.5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]!
                              : Colors.grey[200]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline,
                              size: 32,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.signInToUnlock,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white 
                                  : Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.signInMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[300] // Lighter gray for better visibility in dark mode
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
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
                                backgroundColor: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF2196F3) // Use explicit blue color in dark mode
                                    : Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                l10n.signInNow,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.white, // Explicit white text color
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
  
  String _getUserTypeDisplayName(String userType) {
    switch (userType) {
      case 'client':
        return 'Sokoni Client';
      case 'supplier':
        return 'Sokoni Supplier';
      case 'retailer':
        return 'Sokoni Retailer';
      default:
        return 'User';
    }
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.grey[900],
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[400] 
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    // Assign colors based on menu item
    Color iconColor;
    Color backgroundColor;
    
    if (title.contains('Inventory')) {
      iconColor = const Color(0xFF2196F3);
      backgroundColor = const Color(0xFF2196F3).withOpacity(0.1);
    } else if (title.contains('Customer Orders') || title.contains('My Orders')) {
      iconColor = const Color(0xFF4CAF50);
      backgroundColor = const Color(0xFF4CAF50).withOpacity(0.1);
    } else if (title.contains('Wallet')) {
      iconColor = const Color(0xFFFF9800);
      backgroundColor = const Color(0xFFFF9800).withOpacity(0.1);
    } else if (title.contains('Addresses')) {
      iconColor = const Color(0xFF9C27B0);
      backgroundColor = const Color(0xFF9C27B0).withOpacity(0.1);
    } else if (title.contains('Settings')) {
      iconColor = const Color(0xFF607D8B);
      backgroundColor = const Color(0xFF607D8B).withOpacity(0.1);
    } else {
      iconColor = const Color(0xFF667EEA);
      backgroundColor = const Color(0xFF667EEA).withOpacity(0.1);
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark 
                              ? Colors.white 
                              : Colors.grey[900],
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark 
                              ? Colors.grey[400] 
                              : Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark 
                      ? Colors.grey[500] 
                      : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


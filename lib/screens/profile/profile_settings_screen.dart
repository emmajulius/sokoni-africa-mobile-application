import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../../services/language_service.dart' show LanguageService, AppLocalizations;
import '../inventory/inventory_screen.dart';
import '../orders/customer_orders_screen.dart';
import '../orders/my_orders_screen.dart';
import '../wallet/wallet_screen.dart';
import '../auth/login_screen.dart';
import 'update_profile_screen.dart';
import 'update_business_screen.dart';
import 'sales_analytics_screen.dart';
import 'language_region_screen.dart';
import 'kyc_verification_screen.dart';
import 'help_center_screen.dart';
import 'report_problem_screen.dart';
import 'terms_privacy_screen.dart';
import 'addresses_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();
  final Set<String> _updatingSettings = {};
  
  @override
  void initState() {
    super.initState();
    _settingsService.addListener(_onSettingsChanged);
    _languageService.addListener(_onLanguageChanged);
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await _settingsService.initialize();
  }
  
  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    _languageService.removeListener(_onLanguageChanged);
    super.dispose();
  }
  
  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  void _handleLogout() {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          l10n.logOut,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          l10n.areYouSureLogOut ?? 'Are you sure you want to log out?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
  }

  bool _profileUpdated = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    final canBuy = _authService.canBuy;
    final canSell = _authService.canSell;
    final isGuest = _authService.isGuest;
    
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Allow normal back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settings),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Return true if profile was updated so parent can refresh
              Navigator.pop(context, _profileUpdated);
            },
          ),
        ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: ListView(
          children: [
            // Compact Settings Header with Gradient
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.settings,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.grey[900],
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.manageAccountPreferences,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey[400] 
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                  // Personal Information - not for guests
                  if (!isGuest)
                    _buildSection(
                      title: l10n.personalInformation,
                      subtitle: l10n.updatePersonalDetails ?? 'Update your personal details like name, username, email, and phone number to keep your account information current.',
                      children: [
                        _buildSettingItem(
                          icon: Icons.person,
                          title: l10n.updateProfile,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UpdateProfileScreen(),
                              ),
                            );
                            // Refresh if profile was updated
                            if (result == true && mounted) {
                              // Reload profile data from API
                              await _authService.loadUserProfile();
                              _profileUpdated = true;
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  // Business Information - only for sellers
                  if (canSell)
                    _buildSection(
                      title: l10n.businessInformation,
                      subtitle: l10n.updateBusinessDetailsSubtitle ?? 'Update your Business details like Shop Name, Shop Type, to keep your account information current.',
                      children: [
                        _buildSettingItem(
                          icon: Icons.store,
                          title: l10n.updateBusinessDetailsTitle,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UpdateBusinessScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingItem(
                          icon: Icons.local_shipping,
                          title: l10n.setPickupLocation,
                          subtitle: l10n.setPickupLocationSubtitle ?? 'Set your business location for shipping. Buyers can use Sokoni Africa Logistics if location is set.',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddressesScreen(),
                              ),
                            );
                            // Optionally refresh if needed
                            if (result == true && mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  // General
                  _buildSection(
                    title: l10n.general,
                    children: [
                      if (canSell)
                        _buildSettingItem(
                          icon: Icons.inventory_2,
                          title: l10n.myInventory,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InventoryScreen(),
                              ),
                            );
                          },
                        ),
                      if (canSell)
                        _buildSettingItem(
                          icon: Icons.shopping_bag,
                          title: l10n.customerOrders,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CustomerOrdersScreen(),
                              ),
                            );
                          },
                        ),
                      if (canBuy && !isGuest)
                        _buildSettingItem(
                          icon: Icons.shopping_cart,
                          title: l10n.myOrders,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyOrdersScreen(),
                              ),
                            );
                          },
                        ),
                      if (canSell)
                        _buildSettingItem(
                          icon: Icons.analytics,
                          title: l10n.salesAnalytics,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SalesAnalyticsScreen(),
                              ),
                            );
                          },
                        ),
                      if (!isGuest)
                        _buildSettingItem(
                          icon: Icons.account_balance_wallet,
                          title: l10n.walletPayment,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WalletScreen(),
                              ),
                            );
                          },
                        ),
                      if (!isGuest)
                        _buildSettingItem(
                          icon: Icons.location_on,
                          title: l10n.myAddresses,
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
                  ),
                  // Notification - not for guests
                  if (!isGuest)
                    _buildSection(
                      title: l10n.notification,
                      children: [
                        _buildSwitchItem(
                          icon: Icons.notifications,
                          title: l10n.activityNotifications,
                          subtitle: l10n.enableDisablePushNotifications ?? 'Enable or disable push notifications for real-time updates',
                          value: _settingsService.activityNotifications,
                          isLoading: _updatingSettings.contains('activity_notifications'),
                          onChanged: (value) => _handleToggle(
                            key: 'activity_notifications',
                            value: value,
                            updateSetting: (v) => _settingsService.setActivityNotifications(v),
                            enabledMessage: l10n.activityNotificationsEnabled ?? 'Activity notifications enabled',
                            disabledMessage: l10n.activityNotificationsDisabled ?? 'Activity notifications disabled',
                          ),
                        ),
                        _buildSwitchItem(
                          icon: Icons.local_offer,
                          title: l10n.promotionsOffers,
                          subtitle: l10n.getPushNotificationsForOffers,
                          value: _settingsService.promotionsNotifications,
                          isLoading: _updatingSettings.contains('promotions_notifications'),
                          onChanged: (value) => _handleToggle(
                            key: 'promotions_notifications',
                            value: value,
                            updateSetting: (v) => _settingsService.setPromotionsNotifications(v),
                            enabledMessage: l10n.promotionsNotificationsEnabled ?? 'Promotions notifications enabled',
                            disabledMessage: l10n.promotionsNotificationsDisabled ?? 'Promotions notifications disabled',
                          ),
                        ),
                        _buildSwitchItem(
                          icon: Icons.email,
                          title: l10n.directEmailNotification,
                          subtitle: l10n.getNotifiedViaEmail ?? 'Get notified via email for important account activities',
                          value: _settingsService.emailNotifications,
                          isLoading: _updatingSettings.contains('email_notifications'),
                          onChanged: (value) => _handleToggle(
                            key: 'email_notifications',
                            value: value,
                            updateSetting: (v) => _settingsService.setEmailNotifications(v),
                            enabledMessage: l10n.emailNotificationsEnabled ?? 'Email notifications enabled',
                            disabledMessage: l10n.emailNotificationsDisabled ?? 'Email notifications disabled',
                          ),
                        ),
                      ],
                    ),
                  // Appearance & Preferences
                  _buildSection(
                    title: l10n.appearancePreferences,
                    children: [
                      _buildSwitchItem(
                        icon: Icons.dark_mode,
                        title: l10n.darkMode,
                        subtitle: l10n.reduceEyeStrain ?? 'Reduce eye strain and improve readability',
                        value: _settingsService.darkMode,
                        isLoading: _updatingSettings.contains('dark_mode'),
                        onChanged: (value) => _handleToggle(
                          key: 'dark_mode',
                          value: value,
                          updateSetting: (v) => _settingsService.setDarkMode(v),
                          enabledMessage: l10n.darkModeEnabled ?? 'Dark mode enabled',
                          disabledMessage: l10n.darkModeDisabled ?? 'Dark mode disabled',
                          silent: true,
                        ),
                      ),
                      _buildSettingItem(
                        icon: Icons.language,
                        title: l10n.languageRegion,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LanguageRegionScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  // Account & Support
                  _buildSection(
                    title: l10n.accountSupport,
                    children: [
                      if (!isGuest)
                        _buildSettingItem(
                          icon: Icons.verified_user,
                          title: l10n.kycAccountVerification,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const KYCVerificationScreen(),
                              ),
                            );
                          },
                        ),
                      _buildSettingItem(
                        icon: Icons.help_outline,
                        title: l10n.helpCenter,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpCenterScreen(),
                            ),
                          );
                        },
                      ),
                      if (!isGuest)
                        _buildSettingItem(
                          icon: Icons.report_problem,
                          title: l10n.reportProblem,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReportProblemScreen(),
                              ),
                            );
                          },
                        ),
                      _buildSettingItem(
                        icon: Icons.description,
                        title: l10n.termsPrivacy,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsPrivacyScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        icon: Icons.logout,
                        title: l10n.logOut,
                        onTap: _handleLogout,
                        textColor: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
      ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    // Assign colors based on section
    Color sectionColor;
    if (title.contains('Personal')) {
      sectionColor = const Color(0xFF2196F3);
    } else if (title.contains('Business')) {
      sectionColor = const Color(0xFF4CAF50);
    } else if (title.contains('General')) {
      sectionColor = const Color(0xFF667EEA);
    } else if (title.contains('Notification')) {
      sectionColor = const Color(0xFFFF9800);
    } else if (title.contains('Appearance')) {
      sectionColor = const Color(0xFF9C27B0);
    } else if (title.contains('Account')) {
      sectionColor = const Color(0xFF607D8B);
    } else {
      sectionColor = const Color(0xFF667EEA);
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: sectionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSectionIcon(title),
                  color: sectionColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark 
                            ? Colors.white 
                            : Colors.grey[900],
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark 
                              ? Colors.grey[400] 
                              : Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        ...children,
        const SizedBox(height: 4),
      ],
    );
  }
  
  IconData _getSectionIcon(String title) {
    if (title.contains('Personal')) {
      return Icons.person_rounded;
    } else if (title.contains('Business')) {
      return Icons.store_rounded;
    } else if (title.contains('General')) {
      return Icons.dashboard_rounded;
    } else if (title.contains('Notification')) {
      return Icons.notifications_rounded;
    } else if (title.contains('Appearance')) {
      return Icons.palette_rounded;
    } else if (title.contains('Account')) {
      return Icons.account_circle_rounded;
    } else {
      return Icons.settings_rounded;
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? textColor,
  }) {
    // Assign colors based on setting type
    Color iconColor = textColor ?? const Color(0xFF667EEA);
    Color backgroundColor;
    
    if (title.contains('Profile') || title.contains('Update')) {
      iconColor = const Color(0xFF2196F3);
      backgroundColor = const Color(0xFF2196F3).withOpacity(0.1);
    } else if (title.contains('Business') || title.contains('Pickup')) {
      iconColor = const Color(0xFF4CAF50);
      backgroundColor = const Color(0xFF4CAF50).withOpacity(0.1);
    } else if (title.contains('Inventory')) {
      iconColor = const Color(0xFF2196F3);
      backgroundColor = const Color(0xFF2196F3).withOpacity(0.1);
    } else if (title.contains('Orders')) {
      iconColor = const Color(0xFF4CAF50);
      backgroundColor = const Color(0xFF4CAF50).withOpacity(0.1);
    } else if (title.contains('Analytics')) {
      iconColor = const Color(0xFF9C27B0);
      backgroundColor = const Color(0xFF9C27B0).withOpacity(0.1);
    } else if (title.contains('Wallet')) {
      iconColor = const Color(0xFFFF9800);
      backgroundColor = const Color(0xFFFF9800).withOpacity(0.1);
    } else if (title.contains('Address')) {
      iconColor = const Color(0xFF9C27B0);
      backgroundColor = const Color(0xFF9C27B0).withOpacity(0.1);
    } else if (title.contains('Language')) {
      iconColor = const Color(0xFF2196F3);
      backgroundColor = const Color(0xFF2196F3).withOpacity(0.1);
    } else if (title.contains('KYC') || title.contains('Verification')) {
      iconColor = const Color(0xFF4CAF50);
      backgroundColor = const Color(0xFF4CAF50).withOpacity(0.1);
    } else if (title.contains('Help')) {
      iconColor = const Color(0xFF2196F3);
      backgroundColor = const Color(0xFF2196F3).withOpacity(0.1);
    } else if (title.contains('Report')) {
      iconColor = const Color(0xFFFF5722);
      backgroundColor = const Color(0xFFFF5722).withOpacity(0.1);
    } else if (title.contains('Terms') || title.contains('Privacy')) {
      iconColor = const Color(0xFF607D8B);
      backgroundColor = const Color(0xFF607D8B).withOpacity(0.1);
    } else if (title.contains('Log Out')) {
      iconColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
    } else {
      backgroundColor = iconColor.withOpacity(0.1);
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
                          color: textColor ?? (isDark 
                              ? Colors.white 
                              : Colors.grey[900]),
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
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

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Future<void> Function(bool) onChanged,
    required bool isLoading,
  }) {
    // Assign colors based on switch type
    Color iconColor;
    Color backgroundColor;
    
    if (title.contains('Activity')) {
      iconColor = const Color(0xFF2196F3);
      backgroundColor = const Color(0xFF2196F3).withOpacity(0.1);
    } else if (title.contains('Promotions')) {
      iconColor = const Color(0xFFFF9800);
      backgroundColor = const Color(0xFFFF9800).withOpacity(0.1);
    } else if (title.contains('Email')) {
      iconColor = const Color(0xFF9C27B0);
      backgroundColor = const Color(0xFF9C27B0).withOpacity(0.1);
    } else if (title.contains('Dark Mode')) {
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
              if (isLoading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Switch(
                  value: value,
                  onChanged: (newValue) async {
                    await onChanged(newValue);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleToggle({
    required String key,
    required bool value,
    required Future<void> Function(bool) updateSetting,
    required String enabledMessage,
    required String disabledMessage,
    bool silent = false,
  }) async {
    if (_updatingSettings.contains(key)) return;
    setState(() {
      _updatingSettings.add(key);
    });

    try {
      await updateSetting(value);
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? enabledMessage : disabledMessage),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context) ?? 
                     AppLocalizations(_languageService.currentLocale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToUpdateSetting ?? 'Failed to update setting. Please try again.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingSettings.remove(key);
        });
      }
    }
  }
}


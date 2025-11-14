import 'package:flutter/material.dart';
import '../feed/feed_screen.dart';
import '../search/search_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';
import '../messages/messages_screen.dart';
import '../inventory/inventory_screen.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../utils/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();
  
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

  List<Widget> get _screens {
    final canBuy = _authService.canBuy;
    final canSell = _authService.canSell;
    
    return [
      const FeedScreen(),
      const SearchScreen(),
      if (canBuy && !canSell)
        const CartScreen() // Client
      else if (!canBuy && canSell)
        const InventoryScreen() // Supplier
      else if (canBuy && canSell)
        const CartScreen() // Retailer (default to cart)
      else
        const CartScreen(), // Fallback
      const MessagesScreen(),
      const ProfileScreen(),
    ];
  }
  
  List<BottomNavigationBarItem> get _navigationItems {
    final canBuy = _authService.canBuy;
    final canSell = _authService.canSell;
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home),
        label: l10n.home,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.search),
        label: l10n.search,
      ),
      if (canBuy && !canSell)
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_cart),
          label: l10n.cart,
        )
      else if (!canBuy && canSell)
        BottomNavigationBarItem(
          icon: const Icon(Icons.inventory_2),
          label: l10n.inventory,
        )
      else if (canBuy && canSell)
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_cart),
          label: l10n.cart,
        )
      else
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_cart),
          label: l10n.cart,
        ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.message),
        label: l10n.messages,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person),
        label: l10n.profile,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent popping MainNavigationScreen
      onPopInvokedWithResult: (didPop, result) async {
        // When back button is pressed on a tab screen:
        // - If we're on the first tab (FeedScreen), do nothing (stay on app)
        // - Otherwise, switch to the first tab (FeedScreen)
        if (!didPop) {
          if (_currentIndex != 0) {
            // Switch to home tab instead of popping
            setState(() {
              _currentIndex = 0;
            });
          }
          // If already on home tab, do nothing (prevent logout)
        }
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textTertiary,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            backgroundColor: AppTheme.surfaceColor,
            elevation: 0,
            items: _navigationItems,
          ),
        ),
      ),
    );
  }
}


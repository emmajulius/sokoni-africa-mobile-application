import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/cart_item_model.dart';
import '../../utils/helpers.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/language_service.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItemModel> _cartItems = [];
  double _total = 0.0;
  double _processingFee = 0.0;
  static const double _processingFeeRate = 0.02; // 2%
  final double _discount = 0.0;
  bool _isLoading = true;
  final LanguageService _languageService = LanguageService();
  final CartService _cartService = CartService();
  
  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _loadCartItems();
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

  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      await authService.initialize();
      
      if (!authService.isAuthenticated || authService.authToken == null) {
        setState(() {
          _cartItems = [];
          _isLoading = false;
        });
        return;
      }

      final items = await _cartService.getCartItems();
      
      if (mounted) {
        setState(() {
          _cartItems = items;
          _calculateTotal();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cartItems = [];
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cart: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _calculateTotal() {
    final subtotal = _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    _processingFee = subtotal * _processingFeeRate;
    _total = subtotal + _processingFee - _discount;
  }

  Future<void> _updateQuantity(int index, int quantity) async {
    if (quantity <= 0) {
      // Remove item
      try {
        final itemId = int.parse(_cartItems[index].id);
        await _cartService.removeFromCart(itemId);
        await _loadCartItems(); // Reload cart
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Update quantity
      try {
        final itemId = int.parse(_cartItems[index].id);
        await _cartService.updateCartItem(itemId: itemId, quantity: quantity);
        await _loadCartItems(); // Reload cart
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating quantity: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCartItemImage(CartItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? imageUrl;
    if (item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty) {
      imageUrl = item.product.imageUrl;
    } else if (item.product.images.isNotEmpty) {
      final candidate = item.product.images.firstWhere(
        (url) => url.isNotEmpty,
        orElse: () => '',
      );
      if (candidate.isNotEmpty) {
        imageUrl = candidate;
      }
    }

    if (imageUrl == null) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image_not_supported,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      memCacheWidth: 200,
      memCacheHeight: 200,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image_not_supported,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDark = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? (isDark ? Colors.white : Colors.grey[900]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Show message for suppliers (they can't buy)
    if (!authService.canBuy) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        body: Column(
          children: [
            // Compact Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.grey[900]!, Colors.grey[800]!]
                      : [Colors.white, Colors.white],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shopping_cart_rounded,
                      color: isDark ? Colors.blue[300] : Colors.blue[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.cart,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Empty State
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: isDark ? Colors.grey[400] : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.cartNotAvailable,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        l10n.cartNotAvailableMsg(authService.isSupplier ? l10n.supplier : l10n.user),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Compact Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.blue[900]!, Colors.blue[800]!]
                    : [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.cart,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_cartItems.length} item${_cartItems.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Cart Items or Loading/Empty State
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading cart...',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _cartItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [Colors.grey[800]!, Colors.grey[700]!]
                                      : [Colors.blue[50]!, Colors.blue[100]!],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: isDark ? Colors.blue[300] : Colors.blue[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              l10n.cartEmpty,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add items to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _loadCartItems,
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                label: const Text(
                                  'Refresh',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCartItems,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              color: isDark ? Colors.grey[900] : Colors.white,
                              shadowColor: Colors.black.withOpacity(0.1),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Image
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _buildCartItemImage(item),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Product Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.store,
                                                size: 14,
                                                color: isDark ? Colors.blue[300] : Colors.blue[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  item.product.sellerUsername,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark ? Colors.blue[300] : Colors.blue[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.product.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: isDark ? Colors.white : Colors.grey[900],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (item.selectedAttributes != null) ...[
                                            const SizedBox(height: 4),
                                            ...item.selectedAttributes!.entries.map((e) => Padding(
                                              padding: const EdgeInsets.only(bottom: 2),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.circle,
                                                    size: 6,
                                                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '${e.key}: ${e.value}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                Helpers.formatCurrency(item.totalPrice),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: isDark ? Colors.blue[300] : Colors.blue[600],
                                                ),
                                              ),
                                              if (item.quantity > 1) ...[
                                                const SizedBox(width: 4),
                                                Text(
                                                  '(${Helpers.formatCurrency(item.product.price)} each)',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Quantity Controls
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove, size: 18),
                                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(
                                                  minWidth: 32,
                                                  minHeight: 32,
                                                ),
                                                onPressed: () {
                                                  _updateQuantity(index, item.quantity - 1);
                                                },
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Text(
                                                  '${item.quantity}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: isDark ? Colors.white : Colors.grey[900],
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add, size: 18),
                                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(
                                                  minWidth: 32,
                                                  minHeight: 32,
                                                ),
                                                onPressed: () {
                                                  _updateQuantity(index, item.quantity + 1);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: Colors.red[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            onPressed: () {
                                              _updateQuantity(index, 0);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          // Total Summary
          if (!_isLoading && _cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            l10n.selectedTotal,
                            Helpers.formatCurrency(_cartItems.fold(
                                0.0, (sum, item) => sum + item.totalPrice)),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Processing Fee (2%)',
                            Helpers.formatCurrency(_processingFee),
                            isDark: isDark,
                          ),
                          if (_discount > 0) ...[
                            const SizedBox(height: 8),
                            _buildSummaryRow(
                              l10n.discount,
                              '-${Helpers.formatCurrency(_discount)}',
                              isDark: isDark,
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.totalAmount,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[900],
                          ),
                        ),
                        Text(
                          Helpers.formatCurrency(_total),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.blue[300] : Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutScreen(
                                  cartItems: _cartItems,
                                  total: _total,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.checkout,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
    );
  }
}


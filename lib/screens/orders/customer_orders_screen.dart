import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/order_service.dart';
import '../../utils/helpers.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();

  final Set<String> _ordersUpdating = {};
  List<OrderModel> _orders = [];

  bool _isLoading = true;
  bool _isSeller = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _bootstrap();
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

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.initialize();
      final l10n = AppLocalizations(_languageService.currentLocale);
      if (!_authService.isAuthenticated || _authService.authToken == null) {
        setState(() {
          _isLoading = false;
          _isSeller = false;
          _errorMessage = l10n.pleaseLogInSellerAccount;
          _orders = [];
        });
        return;
      }

      _isSeller = _authService.canSell;
      if (!_isSeller) {
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.onlySellersCanView;
          _orders = [];
        });
        return;
      }

      await _loadOrders(showLoader: true);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations(_languageService.currentLocale);
      setState(() {
        _isLoading = false;
        final error = _humanizeError(e);
        _errorMessage = '${l10n.failedToInitialiseCustomerOrders.replaceAll('{error}', error)}';
      });
    }
  }

  Future<void> _loadOrders({bool showLoader = false}) async {
    if (!mounted) return;

    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }

    try {
      final orders = await _orderService.getSales();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _humanizeError(e);
        _orders = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n.customerOrders),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadOrders(showLoader: false),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return _ErrorView(
        message: _errorMessage!,
        isSeller: _isSeller,
        onRetry: () => _loadOrders(showLoader: true),
        isDark: isDark,
        l10n: l10n,
      );
    }

    if (_orders.isEmpty) {
      return _EmptyView(
        isSeller: _isSeller,
        onRetry: () => _loadOrders(showLoader: true),
        isDark: isDark,
        l10n: l10n,
      );
    }

    return CustomScrollView(
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
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    size: 32,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context) ?? 
                                 AppLocalizations(_languageService.currentLocale);
                    return Text(
                      l10n.customerOrders,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark 
                            ? Colors.white 
                            : Colors.grey[900],
                        letterSpacing: -0.5,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context) ?? 
                                 AppLocalizations(_languageService.currentLocale);
                    return Text(
                      l10n.manageOrdersFromCustomers,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Orders List
        SliverPadding(
          padding: const EdgeInsets.all(20.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context) ?? 
                                   AppLocalizations(_languageService.currentLocale);
                      return _OrderCard(
                        order: _orders[index],
                        isUpdating: _ordersUpdating.contains(_orders[index].id),
                        onStatusChange: (status) => _updateOrderStatus(_orders[index], status),
                        isDark: isDark,
                        l10n: l10n,
                      );
                    },
                  ),
                );
              },
              childCount: _orders.length,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateOrderStatus(OrderModel order, OrderStatus newStatus) async {
    if (_ordersUpdating.contains(order.id)) return;

    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    final orderId = int.tryParse(order.id);
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invalidOrderIdentifier),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _ordersUpdating.add(order.id);
    });

    try {
      final updatedOrder = await _orderService.updateOrderStatus(
        orderId: orderId,
        status: newStatus,
      );

      if (!mounted) return;

      setState(() {
        final index = _orders.indexWhere((element) => element.id == order.id);
        if (index != -1) {
          _orders[index] = updatedOrder;
        }
        _ordersUpdating.remove(order.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.statusUpdatedTo(_statusLabel(updatedOrder.status, l10n))),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ordersUpdating.remove(order.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.unableToUpdateStatus(_humanizeError(e))),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _humanizeError(Object error) {
    final message = error.toString();
    return message.replaceFirst('Exception: ', '').trim();
  }

}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.isSeller,
    required this.onRetry,
    required this.isDark,
    required this.l10n,
  });

  final String message;
  final bool isSeller;
  final VoidCallback onRetry;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                    Icons.shopping_bag_rounded,
                    size: 32,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.customerOrders,
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.orange[900] : Colors.orange[50])!.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSeller ? Icons.error_outline_rounded : Icons.lock_outline_rounded,
                    size: 64,
                    color: isDark ? Colors.orange[300] : Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isSeller ? l10n.unableToLoadCustomerOrders : l10n.sellerAccessRequired,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      l10n.tryAgain,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.isSeller,
    required this.onRetry,
    required this.isDark,
    required this.l10n,
  });

  final bool isSeller;
  final VoidCallback onRetry;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                    Icons.shopping_bag_rounded,
                    size: 32,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.customerOrders,
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
          // Empty Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.blue[900] : Colors.blue[50])!.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSeller ? Icons.inbox_outlined : Icons.lock_outline_rounded,
                    size: 64,
                    color: isDark ? Colors.blue[300] : Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isSeller ? l10n.noCustomerOrdersYet : l10n.sellerAccessRequired,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isSeller
                      ? l10n.whenBuyersPlaceOrders
                      : l10n.switchToSellerAccount,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      isSeller ? l10n.refreshOrders : l10n.checkAgain,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isUpdating,
    required this.onStatusChange,
    required this.isDark,
    required this.l10n,
  });

  final OrderModel order;
  final bool isUpdating;
  final ValueChanged<OrderStatus> onStatusChange;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final buyerName = (order.customerFullName?.trim().isNotEmpty == true
            ? order.customerFullName
            : order.customerUsername) ??
        l10n.buyer;

    final buyerInitial = buyerName.trim().isNotEmpty
        ? buyerName.trim().substring(0, 1).toUpperCase()
        : 'B';

    final productCount = order.items.fold<int>(0, (acc, item) => acc + item.quantity);

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    child: Text(
                      buyerInitial,
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buyerName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      if ((order.customerEmail ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.email_rounded,
                              size: 12,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                order.customerEmail!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if ((order.customerPhone ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 12,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.customerPhone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        '${l10n.order} #${order.id}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _statusColor(order.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _statusLabel(order.status, l10n),
                    style: TextStyle(
                      color: _statusColor(order.status),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey[800]!.withOpacity(0.3)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_cart_rounded,
                        size: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$productCount ${productCount == 1 ? l10n.item : l10n.items}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._buildItemRows(order, isDark),
                ],
              ),
            ),
            if ((order.shippingAddress ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.local_shipping_rounded,
                      size: 16,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.shippingAddress!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Helpers.formatDateTime(order.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Text(
                  Helpers.formatCurrency(order.totalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Actions(
              status: order.status,
              isUpdating: isUpdating,
              onStatusChange: onStatusChange,
              isDark: isDark,
              l10n: l10n,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemRows(OrderModel order, bool isDark) {
    if (order.items.isEmpty) {
      return [
        Text(
          l10n.noItemsAttachedToOrder,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        )
      ];
    }

    final visibleItems = order.items.take(3).toList();
    final remaining = order.items.length - visibleItems.length;

    final widgets = <Widget>[];
    for (final item in visibleItems) {
      final title = item.product.title.isNotEmpty ? item.product.title : l10n.product;
      final attributes = item.selectedAttributes ?? {};
      final extras = attributes.entries.isNotEmpty
          ? ' (${attributes.entries.map((e) => '${e.key}: ${e.value}').join(', ')})'
          : '';

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 8, top: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  '$title x${item.quantity}$extras',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                Helpers.formatCurrency(item.totalPrice),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (remaining > 0) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '• +$remaining ${remaining == 1 ? l10n.moreItem : l10n.moreItems}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.status,
    required this.isUpdating,
    required this.onStatusChange,
    required this.isDark,
    required this.l10n,
  });

  final OrderStatus status;
  final bool isUpdating;
  final ValueChanged<OrderStatus> onStatusChange;
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final buttons = _buildButtons();
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    if (buttons.length == 1) {
      return buttons.first;
    }

    return Row(
      children: [
        Expanded(child: buttons[0]),
        const SizedBox(width: 12),
        Expanded(child: buttons[1]),
      ],
    );
  }

  List<Widget> _buildButtons() {
    if (status == OrderStatus.pending) {
      return [
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: isUpdating ? null : () => onStatusChange(OrderStatus.confirmed),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(
              l10n.accept,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: isUpdating ? null : () => onStatusChange(OrderStatus.cancelled),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: Text(
              l10n.reject,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ];
    }

    if (status == OrderStatus.confirmed || status == OrderStatus.processing) {
      return [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: isUpdating ? null : () => onStatusChange(OrderStatus.shipped),
            icon: const Icon(Icons.local_shipping_rounded, size: 18),
            label: Text(
              l10n.markAsShipped,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ];
    }

    if (status == OrderStatus.shipped) {
      return [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 18,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.awaitingDeliveryConfirmation,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return const [];
  }
}

String _statusLabel(OrderStatus status, AppLocalizations l10n) {
  switch (status) {
    case OrderStatus.pending:
      return l10n.pending;
    case OrderStatus.confirmed:
      return l10n.confirmed;
    case OrderStatus.processing:
      return l10n.processing;
    case OrderStatus.shipped:
      return l10n.shipped;
    case OrderStatus.delivered:
      return l10n.delivered;
    case OrderStatus.cancelled:
      return l10n.cancelled;
  }
}

Color _statusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Colors.orange;
    case OrderStatus.confirmed:
      return Colors.blue;
    case OrderStatus.processing:
      return Colors.indigo;
    case OrderStatus.shipped:
      return Colors.purple;
    case OrderStatus.delivered:
      return Colors.green;
    case OrderStatus.cancelled:
      return Colors.red;
  }
}




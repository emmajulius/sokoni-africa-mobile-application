import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/cart_item_model.dart';
import '../../models/wallet_model.dart';
import '../../utils/helpers.dart';
import '../../services/auth_service.dart';
import '../../services/wallet_service.dart';
import '../../services/auth_api_service.dart';
import '../../services/order_service.dart';
import '../../services/location_service.dart';
import '../payment/payment_screen.dart';
import '../profile/addresses_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.total,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _selectedShippingAddress;
  WalletModel? _wallet;
  bool _isLoadingWallet = true;
  final WalletService _walletService = WalletService();
  final AuthService _authService = AuthService();
  String? _cachedAddress;
  String? _currentAddress;
  bool _isLoadingAddress = false;
  
  final OrderService _orderService = OrderService();
  final AuthApiService _authApiService = AuthApiService();

  // Fees & state
  static const double _processingFeeRate = 0.02; // 2%
  bool _includeShipping = false;
  bool _isFetchingShipping = false;
  double _shippingFeeSok = 0.0;
  double? _shippingDistanceKm;
  String? _shippingError;
  
  String get _currentUserId => _authService.userId ?? 'guest';

  String get _locationAddressStorageKey => 'location_address_$_currentUserId';

  Set<String> get _sellerIds =>
      widget.cartItems.map((item) => item.product.sellerId).toSet();

  bool get _supportsShipping => _sellerIds.length == 1;

  int? get _primarySellerId {
    if (!_supportsShipping) return null;
    final sellerIdStr = widget.cartItems.first.product.sellerId;
    return int.tryParse(sellerIdStr);
  }
  
  @override
  void initState() {
    super.initState();
    _loadWallet();
    _loadAddress();
  }
  
  Future<void> _loadAddress() async {
    if (mounted) {
      setState(() {
        _isLoadingAddress = true;
      });
    }
    
    // Try to get address with refresh flag
    // This will fetch from API, but won't clear SharedPreferences cache until API returns
    final address = await _getUserAddress(refresh: true);
    
    if (mounted) {
      setState(() {
        _currentAddress = address;
        _isLoadingAddress = false;
        // Auto-select if valid address
        if (address != null && 
            address.isNotEmpty && 
            address != 'No address set' &&
            address != 'Please login to set shipping address' &&
            address != 'Error loading address' &&
            address != 'No address set. Please update your profile.') {
          // Always update selected address if we have a valid one
          _selectedShippingAddress = address;
        } else {
          // Don't clear selected address if we already had one and API call failed
          // This prevents clearing a valid address due to temporary API issues
          if (_selectedShippingAddress == null || 
              _selectedShippingAddress == 'No address set' ||
              _selectedShippingAddress == 'Please login to set shipping address' ||
              _selectedShippingAddress == 'Error loading address' ||
              _selectedShippingAddress == 'No address set. Please update your profile.') {
            _selectedShippingAddress = null;
          }
        }
      });
    }
  }
  
  Future<void> _loadWallet() async {
    try {
      await _authService.initialize();
      final wallet = await _walletService.getWalletBalance();
      if (mounted) {
        setState(() {
          _wallet = wallet;
          _isLoadingWallet = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
        });
      }
    }
  }

  Future<void> _fetchShippingEstimate() async {
    final sellerId = _primarySellerId;
    if (sellerId == null) {
      setState(() {
        _shippingError = 'Shipping is available only when ordering from a single seller.';
        _isFetchingShipping = false;
        _includeShipping = false;
        _shippingFeeSok = 0.0;
        _shippingDistanceKm = null;
      });
      return;
    }

    setState(() {
      _isFetchingShipping = true;
      _shippingError = null;
      _shippingDistanceKm = null;
    });

    // Show message that we're getting current location
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Getting your current location for shipping calculation...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Automatically get current location and ensure coordinates are saved
    final ensured = await _ensureBuyerCoordinates();
    if (!ensured) {
      setState(() {
        _includeShipping = false;
        _isFetchingShipping = false;
      });
      return;
    }

    // Show message that shipping is based on current location
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shipping value based on your current location'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    }

    try {
      final result = await _orderService.getShippingEstimate(sellerId);
      final fee = result['shipping_fee_sok'];
      final distance = result['distance_km'];

      setState(() {
        _shippingFeeSok = fee is num ? fee.toDouble() : 0.0;
        _shippingDistanceKm = distance is num ? distance.toDouble() : null;
        _includeShipping = true;
        _shippingError = null;
        _isFetchingShipping = false;
      });
    } catch (e) {
      setState(() {
        _shippingError = e.toString().replaceFirst('Exception: ', '');
        _includeShipping = false;
        _shippingFeeSok = 0.0;
        _shippingDistanceKm = null;
        _isFetchingShipping = false;
      });
    }
  }
  
  Future<bool> _ensureBuyerCoordinates() async {
    try {
      await _authService.initialize();
      final token = _authService.authToken;
      if (token == null) {
        setState(() {
          _shippingError = 'Please sign in to use delivery.';
        });
        return false;
      }

      // 1. Try to reuse coordinates already stored on the profile (from a previous capture).
      final profile = await _authApiService.getCurrentUserProfile(token);
      final profileLatitude = _parseDouble(profile['latitude']);
      final profileLongitude = _parseDouble(profile['longitude']);
      final profileAddress = profile['location_address']?.toString();

      if (profileLatitude != null && profileLongitude != null) {
        if ((_currentAddress == null || _currentAddress!.isEmpty) &&
            profileAddress != null &&
            profileAddress.trim().isNotEmpty) {
          setState(() {
            _currentAddress = profileAddress.trim();
            _selectedShippingAddress ??= _currentAddress;
          });
        }
        return true;
      }

      // 2. Fresh capture required – request current position.
      final position = await LocationService().getCurrentLocation();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Turn on location services and allow access to calculate delivery distance.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  LocationService().requestPermission();
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() {
          _shippingError = 'Enable location and permission, then try again.';
        });
        return false;
      }

      String? addressString = _currentAddress ?? _selectedShippingAddress;
      if (addressString == null || addressString.isEmpty) {
        addressString = await LocationService()
            .getAddressFromCoordinates(position.latitude, position.longitude);
      }

      await _authApiService.updateUserProfile(
        token: token,
        locationAddress: addressString,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        if (addressString != null && addressString.trim().isNotEmpty) {
          _currentAddress = addressString.trim();
          _selectedShippingAddress ??= _currentAddress;
        }
      });

      return true;
    } catch (e) {
      setState(() {
        _shippingError = e.toString().replaceFirst('Exception: ', '');
      });
      return false;
    }
  }
  
  double get _subtotalSokocoin {
    return widget.cartItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
  }
  
  double get _shippingSokocoin => _includeShipping ? _shippingFeeSok : 0.0;

  double get _processingFeeSokocoin {
    return _subtotalSokocoin * _processingFeeRate;
  }
  
  double get _totalSokocoin {
    return _subtotalSokocoin + _shippingSokocoin + _processingFeeSokocoin;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSufficientBalance = _wallet != null && _wallet!.sokocoinBalance >= _totalSokocoin;
    
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
                    Icons.shopping_bag_rounded,
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
                        'Checkout & Order',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Review and complete your order',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet Balance Card
                  if (_isLoadingWallet)
                    Card(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_wallet != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: hasSufficientBalance
                            ? LinearGradient(
                                colors: [Colors.green[50]!, Colors.green[100]!],
                              )
                            : LinearGradient(
                                colors: [Colors.red[50]!, Colors.red[100]!],
                              ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasSufficientBalance
                              ? Colors.green[300]!
                              : Colors.red[300]!,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (hasSufficientBalance ? Colors.green : Colors.red)
                                .withOpacity(0.1),
                            blurRadius: 8,
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: hasSufficientBalance
                                      ? Colors.green[200]
                                      : Colors.red[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  hasSufficientBalance
                                      ? Icons.account_balance_wallet
                                      : Icons.warning,
                                  color: hasSufficientBalance
                                      ? Colors.green[900]
                                      : Colors.red[900],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sokocoin Balance',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: hasSufficientBalance
                                            ? Colors.green[900]
                                            : Colors.red[900],
                                      ),
                                    ),
                                    Text(
                                      '${_wallet!.sokocoinBalance.toStringAsFixed(2)} SOK',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: hasSufficientBalance
                                            ? Colors.green[900]
                                            : Colors.red[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Required for this order:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: hasSufficientBalance
                                        ? Colors.green[900]
                                        : Colors.red[900],
                                  ),
                                ),
                                Text(
                                  '${_totalSokocoin.toStringAsFixed(2)} SOK',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: hasSufficientBalance
                                        ? Colors.green[900]
                                        : Colors.red[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!hasSufficientBalance) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Insufficient balance. Top up ${(_totalSokocoin - _wallet!.sokocoinBalance).toStringAsFixed(2)} SOK',
                                      style: TextStyle(
                                        color: Colors.orange[900],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Info Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blue[900] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDark ? Colors.blue[300] : Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Review your order and complete your purchase using Sokocoin. All transactions are processed in real-time.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.blue[200] : Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Shipping Address Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: isDark ? Colors.blue[300] : Colors.blue[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Shipping Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.refresh,
                            size: 18,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                          tooltip: 'Refresh address',
                          onPressed: () async {
                            await _loadAddress();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isLoadingAddress
                      ? Card(
                          color: isDark ? Colors.grey[900] : Colors.white,
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      : _currentAddress == null || 
                        _currentAddress!.isEmpty || 
                        _currentAddress == 'No address set' ||
                        _currentAddress == 'Please login to set shipping address' ||
                        _currentAddress == 'Error loading address' ||
                        _currentAddress == 'No address set. Please update your profile.'
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.orange[900] : Colors.orange[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.warning,
                                      color: Colors.orange[900],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'No Shipping Address',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isDark ? Colors.orange[200] : Colors.orange[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _currentAddress ?? 'No address set. Please update your profile in settings.',
                                style: TextStyle(
                                  color: isDark ? Colors.orange[200] : Colors.orange[900],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AddressesScreen(),
                                      ),
                                    );
                                    if (mounted) {
                                      final prefs = await SharedPreferences.getInstance();
                                      final cachedAddress = prefs.getString(_locationAddressStorageKey);
                                      if (cachedAddress != null && cachedAddress.isNotEmpty &&
                                          cachedAddress != 'No address set. Please update your profile.' &&
                                          cachedAddress != 'Please login to set shipping address' &&
                                          cachedAddress != 'Error loading address') {
                                        setState(() {
                                          _cachedAddress = cachedAddress;
                                          _currentAddress = cachedAddress;
                                          _selectedShippingAddress = cachedAddress;
                                        });
                                      }
                                      await _loadAddress();
                                    }
                                  },
                                  icon: const Icon(Icons.location_on),
                                  label: const Text('Go to Addresses'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildAddressCard(
                              'Delivery Address',
                              _currentAddress!,
                              _currentAddress!,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddressesScreen(),
                                    ),
                                  );
                                  if (mounted) {
                                    final prefs = await SharedPreferences.getInstance();
                                    final cachedAddress = prefs.getString(_locationAddressStorageKey);
                                    if (cachedAddress != null && cachedAddress.isNotEmpty &&
                                        cachedAddress != 'No address set. Please update your profile.' &&
                                        cachedAddress != 'Please login to set shipping address' &&
                                        cachedAddress != 'Error loading address') {
                                      setState(() {
                                        _cachedAddress = cachedAddress;
                                        _currentAddress = cachedAddress;
                                        _selectedShippingAddress = cachedAddress;
                                      });
                                    }
                                    await _loadAddress();
                                  }
                                },
                                icon: const Icon(Icons.edit_location_alt, size: 18),
                                label: const Text('Change Address'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 24),
                  // Delivery Option
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.local_shipping,
                          color: isDark ? Colors.blue[300] : Colors.blue[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery Option',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile.adaptive(
                            value: _includeShipping,
                            onChanged: (!_supportsShipping || _isFetchingShipping)
                                ? null
                                : (value) {
                                    if (value) {
                                      setState(() {
                                        _includeShipping = true;
                                        _shippingError = null;
                                        _shippingDistanceKm = null;
                                        _shippingFeeSok = 0.0;
                                      });
                                      _fetchShippingEstimate();
                                    } else {
                                      setState(() {
                                        _includeShipping = false;
                                        _shippingFeeSok = 0.0;
                                        _shippingDistanceKm = null;
                                        _shippingError = null;
                                      });
                                    }
                                  },
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.blue[900] : Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.local_shipping,
                                color: isDark ? Colors.blue[300] : Colors.blue[600],
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Sokoni Africa Logistics',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                            ),
                            subtitle: Text(
                              _supportsShipping
                                  ? 'Doorstep delivery handled by Sokoni Africa.'
                                  : 'Available only when your cart contains items from a single seller.',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ),
                          if (_isFetchingShipping)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: LinearProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                              ),
                            ),
                          if (_shippingError != null && !_isFetchingShipping)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _shippingError!,
                                        style: TextStyle(
                                          color: Colors.red[900],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_includeShipping && !_isFetchingShipping && _shippingError == null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.green[900] : Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green[700],
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Estimated fee: ${Helpers.formatCurrency(_shippingFeeSok)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: isDark ? Colors.green[200] : Colors.green[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_shippingDistanceKm != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Distance: ${_shippingDistanceKm!.toStringAsFixed(2)} km',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.green[300] : Colors.green[700],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      'Fee is deducted in Sokocoin and handled by Sokoni Africa logistics.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.green[300] : Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Order Summary
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: isDark ? Colors.blue[300] : Colors.blue[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Cart Items Summary
                          ...widget.cartItems.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.product.title} x${item.quantity}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                                    ),
                                  ),
                                ),
                                Text(
                                  Helpers.formatCurrency(item.totalPrice),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.grey[900],
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const Divider(height: 24),
                          _buildSummaryRow('Subtotal', Helpers.formatCurrency(_subtotalSokocoin), isDark: isDark),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Shipping',
                            _includeShipping
                                ? Helpers.formatCurrency(_shippingSokocoin)
                                : 'Not included',
                            isDark: isDark,
                            color: _includeShipping ? null : (isDark ? Colors.grey[500] : Colors.grey[500]),
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Processing Fee (2%)',
                            Helpers.formatCurrency(_processingFeeSokocoin),
                            isDark: isDark,
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total (Sokocoin)',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.grey[900],
                                ),
                              ),
                              Text(
                                Helpers.formatCurrency(_totalSokocoin),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: hasSufficientBalance
                                      ? (isDark ? Colors.green[300] : Colors.green[600])
                                      : (isDark ? Colors.red[300] : Colors.red[600]),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Bottom Button
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
              child: SizedBox(
                width: double.infinity,
                child: (_wallet != null && hasSufficientBalance && _selectedShippingAddress != null)
                    ? Container(
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
                                builder: (context) => PaymentScreen(
                                  totalSokocoin: _totalSokocoin,
                                  cartItems: widget.cartItems,
                                  shippingAddress: _selectedShippingAddress!,
                                  shippingFeeSok: _shippingSokocoin,
                                  processingFeeSok: _processingFeeSokocoin,
                                  includeShipping: _includeShipping,
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
                            'Place Order (${_totalSokocoin.toStringAsFixed(2)} SOK)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            !hasSufficientBalance
                                ? 'Insufficient Balance'
                                : _selectedShippingAddress == null
                                    ? 'Select Shipping Address'
                                    : 'Place Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
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

  Future<String?> _getUserAddress({bool refresh = false}) async {
    try {
      // If refreshing, check SharedPreferences first (addresses screen saves there immediately)
      if (refresh) {
        final prefs = await SharedPreferences.getInstance();
        final cachedAddress = prefs.getString(_locationAddressStorageKey);
        if (cachedAddress != null && cachedAddress.isNotEmpty &&
            cachedAddress != 'No address set. Please update your profile.' &&
            cachedAddress != 'Please login to set shipping address' &&
            cachedAddress != 'Error loading address') {
          // Update in-memory cache
          _cachedAddress = cachedAddress;
          print('Found address in SharedPreferences: $cachedAddress');
          // Don't return yet - still try to fetch from API to sync
        }
        // Clear in-memory cache to force API fetch
        // But keep SharedPreferences cache as fallback
      }
      
      // Use cached address if available and not refreshing
      if (!refresh && _cachedAddress != null && _cachedAddress!.isNotEmpty) {
        // Still validate it's not an error message
        if (_cachedAddress != 'No address set. Please update your profile.' &&
            _cachedAddress != 'Please login to set shipping address' &&
            _cachedAddress != 'Error loading address') {
          return _cachedAddress;
        }
      }
      
      await _authService.initialize();
      final token = _authService.authToken;
      
      if (token == null) {
        // If no token, check SharedPreferences as fallback
        final prefs = await SharedPreferences.getInstance();
        final cachedAddress = prefs.getString(_locationAddressStorageKey);
        if (cachedAddress != null && cachedAddress.isNotEmpty &&
            cachedAddress != 'No address set. Please update your profile.' &&
            cachedAddress != 'Please login to set shipping address' &&
            cachedAddress != 'Error loading address') {
          _cachedAddress = cachedAddress;
          return cachedAddress;
        }
        return 'Please login to set shipping address';
      }
      
      // Always fetch fresh from API to ensure we have the latest address
      try {
        print('Fetching address from API (refresh: $refresh)...');
        final authApiService = AuthApiService();
        final profileData = await authApiService.getCurrentUserProfile(token);
        print('Profile data received: ${profileData.keys}');
        
        // Try different possible field names
        String? locationAddress = profileData['location_address'] as String?;
        if (locationAddress == null || locationAddress.isEmpty) {
          // Try alternative field name
          locationAddress = profileData['locationAddress'] as String?;
        }
        
        print('Location address from API: $locationAddress');
        
        if (locationAddress != null && locationAddress.isNotEmpty && locationAddress.trim().isNotEmpty) {
          // Store in preferences for caching
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_locationAddressStorageKey, locationAddress);
          _cachedAddress = locationAddress;
          print('Address cached successfully: $locationAddress');
          return locationAddress;
        } else {
          print('Location address is null or empty from API');
          // Check SharedPreferences - it might have been updated by addresses screen
          final prefs = await SharedPreferences.getInstance();
          final cachedAddress = prefs.getString(_locationAddressStorageKey);
          if (cachedAddress != null && cachedAddress.isNotEmpty &&
              cachedAddress != 'No address set. Please update your profile.' &&
              cachedAddress != 'Please login to set shipping address' &&
              cachedAddress != 'Error loading address') {
            print('Using address from SharedPreferences: $cachedAddress');
            _cachedAddress = cachedAddress;
            return cachedAddress;
          }
          // Clear cache if address was removed from both API and cache
          _cachedAddress = null;
        }
      } catch (e) {
        print('Error fetching address from API: $e');
        // Fallback to SharedPreferences cache if API fails
        final prefs = await SharedPreferences.getInstance();
        final cachedAddress = prefs.getString(_locationAddressStorageKey);
        if (cachedAddress != null && cachedAddress.isNotEmpty) {
          // Validate it's not an error message
          if (cachedAddress != 'No address set. Please update your profile.' &&
              cachedAddress != 'Please login to set shipping address' &&
              cachedAddress != 'Error loading address') {
            print('Using cached address after API error: $cachedAddress');
            _cachedAddress = cachedAddress;
            return cachedAddress;
          }
        }
      }
      
      // Final fallback - check SharedPreferences one more time
      final prefs = await SharedPreferences.getInstance();
      final cachedAddress = prefs.getString(_locationAddressStorageKey);
      if (cachedAddress != null && cachedAddress.isNotEmpty &&
          cachedAddress != 'No address set. Please update your profile.' &&
          cachedAddress != 'Please login to set shipping address' &&
          cachedAddress != 'Error loading address') {
        _cachedAddress = cachedAddress;
        return cachedAddress;
      }
      
      return 'No address set. Please update your profile.';
    } catch (e) {
      print('Error in _getUserAddress: $e');
      // Try to get cached address as last resort
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedAddress = prefs.getString(_locationAddressStorageKey);
        if (cachedAddress != null && cachedAddress.isNotEmpty) {
          // Validate it's not an error message
          if (cachedAddress != 'No address set. Please update your profile.' &&
              cachedAddress != 'Please login to set shipping address' &&
              cachedAddress != 'Error loading address') {
            _cachedAddress = cachedAddress;
            return cachedAddress;
          }
        }
      } catch (_) {}
      return 'Error loading address';
    }
  }

  Widget _buildAddressCard(String title, String address, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedShippingAddress == value;
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: isDark
                    ? [Colors.blue[900]!, Colors.blue[800]!]
                    : [Colors.blue[50]!, Colors.blue[100]!],
              )
            : null,
        color: isSelected ? null : (isDark ? Colors.grey[900] : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? Colors.blue[400]!
              : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.blue.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedShippingAddress = value;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue[200]
                      : (isDark ? Colors.grey[800] : Colors.grey[200]),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Colors.blue[900]
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  size: 20,
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
                        fontSize: 15,
                        color: isSelected
                            ? (isDark ? Colors.blue[200] : Colors.blue[900])
                            : (isDark ? Colors.white : Colors.grey[900]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? (isDark ? Colors.blue[300] : Colors.blue[700])
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


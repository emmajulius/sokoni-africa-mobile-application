import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/auth_api_service.dart';
import '../../services/language_service.dart';
import '../../services/location_service.dart';
import '../../utils/phone_validation_utils.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();
  final List<AddressModel> _addresses = [];
  bool _isLoading = false;
  bool _isSeller = false;
  bool _hasPickupLocation = false;

  String get _currentUserId => _authService.userId ?? 'guest';

  String get _addressStorageKey => 'address_data_$_currentUserId';

  String get _locationAddressStorageKey => 'location_address_$_currentUserId';

  @override
  void initState() {
    super.initState();
    _checkGuestAccess();
  }

  Future<void> _checkGuestAccess() async {
    await _authService.initialize();
    if (_authService.isGuest) {
      // Guest users cannot access addresses
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address management is only available for registered users. Please sign in to continue.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
      return;
    }
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    _addresses.clear();

    try {
      await _authService.initialize();

      // Load any locally cached address first (for speed / offline)
      final stored = await _loadAddressFromStorage();
      if (stored != null) {
        _addresses.add(stored);
      }

      // Refresh from backend when authenticated
      final token = _authService.authToken;
      if (token != null) {
        final authApiService = AuthApiService();
        final profile = await authApiService.getCurrentUserProfile(token);

        final userType = profile['user_type']?.toString().toLowerCase();
        final isSeller = userType == 'supplier' || userType == 'retailer';
        
        final locationAddress = profile['location_address']?.toString() ?? '';
        final latitude = _toDouble(profile['latitude']);
        final longitude = _toDouble(profile['longitude']);
        final fullName = profile['full_name']?.toString() ?? _authService.fullName ?? '';
        final phone = profile['phone']?.toString() ?? _authService.phone ?? '';

        if (mounted) {
          setState(() {
            _isSeller = isSeller;
            _hasPickupLocation = latitude != null && longitude != null;
          });
        }

        if (locationAddress.trim().isNotEmpty) {
          final parsedAddress = _parseLocationAddress(
            locationAddress,
            fullName: fullName,
            phone: phone,
            latitude: latitude,
            longitude: longitude,
          );

          _addresses
            ..clear()
            ..add(parsedAddress);

          await _saveAddressToStorage(parsedAddress);
        } else if (_addresses.isNotEmpty) {
          // Backend empty but we have a cached address – push it upstream
          final defaultAddress = _addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => _addresses.first,
          );
          await _saveDefaultAddressToProfile(defaultAddress);
        }
      }
    } catch (e) {
      print('Error loading addresses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load addresses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddAddressDialog(
        defaultFullName: _authService.fullName ?? '',
        defaultPhone: _authService.phone ?? '',
        onSave: (address) async {
          setState(() {
            // If this is set as default, unset other defaults
            if (address.isDefault) {
              for (var addr in _addresses) {
                addr.isDefault = false;
              }
            }
            _addresses.add(address);
          });
          // If this is the default address, save it to user profile
          if (address.isDefault) {
            await _saveDefaultAddressToProfile(address);
          } else {
            await _saveAddressToStorage(address);
          }
        },
      ),
    );
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
        title: Text(l10n.myAddresses),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Scaffold(
              backgroundColor: isDark 
                  ? const Color(0xFF121212)
                  : const Color(0xFFF5F7FA),
              body: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            )
          : CustomScrollView(
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
                            Icons.location_on_rounded,
                            size: 32,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.myAddresses,
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
                          'Manage your delivery addresses',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark 
                                ? Colors.grey[400] 
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Seller Pickup Location Banner
                if (_isSeller)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _buildSellerPickupLocationBanner(),
                    ),
                  ),
                // Addresses List or Empty State
                _addresses.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(20.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final address = _addresses[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildAddressCard(address),
                              );
                            },
                            childCount: _addresses.length,
                          ),
                        ),
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAddressDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Address'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSellerPickupLocationBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerColor = _hasPickupLocation ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  bannerColor.withOpacity(0.2),
                  bannerColor.withOpacity(0.1),
                ]
              : [
                  bannerColor.withOpacity(0.15),
                  bannerColor.withOpacity(0.08),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bannerColor.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _hasPickupLocation 
                  ? Icons.check_circle_rounded 
                  : Icons.warning_rounded,
              color: bannerColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasPickupLocation
                      ? 'Pickup Location Set'
                      : 'Pickup Location Required',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark 
                        ? Colors.white 
                        : (bannerColor == const Color(0xFF4CAF50) 
                            ? Colors.green[900] 
                            : Colors.orange[900]),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _hasPickupLocation
                      ? 'Your business location is set. Buyers can use Sokoni Africa Logistics for shipping.'
                      : 'Set your default address to enable shipping. Location will be captured automatically when you save.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark 
                        ? Colors.grey[300] 
                        : (bannerColor == const Color(0xFF4CAF50) 
                            ? Colors.green[800] 
                            : Colors.orange[800]),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? Colors.grey[850] : Colors.grey[100])!.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 64,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No addresses saved',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first address to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: address.isDefault
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF4CAF50).withOpacity(0.2),
                        const Color(0xFF4CAF50).withOpacity(0.1),
                      ]
                    : [
                        const Color(0xFF4CAF50).withOpacity(0.1),
                        Colors.white,
                      ],
              )
            : null,
        color: address.isDefault 
            ? null 
            : (isDark 
                ? Colors.grey[850]!.withOpacity(0.5)
                : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault
              ? const Color(0xFF4CAF50).withOpacity(0.4)
              : (isDark 
                  ? Colors.grey[800]!
                  : Colors.grey[200]!),
          width: address.isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: address.isDefault
                ? const Color(0xFF4CAF50).withOpacity(0.2)
                : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: address.isDefault ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _showEditAddressDialog(address);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: address.isDefault 
                          ? const Color(0xFF4CAF50).withOpacity(0.2)
                          : (isDark 
                              ? Colors.grey[800]!.withOpacity(0.5)
                              : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      address.isDefault 
                          ? Icons.home_rounded 
                          : Icons.location_on_rounded,
                      color: address.isDefault 
                          ? const Color(0xFF4CAF50)
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              address.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                            ),
                            if (address.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              address.fullName,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 14,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              address.phone,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Edit button
                  IconButton(
                    icon: Icon(
                      Icons.edit_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    tooltip: 'Edit address',
                    onPressed: () {
                      _showEditAddressDialog(address);
                    },
                  ),
                  // Menu button for additional options
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      if (!address.isDefault)
                        PopupMenuItem(
                          value: 'set_default',
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFF9800),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Set as Default'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5722).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Color(0xFFFF5722),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Delete',
                              style: TextStyle(color: Color(0xFFFF5722)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'set_default') {
                        setState(() {
                          for (var addr in _addresses) {
                            addr.isDefault = addr.id == address.id;
                          }
                        });
                        await _saveDefaultAddressToProfile(address);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(address);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: isDark 
                    ? Colors.grey[800]!
                    : Colors.grey[200]!,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[200] : Colors.grey[800],
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${address.city}, ${address.region}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        if (address.postalCode.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Postal Code: ${address.postalCode}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAddressDialog(AddressModel address) {
    final wasDefault = address.isDefault;
    showDialog(
      context: context,
      builder: (context) => _AddAddressDialog(
        address: address,
        onSave: (updatedAddress) async {
          // Show loading indicator
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text('Saving address...'),
                  ],
                ),
                duration: Duration(seconds: 2),
              ),
            );
          }

          setState(() {
            // If this is set as default, unset other defaults
            if (updatedAddress.isDefault) {
              for (var addr in _addresses) {
                if (addr.id != address.id) {
                  addr.isDefault = false;
                }
              }
            }
            final index = _addresses.indexWhere((a) => a.id == address.id);
            if (index != -1) {
              _addresses[index] = updatedAddress;
            }
          });
          
          try {
            // Save logic:
            // 1. If address is now default, always save it
            // 2. If address was default before, save it (even if user didn't explicitly check the box)
            // 3. If address was default but user unchecked it, find new default or clear
            
            bool shouldSave = false;
            
            if (updatedAddress.isDefault) {
              // Address is marked as default - save it
              shouldSave = true;
            } else if (wasDefault) {
              // Address was default before editing
              // If user unchecked it, we need to handle that
              // But if they just edited details without changing the checkbox, keep it as default
              // For now, if it was default, we'll keep it as default unless explicitly unchecked
              updatedAddress.isDefault = true; // Keep it as default
              shouldSave = true;
            }

            await _saveAddressToStorage(updatedAddress);
            
            if (shouldSave) {
              await _saveDefaultAddressToProfile(updatedAddress);
            } else if (wasDefault && !updatedAddress.isDefault) {
              // User explicitly unchecked default - find new default or clear
              final otherDefaults = _addresses.where((a) => a.isDefault && a.id != updatedAddress.id).toList();
              if (otherDefaults.isNotEmpty) {
                await _saveDefaultAddressToProfile(otherDefaults.first);
              } else {
                // No other default found - clear from profile
                await _clearAddressFromProfile();
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving address: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(AddressModel address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final wasDefault = address.isDefault;
              setState(() {
                _addresses.removeWhere((a) => a.id == address.id);
              });
              Navigator.pop(context);
              
              // If deleted address was default, update profile with new default or clear
              if (wasDefault) {
                if (_addresses.isNotEmpty) {
                  // Find the first default address, or use the first address as default
                  final newDefault = _addresses.firstWhere(
                    (a) => a.isDefault,
                    orElse: () {
                      // If no default found, make the first one default
                      _addresses.first.isDefault = true;
                      return _addresses.first;
                    },
                  );
                  await _saveDefaultAddressToProfile(newDefault);
                } else {
                  // Clear address from profile if no addresses left
                  await _clearAddressFromProfile();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Format address as a complete string for storage
  String _formatAddressString(AddressModel address) {
    final parts = <String>[];
    
    // Add full name and phone if available
    if (address.fullName.isNotEmpty) {
      parts.add(address.fullName);
    }
    if (address.phone.isNotEmpty) {
      parts.add('Phone: ${address.phone}');
    }
    
    // Add address components
    if (address.address.isNotEmpty) {
      parts.add(address.address);
    }
    if (address.city.isNotEmpty) {
      parts.add(address.city);
    }
    if (address.region.isNotEmpty) {
      parts.add(address.region);
    }
    if (address.postalCode.isNotEmpty) {
      parts.add(address.postalCode);
    }
    
    return parts.join(', ');
  }

  /// Save default address to user profile (location_address field)
  Future<void> _saveDefaultAddressToProfile(AddressModel address) async {
    try {
      await _authService.initialize();
      final token = _authService.authToken;
      
      if (token == null) {
        print('No auth token available to save address');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to save address'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final authApiService = AuthApiService();
      
      // Check if user is a seller (supplier or retailer) and if coordinates are missing
      double? latitude = address.latitude;
      double? longitude = address.longitude;
      final profile = await authApiService.getCurrentUserProfile(token);
      final userType = profile['user_type']?.toString().toLowerCase();
      final isSeller = userType == 'supplier' || userType == 'retailer';
      
      // If seller and coordinates are missing, automatically get current location
      if (isSeller && (latitude == null || longitude == null)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Getting your location for shipping pickup point...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        try {
          final locationService = LocationService();
          final position = await locationService.getCurrentLocation();
          
          if (position != null) {
            latitude = position.latitude;
            longitude = position.longitude;
            
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location captured for shipping pickup point'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not get location. Please enable location services and try again. Shipping will not be available until location is set.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
        } catch (e) {
          print('Error getting location for seller: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not get location: $e. Shipping will not be available until location is set.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }

      // Format the address as a complete string
      final addressString = _formatAddressString(address);
      
      print('Saving address to profile: $addressString');
      
      // Save to backend with coordinates (if available)
      final result = await authApiService.updateUserProfile(
        token: token,
        locationAddress: addressString,
        latitude: latitude,
        longitude: longitude,
      );

      print('Address saved successfully: $result');

      // Also save to SharedPreferences for quick access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_locationAddressStorageKey, addressString);
      
      // Update address model with coordinates before saving to storage
      final updatedAddress = AddressModel(
        id: address.id,
        title: address.title,
        fullName: address.fullName,
        phone: address.phone,
        address: address.address,
        city: address.city,
        region: address.region,
        postalCode: address.postalCode,
        isDefault: address.isDefault,
        latitude: latitude,
        longitude: longitude,
        rawAddress: address.rawAddress,
      );
      await _saveAddressToStorage(updatedAddress);
      
      // Update state to reflect pickup location status
      if (mounted) {
        setState(() {
          _hasPickupLocation = latitude != null && longitude != null;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSeller && latitude != null && longitude != null
                        ? 'Address and pickup location saved! Buyers can now use shipping.'
                        : 'Address saved successfully! It will appear in checkout.',
                    softWrap: true,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error saving address to profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to save address: ${e.toString()}',
                    softWrap: true,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      rethrow;
    }
  }

  /// Clear address from user profile
  Future<void> _clearAddressFromProfile() async {
    try {
      await _authService.initialize();
      final token = _authService.authToken;
      
      if (token == null) return;

      final authApiService = AuthApiService();
      await authApiService.updateUserProfile(
        token: token,
        locationAddress: '',
      );

      final prefs = await SharedPreferences.getInstance();
      prefs
        ..remove(_locationAddressStorageKey)
        ..remove(_addressStorageKey);
    } catch (e) {
      print('Error clearing address from profile: $e');
    }
  }

  Future<AddressModel?> _loadAddressFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedJson = prefs.getString(_addressStorageKey);
    if (storedJson == null || storedJson.isEmpty) {
      return null;
    }

    try {
      final data = json.decode(storedJson) as Map<String, dynamic>;
      return AddressModel(
        id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: data['title']?.toString() ?? 'Home',
        fullName: data['fullName']?.toString() ?? _authService.fullName ?? '',
        phone: data['phone']?.toString() ?? _authService.phone ?? '',
        address: data['address']?.toString() ?? '',
        city: data['city']?.toString() ?? '',
        region: data['region']?.toString() ?? '',
        postalCode: data['postalCode']?.toString() ?? '',
        isDefault: data['isDefault'] as bool? ?? true,
        latitude: _toDouble(data['latitude']),
        longitude: _toDouble(data['longitude']),
        rawAddress: data['rawAddress']?.toString(),
      );
    } catch (e) {
      print('Failed to decode stored address: $e');
      return null;
    }
  }

  Future<void> _saveAddressToStorage(AddressModel address) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'id': address.id,
      'title': address.title,
      'fullName': address.fullName,
      'phone': address.phone,
      'address': address.address,
      'city': address.city,
      'region': address.region,
      'postalCode': address.postalCode,
      'isDefault': address.isDefault,
      'latitude': address.latitude,
      'longitude': address.longitude,
      'rawAddress': address.rawAddress ?? _formatAddressString(address),
    };
    await prefs.setString(_addressStorageKey, json.encode(data));
  }

  AddressModel _parseLocationAddress(
    String addressString, {
    String? fullName,
    String? phone,
    double? latitude,
    double? longitude,
  }) {
    final segments = addressString
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    String extractedFullName = fullName ?? _authService.fullName ?? '';
    String extractedPhone = phone ?? _authService.phone ?? '';
    String street = '';
    String city = '';
    String region = '';
    String postalCode = '';

    for (final segment in segments) {
      final lower = segment.toLowerCase();
      if (lower.startsWith('phone:')) {
        extractedPhone = segment.split(':').last.trim();
      } else if (extractedFullName.isEmpty) {
        extractedFullName = segment;
      } else if (street.isEmpty) {
        street = segment;
      } else if (city.isEmpty) {
        city = segment;
      } else if (region.isEmpty) {
        region = segment;
      } else if (postalCode.isEmpty) {
        postalCode = segment;
      }
    }

    return AddressModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Home',
      fullName: extractedFullName,
      phone: extractedPhone,
      address: street,
      city: city,
      region: region,
      postalCode: postalCode,
      isDefault: true,
      latitude: latitude,
      longitude: longitude,
      rawAddress: addressString,
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }
}

class AddressModel {
  final String id;
  final String title;
  final String fullName;
  final String phone;
  final String address;
  final String city;
  final String region;
  final String postalCode;
  bool isDefault;
  final double? latitude;
  final double? longitude;
  final String? rawAddress;

  AddressModel({
    required this.id,
    required this.title,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.city,
    required this.region,
    required this.postalCode,
    this.isDefault = false,
    this.latitude,
    this.longitude,
    this.rawAddress,
  });
}

class _AddAddressDialog extends StatefulWidget {
  final AddressModel? address;
  final Future<void> Function(AddressModel) onSave;
  final String defaultFullName;
  final String defaultPhone;

  const _AddAddressDialog({
    this.address,
    required this.onSave,
    this.defaultFullName = '',
    this.defaultPhone = '',
  });

  @override
  State<_AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<_AddAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _regionController = TextEditingController();
  final _postalCodeController = TextEditingController();
  bool _isDefault = false;
  double? _latitude;
  double? _longitude;
  String? _rawAddress;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      final addr = widget.address!;
      _titleController.text = addr.title;
      _fullNameController.text = addr.fullName;
      _phoneController.text = addr.phone;
      _addressController.text = addr.address;
      _cityController.text = addr.city;
      _regionController.text = addr.region;
      _postalCodeController.text = addr.postalCode;
      _isDefault = addr.isDefault;
      _latitude = addr.latitude;
      _longitude = addr.longitude;
      _rawAddress = addr.rawAddress;
    } else {
      if (widget.defaultFullName.isNotEmpty) {
        _fullNameController.text = widget.defaultFullName;
      }
      if (widget.defaultPhone.isNotEmpty) {
        _phoneController.text = widget.defaultPhone;
      }
      _titleController.text = 'Home';
      _isDefault = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }



  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final address = AddressModel(
        id: widget.address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        region: _regionController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        isDefault: _isDefault,
        latitude: _latitude,
        longitude: _longitude,
        rawAddress: _rawAddress,
      );

      await widget.onSave(address);

      if (mounted && (address.latitude == null || address.longitude == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Address saved. Add location later if you want Sokoni Africa delivery to calculate distance.',
            ),
            backgroundColor: Colors.blueGrey,
            duration: Duration(seconds: 4),
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF4CAF50),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.address == null ? 'Add Address' : 'Edit Address',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Address Title Field Card
                      Container(
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.grey[800]!.withOpacity(0.5)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextFormField(
                          controller: _titleController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Address Title',
                            hintText: 'Home, Work, etc.',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.title_rounded,
                                color: Color(0xFF2196F3),
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter address title';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Full Name Field Card
                      Container(
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.grey[800]!.withOpacity(0.5)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextFormField(
                          controller: _fullNameController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9C27B0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF9C27B0),
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter full name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Phone Field Card
                      Container(
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.grey[800]!.withOpacity(0.5)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.phone_rounded,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (value) {
                            // Use generic validation since addresses might be for different countries
                            // Minimum 7 digits, maximum 15 digits (international format)
                            return PhoneValidationUtils.validatePhoneNumberGeneric(
                              value,
                              minLength: 7,
                              maxLength: 15,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Street Address Field Card
                      Container(
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.grey[800]!.withOpacity(0.5)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: TextFormField(
                          controller: _addressController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Street Address',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            prefixIcon: Container(
                              padding: const EdgeInsets.only(top: 12),
                              margin: const EdgeInsets.only(right: 8),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.home_rounded,
                                  color: Color(0xFFFF9800),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter street address';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // City Field Card
                      Container(
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.grey[800]!.withOpacity(0.5)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextFormField(
                          controller: _cityController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: 'City',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.location_city_rounded,
                                color: Color(0xFF2196F3),
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter city';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Region Field Card
                      Container(
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.grey[800]!.withOpacity(0.5)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextFormField(
                          controller: _regionController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Region/State',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF667EEA).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.map_rounded,
                                color: Color(0xFF667EEA),
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter region';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Postal Code Field Card
                      Container(
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.grey[800]!.withOpacity(0.5)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextFormField(
                          controller: _postalCodeController,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Postal Code',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9C27B0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.markunread_mailbox_rounded,
                                color: Color(0xFF9C27B0),
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter postal code';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Default Address Checkbox Card
                      Container(
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.grey[800]!.withOpacity(0.3)
                              : Colors.blue[50]!.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.grey[700]!
                                : Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            'Set as default address',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                          ),
                          subtitle: Text(
                            'Only the default address will be used in checkout',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          value: _isDefault,
                          activeColor: const Color(0xFF4CAF50),
                          onChanged: (value) {
                            setState(() {
                              _isDefault = value ?? false;
                            });
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey[900]!.withOpacity(0.5)
                    : Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _save(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Save Address',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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
}


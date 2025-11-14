import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';
import '../../services/api_service.dart';
import '../../widgets/story_bar_widget.dart';
import '../../services/story_api_service.dart';
import '../../models/story_model.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/location_service.dart';
import '../stories/create_story_screen.dart';
import '../inventory/create_product_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../services/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  List<ProductModel> _products = [];
  List<ProductModel> _allProducts = []; // Store all products
  List<UserStories> _userStories = [];
  bool _isLoading = true;
  String? _selectedCategory; // null means "All"
  final LanguageService _languageService = LanguageService();
  final LocationService _locationService = LocationService();
  Position? _userLocation;
  bool _isLocationEnabled = false;
  bool _isRequestingLocation = false;
  final NotificationService _notificationService = NotificationService();
  int _unreadNotificationCount = 0;
  Timer? _notificationRefreshTimer;
  Timer? _auctionUpdateTimer; // Timer for updating auction products in real-time
  
  // Available categories - will be localized in build method
  List<Map<String, String?>> _getCategories(AppLocalizations l10n) {
    return [
      {'value': null, 'label': l10n.all},
      {'value': 'electronics', 'label': l10n.electronics},
      {'value': 'fashion', 'label': l10n.fashion},
      {'value': 'food', 'label': l10n.food},
      {'value': 'beauty', 'label': l10n.beauty},
      {'value': 'home_kitchen', 'label': l10n.homeKitchen},
      {'value': 'sports', 'label': l10n.sports},
      {'value': 'automotives', 'label': l10n.automotives},
      {'value': 'books', 'label': l10n.books},
      {'value': 'kids', 'label': l10n.kids},
      {'value': 'agriculture', 'label': l10n.agriculture},
      {'value': 'art_craft', 'label': l10n.artCraft},
      {'value': 'computer_software', 'label': l10n.computerSoftware},
      {'value': 'health_wellness', 'label': l10n.healthWellness},
    ];
  }
  
  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _initializeLocation();
    _loadProducts();
    _loadStories();
    _loadUnreadNotificationCount();
    // Refresh notification count every 10 seconds
    _notificationRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadUnreadNotificationCount();
    });
    
    // Start real-time updates for auction products (every 15 seconds)
    _auctionUpdateTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _updateAuctionProducts();
    });
  }
  
  Future<void> _initializeLocation() async {
    try {
      final permission = await _locationService.checkPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final location = await _locationService.getCurrentLocation();
        if (location != null && mounted) {
          setState(() {
            _userLocation = location;
            _isLocationEnabled = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing location: $e');
    }
  }
  
  Future<void> _requestLocationPermission() async {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    setState(() {
      _isRequestingLocation = true;
    });
    
    try {
      final permission = await _locationService.requestPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final location = await _locationService.getCurrentLocation();
        if (location != null && mounted) {
          setState(() {
            _userLocation = location;
            _isLocationEnabled = true;
            _isRequestingLocation = false;
          });
          // Reload products with location
          _loadProducts();
        } else {
          if (mounted) {
            setState(() {
              _isRequestingLocation = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.unableToGetLocation),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isRequestingLocation = false;
          });
          _showLocationPermissionDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRequestingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorGettingLocation}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showLocationPermissionDialog() {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.locationPermissionRequired),
        content: Text(l10n.locationPermissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    _scrollController.dispose();
    _notificationRefreshTimer?.cancel();
    _auctionUpdateTimer?.cancel();
    super.dispose();
  }
  
  // Update auction products in real-time (lightweight - only updates time remaining locally)
  void _updateAuctionProducts() {
    if (!mounted || _allProducts.isEmpty) return;
    
    // Update time remaining for auction products locally (no API call)
    final now = DateTime.now().toUtc();
    bool hasChanges = false;
    
    final updatedProducts = _allProducts.map((product) {
      if (product.isAuction && product.auctionEndTime != null) {
        try {
          final endTime = product.auctionEndTime!;
          final endTimeUtc = endTime.isUtc ? endTime : endTime.toUtc();
          final remaining = endTimeUtc.difference(now).inSeconds;
          
          // Only update if time remaining changed significantly (more than 1 second)
          final currentTimeRemaining = product.timeRemainingSeconds ?? 0;
          if ((remaining - currentTimeRemaining).abs() > 1) {
            hasChanges = true;
            // Create updated product with new time remaining
            return ProductModel(
              id: product.id,
              title: product.title,
              description: product.description,
              price: product.price,
              category: product.category,
              sellerId: product.sellerId,
              sellerUsername: product.sellerUsername,
              sellerLocation: product.sellerLocation,
              sellerProfileImage: product.sellerProfileImage,
              imageUrl: product.imageUrl,
              images: product.images,
              isAuction: product.isAuction,
              auctionStatus: remaining <= 0 ? 'ended' : product.auctionStatus,
              auctionEndTime: product.auctionEndTime,
              currentBid: product.currentBid,
              startingPrice: product.startingPrice,
              bidIncrement: product.bidIncrement,
              timeRemainingSeconds: max(0, remaining),
              likes: product.likes,
              comments: product.comments,
              rating: product.rating,
              tags: product.tags,
              isSponsored: product.isSponsored,
              isWingaEnabled: product.isWingaEnabled,
              hasWarranty: product.hasWarranty,
              isPrivate: product.isPrivate,
              isAdultContent: product.isAdultContent,
              unitType: product.unitType,
              stockQuantity: product.stockQuantity,
              createdAt: product.createdAt,
              auctionStartTime: product.auctionStartTime,
              auctionDurationMinutes: product.auctionDurationMinutes,
              currentBidderId: product.currentBidderId,
              currentBidderUsername: product.currentBidderUsername,
              bidCount: product.bidCount,
              winnerId: product.winnerId,
              winnerPaid: product.winnerPaid,
            );
          }
        } catch (e) {
          print('Error updating auction time: $e');
        }
      }
      return product;
    }).toList();
    
    if (hasChanges && mounted) {
      setState(() {
        _allProducts = updatedProducts;
        _filterProductsByCategory(_selectedCategory);
      });
    }
  }
  
  Future<void> _loadUnreadNotificationCount() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      if (!authService.isAuthenticated || authService.isGuest) {
        if (mounted) {
          setState(() {
            _unreadNotificationCount = 0;
          });
        }
        return;
      }

      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread notification count: $e');
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  void _filterProductsByCategory(String? category, [AppLocalizations? l10n]) {
    setState(() {
      _selectedCategory = category;
      if (category == null) {
        // Show all products
        _products = List.from(_allProducts);
      } else {
        // Filter by category (case-insensitive)
        _products = _allProducts.where((product) {
          return product.category.toLowerCase() == category.toLowerCase();
        }).toList();
      }
    });
  }

  Future<void> _loadStories() async {
    try {
      final storyApiService = StoryApiService();
      final storiesData = await storyApiService.getStories();
      
      // Group stories by user
      final Map<String, List<StoryModel>> userStoriesMap = {};
      final Map<String, Map<String, dynamic>> userInfoMap = {};
      
      for (var storyData in storiesData) {
        final userId = storyData['user_id']?.toString() ?? '';
        final username = storyData['user']?['username'] ?? storyData['username'] ?? 'Unknown';
        final profileImage = storyData['user']?['profile_image'] ?? storyData['user_profile_image'];
        
        if (!userStoriesMap.containsKey(userId)) {
          userStoriesMap[userId] = [];
          userInfoMap[userId] = {
            'username': username,
            'profile_image': profileImage,
          };
        }
        
        // Parse story data
        final story = StoryModel(
          id: storyData['id']?.toString() ?? '',
          userId: userId,
          username: username,
          userProfileImage: profileImage,
          imageUrl: storyData['media_type'] == 'image' ? storyData['media_url'] : null,
          videoUrl: storyData['media_type'] == 'video' ? storyData['media_url'] : null,
          caption: storyData['caption'],
          createdAt: storyData['created_at'] != null
              ? DateTime.parse(storyData['created_at'])
              : DateTime.now(),
          expiresAt: storyData['expires_at'] != null
              ? DateTime.parse(storyData['expires_at'])
              : DateTime.now().add(const Duration(hours: 24)),
          viewsCount: storyData['views_count'] ?? 0,
        );
        
        userStoriesMap[userId]!.add(story);
      }
      
      // Convert to UserStories list
      final userStoriesList = userStoriesMap.entries.map((entry) {
        final stories = entry.value;
        stories.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final userInfo = userInfoMap[entry.key]!;
        
        return UserStories(
          userId: entry.key,
          username: userInfo['username'] ?? 'Unknown',
          profileImage: userInfo['profile_image'],
          stories: stories,
          hasNewStories: stories.any((s) => s.viewsCount == 0),
        );
      }).toList();
      
      if (mounted) {
        setState(() {
          _userStories = userStoriesList;
        });
      }
    } catch (e) {
      print('Error loading stories: $e');
      // Handle error silently - stories are optional
      if (mounted) {
        setState(() {
          _userStories = [];
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      // Only pass location if location-based sorting is explicitly enabled
      // This makes product loading much faster by default
      final products = await apiService.getProducts(
        // Only use location if explicitly enabled (user toggled it on)
        latitude: _isLocationEnabled ? _userLocation?.latitude : null,
        longitude: _isLocationEnabled ? _userLocation?.longitude : null,
      );
      
      if (mounted) {
        setState(() {
          _allProducts = products;
          _filterProductsByCategory(_selectedCategory, l10n); // Apply current filter
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error - no fallback to mock data
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorLoadingProducts}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        
        // Don't use mock data - show empty state
        setState(() {
          _allProducts = [];
          _filterProductsByCategory(_selectedCategory, l10n);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProducts();
          await _loadStories();
        },
        child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Compact Header with Gradient
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.grey[900]!, Colors.grey[800]!]
                      : [Colors.white, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                  // App Name/Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sokoniAfrica,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.discoverAndShop,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Location button
                  Container(
                    decoration: BoxDecoration(
                      color: _isLocationEnabled
                          ? (isDark ? Colors.green[900] : Colors.green[50])
                          : (isDark ? Colors.grey[800] : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isLocationEnabled
                            ? Colors.green
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isLocationEnabled ? Icons.location_on : Icons.location_off,
                        color: _isLocationEnabled ? Colors.green : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        size: 20,
                      ),
                      onPressed: _isRequestingLocation ? null : () {
                        if (_isLocationEnabled) {
                          setState(() {
                            _isLocationEnabled = false;
                            _userLocation = null;
                          });
                          _loadProducts();
                        } else {
                          _requestLocationPermission();
                        }
                      },
                      tooltip: _isLocationEnabled ? l10n.disableLocationBasedSorting : l10n.enableLocationBasedSorting,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add Product button (for sellers)
                  if (AuthService().canSell)
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
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white, size: 20),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateProductScreen(),
                            ),
                          );
                          if (result != null) {
                            // If result is a Map, it's the created product data - add it optimistically
                            if (result is Map<String, dynamic>) {
                              try {
                                final newProduct = ProductModel.fromJson(result);
                                if (mounted) {
                                  setState(() {
                                    // Add new product at the beginning of the list
                                    _allProducts.insert(0, newProduct);
                                    _filterProductsByCategory(_selectedCategory);
                                  });
                                }
                              } catch (e) {
                                print('Error adding created product: $e');
                                // Fallback to full refresh
                                _loadProducts();
                              }
                            } else if (result == true) {
                              // Fallback: full refresh if no product data
                              _loadProducts();
                            }
                          }
                        },
                        tooltip: l10n.createProduct,
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Notifications button
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                            size: 20,
                          ),
                          onPressed: () {
                            final authService = AuthService();
                            if (authService.isGuest) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notifications are only available for registered users. Please sign in to continue.'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationsScreen(),
                                ),
                              ).then((_) {
                                _loadUnreadNotificationCount();
                              });
                            }
                          },
                        ),
                      ),
                      if (_unreadNotificationCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? Colors.grey[900]! : Colors.white, width: 2),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Story Bar
          SliverToBoxAdapter(
            child: StoryBarWidget(
              userStories: _userStories,
              onAddStory: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateStoryScreen(),
                  ),
                ).then((_) {
                  _loadStories();
                });
              },
              onStoriesUpdated: () {
                _loadStories();
              },
            ),
          ),
          // Category Filter - Modern Style
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final categories = _getCategories(l10n);
                return Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category['value'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [Colors.blue[400]!, Colors.blue[600]!],
                              )
                            : null,
                        color: isSelected ? null : (isDark ? Colors.grey[800] : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            _filterProductsByCategory(category['value'], l10n);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Center(
                              child: Text(
                                category['label']!,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                    },
                  ),
                );
              },
            ),
          ),
          // Products List or Loading/Empty State
          if (_isLoading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.loadingProducts,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
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
                        Icons.inbox_outlined,
                        size: 64,
                        color: isDark ? Colors.grey[400] : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.noProductsFound,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your filters',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadProducts,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _products[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ProductCard(
                        product: product,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                product: product,
                              ),
                            ),
                          );
                          if (result == true && mounted) {
                            await _loadProducts();
                          }
                        },
                      ),
                    );
                  },
                  childCount: _products.length,
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}


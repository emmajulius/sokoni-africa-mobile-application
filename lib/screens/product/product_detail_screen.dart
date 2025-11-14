import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../models/product_model.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/reports_service.dart';
import '../../services/saved_products_service.dart';
import '../../services/product_engagement_service.dart';
import '../../services/language_service.dart';
import '../../services/api_service.dart';
import '../../services/follow_service.dart';
import '../../widgets/auction_countdown_timer.dart';
import '../auth/login_screen.dart';
import '../messages/messages_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLiked = false;
  int _likes = 0;
  int _comments = 0;
  double _rating = 0.0;
  double? _userRating; // User's own rating
  bool _isLoadingEngagement = true;
  bool _isAddingToCart = false;
  bool _isSaved = false;
  List<Map<String, dynamic>> _productComments = [];
  bool _isLoadingComments = false;
  bool _engagementUpdated = false; // Track if engagement was updated
  bool _isFollowing = false;
  bool _isLoadingFollowStatus = true;
  bool _isTogglingFollow = false;
  bool _followsYou = false; // Whether the seller follows the current user
  
  // Auction-specific state
  ProductModel? _currentAuctionProduct; // Updated auction data
  List<Map<String, dynamic>> _bidHistory = [];
  bool _isLoadingBids = false;
  bool _isPlacingBid = false;
  Timer? _auctionUpdateTimer;
  int? _timeRemainingSeconds;
  String? _currentUserId; // Cache current user ID
  DateTime? _lastDataUpdate; // Track last data update to reduce API calls
  
  final LanguageService _languageService = LanguageService();
  final CartService _cartService = CartService();
  final ReportsService _reportsService = ReportsService();
  final SavedProductsService _savedProductsService = SavedProductsService();
  final ProductEngagementService _engagementService = ProductEngagementService();
  final ApiService _apiService = ApiService();
  final FollowService _followService = FollowService();
  final TextEditingController _commentController = TextEditingController();
  
  String? _primaryImageUrl() {
    if (widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty) {
      return widget.product.imageUrl;
    }
    if (widget.product.images.isNotEmpty) {
      final candidate = widget.product.images.firstWhere(
        (url) => url.isNotEmpty,
        orElse: () => '',
      );
      if (candidate.isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }
  
  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _likes = widget.product.likes;
    _comments = widget.product.comments;
    _rating = widget.product.rating;
    _loadProductEngagement();
    _checkSavedStatus();
    _loadComments();
    _checkFollowStatus();
    
    // Initialize auction data if it's an auction
    if (widget.product.isAuction) {
      try {
        _currentAuctionProduct = widget.product;
        // Try to get time remaining from product, or calculate it from end time
        _timeRemainingSeconds = widget.product.timeRemainingSeconds;
        if (_timeRemainingSeconds == null || _timeRemainingSeconds! <= 0) {
          _timeRemainingSeconds = _calculateTimeRemaining(widget.product);
        }
        
        // For active auctions, defer data fetching to avoid blocking initial load
        // Only fetch if really needed (user wants to see live data)
        final auctionStatus = widget.product.auctionStatus ?? 'pending';
        if (auctionStatus == 'active' || auctionStatus == 'pending') {
          // Defer auction data update - don't block initial load
          // Only update after a longer delay to allow UI to render first
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _updateAuctionData().catchError((e) {
                print('Error updating auction data: $e');
                // Continue with existing data
              });
            }
          });
        }
        
        // Defer bid history loading - load it only when user scrolls to bid history section
        // This makes initial load much faster
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && widget.product.isAuction) {
            _loadAuctionBids().catchError((e) {
              print('Error loading auction bids: $e');
            });
          }
        });
        
        // Start polling for auction updates (only if auction is active)
        // Delay polling to allow initial build to complete
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && widget.product.isAuction) {
            _startAuctionPolling();
          }
        });
      } catch (e) {
        print('Error initializing auction data: $e');
        // Continue with initialization even if auction setup fails
        // This prevents white screen
      }
    }
    
    // Get current user ID
    _loadCurrentUserId();
  }
  
  Future<void> _loadCurrentUserId() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      if (mounted) {
        setState(() {
          _currentUserId = authService.userId?.toString();
        });
      }
    } catch (e) {
      print('Error loading current user ID: $e');
    }
  }
  
  @override
  void dispose() {
    _auctionUpdateTimer?.cancel();
    _languageService.removeListener(_onLanguageChanged);
    _commentController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProductEngagement() async {
    try {
      final productId = int.parse(widget.product.id);
      final productData = await _apiService.getProduct(productId);
      
      // productData is guaranteed to be Map<String, dynamic> (non-nullable)
      // If there's an error, getProduct throws an exception
      if (mounted) {
        setState(() {
          // Safely extract engagement data with fallbacks
          _likes = _parseIntSafely(productData['likes']) ?? widget.product.likes;
          _comments = _parseIntSafely(productData['comments']) ?? widget.product.comments;
          final ratingValue = productData['rating'];
          _rating = ratingValue is num ? ratingValue.toDouble() : widget.product.rating;
          _isLoadingEngagement = false;
        });
      }
      
      // Check if user has liked this product
      try {
        final authService = AuthService();
        await authService.initialize();
        if (authService.isAuthenticated) {
          // We'll check this by trying to fetch the product with auth token
          // For now, we'll check via the API response if it includes is_liked
          // This will be updated when we add is_liked to ProductResponse
        }
      } catch (e) {
        print('Error checking auth for engagement: $e');
        // Don't fail the whole method if auth check fails
      }
    } catch (e) {
      print('Error loading product engagement: $e');
      if (mounted) {
        setState(() {
          // Use widget product data as fallback
          _likes = widget.product.likes;
          _comments = widget.product.comments;
          _rating = widget.product.rating;
          _isLoadingEngagement = false;
        });
      }
    }
  }
  
  // Helper method to safely parse integers
  int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) {
      if (!value.isFinite) return null;
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
  
  // Helper method to calculate time remaining from auction end time
  int? _calculateTimeRemaining(ProductModel auction) {
    try {
      if (auction.auctionEndTime != null) {
        final now = DateTime.now();
        final endTime = auction.auctionEndTime!;
        final difference = endTime.difference(now);
        final seconds = difference.inSeconds;
        return seconds > 0 ? seconds : 0;
      }
      return null;
    } catch (e) {
      print('Error calculating time remaining: $e');
      return null;
    }
  }
  
  Future<void> _loadComments() async {
    try {
      setState(() {
        _isLoadingComments = true;
      });
      
      final productId = int.parse(widget.product.id);
      final comments = await _engagementService.getProductComments(productId);
      
      if (mounted) {
        setState(() {
          _productComments = comments;
          _comments = comments.length;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
      }
    }
  }
  
  Future<void> _toggleLike() async {
    final authService = AuthService();
    await authService.initialize();
    
    if (!authService.isAuthenticated || authService.authToken == null) {
      _showLoginPrompt(context, 'like');
      return;
    }
    
    final productId = int.parse(widget.product.id);
    Map<String, dynamic>? result;
    
    try {
      // Try the opposite of current state
      if (_isLiked) {
        // Currently liked, try to unlike
        result = await _engagementService.unlikeProduct(productId);
      } else {
        // Currently not liked, try to like
        result = await _engagementService.likeProduct(productId);
      }
    } catch (e) {
      // If action failed due to state mismatch, try the opposite action
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already liked') || errorMsg.contains('product already liked')) {
        // Tried to like but already liked, so unlike instead
        try {
          result = await _engagementService.unlikeProduct(productId);
        } catch (e2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to toggle like: ${e2.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else if (errorMsg.contains('not liked') || errorMsg.contains('product not liked')) {
        // Tried to unlike but not liked, so like instead
        try {
          result = await _engagementService.likeProduct(productId);
        } catch (e2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to toggle like: ${e2.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else {
        // Other error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ${_isLiked ? "unlike" : "like"} product: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
    
    // Update state with result
    if (mounted) {
      setState(() {
        _isLiked = result?['is_liked'] ?? !_isLiked;
        _likes = result?['likes'] ?? _likes;
        _engagementUpdated = true; // Mark engagement as updated
      });
    }
  }
  
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }
    
    final authService = AuthService();
    await authService.initialize();
    
    if (!authService.isAuthenticated || authService.authToken == null) {
      _showLoginPrompt(context, 'comment');
      return;
    }
    
    try {
      final productId = int.parse(widget.product.id);
      await _engagementService.addComment(productId, _commentController.text.trim());
      
      _commentController.clear();
      await _loadComments();
      await _loadProductEngagement(); // Refresh engagement stats
      
      if (mounted) {
        setState(() {
          _engagementUpdated = true; // Mark engagement as updated
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _rateProduct(double rating) async {
    final authService = AuthService();
    await authService.initialize();
    
    if (!authService.isAuthenticated || authService.authToken == null) {
      _showLoginPrompt(context, 'rate');
      return;
    }
    
    try {
      final productId = int.parse(widget.product.id);
      await _engagementService.rateProduct(productId, rating);
      
      // Update user's rating
      setState(() {
        _userRating = rating;
        _engagementUpdated = true; // Mark engagement as updated
      });
      
      await _loadProductEngagement(); // Refresh engagement stats
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product rated ${rating.toStringAsFixed(1)} stars'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rate product: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _checkSavedStatus() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      if (authService.isAuthenticated) {
        final productId = int.parse(widget.product.id);
        final isSaved = await _savedProductsService.isProductSaved(productId);
        if (mounted) {
          setState(() {
            _isSaved = isSaved;
          });
        }
      }
    } catch (e) {
      print('Error checking saved status: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      
      if (!authService.isAuthenticated || authService.isGuest) {
        if (mounted) {
          setState(() {
            _isLoadingFollowStatus = false;
            _isFollowing = false;
            _followsYou = false;
          });
        }
        return;
      }

      final sellerId = int.parse(widget.product.sellerId);
      
      // Check both follow statuses in parallel
      final results = await Future.wait([
        _followService.checkIfFollowing(sellerId),
        _followService.checkIfFollowsYou(sellerId),
      ]);
      
      if (mounted) {
        setState(() {
          _isFollowing = results[0];
          _followsYou = results[1];
          _isLoadingFollowStatus = false;
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
      if (mounted) {
        setState(() {
          _isLoadingFollowStatus = false;
          _isFollowing = false;
          _followsYou = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_isTogglingFollow) return;

    final authService = AuthService();
    await authService.initialize();
    
    if (!authService.isAuthenticated || authService.isGuest) {
      _showLoginPrompt(context, 'follow');
      return;
    }

    setState(() {
      _isTogglingFollow = true;
    });

    try {
      final sellerId = int.parse(widget.product.sellerId);
      final wasFollowing = _isFollowing;

      // Optimistically update UI
      setState(() {
        _isFollowing = !_isFollowing;
      });

      Map<String, dynamic> result;
      try {
        if (wasFollowing) {
          result = await _followService.unfollowUser(sellerId);
        } else {
          result = await _followService.followUser(sellerId);
        }

        // Update with server response if available
        if (result.containsKey('followers_count')) {
          // Could update seller's follower count if needed
        }
      } catch (e) {
        // Revert on error
        setState(() {
          _isFollowing = wasFollowing;
        });

        final errorMessage = e.toString();
        if (errorMessage.contains('already following')) {
          // Already following, try to unfollow
          try {
            result = await _followService.unfollowUser(sellerId);
            setState(() {
              _isFollowing = false;
            });
          } catch (e2) {
            throw Exception('Failed to toggle follow: $e2');
          }
        } else if (errorMessage.contains('not following')) {
          // Not following, try to follow
          try {
            result = await _followService.followUser(sellerId);
            setState(() {
              _isFollowing = true;
            });
          } catch (e2) {
            throw Exception('Failed to toggle follow: $e2');
          }
        } else {
          rethrow;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? 'You are now following ${widget.product.sellerUsername}' : 'You unfollowed ${widget.product.sellerUsername}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isFollowing ? "follow" : "unfollow"}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFollow = false;
        });
      }
    }
  }
  
  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addToCart() async {
    final authService = AuthService();
    await authService.initialize();
    
    if (!authService.isAuthenticated || authService.authToken == null) {
      _showLoginPrompt(context, 'add to cart');
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final productId = int.parse(widget.product.id);
      await _cartService.addToCart(productId: productId, quantity: 1);
      
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.title} added to cart!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pop(context);
                // Navigate to cart - you may need to adjust this based on your navigation structure
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareProduct() {
    final productUrl = '${AppConstants.baseUrl}/products/${widget.product.id}';
    
    // Format price based on product type
    String priceText;
    if (widget.product.isAuction) {
      final auction = _currentAuctionProduct ?? widget.product;
      final currentBid = auction.currentBid ?? auction.startingPrice;
      if (currentBid != null) {
        priceText = Helpers.formatCurrency(currentBid);
      } else {
        priceText = 'Auction';
      }
    } else {
      priceText = Helpers.formatCurrency(widget.product.price);
    }
    
    final shareText = 'Check out ${widget.product.title} - $priceText\n$productUrl';
    
    Share.share(
      shareText,
      subject: widget.product.title,
    );
  }

  Future<void> _saveForLater() async {
    final authService = AuthService();
    await authService.initialize();
    
    if (!authService.isAuthenticated || authService.authToken == null) {
      _showLoginPrompt(context, 'save product');
      return;
    }

    try {
      final productId = int.parse(widget.product.id);
      
      if (_isSaved) {
        await _savedProductsService.unsaveProduct(productId);
        if (mounted) {
          setState(() {
            _isSaved = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product removed from saved'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _savedProductsService.saveProduct(productId);
        if (mounted) {
          setState(() {
            _isSaved = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product saved for later'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isSaved ? "unsave" : "save"} product: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _reportProduct() {
    final authService = AuthService();
    if (authService.isGuest) {
      _showLoginPrompt(context, 'report product');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ReportProductDialog(
        productId: int.parse(widget.product.id),
        reportsService: _reportsService,
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Product'),
              onTap: () {
                Navigator.pop(context);
                _reportProduct();
              },
            ),
            ListTile(
              leading: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
              title: Text(_isSaved ? 'Remove from Saved' : 'Save for Later'),
              onTap: () {
                Navigator.pop(context);
                _saveForLater();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Product Link'),
              onTap: () {
                Navigator.pop(context);
                final productUrl = '${AppConstants.baseUrl}/products/${widget.product.id}';
                Clipboard.setData(ClipboardData(text: productUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Product Details'),
              onTap: () {
                Navigator.pop(context);
                _showProductInfo();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProductInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          widget.product.title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category: ${widget.product.category}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seller: ${widget.product.sellerUsername}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (widget.product.sellerLocation != null) ...[
              const SizedBox(height: 8),
              Text(
                'Location: ${widget.product.sellerLocation}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              widget.product.isAuction
                  ? 'Auction: ${_currentAuctionProduct?.currentBid != null ? Helpers.formatCurrency(_currentAuctionProduct!.currentBid!) : _currentAuctionProduct?.startingPrice != null ? Helpers.formatCurrency(_currentAuctionProduct!.startingPrice!) : "No bids yet"}'
                  : 'Price: ${Helpers.formatCurrency(widget.product.price)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rating: ${widget.product.rating.toStringAsFixed(1)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _sendMessageToSeller() {
    final authService = AuthService();
    if (authService.isGuest) {
      _showLoginPrompt(context, 'message seller');
      return;
    }

    // Navigate to messages screen with seller ID
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesScreen(
          sellerId: widget.product.sellerId,
          sellerName: widget.product.sellerUsername,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final l10n = AppLocalizations.of(context) ?? 
                   AppLocalizations(_languageService.currentLocale);
      
      return PopScope(
        canPop: !_engagementUpdated, // Prevent pop if engagement updated, so we can return result
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _engagementUpdated) {
            // Pop was prevented, manually pop with result
            Future.microtask(() {
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop(true);
              }
            });
          }
        },
        child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // App Bar with Image
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // Return result if engagement was updated, otherwise just pop
                  Navigator.of(context).pop(_engagementUpdated ? true : null);
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeroImage(),
              ),
              actions: [
                IconButton(
                  icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
                  color: _isLiked ? Colors.red : Colors.white,
                  onPressed: _toggleLike,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  color: Colors.white,
                  onPressed: _shareProduct,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  color: Colors.white,
                  onPressed: _showMoreOptions,
                ),
              ],
            ),
            // Product Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price or Auction Info
                    if (widget.product.isAuction) ...[
                      _buildAuctionInfo(),
                      const SizedBox(height: 16),
                    ] else ...[
                      Text(
                        Helpers.formatCurrency(widget.product.price),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  // Seller Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: widget.product.sellerProfileImage != null
                            ? NetworkImage(widget.product.sellerProfileImage!)
                            : null,
                        child: widget.product.sellerProfileImage == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.sellerUsername,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (widget.product.sellerLocation != null)
                              Text(
                                widget.product.sellerLocation!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _isTogglingFollow || _isLoadingFollowStatus
                            ? null
                            : () {
                                _toggleFollow();
                              },
                        style: TextButton.styleFrom(
                          backgroundColor: _isFollowing 
                              ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                              : null,
                          foregroundColor: _isFollowing 
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.primary,
                        ),
                        child: _isLoadingFollowStatus
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _isFollowing 
                                    ? 'Following' 
                                    : (_followsYou ? 'Follow Back' : l10n.follow),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    widget.product.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tags
                  Wrap(
                    spacing: 8,
                    children: widget.product.tags.map((tag) {
                      return Chip(
                        label: Text('#$tag'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Description
                  Text(
                    l10n.description,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(l10n.likes, _isLoadingEngagement ? '...' : _likes.toString()),
                      _buildStatColumn(l10n.comments, _isLoadingEngagement ? '...' : _comments.toString()),
                      _buildStatColumn(l10n.rating, _isLoadingEngagement ? '...' : _rating.toStringAsFixed(1)),
                    ],
                  ),
                  // Bid History (for auctions)
                  if (widget.product.isAuction) _buildBidHistory(),
                  const SizedBox(height: 24),
                  // Rating Section
                  if (!AuthService().isGuest)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rate this product',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                final rating = (index + 1).toDouble();
                                final displayRating = _userRating ?? _rating;
                                return IconButton(
                                  icon: Icon(
                                    rating <= displayRating ? Icons.star : Icons.star_border,
                                    color: rating <= displayRating ? Colors.amber : Colors.grey,
                                    size: 32,
                                  ),
                                  onPressed: () => _rateProduct(rating),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Comments Section
                  Text(
                    'Comments ($_comments)',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add Comment
                  if (!AuthService().isGuest)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Write a comment...',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: _addComment,
                                ),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Comments List
                  if (_isLoadingComments)
                    const Center(child: CircularProgressIndicator())
                  else if (_productComments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No comments yet. Be the first to comment!',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._productComments.map((comment) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: comment['user_profile_image'] != null
                              ? NetworkImage(comment['user_profile_image'])
                              : null,
                          child: comment['user_profile_image'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          comment['username'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(comment['content'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              _formatCommentTime(comment['created_at']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Builder(
          builder: (context) {
            // Check if current user is the seller
            final currentUserId = _currentUserId;
            final isSeller = currentUserId != null && currentUserId == widget.product.sellerId;
            
            // Build list of action buttons
            final List<Widget> actionButtons = [];
            
            // Only show "Message Seller" button if current user is NOT the seller
            if (!isSeller) {
              actionButtons.add(
                SizedBox(
                  width: 160,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _sendMessageToSeller,
                    child: Text(
                      l10n.messageSeller,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }
            
            // Show auction buttons or regular add to cart (only if not seller)
            if (!isSeller) {
              if (widget.product.isAuction) {
                // Add auction action buttons (method already handles seller case)
                actionButtons.add(_buildAuctionActionButtons());
              } else if (AuthService().canBuy) {
                actionButtons.add(
                  SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _isAddingToCart ? null : _addToCart,
                      child: _isAddingToCart
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              l10n.addToCart,
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                );
              }
            }
            
            // If no buttons to show (seller viewing their own product), return empty container
            if (actionButtons.isEmpty) {
              return const SizedBox.shrink();
            }
            
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: actionButtons,
            );
          },
        ),
      ),
      ),
    );
    } catch (e, stackTrace) {
      // Catch any errors in the build method to prevent white screen
      print('Error building ProductDetailScreen: $e');
      print('Stack trace: $stackTrace');
      
      // Return error screen instead of white screen
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(
            widget.product.title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          iconTheme: IconThemeData(
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading product details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildHeroImage() {
    final heroImage = _primaryImageUrl();
    if (heroImage == null) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
      );
    }

    return CachedNetworkImage(
      imageUrl: heroImage,
      fit: BoxFit.cover,
      memCacheWidth: 1200,
      memCacheHeight: 1200,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAuctionInfo() {
    try {
      // Use current auction product if available, otherwise use widget product
      final auction = _currentAuctionProduct ?? widget.product;
      
      // Calculate status based on end time (client-side check for accuracy)
      String status = auction.auctionStatus ?? (auction.isAuction ? 'pending' : 'unknown');
      
      // Check if auction has actually ended based on end time (more reliable than server status)
      bool hasEndedByTime = false;
      if (auction.auctionEndTime != null) {
        try {
          final endTime = auction.auctionEndTime!;
          final now = DateTime.now().toUtc();
          final endTimeUtc = endTime.isUtc ? endTime : endTime.toUtc();
          hasEndedByTime = now.isAfter(endTimeUtc) || now.isAtSameMomentAs(endTimeUtc);
          
          // If time has passed but status says active, update status locally
          if (hasEndedByTime && (status == 'active' || status == 'pending')) {
            status = 'ended';
          }
        } catch (e) {
          print('Error checking auction end time: $e');
        }
      }
      
      final isActive = !hasEndedByTime && (status == 'active' || status == 'pending');
      final isEnded = hasEndedByTime || status == 'ended' || status == 'completed';
      
      // Safely get bid information with fallbacks
      final currentBid = auction.currentBid ?? 
                        auction.startingPrice ?? 
                        (auction.isAuction ? 0.0 : auction.price);
      final startingPrice = auction.startingPrice ?? 
                           (auction.isAuction ? 0.0 : auction.price);
      final bidIncrement = auction.bidIncrement ?? 1.0;
    
    return Card(
      color: isActive 
          ? Colors.purple.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1)
          : Theme.of(context).colorScheme.surface.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auction badge
            Row(
              children: [
                Icon(
                  isActive ? Icons.gavel : Icons.gavel_outlined,
                  color: isActive 
                      ? Colors.purple 
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'LIVE AUCTION' : isEnded ? 'AUCTION ENDED' : 'AUCTION',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isActive 
                        ? Colors.purple 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Countdown timer (for active auctions)
            if (isActive) ...[
              Builder(
                builder: (context) {
                  try {
                    // Safely get time remaining with multiple fallbacks
                    int? timeRemaining = _timeRemainingSeconds;
                    if (timeRemaining == null || timeRemaining <= 0) {
                      timeRemaining = auction.timeRemainingSeconds;
                    }
                    if (timeRemaining == null || timeRemaining <= 0) {
                      timeRemaining = _calculateTimeRemaining(auction);
                    }
                    
                    // Only show countdown if we have valid time remaining
                    if (timeRemaining != null && timeRemaining > 0) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer, size: 18, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AuctionCountdownTimer(
                                  timeRemainingSeconds: timeRemaining,
                                  showLabel: false,
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    } else {
                      // Show loading/updating message if time remaining is not available yet
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Auction is active. Loading time information...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                  } catch (e) {
                    print('Error building countdown timer: $e');
                    // Return empty widget if countdown fails
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
            // Current bid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Current Bid' : 'Final Bid',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Helpers.formatCurrency(currentBid),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.purple : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                if (isActive) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Starting Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatCurrency(startingPrice),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Minimum bid increment: ${Helpers.formatCurrency(bidIncrement)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (auction.bidCount != null && auction.bidCount! > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${auction.bidCount} ${auction.bidCount == 1 ? 'bid' : 'bids'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
            if (isEnded) ...[
              const SizedBox(height: 12),
              if (auction.winnerId != null) ...[
                Text(
                  'Winner: ${auction.currentBidderUsername ?? "Unknown"}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (auction.winnerPaid == true) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: const Text(
                      'Payment Completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
    } catch (e) {
      print('Error building auction info: $e');
      // Return error widget instead of crashing
      return Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error loading auction information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Please try refreshing the page.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  Widget _buildAuctionActionButtons() {
    final auction = _currentAuctionProduct ?? widget.product;
    final status = auction.auctionStatus ?? 'pending';
    final isActive = status == 'active' || status == 'pending';
    final isEnded = status == 'ended';
    
    // Use cached user ID
    final currentUserId = _currentUserId;
    final isSeller = currentUserId != null && currentUserId == widget.product.sellerId;
    final isWinner = currentUserId != null && auction.winnerId != null && currentUserId == auction.winnerId;
    final winnerPaid = auction.winnerPaid == true;
    
    if (isSeller) {
      // Seller view - no action buttons
      return const SizedBox.shrink();
    }
    
    if (isEnded && isWinner && !winnerPaid) {
      // Winner needs to complete payment
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.green,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: _completeAuctionPayment,
          icon: const Icon(Icons.payment, color: Colors.white),
          label: const Text(
            'Complete Payment',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    if (isActive) {
      // Active auction - show place bid button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.purple,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: _isPlacingBid ? null : _placeBid,
          icon: _isPlacingBid
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.gavel, color: Colors.white),
          label: Text(
            _isPlacingBid ? 'Placing Bid...' : 'Place Bid',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    // Auction ended, user is not winner
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'This auction has ended',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  Widget _buildBidHistory() {
    if (!widget.product.isAuction) return const SizedBox.shrink();
    
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Bid History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingBids)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_bidHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No bids yet. Be the first to bid!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bidHistory.length,
              itemBuilder: (context, index) {
                try {
                  if (index >= _bidHistory.length) {
                    return const SizedBox.shrink();
                  }
                  final bid = _bidHistory[index];
                  // Bid is already validated as Map<String, dynamic> when loading
                  // No need to check type again
                  
                  final isWinning = bid['is_winning_bid'] == true;
                  final isOutbid = bid['is_outbid'] == true;
                  final bidAmount = bid['bid_amount'] ?? 0;
                  final bidderUsername = bid['bidder_username'] ?? 'Unknown';
                  final bidderProfileImage = bid['bidder_profile_image'];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isWinning ? Colors.green[50] : Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: bidderProfileImage != null && bidderProfileImage is String && bidderProfileImage.isNotEmpty
                            ? NetworkImage(bidderProfileImage)
                            : null,
                        child: bidderProfileImage == null || bidderProfileImage.toString().isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        bidderUsername.toString(),
                        style: TextStyle(
                          fontWeight: isWinning ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        _formatBidTime(bid['bid_time']),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Helpers.formatCurrency(bidAmount is num ? bidAmount.toDouble() : 0.0),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isWinning ? Colors.green : Colors.black,
                            ),
                          ),
                          if (isWinning)
                            const Text(
                              'Winning',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else if (isOutbid)
                            const Text(
                              'Outbid',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                } catch (e) {
                  print('Error building bid item: $e');
                  // Return empty widget instead of crashing
                  return const SizedBox.shrink();
                }
              },
            ),
        ],
      );
    } catch (e) {
      print('Error building bid history: $e');
      // Return error message instead of crashing
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Error loading bid history: ${e.toString()}',
          style: TextStyle(color: Colors.red[900]),
        ),
      );
    }
  }
  
  void _showLoginPrompt(BuildContext context, String action) {
    final l10n = AppLocalizations.of(context) ?? 
                 AppLocalizations(_languageService.currentLocale);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signInRequired),
        content: Text(l10n.signInToAction(action)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            child: Text(l10n.signIn),
          ),
        ],
      ),
    );
  }
  
  // Helper method to safely format bid time
  String _formatBidTime(dynamic bidTime) {
    if (bidTime == null) {
      return 'Unknown time';
    }
    
    try {
      if (bidTime is String) {
        if (bidTime.isEmpty) {
          return 'Unknown time';
        }
        return Helpers.formatRelativeTime(DateTime.parse(bidTime));
      } else if (bidTime is DateTime) {
        return Helpers.formatRelativeTime(bidTime);
      } else {
        return 'Unknown time';
      }
    } catch (e) {
      print('Error parsing bid time: $e');
      return 'Unknown time';
    }
  }
  
  // Helper method to safely format comment time
  String _formatCommentTime(dynamic commentTime) {
    if (commentTime == null) {
      return 'Unknown time';
    }
    
    try {
      if (commentTime is String) {
        if (commentTime.isEmpty) {
          return 'Unknown time';
        }
        return Helpers.formatRelativeTime(DateTime.parse(commentTime));
      } else if (commentTime is DateTime) {
        return Helpers.formatRelativeTime(commentTime);
      } else {
        return 'Unknown time';
      }
    } catch (e) {
      print('Error parsing comment time: $e');
      return 'Unknown time';
    }
  }
  
  // Auction-specific methods
  Future<void> _loadAuctionBids() async {
    if (!widget.product.isAuction) return;
    
    setState(() {
      _isLoadingBids = true;
    });
    
    try {
      final productId = int.parse(widget.product.id);
      final bids = await _apiService.getAuctionBids(productId);
      
      // Filter out invalid bids to prevent crashes
      final validBids = (bids as List).where((bid) {
        try {
          // Validate bid structure
          if (bid is! Map<String, dynamic>) return false;
          if (bid['bid_amount'] == null) return false;
          return true;
        } catch (e) {
          print('Invalid bid data: $e');
          return false;
        }
      }).toList();
      
      if (mounted) {
        setState(() {
          _bidHistory = validBids.cast<Map<String, dynamic>>();
          _isLoadingBids = false;
        });
      }
    } catch (e) {
      print('Error loading auction bids: $e');
      if (mounted) {
        setState(() {
          _isLoadingBids = false;
          // Set empty list instead of crashing
          _bidHistory = [];
        });
      }
    }
  }
  
  Future<void> _updateAuctionData() async {
    if (!widget.product.isAuction) return;
    
    try {
      final productId = int.parse(widget.product.id);
      // Fetch full product details which includes auction info
      // getProduct returns Map<String, dynamic> (non-nullable) or throws an exception
      final productData = await _apiService.getProduct(productId);
      
      // Check if product data is empty
      if (productData.isEmpty) {
        print('Warning: Product data is empty');
        return;
      }
      
      // Update product model with latest auction data
      final updatedProduct = ProductModel.fromJson(productData);
      
      // Calculate time remaining if not provided
      int? timeRemaining = updatedProduct.timeRemainingSeconds;
      if (timeRemaining == null || timeRemaining <= 0) {
        timeRemaining = _calculateTimeRemaining(updatedProduct);
      }
      
      if (mounted) {
        setState(() {
          _currentAuctionProduct = updatedProduct;
          _timeRemainingSeconds = timeRemaining;
        });
      }
    } catch (e, stackTrace) {
      print('Error updating auction data: $e');
      print('Stack trace: $stackTrace');
      // Don't update state on error - keep existing data
      // This prevents white screen if update fails
      // But try to calculate time remaining from existing data
      if (mounted && _currentAuctionProduct != null) {
        try {
          final calculatedTime = _calculateTimeRemaining(_currentAuctionProduct!);
          if (calculatedTime != null && calculatedTime != _timeRemainingSeconds) {
            setState(() {
              _timeRemainingSeconds = calculatedTime;
            });
          }
        } catch (e2) {
          print('Error calculating time remaining in error handler: $e2');
        }
      }
    }
  }
  
  void _startAuctionPolling() {
    if (!widget.product.isAuction) return;
    if (!mounted) return;
    
    // Cancel any existing timer
    _auctionUpdateTimer?.cancel();
    
    // Check if auction is active before starting polling
    final currentStatus = _currentAuctionProduct?.auctionStatus ?? widget.product.auctionStatus;
    if (currentStatus != 'active' && currentStatus != 'pending') {
      // Don't start polling for ended or cancelled auctions
      return;
    }
    
    // Poll every 8 seconds for active auctions (better real-time feel)
    _auctionUpdateTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Check if auction has ended locally (client-side check)
      bool hasEnded = false;
      final auction = _currentAuctionProduct ?? widget.product;
      if (auction.auctionEndTime != null) {
        try {
          final endTime = auction.auctionEndTime!;
          final now = DateTime.now().toUtc();
          final endTimeUtc = endTime.isUtc ? endTime : endTime.toUtc();
          hasEnded = now.isAfter(endTimeUtc) || now.isAtSameMomentAs(endTimeUtc);
        } catch (e) {
          print('Error checking end time in polling: $e');
        }
      }
      
      // Only poll if auction is still active (by time, not just status)
      if (!hasEnded) {
        // Update time remaining locally first (fast, no API call)
        if (auction.auctionEndTime != null) {
          try {
            final calculatedTime = _calculateTimeRemaining(auction);
            if (calculatedTime != null && mounted) {
              setState(() {
                _timeRemainingSeconds = calculatedTime;
              });
            }
          } catch (e) {
            print('Error calculating time in polling: $e');
          }
        }
        
        // Update data less frequently (every 20 seconds) for better real-time feel
        final now = DateTime.now();
        final lastUpdate = _lastDataUpdate ?? DateTime(1970);
        if (now.difference(lastUpdate).inSeconds >= 20) {
          _updateAuctionData().then((_) {
            _lastDataUpdate = DateTime.now();
          }).catchError((e) {
            print('Error in polling update: $e');
          });
        }
      } else {
        // Auction has ended - stop polling and update status
        timer.cancel();
        _auctionUpdateTimer = null;
        if (mounted) {
          setState(() {
            _timeRemainingSeconds = 0;
            if (_currentAuctionProduct != null) {
              // Update status in existing product model instead of creating new one
              // This avoids missing required fields
              final current = _currentAuctionProduct!;
              _currentAuctionProduct = ProductModel(
                id: current.id,
                title: current.title,
                description: current.description,
                price: current.price,
                category: current.category,
                sellerId: current.sellerId,
                sellerUsername: current.sellerUsername,
                sellerLocation: current.sellerLocation,
                sellerProfileImage: current.sellerProfileImage,
                imageUrl: current.imageUrl,
                images: current.images,
                isAuction: current.isAuction,
                auctionStatus: 'ended',
                auctionEndTime: current.auctionEndTime,
                currentBid: current.currentBid,
                startingPrice: current.startingPrice,
                bidIncrement: current.bidIncrement,
                timeRemainingSeconds: 0,
                likes: current.likes,
                comments: current.comments,
                rating: current.rating,
                tags: current.tags,
                isSponsored: current.isSponsored,
                isWingaEnabled: current.isWingaEnabled,
                hasWarranty: current.hasWarranty,
                isPrivate: current.isPrivate,
                isAdultContent: current.isAdultContent,
                unitType: current.unitType,
                stockQuantity: current.stockQuantity,
                createdAt: current.createdAt,
                // Auction fields
                auctionStartTime: current.auctionStartTime,
                auctionDurationMinutes: current.auctionDurationMinutes,
                currentBidderId: current.currentBidderId,
                currentBidderUsername: current.currentBidderUsername,
                bidCount: current.bidCount,
                winnerId: current.winnerId,
                winnerPaid: current.winnerPaid,
              );
            }
          });
        }
      }
    });
  }
  
  Future<void> _placeBid() async {
    if (!mounted) return;
    
    final authService = AuthService();
    await authService.initialize();
    
    if (!mounted) return;
    
    if (!authService.isAuthenticated || authService.isGuest) {
      _showLoginPrompt(context, 'place a bid');
      return;
    }
    
    // Check if user is the seller
    final currentUserId = authService.userId;
    if (currentUserId != null && currentUserId.toString() == widget.product.sellerId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot bid on your own auction'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Show bid dialog
    if (mounted) {
      _showBidDialog();
    }
  }
  
  void _showBidDialog() {
    if (!mounted) return;
    
    final auction = _currentAuctionProduct ?? widget.product;
    final currentBid = auction.currentBid ?? auction.startingPrice ?? 0;
    final bidIncrement = auction.bidIncrement ?? 1;
    final minBid = currentBid + bidIncrement;
    
    showDialog(
      context: context,
      builder: (dialogContext) => _BidDialog(
        currentBid: currentBid,
        minBid: minBid,
        onBidPlaced: (bidAmount) async {
          Navigator.pop(dialogContext);
          await _submitBid(bidAmount);
        },
      ),
    );
  }
  
  Future<void> _submitBid(double bidAmount) async {
    if (!mounted) return;
    
    setState(() {
      _isPlacingBid = true;
    });
    
    try {
      final productId = int.parse(widget.product.id);
      await _apiService.placeBid(productId, bidAmount);
      
      // Show success immediately - don't wait for refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Bid placed successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Refresh auction data and bids in background (non-blocking)
      // Don't wait for these - they can fail without affecting bid placement
      Future.wait([
        _updateAuctionData().catchError((e) {
          print('Background: Error updating auction data after bid: $e');
        }),
        _loadAuctionBids().catchError((e) {
          print('Background: Error loading bids after bid: $e');
        }),
      ]).catchError((e) {
        print('Background: Error refreshing data after bid: $e');
        return <void>[];
      });
      
      // Update current user ID in background
      _loadCurrentUserId().catchError((e) {
        print('Background: Error loading user ID: $e');
      });
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place bid: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingBid = false;
        });
      }
    }
  }
  
  Future<void> _completeAuctionPayment() async {
    if (!mounted) return;
    
    final authService = AuthService();
    await authService.initialize();
    
    if (!mounted) return;
    
    if (!authService.isAuthenticated || authService.isGuest) {
      _showLoginPrompt(context, 'complete payment');
      return;
    }
    
    // Check if user is the winner
    final currentUserId = authService.userId;
    final auction = _currentAuctionProduct ?? widget.product;
    
    if (currentUserId == null || currentUserId.toString() != auction.winnerId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not the winner of this auction'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (!mounted) return;
    
    // Show payment confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Winning Bid: ${Helpers.formatCurrency(auction.currentBid ?? auction.startingPrice ?? 0)}'),
            const SizedBox(height: 8),
            const Text('Processing Fee (2%): Will be calculated'),
            const SizedBox(height: 8),
            const Text('Shipping: Optional'),
            const SizedBox(height: 16),
            const Text('Do you want to proceed with payment?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
    
    if (!mounted) return;
    
    if (confirmed == true) {
      // Show shipping option dialog
      final includeShipping = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Shipping Option'),
          content: const Text('Do you want to include shipping?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      
      if (mounted) {
        await _processAuctionPayment(includeShipping ?? false);
      }
    }
  }
  
  Future<void> _processAuctionPayment(bool includeShipping) async {
    if (!mounted) return;
    
    try {
      final productId = int.parse(widget.product.id);
      await _apiService.completeAuctionPayment(productId, includeShipping: includeShipping);
      
      if (!mounted) return;
      
      // Refresh auction data
      await _updateAuctionData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete payment: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Bid Dialog
class _BidDialog extends StatefulWidget {
  final double currentBid;
  final double minBid;
  final Function(double) onBidPlaced;

  const _BidDialog({
    required this.currentBid,
    required this.minBid,
    required this.onBidPlaced,
  });

  @override
  State<_BidDialog> createState() => _BidDialogState();
}

class _BidDialogState extends State<_BidDialog> {
  late final TextEditingController _bidController;

  @override
  void initState() {
    super.initState();
    _bidController = TextEditingController(text: widget.minBid.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.gavel, color: Colors.purple),
          SizedBox(width: 8),
          Text('Place Bid'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Bid:', style: TextStyle(fontSize: 14)),
                      Text(
                        Helpers.formatCurrency(widget.currentBid),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Minimum Bid:', style: TextStyle(fontSize: 14)),
                      Text(
                        Helpers.formatCurrency(widget.minBid),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bidController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Bid Amount (SOK)',
                border: OutlineInputBorder(),
                prefixText: 'SOK ',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
          ),
          onPressed: () {
            final bidAmount = double.tryParse(_bidController.text);
            if (bidAmount == null || bidAmount < widget.minBid) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bid must be at least ${Helpers.formatCurrency(widget.minBid)}'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            widget.onBidPlaced(bidAmount);
          },
          child: const Text('Place Bid', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Report Product Dialog
class _ReportProductDialog extends StatefulWidget {
  final int productId;
  final ReportsService reportsService;

  const _ReportProductDialog({
    required this.productId,
    required this.reportsService,
  });

  @override
  State<_ReportProductDialog> createState() => _ReportProductDialogState();
}

class _ReportProductDialogState extends State<_ReportProductDialog> {
  String? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _reasons = ['spam', 'inappropriate', 'fake', 'other'];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.reportsService.reportProduct(
        productId: widget.productId,
        reason: _selectedReason!,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report product: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please select a reason for reporting:'),
            const SizedBox(height: 16),
            ..._reasons.map((reason) {
              return RadioListTile<String>(
                title: Text(reason[0].toUpperCase() + reason.substring(1)),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
              );
            }),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Additional details (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}


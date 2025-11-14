import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../utils/helpers.dart';
import '../utils/app_theme.dart';
import '../utils/image_helper.dart';
import '../services/product_engagement_service.dart';
import '../services/auth_service.dart';
import 'auction_countdown_timer.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final Function(bool)? onLikeChanged; // Callback when like state changes
  final bool showOwnerActions;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onUpdateAddress;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onLikeChanged,
    this.showOwnerActions = false,
    this.onDelete,
    this.onEdit,
    this.onUpdateAddress,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool _isLiked;
  late int _likes;
  bool _isTogglingLike = false;
  final ProductEngagementService _engagementService = ProductEngagementService();
  final AuthService _authService = AuthService();
  late List<String> _imageUrls;
  late PageController _imageController;
  int _currentImageIndex = 0;

  String? get _sellerLocation {
    final location = widget.product.sellerLocation;
    if (location == null) return null;
    final trimmed = location.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (lower == 'null' || lower == 'none' || lower == 'undefined') {
      return null;
    }
    return trimmed;
  }

  String get _formattedSellerLocation {
    final location = _sellerLocation;
    if (location == null) return '';
    
    // If address is too long, truncate it nicely
    // Try to preserve the most important parts (city, region)
    final parts = location.split(',');
    if (parts.length > 3) {
      // Take the last 2-3 parts (usually city, region, country)
      return parts.sublist(parts.length - 3).join(', ').trim();
    }
    
    // If still too long, truncate to 50 characters
    if (location.length > 50) {
      return '${location.substring(0, 47)}...';
    }
    
    return location;
  }

  bool get _hasSellerLocation => _sellerLocation != null && _sellerLocation!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.product.isLiked ?? false;
    _likes = widget.product.likes;
    _imageUrls = _extractImageUrls(widget.product);
    _imageController = PageController();
  }

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.product.isLiked != oldWidget.product.isLiked) {
      _isLiked = widget.product.isLiked ?? false;
    }
    if (widget.product.likes != oldWidget.product.likes) {
      _likes = widget.product.likes;
    }
    if (widget.product.id != oldWidget.product.id ||
        !listEquals(widget.product.images, oldWidget.product.images) ||
        widget.product.imageUrl != oldWidget.product.imageUrl) {
      _imageUrls = _extractImageUrls(widget.product);
      _currentImageIndex = 0;
      _imageController.dispose();
      _imageController = PageController();
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    // Prevent multiple simultaneous requests
    if (_isTogglingLike) return;

    // Check if user is authenticated
    await _authService.initialize();
    if (!_authService.isAuthenticated || _authService.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to like products'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isTogglingLike = true;
    });

    try {
      final productId = int.parse(widget.product.id);
      final wasLiked = _isLiked;

      // Optimistically update UI
      setState(() {
        _isLiked = !_isLiked;
        _likes += _isLiked ? 1 : -1;
      });

      // Call API
      Map<String, dynamic> result;
      try {
        if (wasLiked) {
          result = await _engagementService.unlikeProduct(productId);
        } else {
          result = await _engagementService.likeProduct(productId);
        }
        
        // Update likes count from response if available
        if (result.containsKey('likes')) {
          final likesFromResponse = result['likes'];
          if (likesFromResponse != null) {
            setState(() {
              _likes = likesFromResponse as int;
            });
          }
        }
      } catch (e) {
        // If API call fails, revert UI changes
        setState(() {
          _isLiked = wasLiked;
          _likes += wasLiked ? 1 : -1;
        });

        // Handle specific errors
        final errorMessage = e.toString();
        if (errorMessage.contains('already liked')) {
          // Product was already liked, try to unlike
          try {
            result = await _engagementService.unlikeProduct(productId);
            setState(() {
              _isLiked = false;
              _likes = _likes > 0 ? _likes - 1 : 0;
            });
            // Update likes count from response
            if (result.containsKey('likes')) {
              final likesFromResponse = result['likes'];
              if (likesFromResponse != null) {
                setState(() {
                  _likes = likesFromResponse as int;
                });
              }
            }
          } catch (e2) {
            throw Exception('Failed to toggle like: $e2');
          }
        } else if (errorMessage.contains('not liked')) {
          // Product was not liked, try to like
          try {
            result = await _engagementService.likeProduct(productId);
            setState(() {
              _isLiked = true;
              _likes += 1;
            });
            // Update likes count from response
            if (result.containsKey('likes')) {
              final likesFromResponse = result['likes'];
              if (likesFromResponse != null) {
                setState(() {
                  _likes = likesFromResponse as int;
                });
              }
            }
          } catch (e2) {
            throw Exception('Failed to toggle like: $e2');
          }
        } else {
          rethrow;
        }
      }

      // Notify parent widget
      if (widget.onLikeChanged != null) {
        widget.onLikeChanged!(_isLiked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isLiked ? "like" : "unlike"} product: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingLike = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 280,
                    child: _buildProductImage(),
                  ),
                ),
                // Auction badge (priority over sponsored)
                if (widget.product.isAuction)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: widget.product.auctionStatus == 'active'
                            ? const LinearGradient(
                                colors: [Colors.purple, Colors.deepPurple],
                              )
                            : null,
                        color: widget.product.auctionStatus == 'ended'
                            ? Colors.grey[700]
                            : widget.product.auctionStatus == 'pending'
                                ? Colors.orange
                                : Colors.purple,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.gavel, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.product.auctionStatus == 'active'
                                  ? 'LIVE AUCTION'
                                  : widget.product.auctionStatus == 'ended'
                                      ? 'AUCTION ENDED'
                                      : 'AUCTION',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (widget.product.isSponsored)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accentColor, AppTheme.accentLight],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: const Text(
                        'Sponsored',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                // Countdown timer for active auctions
                if (widget.product.isAuction && 
                    (widget.product.auctionStatus == 'active' || widget.product.auctionStatus == null) &&
                    widget.product.timeRemainingSeconds != null &&
                    widget.product.timeRemainingSeconds! > 0)
                  Positioned(
                    bottom: _imageUrls.length > 1 ? 40 : 12, // Move up if pagination indicator is visible
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: AuctionCountdownTimer(
                        timeRemainingSeconds: widget.product.timeRemainingSeconds!,
                        showLabel: true,
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (widget.showOwnerActions)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20, color: Colors.black),
                        onSelected: (value) {
                          if (value == 'edit') {
                            widget.onEdit?.call();
                          } else if (value == 'delete') {
                            widget.onDelete?.call();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_authService.isAuthenticated)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: _isLiked ? Colors.red : Colors.black,
                        ),
                        onPressed: _isTogglingLike ? null : _toggleLike,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ),
                if (!widget.showOwnerActions && !_authService.isAuthenticated)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: const Icon(Icons.favorite_border, size: 20, color: Colors.black),
                    ),
                  ),
              ],
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seller Info
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                        child: widget.product.sellerProfileImage != null
                            ? CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                backgroundImage: CachedNetworkImageProvider(
                                  widget.product.sellerProfileImage!,
                                ),
                              )
                            : CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                child: Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.sellerUsername,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            // Show address details
                            if (_hasSellerLocation)
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _formattedSellerLocation,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            if (!_hasSellerLocation && widget.showOwnerActions)
                              _buildMissingAddressPrompt(context),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          Helpers.formatRelativeTime(widget.product.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Price or Current Bid (for auctions)
                  if (widget.product.isAuction && 
                      (widget.product.auctionStatus == 'active' || widget.product.auctionStatus == null || widget.product.auctionStatus == 'pending')) ...[
                    // Show current bid for active auctions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Bid',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.currentBid != null
                              ? Helpers.formatCurrency(widget.product.currentBid!)
                              : Helpers.formatCurrency(widget.product.startingPrice ?? widget.product.price),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.product.bidCount != null && widget.product.bidCount! > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${widget.product.bidCount} ${widget.product.bidCount == 1 ? 'bid' : 'bids'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                              ),
                            ),
                          ),
                        if (widget.product.startingPrice != null && widget.product.currentBid == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Starting: ${Helpers.formatCurrency(widget.product.startingPrice!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ] else if (widget.product.isAuction && widget.product.auctionStatus == 'ended') ...[
                    // Show final bid for ended auctions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Final Bid',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.currentBid != null
                              ? Helpers.formatCurrency(widget.product.currentBid!)
                              : Helpers.formatCurrency(widget.product.startingPrice ?? widget.product.price),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.product.winnerPaid == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: const Text(
                                'Paid',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    // Regular product price
                    Text(
                      Helpers.formatCurrency(widget.product.price),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Product Title
                  Text(
                    widget.product.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Description Preview
                  Text(
                    widget.product.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Engagement Stats
                  Row(
                    children: [
                      _buildStatIcon(Icons.favorite, _likes, Colors.red),
                      const SizedBox(width: 20),
                      _buildStatIcon(Icons.comment, widget.product.comments, AppTheme.infoColor),
                      const SizedBox(width: 20),
                      _buildStatIcon(Icons.star, widget.product.rating, AppTheme.warningColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tags
                  if (widget.product.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.product.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, num value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          Helpers.formatNumber((value is double && !value.isFinite) ? 0 : value.toInt()),
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMissingAddressPrompt(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Add your pickup address so buyers can find you.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (widget.onUpdateAddress != null) {
                widget.onUpdateAddress!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Go to Profile > My Addresses to update your address.'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text(
              'Update',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractImageUrls(ProductModel product) {
    final urls = <String>[];
    final primary = product.imageUrl;
    if (primary != null && primary.trim().isNotEmpty) {
      urls.add(primary.trim());
    }
    if (product.images.isNotEmpty) {
      for (final image in product.images) {
        final trimmed = image.trim();
        if (trimmed.isNotEmpty && !urls.contains(trimmed)) {
          urls.add(trimmed);
        }
      }
    }
    return urls;
  }

  Widget _buildProductImage() {
    if (_imageUrls.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'No image available',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          controller: _imageController,
          itemCount: _imageUrls.length,
          onPageChanged: (index) {
            setState(() => _currentImageIndex = index);
          },
          itemBuilder: (context, index) {
            final imageUrl = _imageUrls[index];
            // Use thumbnail for list views (product cards) - much faster loading
            return ImageHelper.buildCachedImage(
              imageUrl: imageUrl,
              useThumbnail: true, // Use thumbnail for list views
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
              placeholder: Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: Container(
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_imageUrls.length > 1)
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1} / ${_imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) {
    // Check for Infinity or NaN before converting
    if (!value.isFinite) return defaultValue;
    return value.toInt();
  }
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) {
    // Check for Infinity or NaN before converting
    if (!value.isFinite) return null;
    return value.toInt();
  }
  if (value is String) return int.tryParse(value);
  return null;
}

double? _parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _parseAuctionDurationMinutes(Map<String, dynamic> json) {
  // First check for the new minutes format
  if (json['auction_duration_minutes'] != null || json['auctionDurationMinutes'] != null) {
    return _parseNullableInt(json['auction_duration_minutes'] ?? json['auctionDurationMinutes']);
  }
  
  // Backward compatibility: convert hours to minutes
  if (json['auction_duration_hours'] != null || json['auctionDurationHours'] != null) {
    final hours = _parseNullableDouble(json['auction_duration_hours'] ?? json['auctionDurationHours']);
    if (hours != null) {
      return (hours * 60).round();
    }
  }
  
  return null;
}

bool _parseBool(dynamic value, [bool defaultValue = false]) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return defaultValue;
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value
        .map((item) => item?.toString() ?? '')
        .where((element) => element.isNotEmpty)
        .toList();
  }
  return const [];
}

class ProductModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String? imageUrl;
  final List<String> images;
  final String category;
  final String sellerId;
  final String sellerUsername;
  final String? sellerLocation;
  final String? sellerProfileImage;
  final int likes;
  final int comments;
  final double rating;
  final List<String> tags;
  final bool isSponsored;
  final bool isWingaEnabled;
  final bool hasWarranty;
  final bool isPrivate;
  final bool isAdultContent;
  final String? unitType;
  final int? stockQuantity;
  final double? distance; // Distance in kilometers from user's location
  final bool? isLiked; // Whether the current user has liked this product
  final DateTime createdAt;
  // Auction fields
  final bool isAuction;
  final double? startingPrice;
  final double? bidIncrement;
  final int? auctionDurationMinutes; // Duration in minutes (1-43200 minutes = 720 hours max)
  final DateTime? auctionStartTime;
  final DateTime? auctionEndTime;
  final double? currentBid;
  final String? currentBidderId;
  final String? currentBidderUsername;
  final String? auctionStatus; // pending, active, ended, cancelled
  final String? winnerId;
  final bool? winnerPaid;
  final int? bidCount;
  final int? timeRemainingSeconds; // Time remaining until auction ends in seconds

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.imageUrl,
    this.images = const [],
    required this.category,
    required this.sellerId,
    required this.sellerUsername,
    this.sellerLocation,
    this.sellerProfileImage,
    this.likes = 0,
    this.comments = 0,
    this.rating = 0.0,
    this.tags = const [],
    this.isSponsored = false,
    this.isWingaEnabled = false,
    this.hasWarranty = false,
    this.isPrivate = false,
    this.isAdultContent = false,
    this.unitType,
    this.stockQuantity,
    required this.createdAt,
    this.distance,
    this.isLiked,
    // Auction fields
    this.isAuction = false,
    this.startingPrice,
    this.bidIncrement,
    this.auctionDurationMinutes,
    this.auctionStartTime,
    this.auctionEndTime,
    this.currentBid,
    this.currentBidderId,
    this.currentBidderUsername,
    this.auctionStatus,
    this.winnerId,
    this.winnerPaid,
    this.bidCount,
    this.timeRemainingSeconds,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: _parseDouble(json['price'] ?? json['product_price']),
      imageUrl: _normalizePrimaryImage(json),
      images: _normalizeImagesList(json),
      category: json['category'] ?? json['category_slug'] ?? '',
      sellerId: json['seller_id']?.toString() ?? json['sellerId']?.toString() ?? '',
      sellerUsername: json['seller_username'] ?? json['sellerUsername'] ?? '',
      sellerLocation: json['seller_location'] ?? json['sellerLocation'],
      sellerProfileImage: json['seller_profile_image'] ?? json['sellerProfileImage'],
      likes: _parseInt(json['likes']),
      comments: _parseInt(json['comments']),
      rating: _parseDouble(json['rating']),
      tags: _parseStringList(json['tags']),
      isSponsored: _parseBool(json['is_sponsored'] ?? json['isSponsored']),
      isWingaEnabled: _parseBool(json['is_winga_enabled'] ?? json['isWingaEnabled']),
      hasWarranty: _parseBool(json['has_warranty'] ?? json['hasWarranty']),
      isPrivate: _parseBool(json['is_private'] ?? json['isPrivate']),
      isAdultContent: _parseBool(json['is_adult_content'] ?? json['isAdultContent']),
      unitType: json['unit_type'] ?? json['unitType'],
      stockQuantity: _parseNullableInt(json['stock_quantity'] ?? json['stockQuantity']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      distance: json['distance'] != null ? _parseDouble(json['distance']) : null,
      isLiked: json['is_liked'] != null
          ? _parseBool(json['is_liked'])
          : (json.containsKey('isLiked') ? _parseBool(json['isLiked']) : null),
      // Auction fields
      isAuction: _parseBool(json['is_auction'] ?? json['isAuction'], false),
      startingPrice: json['starting_price'] != null || json['startingPrice'] != null
          ? _parseDouble(json['starting_price'] ?? json['startingPrice'])
          : null,
      bidIncrement: json['bid_increment'] != null || json['bidIncrement'] != null
          ? _parseDouble(json['bid_increment'] ?? json['bidIncrement'])
          : null,
      auctionDurationMinutes: _parseAuctionDurationMinutes(json),
      auctionStartTime: json['auction_start_time'] != null || json['auctionStartTime'] != null
          ? DateTime.parse(json['auction_start_time'] ?? json['auctionStartTime'])
          : null,
      auctionEndTime: json['auction_end_time'] != null || json['auctionEndTime'] != null
          ? DateTime.parse(json['auction_end_time'] ?? json['auctionEndTime'])
          : null,
      currentBid: json['current_bid'] != null || json['currentBid'] != null
          ? _parseDouble(json['current_bid'] ?? json['currentBid'])
          : null,
      currentBidderId: json['current_bidder_id']?.toString() ?? json['currentBidderId']?.toString(),
      currentBidderUsername: json['current_bidder_username'] ?? json['currentBidderUsername'],
      auctionStatus: json['auction_status'] ?? json['auctionStatus'],
      winnerId: json['winner_id']?.toString() ?? json['winnerId']?.toString(),
      winnerPaid: json['winner_paid'] != null || json['winnerPaid'] != null
          ? _parseBool(json['winner_paid'] ?? json['winnerPaid'])
          : null,
      bidCount: json['bid_count'] != null || json['bidCount'] != null
          ? _parseNullableInt(json['bid_count'] ?? json['bidCount'])
          : null,
      timeRemainingSeconds: json['time_remaining_seconds'] != null || json['timeRemainingSeconds'] != null
          ? _parseNullableInt(json['time_remaining_seconds'] ?? json['timeRemainingSeconds'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'images': images,
      'category': category,
      'seller_id': sellerId,
      'seller_username': sellerUsername,
      'seller_location': sellerLocation,
      'seller_profile_image': sellerProfileImage,
      'likes': likes,
      'comments': comments,
      'rating': rating,
      'tags': tags,
      'is_sponsored': isSponsored,
      'is_winga_enabled': isWingaEnabled,
      'has_warranty': hasWarranty,
      'is_private': isPrivate,
      'is_adult_content': isAdultContent,
      'unit_type': unitType,
      'stock_quantity': stockQuantity,
      'created_at': createdAt.toIso8601String(),
      'distance': distance,
      'is_liked': isLiked,
      // Auction fields
      'is_auction': isAuction,
      'starting_price': startingPrice,
      'bid_increment': bidIncrement,
      'auction_duration_minutes': auctionDurationMinutes,
      'auction_start_time': auctionStartTime?.toIso8601String(),
      'auction_end_time': auctionEndTime?.toIso8601String(),
      'current_bid': currentBid,
      'current_bidder_id': currentBidderId,
      'current_bidder_username': currentBidderUsername,
      'auction_status': auctionStatus,
      'winner_id': winnerId,
      'winner_paid': winnerPaid,
      'bid_count': bidCount,
      'time_remaining_seconds': timeRemainingSeconds,
    };
  }
}

String? _normalizePrimaryImage(Map<String, dynamic> json) {
  final url = json['image_url']?.toString() ?? json['imageUrl']?.toString();
  if (url == null || url.trim().isEmpty) {
    return null;
  }
  final trimmed = url.trim();
  if (trimmed.toLowerCase() == 'null' ||
      trimmed.toLowerCase().contains('placeholder') ||
      trimmed.toLowerCase().contains('dummy') ||
      trimmed.toLowerCase().contains('default')) {
    return null;
  }
  return trimmed;
}

List<String> _normalizeImagesList(Map<String, dynamic> json) {
  final initial = _parseStringList(json['images']);
  if (initial.isEmpty) {
    return const [];
  }
  return initial
      .map((url) => url.trim())
      .where((url) =>
          url.isNotEmpty &&
          url.toLowerCase() != 'null' &&
          !url.toLowerCase().contains('placeholder') &&
          !url.toLowerCase().contains('dummy') &&
          !url.toLowerCase().contains('default'))
      .toList();
}


import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import 'image_compression_service.dart';
import 'cloudinary_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    if (kDebugMode) {
      print('🌐 API Base URL resolved to: ${AppConstants.baseUrl}');
    }
  }

  String get baseUrl => AppConstants.baseUrl;

  // Get a single product by ID
  Future<Map<String, dynamic>> getProduct(int productId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;
      
      final uri = Uri.parse('$baseUrl/api/products/$productId');
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 45), // Increased timeout for Render free tier
        onTimeout: () {
          throw Exception('Request timeout after 45 seconds. The backend may be waking up from sleep.');
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to fetch product');
      }
    } catch (e) {
      print('Error fetching product: $e');
      rethrow;
    }
  }

  // Get products from API with retry logic for Render cold starts
  Future<List<ProductModel>> getProducts({
    int page = 1,
    int limit = 15, // Reduced from 20 for faster initial load
    String? category,
    String? search,
    double? latitude,
    double? longitude,
    int? sellerId,
    bool? onlySold,
  }) async {
    final authService = AuthService();
    await authService.initialize();
    final token = authService.authToken;
    
    // Get location if not provided - but make it optional and fast
    // Skip location fetch entirely for faster loading - only use if explicitly provided
    double? userLat = latitude;
    double? userLon = longitude;
    // Don't fetch location automatically - it slows down product loading
    // Location is optional and can be provided by the caller if needed
    
    final queryParams = {
      'skip': ((page - 1) * limit).toString(),
      'limit': limit.toString(),
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      if (sellerId != null) 'seller_id': sellerId.toString(),
      if (userLat != null) 'latitude': userLat.toString(),
      if (userLon != null) 'longitude': userLon.toString(),
      if (onlySold == true) 'status': 'sold',
    };
    
    final uri = Uri.parse('$baseUrl/api/products').replace(
      queryParameters: queryParams,
    );

    print('Fetching products from: $uri');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // Add auth token if available (optional for products endpoint)
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    // Optimized for faster loading - single attempt with shorter timeout
    try {
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 12), // Short timeout for faster failure detection
        onTimeout: () {
          throw Exception('Request timeout. Backend may be waking up from sleep.');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle different response formats
        List<dynamic> productsList = [];
        
        if (data is Map) {
          // Check if response has a 'data' or 'products' key
          if (data['data'] != null) {
            productsList = data['data'] is List ? data['data'] : [];
          } else if (data['products'] != null) {
            productsList = data['products'] is List ? data['products'] : [];
          } else if (data['results'] != null) {
            productsList = data['results'] is List ? data['results'] : [];
          } else {
            // If the response itself is a list
            productsList = data.values.toList().firstWhere(
              (value) => value is List,
              orElse: () => [],
            );
          }
        } else if (data is List) {
          productsList = data;
        }

        return productsList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading products: $e');
      rethrow;
    }
  }

  // Upload images directly to Cloudinary (bypasses backend for faster uploads)
  Future<List<String>> uploadImages(
    List<XFile> imageFiles, {
    Function(int, int)? onProgress,
    String? folder, // Optional: specify folder (defaults to products folder)
  }) async {
    try {
      final cloudinaryService = CloudinaryService();
      
      // Check if Cloudinary is configured
      if (!cloudinaryService.isConfigured) {
        if (kDebugMode) {
          print('⚠️ Cloudinary not configured, falling back to backend upload');
          print('   Configuration status: ${cloudinaryService.configurationStatus}');
        }
        // Fallback to backend upload if Cloudinary not configured
        return await _uploadImagesToBackend(imageFiles, onProgress: onProgress);
      }
      
      final uploadFolder = folder ?? AppConstants.cloudinaryProductsFolder;
      print('☁️ Uploading ${imageFiles.length} images directly to Cloudinary...');
      print('   Folder: $uploadFolder');
      
      // Upload directly to Cloudinary
      // Optimized for faster uploads: smaller size, lower quality
      final urls = await cloudinaryService.uploadImages(
        imageFiles,
        folder: uploadFolder,
        onProgress: onProgress,
        maxWidth: 1000, // Reduced from 1200 for faster uploads
        maxHeight: 1000, // Reduced from 1200 for faster uploads
        quality: 75, // Reduced from 80 for smaller file sizes
      );
      
      print('✅ Successfully uploaded ${urls.length} images to Cloudinary');
      return urls;
    } catch (e) {
      print('❌ Error uploading images to Cloudinary: $e');
      // Fallback to backend upload on error
      if (kDebugMode) {
        print('⚠️ Falling back to backend upload');
      }
      return await _uploadImagesToBackend(imageFiles, onProgress: onProgress);
    }
  }

  // Fallback: Upload images to backend (old method)
  Future<List<String>> _uploadImagesToBackend(List<XFile> imageFiles, {Function(int, int)? onProgress}) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;
      
      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      final compressionService = ImageCompressionService();
      final compressedFiles = await compressionService.compressImages(
        files: imageFiles,
        maxWidth: 800,
        maxHeight: 800,
        quality: 75,
      );
      
      final uri = Uri.parse('$baseUrl/api/uploads/upload-multiple');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      for (var file in compressedFiles) {
        try {
          final bytes = await file.readAsBytes();
          final multipartFile = http.MultipartFile.fromBytes(
            'files',
            bytes,
            filename: file.name,
            contentType: MediaType('image', 'jpeg'),
          );
          request.files.add(multipartFile);
        } catch (e) {
          print('   Failed to add file ${file.name}: $e');
        }
      }
      
      if (request.files.isEmpty) {
        throw Exception('No valid image files to upload');
      }
      
      final response = await request.send().timeout(
        const Duration(seconds: 180),
        onTimeout: () {
          throw Exception('Upload timeout after 180 seconds.');
        },
      );
      
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 201) {
        final data = json.decode(responseBody);
        List<String> urls;
        if (data['urls'] != null && data['urls'] is List) {
          urls = (data['urls'] as List).map((url) => url.toString()).toList();
        } else if (data['data'] != null && data['data'] is List) {
          urls = (data['data'] as List).map((item) {
            if (item is Map && item['url'] != null) {
              return item['url'].toString();
            }
            return item.toString();
          }).toList();
        } else {
          throw Exception('Unexpected response format');
        }
        return urls;
      } else {
        final error = json.decode(responseBody);
        throw Exception(error['detail'] ?? 'Failed to upload images: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error uploading images to backend: $e');
      rethrow;
    }
  }

  // Upload story media (image or video) directly to Cloudinary
  Future<Map<String, dynamic>> uploadStoryMedia(XFile mediaFile) async {
    try {
      final cloudinaryService = CloudinaryService();
      
      // Check if Cloudinary is configured
      if (!cloudinaryService.isConfigured) {
        if (kDebugMode) {
          print('⚠️ Cloudinary not configured, falling back to backend upload');
        }
        return await _uploadStoryMediaToBackend(mediaFile);
      }
      
      final isVideo = mediaFile.name.toLowerCase().endsWith('.mp4') ||
          mediaFile.name.toLowerCase().endsWith('.mov') ||
          mediaFile.name.toLowerCase().endsWith('.avi');
      
      print('☁️ Uploading story ${isVideo ? "video" : "image"} directly to Cloudinary: ${mediaFile.name}...');
      
      if (isVideo) {
        // Upload video to Cloudinary
        final result = await cloudinaryService.uploadVideo(
          mediaFile,
          folder: AppConstants.cloudinaryStoriesFolder,
        );
        
        print('✅ Successfully uploaded video to Cloudinary');
        return {
          'url': result['url']!,
          'thumbnail_url': result['thumbnail_url']!,
          'media_type': 'video',
        };
      } else {
        // Upload image to Cloudinary
        final url = await cloudinaryService.uploadImage(
          mediaFile,
          folder: AppConstants.cloudinaryStoriesFolder,
          maxWidth: 1080,
          maxHeight: 1920, // Story format
          quality: 85,
        );
        
        print('✅ Successfully uploaded image to Cloudinary');
        return {
          'url': url,
          'media_type': 'image',
        };
      }
    } catch (e) {
      print('❌ Error uploading story media to Cloudinary: $e');
      // Fallback to backend upload on error
      if (kDebugMode) {
        print('⚠️ Falling back to backend upload');
      }
      return await _uploadStoryMediaToBackend(mediaFile);
    }
  }

  // Fallback: Upload story media to backend (old method)
  Future<Map<String, dynamic>> _uploadStoryMediaToBackend(XFile mediaFile) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;
      
      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      final uri = Uri.parse('$baseUrl/api/uploads/upload-story-media');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      String contentType = 'image/jpeg';
      if (mediaFile.name.toLowerCase().endsWith('.mp4') || 
          mediaFile.name.toLowerCase().endsWith('.mov') ||
          mediaFile.name.toLowerCase().endsWith('.avi')) {
        contentType = 'video/mp4';
      } else if (mediaFile.name.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      }
      
      final bytes = await mediaFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: mediaFile.name,
        contentType: MediaType.parse(contentType),
      );
      request.files.add(multipartFile);
      
      final response = await request.send().timeout(
        const Duration(seconds: 180),
        onTimeout: () {
          throw Exception('Upload timeout after 180 seconds.');
        },
      );
      
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 201) {
        final data = json.decode(responseBody);
        return {
          'url': data['url'],
          'media_type': data['media_type'],
        };
      } else {
        final error = json.decode(responseBody);
        throw Exception(error['detail'] ?? 'Failed to upload story media: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error uploading story media to backend: $e');
      rethrow;
    }
  }

  // Create a new product
  Future<Map<String, dynamic>> createProduct({
    required String title,
    required String description,
    double? price,
    String? currency,
    required String category,
    String? unitType,
    int? stockQuantity,
    bool isWingaEnabled = false,
    bool hasWarranty = false,
    bool isPrivate = false,
    bool isAdultContent = false,
    List<String> images = const [],
    String? imageUrl,
    List<String> tags = const [],
    // Auction fields
    bool isAuction = false,
    double? startingPrice,
    double? bidIncrement,
    int? auctionDurationMinutes,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize(); // Ensure auth state is loaded
      final token = authService.authToken;
      
      print('🔐 Auth check for product creation:');
      print('   Is authenticated: ${authService.isAuthenticated}');
      print('   Has token: ${token != null}');
      print('   Token (first 20 chars): ${token != null ? token.substring(0, token.length > 20 ? 20 : token.length) : "null"}...');
      
      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      final uri = Uri.parse('$baseUrl/api/products');
      
      final body = {
        'title': title,
        'description': description,
        'category': category,
        if (images.isNotEmpty) 'images': images, // Only include if not empty
        'tags': tags,
        'is_winga_enabled': isWingaEnabled,
        'has_warranty': hasWarranty,
        'is_private': isPrivate,
        'is_adult_content': isAdultContent,
        'is_auction': isAuction,
        if (unitType != null) 'unit_type': unitType,
        if (stockQuantity != null) 'stock_quantity': stockQuantity,
        if (imageUrl != null) 'image_url': imageUrl,
        // Regular product fields
        if (!isAuction && price != null) 'price': price,
        if (!isAuction && currency != null) 'currency': currency,
        // Auction fields - send minutes directly, backend will handle conversion
        if (isAuction && startingPrice != null) 'starting_price': startingPrice,
        if (isAuction && bidIncrement != null) 'bid_increment': bidIncrement,
        if (isAuction && auctionDurationMinutes != null) 'auction_duration_minutes': auctionDurationMinutes,
      };

      print('Creating product: $uri');
      print('Request body: ${json.encode(body)}');
      print('Authorization header: Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...');

      // Optimized for faster product creation - single attempt with reasonable timeout
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 20), // Reduced timeout for faster failure detection
        onTimeout: () {
          throw Exception('Request timeout. Backend may be waking up from sleep.');
        },
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'product': data,
        };
      } else {
        // Try to parse error message
        try {
          final error = json.decode(response.body);
          final errorMessage = error['detail'] ?? 
                              error['message'] ?? 
                              error['error'] ?? 
                              'Failed to create product: ${response.statusCode}';
          throw Exception(errorMessage);
        } catch (e) {
          // If JSON parsing fails, use raw response
          throw Exception('Failed to create product: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('Error creating product: $e');
      rethrow;
    }
  }

  // Update an existing product
  Future<Map<String, dynamic>> updateProduct({
    required int productId,
    String? title,
    String? description,
    double? price,
    String? currency,
    String? category,
    String? unitType,
    int? stockQuantity,
    bool? isWingaEnabled,
    bool? hasWarranty,
    bool? isPrivate,
    bool? isAdultContent,
    List<String>? images,
    String? imageUrl,
    List<String>? tags,
    // Auction fields
    double? startingPrice,
    double? bidIncrement,
    int? auctionDurationMinutes,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;
      
      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      final uri = Uri.parse('$baseUrl/api/products/$productId');
      
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (category != null) body['category'] = category;
      if (images != null) body['images'] = images;
      if (tags != null) body['tags'] = tags;
      if (isWingaEnabled != null) body['is_winga_enabled'] = isWingaEnabled;
      if (hasWarranty != null) body['has_warranty'] = hasWarranty;
      if (isPrivate != null) body['is_private'] = isPrivate;
      if (isAdultContent != null) body['is_adult_content'] = isAdultContent;
      if (unitType != null) body['unit_type'] = unitType;
      if (stockQuantity != null) body['stock_quantity'] = stockQuantity;
      if (imageUrl != null) body['image_url'] = imageUrl;
      if (price != null) body['price'] = price;
      if (currency != null) body['currency'] = currency;
      // Auction fields - send minutes directly, backend will handle conversion
      if (startingPrice != null) body['starting_price'] = startingPrice;
      if (bidIncrement != null) body['bid_increment'] = bidIncrement;
      if (auctionDurationMinutes != null) body['auction_duration_minutes'] = auctionDurationMinutes;

      print('Updating product: $uri');
      print('Request body: ${json.encode(body)}');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 45), // Increased timeout for Render free tier
        onTimeout: () {
          throw Exception('Request timeout. The backend may be waking up from sleep.');
        },
      );

      print('Update product response status: ${response.statusCode}');
      print('Update product response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'product': data,
        };
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to update product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(int productId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      final uri = Uri.parse('$baseUrl/api/products/$productId');
      print('🗑️ Deleting product: $uri');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 45), // Increased timeout for Render free tier
        onTimeout: () {
          throw Exception('Request timeout. The backend may be waking up from sleep.');
        },
      );

      print('🗑️ Delete product response status: ${response.statusCode}');

      if (response.statusCode == 204) {
        print('✅ Product deleted successfully');
        return;
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
        throw Exception(errorBody['detail'] ?? 'Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting product: $e');
      rethrow;
    }
  }

  // Test endpoint connectivity
  Future<Map<String, dynamic>> testEndpoint() async {
    try {
      final uri = Uri.parse('$baseUrl/get_products');
      print('Testing endpoint: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'headers': response.headers,
        'body': response.body,
        'bodyLength': response.body.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Auction methods
  Future<List<Map<String, dynamic>>> getActiveAuctions({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      final uri = Uri.parse('$baseUrl/api/auctions/active').replace(queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
      });

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 45), // Increased timeout for Render free tier
        onTimeout: () {
          throw Exception('Request timeout. The backend may be waking up from sleep.');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
        throw Exception(errorBody['detail'] ?? 'Failed to get active auctions');
      }
    } catch (e) {
      print('Error getting active auctions: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAuctionDetails(int productId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      final uri = Uri.parse('$baseUrl/api/auctions/$productId');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 45), // Increased timeout for Render free tier
        onTimeout: () {
          throw Exception('Request timeout. The backend may be waking up from sleep.');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
        throw Exception(errorBody['detail'] ?? 'Failed to get auction details');
      }
    } catch (e) {
      print('Error getting auction details: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAuctionBids(
    int productId, {
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/auctions/$productId/bids').replace(queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 45), // Increased timeout for Render free tier
        onTimeout: () {
          throw Exception('Request timeout. The backend may be waking up from sleep.');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
        throw Exception(errorBody['detail'] ?? 'Failed to get auction bids');
      }
    } catch (e) {
      print('Error getting auction bids: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> placeBid(int productId, double bidAmount) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      final uri = Uri.parse('$baseUrl/api/auctions/$productId/bid');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bid_amount': bidAmount,
        }),
      ).timeout(
        const Duration(seconds: 45), // Increased timeout for Render free tier
        onTimeout: () {
          throw Exception('Request timeout. The backend may be waking up from sleep. Please try again.');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
        throw Exception(errorBody['detail'] ?? 'Failed to place bid');
      }
    } catch (e) {
      print('Error placing bid: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeAuctionPayment(
    int productId, {
    bool includeShipping = false,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      final uri = Uri.parse('$baseUrl/api/auctions/$productId/complete-payment').replace(
        queryParameters: {
          'include_shipping': includeShipping.toString(),
        },
      );

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 45), // Increased timeout for Render free tier
        onTimeout: () {
          throw Exception('Request timeout. The backend may be waking up from sleep.');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
        throw Exception(errorBody['detail'] ?? 'Failed to complete payment');
      }
    } catch (e) {
      print('Error completing auction payment: $e');
      rethrow;
    }
  }
}


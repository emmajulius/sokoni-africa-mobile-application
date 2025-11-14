import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class ProductEngagementService {
  final String baseUrl = AppConstants.baseUrl;
  final AuthService _authService = AuthService();

  // Like a product
  Future<Map<String, dynamic>> likeProduct(int productId) async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || _authService.authToken == null) {
        throw Exception('User must be authenticated to like products');
      }

      final uri = Uri.parse('$baseUrl/api/products/$productId/like');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to like product');
      }
    } catch (e) {
      print('Error liking product: $e');
      rethrow;
    }
  }

  // Unlike a product
  Future<Map<String, dynamic>> unlikeProduct(int productId) async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || _authService.authToken == null) {
        throw Exception('User must be authenticated to unlike products');
      }

      final uri = Uri.parse('$baseUrl/api/products/$productId/like');
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to unlike product');
      }
    } catch (e) {
      print('Error unliking product: $e');
      rethrow;
    }
  }

  // Get product comments
  Future<List<Map<String, dynamic>>> getProductComments(int productId, {int skip = 0, int limit = 50}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/products/$productId/comments?skip=$skip&limit=$limit');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> comments = json.decode(response.body);
        return comments.cast<Map<String, dynamic>>();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to fetch comments');
      }
    } catch (e) {
      print('Error fetching comments: $e');
      rethrow;
    }
  }

  // Add a comment
  Future<Map<String, dynamic>> addComment(int productId, String content) async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || _authService.authToken == null) {
        throw Exception('User must be authenticated to comment');
      }

      final uri = Uri.parse('$baseUrl/api/products/$productId/comments');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_authService.authToken}',
        },
        body: json.encode({'content': content}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to add comment');
      }
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  // Rate a product
  Future<Map<String, dynamic>> rateProduct(int productId, double rating) async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || _authService.authToken == null) {
        throw Exception('User must be authenticated to rate products');
      }

      if (rating < 1.0 || rating > 5.0) {
        throw Exception('Rating must be between 1.0 and 5.0');
      }

      final uri = Uri.parse('$baseUrl/api/products/$productId/rating');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_authService.authToken}',
        },
        body: json.encode({'rating': rating}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to rate product');
      }
    } catch (e) {
      print('Error rating product: $e');
      rethrow;
    }
  }

  // Check if product is liked by current user
  Future<bool> isProductLiked(int productId) async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || _authService.authToken == null) {
        return false;
      }

      // Fetch product details which includes is_liked status
      final uri = Uri.parse('$baseUrl/api/products/$productId');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Note: We'll need to add is_liked to ProductResponse schema
        // For now, return false
        return false;
      }
      return false;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }
}


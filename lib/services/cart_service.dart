import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_item_model.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final String baseUrl = AppConstants.baseUrl;

  // Get cart items
  Future<List<CartItemModel>> getCartItems() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/cart');
      
      print('🛒 Fetching cart items from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('🛒 Cart response status: ${response.statusCode}');
      print('🛒 Cart response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> cartItemsList = data is List ? data : [];
        
        return cartItemsList
            .map((json) => CartItemModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to load cart items');
      }
    } catch (e) {
      print('❌ Error fetching cart items: $e');
      rethrow;
    }
  }

  // Add item to cart
  Future<CartItemModel> addToCart({
    required int productId,
    int quantity = 1,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/cart');
      
      final body = {
        'product_id': productId,
        'quantity': quantity,
      };

      print('🛒 Adding to cart: $body');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('🛒 Add to cart response status: ${response.statusCode}');
      print('🛒 Add to cart response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return CartItemModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to add item to cart');
      }
    } catch (e) {
      print('❌ Error adding to cart: $e');
      rethrow;
    }
  }

  // Update cart item quantity
  Future<CartItemModel> updateCartItem({
    required int itemId,
    required int quantity,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/cart/$itemId');
      
      print('🛒 Updating cart item $itemId with quantity $quantity');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'quantity': quantity}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('🛒 Update cart item response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null) {
          // Item was removed (quantity <= 0)
          throw Exception('Item removed from cart');
        }
        return CartItemModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to update cart item');
      }
    } catch (e) {
      print('❌ Error updating cart item: $e');
      rethrow;
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(int itemId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/cart/$itemId');
      
      print('🛒 Removing cart item $itemId');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('🛒 Remove cart item response status: ${response.statusCode}');

      if (response.statusCode != 204) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to remove item from cart');
      }
    } catch (e) {
      print('❌ Error removing cart item: $e');
      rethrow;
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/cart');
      
      print('🛒 Clearing cart');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('🛒 Clear cart response status: ${response.statusCode}');

      if (response.statusCode != 204) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to clear cart');
      }
    } catch (e) {
      print('❌ Error clearing cart: $e');
      rethrow;
    }
  }
}


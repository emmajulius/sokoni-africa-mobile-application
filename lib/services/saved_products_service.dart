import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class SavedProductsService {
  static final SavedProductsService _instance = SavedProductsService._internal();
  factory SavedProductsService() => _instance;
  SavedProductsService._internal();

  final String baseUrl = AppConstants.baseUrl;

  // Save a product
  Future<ProductModel> saveProduct(int productId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/saved-products');

      final body = {
        'product_id': productId,
      };

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

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ProductModel.fromJson(data['product']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to save product');
      }
    } catch (e) {
      print('❌ Error saving product: $e');
      rethrow;
    }
  }

  // Get saved products
  Future<List<ProductModel>> getSavedProducts({int skip = 0, int limit = 50}) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/saved-products').replace(
        queryParameters: {
          'skip': skip.toString(),
          'limit': limit.toString(),
        },
      );

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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> savedProductsList = data is List ? data : [];
        return savedProductsList
            .map((json) => ProductModel.fromJson((json as Map<String, dynamic>)['product']))
            .toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to load saved products');
      }
    } catch (e) {
      print('❌ Error fetching saved products: $e');
      rethrow;
    }
  }

  // Unsave a product
  Future<void> unsaveProduct(int productId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/saved-products/$productId');

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

      if (response.statusCode != 204) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to unsave product');
      }
    } catch (e) {
      print('❌ Error unsaving product: $e');
      rethrow;
    }
  }

  // Check if product is saved
  Future<bool> isProductSaved(int productId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        return false;
      }

      final uri = Uri.parse('$baseUrl/api/saved-products/check/$productId');

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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['is_saved'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error checking saved status: $e');
      return false;
    }
  }
}


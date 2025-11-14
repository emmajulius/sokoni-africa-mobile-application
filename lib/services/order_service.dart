import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final String baseUrl = AppConstants.baseUrl;

  Future<List<OrderModel>> getOrders() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/orders');
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
        final data = json.decode(response.body) as List<dynamic>;
        return data
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to fetch orders');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<OrderModel> createOrder({
    required String shippingAddress,
    String? paymentMethod,
    bool includeShipping = false,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/orders');
      final body = json.encode({
        'shipping_address': shippingAddress,
        'payment_method': paymentMethod ?? 'sokocoin',
        'include_shipping': includeShipping,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return OrderModel.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to create order');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  Future<OrderModel> getOrder(String orderId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/orders/$orderId');
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
        final data = json.decode(response.body) as Map<String, dynamic>;
        return OrderModel.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to fetch order');
      }
    } catch (e) {
      throw Exception('Error fetching order: $e');
    }
  }

  Future<Map<String, dynamic>> getShippingEstimate(int sellerId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/orders/shipping/estimate?seller_id=$sellerId');
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
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to estimate shipping');
      }
    } catch (e) {
      throw Exception('Error estimating shipping: $e');
    }
  }

  Future<List<OrderModel>> getSales() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/orders/sales');
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

      final statusCode = response.statusCode;

      if (statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> ordersJson;

        if (decoded is List) {
          ordersJson = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['orders'] is List) {
            ordersJson = decoded['orders'] as List<dynamic>;
          } else if (decoded['results'] is List) {
            ordersJson = decoded['results'] as List<dynamic>;
          } else if (decoded['data'] is List) {
            ordersJson = decoded['data'] as List<dynamic>;
          } else {
            throw Exception('Unexpected sales response format');
          }
        } else {
          throw Exception('Unexpected sales response format');
        }

        return ordersJson
            .whereType<Map<String, dynamic>>()
            .map(OrderModel.fromJson)
            .toList();
      } else {
        String message = 'Request failed with status $statusCode';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('detail')) {
            message = '${errorData['detail']} (HTTP $statusCode)';
          }
        } catch (_) {
          // Ignore JSON parsing issues and use default message
        }
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Failed to fetch sales: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<OrderModel> updateOrderStatus({
    required int orderId,
    required OrderStatus status,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final statusValue = status.toString().split('.').last;
      final uri = Uri.parse('$baseUrl/api/orders/$orderId/status?new_status=$statusValue');
      final response = await http.put(
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
        final data = json.decode(response.body) as Map<String, dynamic>;
        return OrderModel.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  Future<OrderModel> confirmOrderDelivery({required int orderId}) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/orders/$orderId/confirm-delivery');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return OrderModel.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to confirm delivery');
      }
    } catch (e) {
      throw Exception('Error confirming delivery: $e');
    }
  }
}


import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final String baseUrl = AppConstants.baseUrl;

  Future<Map<String, dynamic>> getSalesAnalytics({String period = 'all'}) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/orders/analytics?period=$period');
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
        throw Exception(errorData['detail'] ?? 'Failed to fetch analytics');
      }
    } catch (e) {
      throw Exception('Error fetching analytics: $e');
    }
  }
}


import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallet_model.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final String baseUrl = AppConstants.baseUrl;

  Future<WalletModel> getWalletBalance() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/wallet/balance');
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
        return WalletModel.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to fetch wallet balance');
      }
    } catch (e) {
      throw Exception('Error fetching wallet balance: $e');
    }
  }

  Future<List<WalletTransactionModel>> getTransactions({
    int skip = 0,
    int limit = 20,
    WalletTransactionType? transactionType,
    WalletTransactionStatus? status,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      if (transactionType != null) {
        queryParams['transaction_type'] = transactionType.name;
      }

      if (status != null) {
        queryParams['status'] = status.name;
      }

      final uri = Uri.parse('$baseUrl/api/wallet/transactions')
          .replace(queryParameters: queryParams);

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
            .map((json) => WalletTransactionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to fetch transactions');
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  Future<Map<String, dynamic>> initializeTopup({
    required double amount,
    String currency = 'TZS',
    String paymentMethod = 'card',
    String? phoneNumber,
    String? email,
    String? fullName,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/wallet/topup/initialize');
      final body = json.encode({
        'amount': amount,
        'currency': currency,
        'payment_method': paymentMethod,
        'phone_number': phoneNumber,
        'email': email,
        'full_name': fullName,
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
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        // Try to parse error response
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['detail'] ?? 
                              errorData['message'] ?? 
                              'Failed to initialize topup';
          throw Exception(errorMessage);
        } catch (e) {
          // If response body is not valid JSON, use status code
          throw Exception('Failed to initialize topup: HTTP ${response.statusCode}');
        }
      }
    } catch (e) {
      // Provide more detailed error information
      if (e.toString().contains('Failed to fetch') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        throw Exception('Unable to connect to server. Please check your internet connection.');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Request timeout. Please try again.');
      } else if (e.toString().contains('500')) {
        throw Exception('Server error. Flutterwave API keys may not be configured.');
      }
      throw Exception('Error initializing topup: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> verifyTopup(int transactionId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/wallet/topup/verify/$transactionId');
      final response = await http.post(
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
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to verify topup');
      }
    } catch (e) {
      throw Exception('Error verifying topup: $e');
    }
  }

  Future<Map<String, dynamic>> initiateCashout({
    required double sokocoinAmount,
    required String payoutMethod,
    required String payoutAccount,
    String currency = 'TZS',
    String? fullName,
    String? bankName,
    String? accountName,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/wallet/cashout');
      final body = json.encode({
        'sokocoin_amount': sokocoinAmount,
        'payout_method': payoutMethod,
        'payout_account': payoutAccount,
        'currency': currency,
        'full_name': fullName,
        'bank_name': bankName,
        'account_name': accountName,
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
          throw Exception('Request timeout while contacting Flutterwave');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to initiate cashout');
      }
    } catch (e) {
      final message = e.toString();
      if (message.contains('Request timeout')) {
        throw Exception('Cashout request is taking longer than expected. Please wait a moment and verify your wallet balance.');
      }
      if (message.contains('Failed to fetch') ||
          message.contains('Connection refused') ||
          message.contains('SocketException')) {
        throw Exception('Unable to reach the server. Please check your internet connection.');
      }
      throw Exception('Error initiating cashout: $message');
    }
  }

  Future<List<dynamic>> getBanks(String country) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/wallet/banks/$country');
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
        if (data is Map && data.containsKey('data')) {
          return data['data'] as List<dynamic>;
        }
        return data as List<dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to fetch banks');
      }
    } catch (e) {
      throw Exception('Error fetching banks: $e');
    }
  }

  Future<Map<String, dynamic>> cleanupStuckCashouts() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/wallet/cashout/cleanup-stuck');
      final response = await http.post(
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
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to cleanup stuck cashouts');
      }
    } catch (e) {
      throw Exception('Error cleaning up stuck cashouts: $e');
    }
  }

  Future<Map<String, dynamic>> deleteTransaction(int transactionId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/wallet/transactions/$transactionId');
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

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to delete transaction');
      }
    } catch (e) {
      throw Exception('Error deleting transaction: $e');
    }
  }

  Future<Map<String, dynamic>> deleteAllTransactions() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('$baseUrl/api/wallet/transactions');
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

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to delete transactions');
      }
    } catch (e) {
      throw Exception('Error deleting transactions: $e');
    }
  }
}


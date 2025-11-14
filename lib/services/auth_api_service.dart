import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/http_exception.dart';

class AuthApiService {
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;
  AuthApiService._internal();

  final String baseUrl = AppConstants.baseUrl;

  // Login with username/email/phone and password
  Future<Map<String, dynamic>> login({
    String? username,
    String? email,
    String? phone,
    String? password,
    String? google_token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/login');
      
      final body = <String, dynamic>{};
      
      if (username != null) body['username'] = username;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (password != null) body['password'] = password;
      if (google_token != null) body['google_token'] = google_token;
      
      debugPrint('🔐 ========== LOGIN REQUEST ==========');
      debugPrint('🔐 Login request: $uri');
      debugPrint('🔐 Body keys: ${body.keys.join(", ")}');
      if (google_token != null) {
        debugPrint('🔐 Google token length: ${google_token.length}');
        debugPrint('🔐 Google token preview: ${google_token.substring(0, google_token.length > 50 ? 50 : google_token.length)}...');
      } else {
        debugPrint('🔐 No Google token provided');
      }
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      debugPrint('🔐 ========== LOGIN RESPONSE ==========');
      debugPrint('🔐 Login response status: ${response.statusCode}');
      debugPrint('🔐 Login response body length: ${response.body.length}');
      debugPrint('🔐 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        String errorMessage = 'Login failed';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMessage = errorData['detail'].toString();
          } else {
            errorMessage = 'Login failed with status ${response.statusCode}';
          }
        } catch (e) {
          errorMessage = 'Login failed with status ${response.statusCode}';
        }
        // Create an exception with status code info for better error handling
        throw HttpException(
          errorMessage,
          statusCode: response.statusCode,
          errorMessage: errorMessage,
        );
      }
    } catch (e) {
      print('❌ Error logging in: $e');
      rethrow;
    }
  }

  // Register new user with email, phone, username, password
  Future<Map<String, dynamic>> register({
    required String username,
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? userType,
    String? gender,
    String? googleId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/register');
      
      final body = {
        'username': username,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        if (userType != null) 'user_type': userType,
        if (gender != null) 'gender': gender,
        if (googleId != null) 'google_id': googleId,
      };
      
      print('📝 Register request: $uri');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📝 Register response status: ${response.statusCode}');
      print('📝 Register response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      print('❌ Error registering: $e');
      rethrow;
    }
  }

  // Send OTP to phone number
  Future<Map<String, dynamic>> sendOTP(String phone) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/send-otp');
      
      print('📱 Sending OTP request to: $uri');
      print('📱 Phone number: $phone');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'phone': phone}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - Check if backend is running');
        },
      );

      print('📱 Response status: ${response.statusCode}');
      print('📱 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      print('❌ Error sending OTP: $e');
      print('❌ URL attempted: $baseUrl/api/auth/send-otp');
      rethrow;
    }
  }

  // Verify OTP code
  Future<Map<String, dynamic>> verifyOTP(String phone, String code) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/verify-otp');
      
      print('🔐 Verifying OTP...');
      print('📱 Phone: $phone');
      print('🔑 Code: $code');
      print('🌐 URL: $uri');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'phone': phone,
          'code': code,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - Check if backend is running');
        },
      );

      print('📱 Verification Response status: ${response.statusCode}');
      print('📱 Verification Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['detail'] ?? 'Invalid OTP code';
        print('❌ Verification error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      print('❌ URL attempted: $baseUrl/api/auth/verify-otp');
      rethrow;
    }
  }

  // Register user with phone (after OTP verification)
  Future<Map<String, dynamic>> registerWithPhone({
    required String phone,
    required String username,
    required String fullName,
    String? email,
    String? password,
    String? userType,
    String? gender,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/register-with-phone');
      
      final body = {
        'phone': phone,
        'username': username,
        'full_name': fullName,
        if (email != null) 'email': email,
        if (password != null) 'password': password,
        if (userType != null) 'user_type': userType,
        if (gender != null) 'gender': gender,
      };
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - Check if backend is running');
        },
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getCurrentUserProfile(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/me');
      
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
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String token,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? gender,
    String? profileImage,
    String? locationAddress,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/me');
      
      final body = <String, dynamic>{};
      if (username != null) body['username'] = username;
      if (fullName != null) body['full_name'] = fullName;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (gender != null) body['gender'] = gender;
      if (profileImage != null) body['profile_image'] = profileImage;
      if (locationAddress != null) body['location_address'] = locationAddress;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      
      print('📝 Updating user profile: $body');
      
      final response = await http.put(
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

      print('📝 Update profile response status: ${response.statusCode}');
      print('📝 Update profile response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Forgot password - send OTP
  Future<Map<String, dynamic>> forgotPassword(String phone) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/forgot-password');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'phone': phone}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      print('❌ Error sending forgot password OTP: $e');
      rethrow;
    }
  }

  // Forgot password via email
  Future<Map<String, dynamic>> forgotPasswordByEmail(String email) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/forgot-password-email');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to send reset email');
      }
    } catch (e) {
      print('❌ Error sending password reset email: $e');
      if (e.toString().contains('Not Found')) {
        throw Exception('Email reset endpoint not available on server');
      }
      rethrow;
    }
  }

  // Reset password after OTP verification
  Future<Map<String, dynamic>> resetPassword({
    String? phone,
    String? email,
    required String code,
    required String newPassword,
  }) async {
    try {
      if (phone == null && email == null) {
        throw Exception('Either phone or email must be provided');
      }
      final uri = Uri.parse('$baseUrl/api/auth/reset-password');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          'code': code,
          'new_password': newPassword,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to reset password');
      }
    } catch (e) {
      print('❌ Error resetting password: $e');
      rethrow;
    }
  }

  // Login as guest
  Future<Map<String, dynamic>> loginAsGuest({String userType = 'client'}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/guest').replace(
        queryParameters: {'user_type': userType},
      );
      
      print('👤 Guest login request: $uri');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('👤 Guest login response status: ${response.statusCode}');
      print('👤 Guest login response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to login as guest');
      }
    } catch (e) {
      print('❌ Error logging in as guest: $e');
      rethrow;
    }
  }

}


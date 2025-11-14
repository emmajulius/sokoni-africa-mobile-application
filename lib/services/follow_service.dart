import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class FollowService {
  final String baseUrl = AppConstants.baseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> followUser(int userId) async {
    await _authService.initialize();
    if (!_authService.isAuthenticated || _authService.authToken == null) {
      throw Exception('User not authenticated');
    }

    final uri = Uri.parse('$baseUrl/api/users/$userId/follow');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${_authService.authToken}',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to follow user');
    }
  }

  Future<Map<String, dynamic>> unfollowUser(int userId) async {
    await _authService.initialize();
    if (!_authService.isAuthenticated || _authService.authToken == null) {
      throw Exception('User not authenticated');
    }

    final uri = Uri.parse('$baseUrl/api/users/$userId/follow');
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${_authService.authToken}',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to unfollow user');
    }
  }

  Future<bool> checkIfFollowing(int userId) async {
    await _authService.initialize();
    if (!_authService.isAuthenticated || _authService.isGuest || _authService.authToken == null) {
      return false;
    }

    final uri = Uri.parse('$baseUrl/api/users/$userId/is-following');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${_authService.authToken}',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['is_following'] ?? false;
    } else {
      return false;
    }
  }

  Future<bool> checkIfFollowsYou(int userId) async {
    await _authService.initialize();
    if (!_authService.isAuthenticated || _authService.isGuest || _authService.authToken == null) {
      return false;
    }

    final uri = Uri.parse('$baseUrl/api/users/$userId/follows-you');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${_authService.authToken}',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['follows_you'] ?? false;
    } else {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getFollowers(int userId) async {
    await _authService.initialize();
    if (!_authService.isAuthenticated || _authService.authToken == null) {
      throw Exception('User not authenticated');
    }

    final uri = Uri.parse('$baseUrl/api/users/$userId/followers');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${_authService.authToken}',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> followersList = data['followers'] ?? [];
      return followersList.map((f) => f as Map<String, dynamic>).toList();
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to fetch followers');
    }
  }
}


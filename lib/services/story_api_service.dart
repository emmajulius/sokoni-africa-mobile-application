import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class StoryApiService {
  static final StoryApiService _instance = StoryApiService._internal();
  factory StoryApiService() => _instance;
  StoryApiService._internal();

  final String baseUrl = AppConstants.baseUrl;

  // Get all active stories
  Future<List<Map<String, dynamic>>> getStories({int skip = 0, int limit = 50}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/stories').replace(
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
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> storiesList = data is List ? data : [];
        return storiesList.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load stories: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching stories: $e');
      rethrow;
    }
  }

  // Create a story
  Future<Map<String, dynamic>> createStory({
    required String mediaUrl,
    required String mediaType,
    String? caption,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/stories');

      final body = {
        'media_url': mediaUrl,
        'media_type': mediaType,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
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
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to create story');
      }
    } catch (e) {
      print('❌ Error creating story: $e');
      rethrow;
    }
  }

  // View a story (increment view count)
  Future<Map<String, dynamic>> viewStory(int storyId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/stories/$storyId/view');

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

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body);
        } catch (e) {
          // If response is not valid JSON, return empty map
          return <String, dynamic>{};
        }
      } else {
        // Handle error response - might be JSON or plain text
        try {
          final error = json.decode(response.body);
          throw Exception(error['detail'] ?? error['message'] ?? 'Failed to view story');
        } catch (e) {
          // If error response is not JSON (e.g., "Internal Server Error"), just log it
          // Don't throw - viewing story is not critical, story still displays
          if (kDebugMode) {
            print('⚠️ Story view endpoint returned non-JSON error (${response.statusCode}): ${response.body}');
          }
          // Return empty map to indicate failure but don't crash
          return <String, dynamic>{};
        }
      }
    } catch (e) {
      // Silently handle errors - viewing story is not critical
      if (kDebugMode) {
        print('❌ Error viewing story: $e');
      }
      // Return empty map instead of rethrowing - story still displays
      return <String, dynamic>{};
    }
  }

  // Delete a story (only owner can delete)
  Future<void> deleteStory(int storyId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/stories/$storyId');

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

      if (response.statusCode == 204) {
        // Successfully deleted (204 No Content)
        return;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? error['message'] ?? 'Failed to delete story');
      }
    } catch (e) {
      print('❌ Error deleting story: $e');
      rethrow;
    }
  }
}


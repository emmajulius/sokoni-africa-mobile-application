import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class NotificationModel {
  final int id;
  final int userId;
  final String notificationType;
  final String title;
  final String message;
  final bool isRead;
  final int? relatedUserId;
  final int? relatedProductId;
  final int? relatedOrderId;
  final int? relatedConversationId;
  final String? relatedUserUsername;
  final String? relatedUserProfileImage;
  final String? relatedProductTitle;
  final String? relatedProductImage;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.isRead,
    this.relatedUserId,
    this.relatedProductId,
    this.relatedOrderId,
    this.relatedConversationId,
    this.relatedUserUsername,
    this.relatedUserProfileImage,
    this.relatedProductTitle,
    this.relatedProductImage,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      notificationType: json['notification_type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool,
      relatedUserId: json['related_user_id'] as int?,
      relatedProductId: json['related_product_id'] as int?,
      relatedOrderId: json['related_order_id'] as int?,
      relatedConversationId: json['related_conversation_id'] as int?,
      relatedUserUsername: json['related_user_username'] as String?,
      relatedUserProfileImage: json['related_user_profile_image'] as String?,
      relatedProductTitle: json['related_product_title'] as String?,
      relatedProductImage: json['related_product_image'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class NotificationService {
  final String baseUrl = AppConstants.baseUrl;
  final AuthService _authService = AuthService();

  Future<List<NotificationModel>> getNotifications({
    int skip = 0,
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || _authService.authToken == null) {
        throw Exception('User must be authenticated to get notifications');
      }

      final queryParams = {
        'skip': skip.toString(),
        'limit': limit.toString(),
        if (unreadOnly) 'unread_only': 'true',
      };
      final queryString = Uri(queryParameters: queryParams).query;
      final uri = Uri.parse('$baseUrl/api/notifications?$queryString');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> notificationsJson = json.decode(response.body);
        return notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to fetch notifications');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || _authService.authToken == null) {
        return 0;
      }

      final uri = Uri.parse('$baseUrl/api/notifications/unread-count');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unread_count'] as int? ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || _authService.authToken == null) {
        throw Exception('User must be authenticated to mark notification as read');
      }

      final uri = Uri.parse('$baseUrl/api/notifications/$notificationId/read');
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to mark notification as read');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || _authService.authToken == null) {
        throw Exception('User must be authenticated to mark all notifications as read');
      }

      final uri = Uri.parse('$baseUrl/api/notifications/read-all');
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to mark all notifications as read');
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || _authService.authToken == null) {
        throw Exception('User must be authenticated to delete notification');
      }

      final uri = Uri.parse('$baseUrl/api/notifications/$notificationId');
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 204) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to delete notification');
      }
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  Future<int> deleteAllNotifications() async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || _authService.authToken == null) {
        throw Exception('User must be authenticated to delete all notifications');
      }

      final uri = Uri.parse('$baseUrl/api/notifications');
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_authService.authToken}',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['deleted_count'] as int? ?? 0;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to delete all notifications');
      }
    } catch (e) {
      print('Error deleting all notifications: $e');
      rethrow;
    }
  }
}


import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class MessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderUsername;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      senderId: json['sender_id'] as int,
      senderUsername: json['sender_username'] as String,
      content: json['content'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ConversationModel {
  final int id;
  final int user1Id;
  final int user2Id;
  final String user1Username;
  final String user2Username;
  final String? user1ProfileImage;
  final String? user2ProfileImage;
  final MessageModel? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.user1Username,
    required this.user2Username,
    this.user1ProfileImage,
    this.user2ProfileImage,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as int,
      user1Id: json['user1_id'] as int,
      user2Id: json['user2_id'] as int,
      user1Username: json['user1_username'] as String,
      user2Username: json['user2_username'] as String,
      user1ProfileImage: json['user1_profile_image'] as String?,
      user2ProfileImage: json['user2_profile_image'] as String?,
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String getOtherUsername(int currentUserId) {
    return user1Id == currentUserId ? user2Username : user1Username;
  }

  String? getOtherProfileImage(int currentUserId) {
    return user1Id == currentUserId ? user2ProfileImage : user1ProfileImage;
  }

  int getOtherUserId(int currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }
}

class MessagesService {
  static final MessagesService _instance = MessagesService._internal();
  factory MessagesService() => _instance;
  MessagesService._internal();

  final String baseUrl = AppConstants.baseUrl;

  // Get all conversations
  Future<List<ConversationModel>> getConversations() async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/messages/conversations');

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
        final List<dynamic> conversationsList = data is List ? data : [];
        return conversationsList
            .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to load conversations');
      }
    } catch (e) {
      print('❌ Error fetching conversations: $e');
      rethrow;
    }
  }

  // Get messages in a conversation
  Future<List<MessageModel>> getMessages(int conversationId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/messages/conversations/$conversationId/messages');

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
        final List<dynamic> messagesList = data is List ? data : [];
        return messagesList
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to load messages');
      }
    } catch (e) {
      print('❌ Error fetching messages: $e');
      rethrow;
    }
  }

  // Send a message
  Future<MessageModel> sendMessage({
    required String content,
    int? conversationId,
    int? recipientId,
  }) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      if (conversationId == null && recipientId == null) {
        throw Exception('Either conversationId or recipientId must be provided');
      }

      final uri = Uri.parse('$baseUrl/api/messages/messages');

      final body = {
        'content': content,
        if (conversationId != null) 'conversation_id': conversationId,
        if (recipientId != null) 'recipient_id': recipientId,
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
        return MessageModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to send message');
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  // Get or create conversation with a user
  Future<ConversationModel> getConversationWithUser(int userId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/messages/conversations/with/$userId');

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
        return ConversationModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to get conversation');
      }
    } catch (e) {
      print('❌ Error getting conversation: $e');
      rethrow;
    }
  }

  // Delete a single message
  Future<bool> deleteMessage(int messageId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/messages/messages/$messageId');

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

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Message not found. It may have already been deleted.');
      } else if (response.statusCode == 403) {
        throw Exception('You do not have permission to delete this message.');
      } else {
        try {
          final error = json.decode(response.body);
          throw Exception(error['detail'] ?? 'Failed to delete message');
        } catch (_) {
          throw Exception('Failed to delete message. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Error deleting message: $e');
      rethrow;
    }
  }

  // Delete all messages in a conversation
  Future<bool> deleteAllMessages(int conversationId) async {
    try {
      final authService = AuthService();
      await authService.initialize();
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('$baseUrl/api/messages/conversations/$conversationId/messages');

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

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Conversation not found.');
      } else if (response.statusCode == 403) {
        throw Exception('You do not have permission to delete messages in this conversation.');
      } else {
        try {
          final error = json.decode(response.body);
          throw Exception(error['detail'] ?? 'Failed to delete messages');
        } catch (_) {
          throw Exception('Failed to delete messages. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Error deleting all messages: $e');
      rethrow;
    }
  }
}


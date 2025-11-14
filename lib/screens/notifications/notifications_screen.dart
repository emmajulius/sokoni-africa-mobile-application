import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/follow_service.dart';
import '../../services/language_service.dart';
import '../../utils/helpers.dart';
import '../../utils/app_theme.dart';
import '../product/product_detail_screen.dart';
import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../messages/messages_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final FollowService _followService = FollowService();
  final LanguageService _languageService = LanguageService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;
  Timer? _refreshTimer;
  Map<int, bool> _isFollowingMap = {}; // Track follow status for follow notifications
  final Map<int, bool> _isTogglingMap = {}; // Track if we're toggling follow
  final Map<int, bool> _isExpandedMap = {}; // Track which notifications are expanded

  bool _isServerUnavailable = false;
  int _consecutiveErrors = 0;

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_onLanguageChanged);
    _loadNotifications();
    _loadUnreadCount();
    // Refresh notifications every 10 seconds, but only if server is available
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_isServerUnavailable) {
        _loadNotifications();
        _loadUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadNotifications() async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || _authService.isGuest) {
        if (mounted) {
          setState(() {
            _notifications = [];
            _isLoading = false;
          });
        }
        return;
      }

      final notifications = await _notificationService.getNotifications();
      
      // Check follow status for follow notifications
      final followStatusMap = <int, bool>{};
      for (var notification in notifications) {
        if (notification.notificationType == 'follow' && notification.relatedUserId != null) {
          try {
            final isFollowing = await _followService.checkIfFollowing(notification.relatedUserId!);
            followStatusMap[notification.relatedUserId!] = isFollowing;
          } catch (e) {
            print('Error checking follow status: $e');
            followStatusMap[notification.relatedUserId!] = false;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isFollowingMap = followStatusMap;
          _isLoading = false;
          _isServerUnavailable = false;
          _consecutiveErrors = 0;
        });
      }
    } catch (e) {
      _consecutiveErrors++;
      final errorMessage = e.toString();
      final isConnectionError = errorMessage.contains('Failed to fetch') || 
                                errorMessage.contains('ClientException') ||
                                errorMessage.contains('SocketException') ||
                                errorMessage.contains('NetworkException');
      
      // Only log first few errors to avoid spam
      if (_consecutiveErrors <= 3) {
        print('Error loading notifications: $e');
      }
      
      // Mark server as unavailable after multiple consecutive errors
      if (isConnectionError && _consecutiveErrors >= 3) {
        _isServerUnavailable = true;
        // Try again after 30 seconds
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) {
            setState(() {
              _isServerUnavailable = false;
              _consecutiveErrors = 0;
            });
            _loadNotifications();
          }
        });
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Only show error message for first error, not on every retry
        if (_consecutiveErrors == 1 && !isConnectionError) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n?.errorLoadingNotifications ?? 'Error loading notifications'}: ${errorMessage.length > 100 ? "${errorMessage.substring(0, 100)}..." : errorMessage}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated || _authService.isGuest) {
        return;
      }

      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      // Silently handle unread count errors to avoid spam
      // Only log first error
      if (_consecutiveErrors == 0) {
        print('Error loading unread count: $e');
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await _notificationService.markAsRead(notification.id);
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = NotificationModel(
              id: notification.id,
              userId: notification.userId,
              notificationType: notification.notificationType,
              title: notification.title,
              message: notification.message,
              isRead: true,
              relatedUserId: notification.relatedUserId,
              relatedProductId: notification.relatedProductId,
              relatedOrderId: notification.relatedOrderId,
              relatedConversationId: notification.relatedConversationId,
              relatedUserUsername: notification.relatedUserUsername,
              relatedUserProfileImage: notification.relatedUserProfileImage,
              relatedProductTitle: notification.relatedProductTitle,
              relatedProductImage: notification.relatedProductImage,
              createdAt: notification.createdAt,
            );
          }
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        });
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) {
            return NotificationModel(
              id: n.id,
              userId: n.userId,
              notificationType: n.notificationType,
              title: n.title,
              message: n.message,
              isRead: true,
              relatedUserId: n.relatedUserId,
              relatedProductId: n.relatedProductId,
              relatedOrderId: n.relatedOrderId,
              relatedConversationId: n.relatedConversationId,
              relatedUserUsername: n.relatedUserUsername,
              relatedUserProfileImage: n.relatedUserProfileImage,
              relatedProductTitle: n.relatedProductTitle,
              relatedProductImage: n.relatedProductImage,
              createdAt: n.createdAt,
            );
          }).toList();
          _unreadCount = 0;
        });
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n?.errorMarkingAllAsRead ?? 'Error marking all as read'}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.deleteNotification ?? 'Delete Notification'),
        content: Text(l10n?.areYouSureDeleteNotification ?? 'Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _notificationService.deleteNotification(notification.id);
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
          if (!notification.isRead && _unreadCount > 0) {
            _unreadCount--;
          }
        });
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.notificationDeleted ?? 'Notification deleted'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.errorDeletingNotification ?? 'Error deleting notification'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.deleteAllNotifications ?? 'Delete All Notifications'),
        content: Text(l10n != null 
          ? l10n.areYouSureDeleteAllNotifications.replaceAll('{count}', _notifications.length.toString())
          : 'Are you sure you want to delete all ${_notifications.length} notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n?.deleteAll ?? 'Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final deletedCount = await _notificationService.deleteAllNotifications();
      if (mounted) {
        setState(() {
          _notifications = [];
          _unreadCount = 0;
        });
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n != null
              ? l10n.deletedNotificationsCount.replaceAll('{count}', deletedCount.toString())
              : 'Deleted $deletedCount notification(s)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.errorDeletingNotifications ?? 'Error deleting notifications'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    await _markAsRead(notification);

    // Navigate based on notification type
    if (notification.notificationType == 'like' || 
        notification.notificationType == 'comment' || 
        notification.notificationType == 'rating') {
      if (notification.relatedProductId != null) {
        try {
          final apiService = ApiService();
          final productData = await apiService.getProduct(notification.relatedProductId!);
          final product = ProductModel.fromJson(productData);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(product: product),
              ),
            );
          }
        } catch (e) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n?.errorLoadingProduct ?? 'Error loading product'}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (notification.notificationType == 'message') {
      if (notification.relatedConversationId != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MessagesScreen(),
            ),
          );
        }
      } else if (notification.relatedUserId != null) {
        if (mounted) {
          final builderL10n = AppLocalizations.of(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessagesScreen(
                sellerId: notification.relatedUserId.toString(),
                sellerName: notification.relatedUserUsername ?? (builderL10n?.user ?? 'User'),
              ),
            ),
          );
        }
      }
    } else if (notification.notificationType == 'follow') {
      // Don't navigate, just mark as read - actions are shown in the notification item
      await _markAsRead(notification);
    }
    // Add more navigation cases for other notification types (order, etc.)
  }

  Future<void> _handleFollowBack(int userId, String username) async {
    if (_isTogglingMap[userId] == true) return;

    await _authService.initialize();
    if (!_authService.isAuthenticated || _authService.isGuest) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.pleaseSignInToFollowUsers ?? 'Please sign in to follow users'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTogglingMap[userId] = true;
    });

    try {
      final wasFollowing = _isFollowingMap[userId] ?? false;

      // Optimistically update UI
      setState(() {
        _isFollowingMap[userId] = !wasFollowing;
      });

      try {
        if (wasFollowing) {
          await _followService.unfollowUser(userId);
        } else {
          await _followService.followUser(userId);
        }
      } catch (e) {
        // Revert on error
        setState(() {
          _isFollowingMap[userId] = wasFollowing;
        });

        final errorMessage = e.toString();
        if (errorMessage.contains('already following')) {
          try {
            await _followService.unfollowUser(userId);
            setState(() {
              _isFollowingMap[userId] = false;
            });
          } catch (e2) {
            throw Exception('Failed to toggle follow: $e2');
          }
        } else if (errorMessage.contains('not following')) {
          try {
            await _followService.followUser(userId);
            setState(() {
              _isFollowingMap[userId] = true;
            });
          } catch (e2) {
            throw Exception('Failed to toggle follow: $e2');
          }
        } else {
          rethrow;
        }
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowingMap[userId]! 
              ? (l10n != null ? l10n.youAreNowFollowing.replaceAll('{username}', username) : 'You are now following $username')
              : (l10n != null ? l10n.youUnfollowed.replaceAll('{username}', username) : 'You unfollowed $username')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.failedToFollow ?? 'Failed to follow'}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingMap[userId] = false;
        });
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'rating':
        return Icons.star;
      case 'message':
        return Icons.message;
      case 'order':
        return Icons.shopping_bag;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'rating':
        return Colors.orange;
      case 'message':
        return Colors.green;
      case 'order':
        return Colors.purple;
      case 'follow':
        return Colors.teal;
      default:
        return AppTheme.primaryColor;
    }
  }

  Widget _buildExpandableMessage(NotificationModel notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _isExpandedMap[notification.id] ?? false;
    final message = notification.message;
    
    // Check if message needs truncation (roughly 100 characters for 2 lines on small screens)
    final needsTruncation = message.length > 100;
    
    if (!needsTruncation) {
      // Message is short, no need for expand/collapse
      return Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
          maxLines: isExpanded ? null : 2,
          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpandedMap[notification.id] = !isExpanded;
            });
          },
          child: Text(
            isExpanded 
              ? (AppLocalizations.of(context)?.readLess ?? 'Read less')
              : (AppLocalizations.of(context)?.readMore ?? 'Read more'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.blue[900]!, Colors.blue[800]!]
                    : [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 24,
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${_unreadCount > 99 ? '99+' : _unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.notifications ?? 'Notifications',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _unreadCount > 0
                            ? (l10n != null 
                                ? l10n.unreadNotificationsCount.replaceAll('{count}', _unreadCount.toString())
                                : '$_unreadCount unread notification${_unreadCount != 1 ? 's' : ''}')
                            : (l10n?.allCaughtUp ?? 'All caught up!'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_notifications.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: isDark ? Colors.grey[900] : Colors.white,
                    onSelected: (value) {
                      if (value == 'mark_all_read' && _unreadCount > 0) {
                        _markAllAsRead();
                      } else if (value == 'delete_all') {
                        _deleteAllNotifications();
                      }
                    },
                    itemBuilder: (context) => [
                      if (_unreadCount > 0)
                        PopupMenuItem(
                          value: 'mark_all_read',
                          child: Row(
                            children: [
                              Icon(Icons.done_all, size: 20, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                              const SizedBox(width: 8),
                              Text(
                                l10n?.markAllAsRead ?? 'Mark all as read',
                                style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete_all',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(l10n?.deleteAll ?? 'Delete all', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.loadingNotifications ?? 'Loading notifications...',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [Colors.grey[800]!, Colors.grey[700]!]
                                      : [Colors.blue[50]!, Colors.blue[100]!],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: isDark ? Colors.blue[300] : Colors.blue[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              l10n?.noNotificationsYet ?? 'No notifications yet',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n?.youreAllCaughtUp ?? 'You\'re all caught up!',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadNotifications();
                          await _loadUnreadCount();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            final notificationColor = _getNotificationColor(notification.notificationType);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: notification.isRead
                                      ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
                                      : notificationColor.withOpacity(0.5),
                                  width: notification.isRead ? 1 : 2,
                                ),
                              ),
                              color: notification.isRead
                                  ? (isDark ? Colors.grey[900] : Colors.white)
                                  : (isDark
                                      ? notificationColor.withOpacity(0.1)
                                      : notificationColor.withOpacity(0.05)),
                              shadowColor: Colors.black.withOpacity(0.1),
                              child: InkWell(
                                onTap: () => _handleNotificationTap(notification),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Avatar/Icon
                                      Stack(
                                        children: [
                                          if (notification.relatedUserProfileImage != null)
                                            CircleAvatar(
                                              radius: 28,
                                              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                              child: CircleAvatar(
                                                radius: 26,
                                                backgroundImage: CachedNetworkImageProvider(
                                                  notification.relatedUserProfileImage!,
                                                ),
                                              ),
                                            )
                                          else if (notification.relatedProductImage != null)
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(28),
                                                border: Border.all(
                                                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                                  width: 2,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(28),
                                                child: CachedNetworkImage(
                                                  imageUrl: notification.relatedProductImage!,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                                                    child: Center(
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                                                      ),
                                                    ),
                                                  ),
                                                  errorWidget: (context, url, error) => Container(
                                                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: notificationColor.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: notificationColor.withOpacity(0.3),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Icon(
                                                _getNotificationIcon(notification.notificationType),
                                                color: notificationColor,
                                                size: 28,
                                              ),
                                            ),
                                          if (!notification.isRead)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: notificationColor,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isDark ? Colors.grey[900]! : Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notification.title,
                                                    style: TextStyle(
                                                      fontWeight: notification.isRead
                                                          ? FontWeight.w500
                                                          : FontWeight.bold,
                                                      fontSize: 15,
                                                      color: isDark ? Colors.white : Colors.grey[900],
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            _buildExpandableMessage(notification),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 12,
                                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  Helpers.formatRelativeTime(notification.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Actions
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          if (notification.notificationType == 'follow' && notification.relatedUserId != null)
                                            Column(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    gradient: (_isFollowingMap[notification.relatedUserId!] ?? false)
                                                        ? null
                                                        : LinearGradient(
                                                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                                                          ),
                                                    color: (_isFollowingMap[notification.relatedUserId!] ?? false)
                                                        ? (isDark ? Colors.grey[800] : Colors.grey[300])
                                                        : null,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: TextButton(
                                                    onPressed: (_isTogglingMap[notification.relatedUserId!] ?? false)
                                                        ? null
                                                        : () => _handleFollowBack(
                                                              notification.relatedUserId!,
                                                              notification.relatedUserUsername ?? (l10n?.user ?? 'User'),
                                                            ),
                                                    style: TextButton.styleFrom(
                                                      backgroundColor: Colors.transparent,
                                                      shadowColor: Colors.transparent,
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      minimumSize: const Size(0, 32),
                                                    ),
                                                    child: (_isTogglingMap[notification.relatedUserId!] ?? false)
                                                        ? const SizedBox(
                                                            width: 14,
                                                            height: 14,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                            ),
                                                          )
                                                        : Text(
                                                            (_isFollowingMap[notification.relatedUserId!] ?? false)
                                                                ? (l10n?.following ?? 'Following')
                                                                : (l10n?.follow ?? 'Follow'),
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: (_isFollowingMap[notification.relatedUserId!] ?? false)
                                                                  ? (isDark ? Colors.grey[400] : Colors.grey[700])
                                                                  : Colors.white,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                            ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.grey[800] : Colors.red[50],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                              onPressed: () => _deleteNotification(notification),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 32,
                                                minHeight: 32,
                                              ),
                                              tooltip: l10n?.deleteNotification ?? 'Delete notification',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}


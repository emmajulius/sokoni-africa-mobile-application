import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/messages_service.dart';
import '../../services/auth_service.dart';
import 'dart:async';

class MessagesScreen extends StatefulWidget {
  final String? sellerId;
  final String? sellerName;

  const MessagesScreen({
    super.key,
    this.sellerId,
    this.sellerName,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessagesService _messagesService = MessagesService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  List<MessageModel> _messages = [];
  ConversationModel? _conversation;
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    if (widget.sellerId != null) {
      _loadConversation();
    } else {
      _loadConversations(showLoading: true); // Show loading on initial load
    }
    // Refresh messages every 5 seconds (silent refresh, no loading indicator)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (widget.sellerId != null && _conversation != null) {
        _loadMessages();
      } else if (widget.sellerId == null) {
        _loadConversations(showLoading: false); // Silent refresh
      }
    });
  }

  Future<void> _initializeAuth() async {
    await _authService.initialize();
    _currentUserId = int.tryParse(_authService.userId ?? '0');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _authService.initialize();
      final sellerId = int.parse(widget.sellerId!);
      _conversation = await _messagesService.getConversationWithUser(sellerId);
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversation: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_conversation == null) return;

    try {
      final messages = await _messagesService.getMessages(_conversation!.id);
      if (mounted) {
        setState(() {
          _messages = messages;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      if (_conversation == null) {
        final sellerId = int.parse(widget.sellerId!);
        await _messagesService.sendMessage(
          content: content,
          recipientId: sellerId,
        );
        await _loadConversation();
      } else {
        await _messagesService.sendMessage(
          content: content,
          conversationId: _conversation!.id,
        );
        await _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
      _messageController.text = content;
    }
  }

  Future<void> _loadConversations({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await _authService.initialize();
      if (!_authService.isAuthenticated) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final conversations = await _messagesService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading conversations: $e');
      if (mounted) {
        // Only show error snackbar on initial load, not on silent refresh
        if (showLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading conversations: $e')),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If sellerId is provided, this screen was pushed from another screen (e.g., ProductDetailScreen)
    // So we should always show a back button and allow normal pop
    final shouldShowBackButton = widget.sellerId != null;
    
    // If sellerId is provided, show chat with that seller
    if (widget.sellerId != null && widget.sellerName != null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
          body: Column(
            children: [
              // Compact Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.grey[900]!, Colors.grey[800]!]
                        : [Colors.white, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 12,
                  left: 16,
                  right: 16,
                ),
                child: Row(
                  children: [
                    if (shouldShowBackButton)
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    if (shouldShowBackButton) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.sellerName!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Online',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_messages.isNotEmpty)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                        onSelected: (value) {
                          if (value == 'delete_all') {
                            _showDeleteAllMessagesDialog();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete_all',
                            child: Row(
                              children: [
                                Icon(Icons.delete_sweep, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete All Messages'),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Messages List
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey[800] : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: isDark ? Colors.grey[400] : Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Start a conversation',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.grey[900],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Send a message to ${widget.sellerName}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMe = message.senderId == (_currentUserId ?? 0);
                              return Dismissible(
                                      key: Key('message_${message.id}'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      confirmDismiss: (direction) async {
                                        return await _confirmDeleteMessage(message);
                                      },
                                      onDismissed: (direction) {
                                        _deleteMessage(message.id);
                                      },
                                      child: Align(
                                        alignment: isMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: GestureDetector(
                                          onLongPress: () => _showDeleteMessageDialog(message),
                                          child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isMe
                                            ? LinearGradient(
                                                colors: [Colors.blue[400]!, Colors.blue[600]!],
                                              )
                                            : null,
                                        color: isMe
                                            ? null
                                            : (isDark ? Colors.grey[800] : Colors.white),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(20),
                                          topRight: const Radius.circular(20),
                                          bottomLeft: Radius.circular(isMe ? 20 : 4),
                                          bottomRight: Radius.circular(isMe ? 4 : 20),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Flexible(
                                            flex: 1,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  message.content,
                                                  style: TextStyle(
                                                    color: isMe
                                                        ? Colors.white
                                                        : (isDark ? Colors.white : Colors.grey[900]),
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatTime(message.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isMe
                                                        ? Colors.white70
                                                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ...[
                                            const SizedBox(width: 8),
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _showDeleteMessageDialog(message),
                                                borderRadius: BorderRadius.circular(20),
                                                child: Container(
                                                  width: 42,
                                                  height: 42,
                                                  constraints: const BoxConstraints(
                                                    minWidth: 42,
                                                    minHeight: 42,
                                                    maxWidth: 42,
                                                    maxHeight: 42,
                                                  ),
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: isMe 
                                                        ? Colors.white.withOpacity(0.95)
                                                        : (isDark ? Colors.grey[800]!.withOpacity(0.95) : Colors.white.withOpacity(0.95)),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.red.withOpacity(0.6),
                                                      width: 2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.25),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.delete,
                                                    size: 24,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              // Message Input
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.grey[900],
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Otherwise show conversations list (this is the tab view)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Compact Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.grey[900]!, Colors.grey[800]!]
                    : [Colors.white, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 16,
              right: 16,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.message_rounded,
                    color: isDark ? Colors.blue[300] : Colors.blue[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your conversations',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Conversations List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                  )
                : _conversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: isDark ? Colors.grey[400] : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No conversations yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start a conversation from a product page',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadConversations(showLoading: false),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _conversations[index];
                            final otherUserId = conversation.getOtherUserId(_currentUserId ?? 0);
                            final otherUsername = conversation.getOtherUsername(_currentUserId ?? 0);
                            final otherProfileImage = conversation.getOtherProfileImage(_currentUserId ?? 0);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              color: isDark ? Colors.grey[900] : Colors.white,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                      backgroundImage: otherProfileImage != null
                                          ? CachedNetworkImageProvider(otherProfileImage)
                                          : null,
                                      child: otherProfileImage == null
                                          ? Icon(
                                              Icons.person,
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            )
                                          : null,
                                    ),
                                    if (conversation.unreadCount > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark ? Colors.grey[900]! : Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            conversation.unreadCount > 9
                                                ? '9+'
                                                : conversation.unreadCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  otherUsername,
                                  style: TextStyle(
                                    fontWeight: conversation.unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.grey[900],
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        conversation.lastMessage != null
                                            ? conversation.lastMessage!.content
                                            : 'No messages yet',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (conversation.lastMessageAt != null)
                                        Text(
                                          _formatTime(conversation.lastMessageAt!),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                trailing: conversation.unreadCount > 0
                                    ? Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.chevron_right,
                                          color: Colors.blue[600],
                                          size: 20,
                                        ),
                                      )
                                    : Icon(
                                        Icons.chevron_right,
                                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                                      ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MessagesScreen(
                                        sellerId: otherUserId.toString(),
                                        sellerName: otherUsername,
                                      ),
                                    ),
                                  ).then((_) {
                                    _loadConversations(showLoading: false);
                                  });
                                },
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<bool?> _confirmDeleteMessage(MessageModel message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteMessageDialog(MessageModel message) async {
    final confirmed = await _confirmDeleteMessage(message);
    if (confirmed == true) {
      _deleteMessage(message.id);
    }
  }

  Future<void> _deleteMessage(int messageId) async {
    try {
      await _messagesService.deleteMessage(messageId);
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == messageId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAllMessagesDialog() async {
    if (_conversation == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Messages'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete all messages in this conversation?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Total messages: ${_messages.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAllMessages();
    }
  }

  Future<void> _deleteAllMessages() async {
    if (_conversation == null) return;

    try {
      await _messagesService.deleteAllMessages(_conversation!.id);
      if (mounted) {
        setState(() {
          _messages = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All messages deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}

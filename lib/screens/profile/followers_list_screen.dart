import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../services/follow_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../messages/messages_screen.dart';

class FollowersListScreen extends StatefulWidget {
  final int userId;
  final String username;

  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final AuthService _authService = AuthService();
  final FollowService _followService = FollowService();
  List<Map<String, dynamic>> _followers = [];
  bool _isLoading = true;
  Map<int, bool> _isFollowingMap = {}; // Track follow status for each follower
  final Map<int, bool> _isTogglingMap = {}; // Track if we're toggling follow for each user

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.initialize();
      final token = _authService.authToken;

      if (token == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('${AppConstants.baseUrl}/api/users/${widget.userId}/followers');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> followersList = data['followers'] ?? [];
        
        final followers = followersList.map((f) => f as Map<String, dynamic>).toList();
        
        // Initialize follow status map
        final followStatusMap = <int, bool>{};
        for (var follower in followers) {
          final followerId = follower['id'] as int;
          followStatusMap[followerId] = follower['is_following_back'] ?? false;
        }

        if (mounted) {
          setState(() {
            _followers = followers;
            _isFollowingMap = followStatusMap;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load followers');
      }
    } catch (e) {
      print('Error loading followers: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading followers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFollow(int followerId, String username) async {
    if (_isTogglingMap[followerId] == true) return;

    await _authService.initialize();
    if (!_authService.isAuthenticated || _authService.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to follow users'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTogglingMap[followerId] = true;
    });

    try {
      final wasFollowing = _isFollowingMap[followerId] ?? false;

      // Optimistically update UI
      setState(() {
        _isFollowingMap[followerId] = !wasFollowing;
      });

      try {
        if (wasFollowing) {
          await _followService.unfollowUser(followerId);
        } else {
          await _followService.followUser(followerId);
        }
      } catch (e) {
        // Revert on error
        setState(() {
          _isFollowingMap[followerId] = wasFollowing;
        });

        final errorMessage = e.toString();
        if (errorMessage.contains('already following')) {
          try {
            await _followService.unfollowUser(followerId);
            setState(() {
              _isFollowingMap[followerId] = false;
            });
          } catch (e2) {
            throw Exception('Failed to toggle follow: $e2');
          }
        } else if (errorMessage.contains('not following')) {
          try {
            await _followService.followUser(followerId);
            setState(() {
              _isFollowingMap[followerId] = true;
            });
          } catch (e2) {
            throw Exception('Failed to toggle follow: $e2');
          }
        } else {
          rethrow;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowingMap[followerId]! ? 'You are now following $username' : 'You unfollowed $username'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isFollowingMap[followerId]! ? "follow" : "unfollow"}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingMap[followerId] = false;
        });
      }
    }
  }

  Future<void> _removeFollower(int followerId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Follower'),
        content: Text('Are you sure you want to remove $username from your followers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Note: Removing a follower means blocking them, which would require a block feature
    // For now, we'll just show a message that this feature is coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Remove follower feature coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.username}\'s Followers'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _followers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No followers yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFollowers,
                  child: ListView.builder(
                    itemCount: _followers.length,
                    itemBuilder: (context, index) {
                      final follower = _followers[index];
                      final followerId = follower['id'] as int;
                      final username = follower['username'] as String;
                      final fullName = follower['full_name'] as String?;
                      final profileImage = follower['profile_image'] as String?;
                      final isVerified = follower['is_verified'] as bool? ?? false;
                      final isFollowingBack = _isFollowingMap[followerId] ?? false;
                      final isToggling = _isTogglingMap[followerId] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.surfaceLight,
                                backgroundImage: profileImage != null
                                    ? CachedNetworkImageProvider(profileImage)
                                    : null,
                                child: profileImage == null
                                    ? const Icon(Icons.person, size: 28, color: AppTheme.textSecondary)
                                    : null,
                              ),
                              if (isVerified)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            fullName ?? username,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '@$username',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Message button
                              IconButton(
                                icon: const Icon(Icons.message_outlined),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MessagesScreen(
                                        sellerId: followerId.toString(),
                                        sellerName: fullName ?? username,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Follow/Following button
                              TextButton(
                                onPressed: isToggling
                                    ? null
                                    : () => _toggleFollow(followerId, username),
                                style: TextButton.styleFrom(
                                  backgroundColor: isFollowingBack ? Colors.grey[300] : AppTheme.primaryColor,
                                  foregroundColor: isFollowingBack ? Colors.black : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: isToggling
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        isFollowingBack ? 'Following' : 'Follow Back',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                              ),
                              // Remove button
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == 'remove') {
                                    _removeFollower(followerId, username);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_remove, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Remove', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}


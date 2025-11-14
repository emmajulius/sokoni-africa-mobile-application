import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/story_model.dart';
import '../../services/story_api_service.dart';
import '../../services/auth_service.dart';

class StoryViewerScreen extends StatefulWidget {
  final UserStories userStories;
  final List<UserStories> allStories;
  final int initialIndex;
  final VoidCallback? onStoriesUpdated;

  const StoryViewerScreen({
    super.key,
    required this.userStories,
    required this.allStories,
    this.initialIndex = 0,
    this.onStoriesUpdated,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  static const Duration _storyDuration = Duration(seconds: 6);
  static const Duration _tickInterval = Duration(milliseconds: 50);

  final StoryApiService _storyApiService = StoryApiService();
  final AuthService _authService = AuthService();

  late final PageController _userPageController;
  late PageController _storyPageController;

  Timer? _progressTimer;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;
  double _progress = 0.0;
  bool _isPaused = false;
  bool _isDeleting = false;
  List<UserStories> _allStories = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _allStories = List.from(widget.allStories);
    _currentUserIndex = _clampUserIndex(widget.initialIndex);
    _currentStoryIndex = 0;
    _userPageController = PageController(initialPage: _currentUserIndex);
    _storyPageController = PageController(initialPage: _currentStoryIndex);
    _initializeAuth();
    _markStoryAsViewed();
    _startProgressTimer();
  }

  Future<void> _initializeAuth() async {
    await _authService.initialize();
    if (mounted) {
      setState(() {
        _currentUserId = _authService.userId;
      });
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _userPageController.dispose();
    _storyPageController.dispose();
    super.dispose();
  }

  int _clampUserIndex(int index) {
    if (_allStories.isEmpty) return 0;
    if (index < 0) return 0;
    if (index >= _allStories.length) {
      return _allStories.length - 1;
    }
    return index;
  }

  void _restartStoryController() {
    _storyPageController.dispose();
    _storyPageController = PageController(initialPage: _currentStoryIndex);
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    if (_isPaused) return;

    final story = _getCurrentStory();
    if (story == null) {
      setState(() => _progress = 0.0);
      return;
    }

    final startTime = DateTime.now();
    setState(() => _progress = 0.0);

    _progressTimer = Timer.periodic(_tickInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isPaused) {
        return;
      }

      final elapsed = DateTime.now().difference(startTime);
      final progress = elapsed.inMilliseconds / _storyDuration.inMilliseconds;

      if (progress >= 1.0) {
        timer.cancel();
        _progress = 1.0;
        _nextStory();
      } else {
        setState(() {
          _progress = progress.clamp(0.0, 1.0);
        });
      }
    });
  }

  void _nextStory() {
    _progressTimer?.cancel();
    final currentUserStories = _allStories.isNotEmpty ? _allStories[_currentUserIndex] : null;
    if (currentUserStories == null) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (_currentStoryIndex < currentUserStories.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _storyPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _markStoryAsViewed();
      _startProgressTimer();
    } else if (_currentUserIndex < _allStories.length - 1) {
      setState(() {
        _currentUserIndex++;
        _currentStoryIndex = 0;
      });
      _userPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _restartStoryController();
      _markStoryAsViewed();
      _startProgressTimer();
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void _previousStory() {
    _progressTimer?.cancel();

    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _storyPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _markStoryAsViewed();
      _startProgressTimer();
    } else if (_currentUserIndex > 0) {
      setState(() {
        _currentUserIndex--;
        final previousUserStories = _allStories[_currentUserIndex];
        _currentStoryIndex = previousUserStories.stories.length - 1;
      });
      _userPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _restartStoryController();
      _markStoryAsViewed();
      _startProgressTimer();
    }
  }

  StoryModel? _getCurrentStory() {
    if (_allStories.isEmpty) return null;
    if (_currentUserIndex < 0 || _currentUserIndex >= _allStories.length) {
      return null;
    }
    final userStories = _allStories[_currentUserIndex];
    if (_currentStoryIndex < 0 || _currentStoryIndex >= userStories.stories.length) {
      return null;
    }
    return userStories.stories[_currentStoryIndex];
  }

  Future<void> _markStoryAsViewed() async {
    final story = _getCurrentStory();
    if (story == null || story.id.isEmpty) return;

    final storyId = int.tryParse(story.id);
    if (storyId == null) return;

    _storyApiService.viewStory(storyId).catchError((_) => <String, dynamic>{});
  }

  bool _isStoryOwner(StoryModel story) {
    if (_currentUserId == null) return false;
    // Compare user IDs (both should be strings, but handle int conversion if needed)
    final storyUserId = story.userId.toString();
    final currentUserIdStr = _currentUserId.toString();
    return storyUserId == currentUserIdStr;
  }

  Future<void> _deleteStory() async {
    final story = _getCurrentStory();
    if (story == null || !_isStoryOwner(story)) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story'),
        content: const Text('Are you sure you want to delete this story? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final storyId = int.tryParse(story.id);
      if (storyId == null) {
        throw Exception('Invalid story ID');
      }

      // Delete story from API
      await _storyApiService.deleteStory(storyId);

      // Pause progress timer during deletion
      _progressTimer?.cancel();

      // Get current state before deletion
      final currentUserStories = _allStories[_currentUserIndex];
      
      // Remove story from local list
      final updatedStories = List<StoryModel>.from(currentUserStories.stories)
        ..removeAt(_currentStoryIndex);

      // Update local stories list
      if (updatedStories.isEmpty) {
        // Remove entire user from stories list
        _allStories.removeAt(_currentUserIndex);

        if (_allStories.isEmpty) {
          // No more stories, navigate back
          if (mounted) {
            widget.onStoriesUpdated?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Story deleted successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
          return;
        }

        // Adjust current user index - move to previous user if possible
        if (_currentUserIndex >= _allStories.length) {
          _currentUserIndex = _allStories.length - 1;
        }
        if (_currentUserIndex < 0) {
          _currentUserIndex = 0;
        }
        _currentStoryIndex = 0;
        
        // Dispose and recreate controllers
        _userPageController.dispose();
        _storyPageController.dispose();
        _userPageController = PageController(initialPage: _currentUserIndex);
        _storyPageController = PageController(initialPage: 0);
      } else {
        // Update current user's stories
        _allStories[_currentUserIndex] = UserStories(
          userId: currentUserStories.userId,
          username: currentUserStories.username,
          profileImage: currentUserStories.profileImage,
          stories: updatedStories,
          hasNewStories: updatedStories.any((s) => s.viewsCount == 0),
        );

        // Adjust current story index
        // When a story is deleted, all stories after it shift down by one index
        // If we deleted the last story, move to the new last story
        // Otherwise, stay at the same index (which will now show the next story)
        if (_currentStoryIndex >= updatedStories.length) {
          _currentStoryIndex = updatedStories.length > 0 ? updatedStories.length - 1 : 0;
        }
        if (_currentStoryIndex < 0) {
          _currentStoryIndex = 0;
        }
        
        // Dispose and recreate story page controller with new index
        _storyPageController.dispose();
        _storyPageController = PageController(initialPage: _currentStoryIndex);
      }

      // Update UI
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _isPaused = false;
        });

        // Mark new current story as viewed
        _markStoryAsViewed();

        // Restart progress timer for new story
        _startProgressTimer();

        // Notify parent to refresh stories
        widget.onStoriesUpdated?.call();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete story: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allStories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No stories available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width * 0.35) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        onLongPressStart: (_) {
          _progressTimer?.cancel();
          setState(() => _isPaused = true);
        },
        onLongPressMoveUpdate: (_) {
          if (!_isPaused) {
            _progressTimer?.cancel();
            setState(() => _isPaused = true);
          }
        },
        onLongPressEnd: (_) {
          setState(() => _isPaused = false);
          _startProgressTimer();
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _userPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentUserIndex = index;
                  _currentStoryIndex = 0;
                });
                _restartStoryController();
                _markStoryAsViewed();
                _startProgressTimer();
              },
              itemCount: _allStories.length,
              itemBuilder: (context, userIndex) {
                final userStories = _allStories[userIndex];
                return _buildUserStoriesPage(userStories);
              },
            ),
            _buildProgressIndicator(),
            _buildTopBar(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStoriesPage(UserStories userStories) {
    // Use current user stories from state to ensure we have the latest data
    final currentUserStories = _currentUserIndex < _allStories.length 
        ? _allStories[_currentUserIndex] 
        : userStories;
    
    return PageView.builder(
      controller: _storyPageController,
      onPageChanged: (index) {
        setState(() {
          _currentStoryIndex = index;
        });
        _markStoryAsViewed();
        _startProgressTimer();
      },
      itemCount: currentUserStories.stories.length,
      itemBuilder: (context, index) {
        if (index >= currentUserStories.stories.length) {
          return const SizedBox.shrink();
        }
        final story = currentUserStories.stories[index];
        return _buildStoryContent(story);
      },
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    if (story.isVideo) {
      // Placeholder for video player integration
      return const Center(
        child: Text(
          'Video story not supported yet',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (story.imageUrl != null && story.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: story.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error, color: Colors.white, size: 48),
        ),
      );
    }

    return Container(
      color: Colors.grey[900],
      alignment: Alignment.center,
      child: const Text(
        'No media',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final userStories = _getCurrentStory() != null ? _allStories[_currentUserIndex] : null;
    if (userStories == null) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: List.generate(userStories.stories.length, (index) {
              final isCurrent = index == _currentStoryIndex;
              final hasPassed = index < _currentStoryIndex;
              final widthFactor = hasPassed ? 1.0 : (isCurrent ? _progress : 0.0);

              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widthFactor,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final story = _getCurrentStory();
    if (story == null) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: story.userProfileImage != null
                    ? NetworkImage(story.userProfileImage!)
                    : null,
                child: story.userProfileImage == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(story.createdAt),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Show delete button only if user owns the story
              if (_isStoryOwner(story))
                PopupMenuButton<String>(
                  icon: Icon(
                    _isDeleting ? Icons.hourglass_empty : Icons.more_vert,
                    color: Colors.blue,
                    size: 26,
                  ),
                  color: Colors.grey[900],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteStory();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _isDeleting ? 'Deleting...' : 'Delete Story',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: _isStoryOwner(story) ? Colors.blue : Colors.white,
                  size: 26,
                ),
                onPressed: () {
                  _progressTimer?.cancel();
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final story = _getCurrentStory();
    if (story == null || (story.caption == null || story.caption!.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          story.caption!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}


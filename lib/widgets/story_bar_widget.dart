import 'package:flutter/material.dart';
import 'package:sokoni_africa_app/models/story_model.dart';
import 'package:sokoni_africa_app/screens/stories/story_viewer_screen.dart';
import 'package:sokoni_africa_app/services/auth_service.dart';

class StoryBarWidget extends StatefulWidget {
  final List<UserStories> userStories;
  final VoidCallback? onAddStory;
  final VoidCallback? onStoriesUpdated;

  const StoryBarWidget({
    super.key,
    required this.userStories,
    this.onAddStory,
    this.onStoriesUpdated,
  });

  @override
  State<StoryBarWidget> createState() => _StoryBarWidgetState();
}

class _StoryBarWidgetState extends State<StoryBarWidget> {
  final AuthService _authService = AuthService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authService.userId;
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authService.initialize();
    if (!mounted) return;
    if (_currentUserId != _authService.userId) {
      setState(() {
        _currentUserId = _authService.userId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = _currentUserId;

    UserStories? myStories;
    int? myStoryIndex;
    if (currentUserId != null) {
      final index = widget.userStories.indexWhere((story) => story.userId == currentUserId);
      if (index != -1) {
        myStories = widget.userStories[index];
        myStoryIndex = index;
      }
    }

    final List<UserStories> otherStories = myStories == null
        ? widget.userStories
        : widget.userStories.where((story) => story.userId != currentUserId).toList();

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: otherStories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryButton(
              context: context,
              authService: _authService,
              myStories: myStories,
              myStoryIndex: myStoryIndex,
            );
          }

          final userStory = otherStories[index - 1];
          return _buildStoryCircle(context, userStory);
        },
      ),
    );
  }

  Widget _buildAddStoryButton({
    required BuildContext context,
    required AuthService authService,
    UserStories? myStories,
    int? myStoryIndex,
  }) {
    bool hasStory = false;
    String? previewImage;

    if (myStories != null && myStories.stories.isNotEmpty) {
      hasStory = true;
      final stories = myStories.stories;
      final mediaStories = stories.where((story) => story.imageUrl != null && story.imageUrl!.isNotEmpty);
      if (mediaStories.isNotEmpty) {
        final latestStory = mediaStories.reduce(
          (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
        );
        previewImage = latestStory.imageUrl ?? latestStory.userProfileImage ?? myStories.profileImage;
      } else {
        final latestStory = stories.reduce(
          (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
        );
        previewImage = latestStory.imageUrl ?? latestStory.userProfileImage ?? myStories.profileImage;
      }
    } else {
      previewImage = myStories?.profileImage;
    }

    void handlePrimaryTap() {
      final storiesToOpen = myStories;
      if (!hasStory || storiesToOpen == null || myStoryIndex == null) {
        if (authService.isGuest) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to add a story'),
            ),
          );
        } else {
          widget.onAddStory?.call();
        }
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryViewerScreen(
            userStories: storiesToOpen,
            allStories: widget.userStories,
            initialIndex: myStoryIndex,
            onStoriesUpdated: widget.onStoriesUpdated,
          ),
        ),
      ).then((_) {
        // Refresh stories after returning from story viewer
        widget.onStoriesUpdated?.call();
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: handlePrimaryTap,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStory
                        ? const LinearGradient(
                            colors: [
                              Colors.purple,
                              Colors.pink,
                              Colors.orange,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: hasStory 
                        ? null 
                        : Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 2,
                          ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        backgroundImage: (previewImage != null && previewImage.isNotEmpty)
                            ? NetworkImage(previewImage)
                            : null,
                        child: previewImage == null || previewImage.isEmpty
                            ? Icon(
                                hasStory ? Icons.play_circle_fill_rounded : Icons.add,
                                color: hasStory 
                                    ? Colors.purple 
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                size: hasStory ? 34 : 30,
                              )
                            : null,
                      ),
                  ),
                ),
              ),
              if (!authService.isGuest && widget.onAddStory != null)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: GestureDetector(
                    onTap: widget.onAddStory,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              hasStory ? 'My Story' : 'Add Story',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCircle(BuildContext context, UserStories userStory) {
    final hasNewStories = userStory.hasNewStories;
    final bool isOwner = userStory.userId == (_currentUserId ?? '');
    final String label = isOwner ? 'My Story' : userStory.username;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryViewerScreen(
                userStories: userStory,
                allStories: widget.userStories,
                initialIndex: widget.userStories.indexOf(userStory),
                onStoriesUpdated: widget.onStoriesUpdated,
              ),
            ),
          ).then((_) {
            // Refresh stories after returning from story viewer
            widget.onStoriesUpdated?.call();
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasNewStories
                    ? const LinearGradient(
                        colors: [
                          Colors.purple,
                          Colors.pink,
                          Colors.orange,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: hasNewStories
                    ? null
                    : Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 2,
                      ),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  backgroundImage: (userStory.profileImage != null && userStory.profileImage!.isNotEmpty)
                      ? NetworkImage(userStory.profileImage!)
                      : null,
                  child: userStory.profileImage == null || userStory.profileImage!.isEmpty
                      ? Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/story_model.dart';

class StoryService {
  static final StoryService _instance = StoryService._internal();
  factory StoryService() => _instance;
  StoryService._internal();

  static const String _storiesKey = 'user_stories';

  // Get all active stories (not expired)
  Future<List<UserStories>> getActiveStories() async {
    final allStories = await _getAllStories();
    
    // Filter expired stories and group by user
    final now = DateTime.now();
    final Map<String, List<StoryModel>> userStoriesMap = {};
    
    for (var story in allStories) {
      if (!story.isExpired && story.expiresAt.isAfter(now)) {
        if (!userStoriesMap.containsKey(story.userId)) {
          userStoriesMap[story.userId] = [];
        }
        userStoriesMap[story.userId]!.add(story);
      }
    }

    // Convert to UserStories list
    return userStoriesMap.entries.map((entry) {
      final stories = entry.value;
      stories.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      return UserStories(
        userId: entry.key,
        username: stories.first.username,
        profileImage: stories.first.userProfileImage,
        stories: stories,
        hasNewStories: stories.any((s) => s.viewsCount == 0),
      );
    }).toList();
  }

  // Create a new story
  Future<StoryModel> createStory({
    required String userId,
    required String username,
    String? userProfileImage,
    String? imageUrl,
    String? videoUrl,
    String? caption,
  }) async {
    final now = DateTime.now();
    final story = StoryModel(
      id: 'story_${now.millisecondsSinceEpoch}',
      userId: userId,
      username: username,
      userProfileImage: userProfileImage,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      caption: caption,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );

    final stories = await _getAllStories();
    stories.add(story);
    await _saveStories(stories);

    return story;
  }

  // Mark story as viewed
  Future<void> markStoryAsViewed(String storyId, String viewerId) async {
    final stories = await _getAllStories();
    final index = stories.indexWhere((s) => s.id == storyId);
    
    if (index != -1) {
      final story = stories[index];
      if (!story.viewers.contains(viewerId)) {
        final updatedViewers = List<String>.from(story.viewers)..add(viewerId);
        stories[index] = story.copyWith(
          viewers: updatedViewers,
          viewsCount: story.viewsCount + 1,
        );
        await _saveStories(stories);
      }
    }
  }

  // Delete expired stories
  Future<void> cleanExpiredStories() async {
    final stories = await _getAllStories();
    final activeStories = stories.where((s) => !s.isExpired).toList();
    await _saveStories(activeStories);
  }

  // Get all stories from storage
  Future<List<StoryModel>> _getAllStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storiesJson = prefs.getStringList(_storiesKey);
      
      if (storiesJson == null || storiesJson.isEmpty) {
        return [];
      }

      return storiesJson
          .map((json) => StoryModel.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Save stories to storage
  Future<void> _saveStories(List<StoryModel> stories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storiesJson = stories
          .map((story) => jsonEncode(story.toJson()))
          .toList();
      await prefs.setStringList(_storiesKey, storiesJson);
    } catch (e) {
      // Handle error
    }
  }

  // Delete a story
  Future<void> deleteStory(String storyId) async {
    final stories = await _getAllStories();
    stories.removeWhere((s) => s.id == storyId);
    await _saveStories(stories);
  }
}


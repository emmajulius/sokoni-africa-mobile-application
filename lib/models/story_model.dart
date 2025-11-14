class StoryModel {
  final String id;
  final String userId;
  final String username;
  final String? userProfileImage;
  final String? imageUrl;
  final String? videoUrl;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewers; // User IDs who viewed the story
  final int viewsCount;

  StoryModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userProfileImage,
    this.imageUrl,
    this.videoUrl,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.viewers = const [],
    this.viewsCount = 0,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasMedia => imageUrl != null || videoUrl != null;

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      userProfileImage: json['user_profile_image'],
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      caption: json['caption'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(hours: 24)),
      viewers: json['viewers'] != null
          ? List<String>.from(json['viewers'])
          : [],
      viewsCount: json['views_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'user_profile_image': userProfileImage,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'viewers': viewers,
      'views_count': viewsCount,
    };
  }

  StoryModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfileImage,
    String? imageUrl,
    String? videoUrl,
    String? caption,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? viewers,
    int? viewsCount,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewers: viewers ?? this.viewers,
      viewsCount: viewsCount ?? this.viewsCount,
    );
  }
}

// Model for grouping stories by user
class UserStories {
  final String userId;
  final String username;
  final String? profileImage;
  final List<StoryModel> stories;
  final bool hasNewStories; // Stories user hasn't viewed yet

  UserStories({
    required this.userId,
    required this.username,
    this.profileImage,
    required this.stories,
    this.hasNewStories = false,
  });

  int get totalStories => stories.length;
  bool get hasActiveStories => stories.any((story) => !story.isExpired);
}


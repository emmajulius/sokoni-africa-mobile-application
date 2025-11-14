class UserModel {
  final String id;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? profileImage;
  final String? location;
  final String? bio;
  final String? gender;
  final String? language;
  final String userType; // 'client', 'supplier', 'retailer'
  final int followers;
  final int soldProducts;
  final double rating;
  final bool isVerified;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.profileImage,
    this.location,
    this.bio,
    this.gender,
    this.language,
    required this.userType,
    this.followers = 0,
    this.soldProducts = 0,
    this.rating = 0.0,
    this.isVerified = false,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      profileImage: json['profile_image'],
      location: json['location'],
      bio: json['bio'],
      gender: json['gender'],
      language: json['language'],
      userType: json['user_type'] ?? 'client',
      followers: json['followers'] ?? 0,
      soldProducts: json['sold_products'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'profile_image': profileImage,
      'location': location,
      'bio': bio,
      'gender': gender,
      'language': language,
      'user_type': userType,
      'followers': followers,
      'sold_products': soldProducts,
      'rating': rating,
      'is_verified': isVerified,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}


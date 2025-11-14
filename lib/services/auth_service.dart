import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'auth_api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isGuest = false;
  bool _isAuthenticated = false;
  String? _userId;
  String? _authToken;
  String? _userType; // 'client', 'supplier', 'retailer'
  String? _username;
  String? _fullName;
  String? _email;
  String? _phone;
  String? _profileImage;
  double? _latitude;
  double? _longitude;
  String? _locationAddress;

  // Getters
  bool get isGuest => _isGuest;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get authToken => _authToken;
  String? get userType => _userType;
  String? get username => _username;
  String? get fullName => _fullName;
  String? get email => _email;
  String? get phone => _phone;
  String? get profileImage => _profileImage;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get locationAddress => _locationAddress;
  
  // Helper methods to check user type
  bool get isClient => _userType == AppConstants.userTypeClient;
  bool get isSupplier => _userType == AppConstants.userTypeSupplier;
  bool get isRetailer => _userType == AppConstants.userTypeRetailer;
  
  // Check if user can buy
  bool get canBuy => (isClient || isRetailer) || (_isGuest && !isSupplier);
  
  // Check if user can sell
  bool get canSell => isSupplier || isRetailer;

  // Initialize auth state from storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('is_guest') ?? false;
    _userId = prefs.getString(AppConstants.keyUserId);
    _authToken = prefs.getString(AppConstants.keyAuthToken);
    _userType = prefs.getString(AppConstants.keyUserType);
    _username = prefs.getString('username');
    _fullName = prefs.getString('full_name');
    _email = prefs.getString('email');
    _phone = prefs.getString('phone');
    _profileImage = prefs.getString('profile_image');
    _latitude = prefs.getDouble('latitude');
    _longitude = prefs.getDouble('longitude');
    _locationAddress = prefs.getString('location_address');
    
    final storedIsAuthenticated = prefs.getBool('is_authenticated');
    if (storedIsAuthenticated != null) {
      _isAuthenticated = storedIsAuthenticated;
    } else {
      _isAuthenticated = _authToken != null;
      await prefs.setBool('is_authenticated', _isAuthenticated);
    }
    
    if (_authToken != null && !_isAuthenticated) {
      _isAuthenticated = true;
      await prefs.setBool('is_authenticated', true);
    }
    
    if (_userType != null) {
      _userType = _userType!.toLowerCase();
      await prefs.setString(AppConstants.keyUserType, _userType!);
    }
  }

  // Update user profile data
  Future<void> updateProfileData({
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? profileImage,
    String? userType,
    double? latitude,
    double? longitude,
    String? locationAddress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (username != null) {
      _username = username;
      await prefs.setString('username', username);
    }
    if (fullName != null) {
      _fullName = fullName;
      await prefs.setString('full_name', fullName);
    }
    if (email != null) {
      _email = email;
      await prefs.setString('email', email);
    }
    if (phone != null) {
      _phone = phone;
      await prefs.setString('phone', phone);
    }
    if (profileImage != null) {
      _profileImage = profileImage;
      await prefs.setString('profile_image', profileImage);
    }
    if (latitude != null) {
      _latitude = latitude;
      await prefs.setDouble('latitude', latitude);
    }
    if (longitude != null) {
      _longitude = longitude;
      await prefs.setDouble('longitude', longitude);
    }
    if (locationAddress != null) {
      _locationAddress = locationAddress;
      await prefs.setString('location_address', locationAddress);
    }
    if (userType != null && userType.isNotEmpty) {
      final normalized = userType.toLowerCase();
      _userType = normalized;
      await prefs.setString(AppConstants.keyUserType, normalized);
    }
  }

  // Load user profile from API
  Future<void> loadUserProfile() async {
    if (!_isAuthenticated || _authToken == null) return;
    
    try {
      final authApiService = AuthApiService();
      final profileData = await authApiService.getCurrentUserProfile(_authToken!);
      
      await updateProfileData(
        username: profileData['username']?.toString(),
        fullName: profileData['full_name']?.toString(),
        email: profileData['email']?.toString(),
        phone: profileData['phone']?.toString(),
        profileImage: profileData['profile_image']?.toString(),
        userType: profileData['user_type']?.toString(),
        latitude: double.tryParse(profileData['latitude']?.toString() ?? ''),
        longitude: double.tryParse(profileData['longitude']?.toString() ?? ''),
        locationAddress: profileData['location_address']?.toString(),
      );
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Login as guest
  Future<void> loginAsGuest({String? userType}) async {
    _isGuest = true;
    _isAuthenticated = false;
    _userId = null;
    _authToken = null;
    _userType = userType ?? AppConstants.userTypeClient; // Default to client for guests

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', true);
    await prefs.setBool('is_authenticated', false);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyAuthToken);
    if (userType != null) {
      await prefs.setString(AppConstants.keyUserType, userType);
    }
  }

  // Login with credentials
  Future<void> login(String userId, String authToken, {String? userType}) async {
    _isGuest = false;
    _isAuthenticated = true;
    _userId = userId;
    _authToken = authToken;
    if (userType != null) {
      _userType = userType;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', false);
    await prefs.setBool('is_authenticated', true);
    await prefs.setString(AppConstants.keyUserId, userId);
    await prefs.setString(AppConstants.keyAuthToken, authToken);
    if (userType != null) {
      await prefs.setString(AppConstants.keyUserType, userType);
    }
  }
  
  // Set user type
  Future<void> setUserType(String userType) async {
    _userType = userType;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserType, userType);
  }

  // Logout
  Future<void> logout() async {
    _isGuest = false;
    _isAuthenticated = false;
    _userId = null;
    _authToken = null;
    _userType = null;
    _username = null;
    _fullName = null;
    _email = null;
    _phone = null;
    _profileImage = null;
    _latitude = null;
    _longitude = null;
    _locationAddress = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_guest');
    await prefs.remove('is_authenticated');
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserType);
    await prefs.remove('username');
    await prefs.remove('full_name');
    await prefs.remove('email');
    await prefs.remove('phone');
    await prefs.remove('profile_image');
    await prefs.remove('latitude');
    await prefs.remove('longitude');
    await prefs.remove('location_address');
  }

  // Check if user needs to sign up for certain actions
  bool requiresAuthForAction(String action) {
    // Actions that require authentication
    const authRequiredActions = [
      'add_to_cart',
      'checkout',
      'create_product',
      'send_message',
      'follow_user',
      'like_product',
      'comment',
    ];
    
    return authRequiredActions.contains(action) && _isGuest;
  }
}


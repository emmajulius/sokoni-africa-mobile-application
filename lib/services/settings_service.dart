import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Notification settings
  bool _activityNotifications = true;
  bool _promotionsNotifications = true;
  bool _emailNotifications = false;

  // Appearance settings
  bool _darkMode = false;

  // Getters
  bool get activityNotifications => _activityNotifications;
  bool get promotionsNotifications => _promotionsNotifications;
  bool get emailNotifications => _emailNotifications;
  bool get darkMode => _darkMode;

  // Initialize settings from storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _activityNotifications = prefs.getBool('activity_notifications') ?? true;
    _promotionsNotifications = prefs.getBool('promotions_notifications') ?? true;
    _emailNotifications = prefs.getBool('email_notifications') ?? false;
    _darkMode = prefs.getBool('is_dark_mode') ?? false;
    notifyListeners();
  }

  // Update notification settings
  Future<void> setActivityNotifications(bool value) async {
    _activityNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('activity_notifications', value);
    notifyListeners();
  }

  Future<void> setPromotionsNotifications(bool value) async {
    _promotionsNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('promotions_notifications', value);
    notifyListeners();
  }

  Future<void> setEmailNotifications(bool value) async {
    _emailNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_notifications', value);
    notifyListeners();
  }

  // Update appearance settings
  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
    notifyListeners();
  }
}


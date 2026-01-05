import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyUserId = 'user_id';
  static const String _keyUserCategory = 'user_category';
  static const String _keyUserData = 'user_data';

  // Save user ID
  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }

  // Get user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  // Save user category
  static Future<void> saveUserCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserCategory, category);
  }

  // Get user category
  static Future<String?> getUserCategory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserCategory);
  }

  // Save user data
  static Future<void> saveUserData(String userDataJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, userDataJson);
  }

  // Get user data
  static Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserData);
  }

  // Clear all data (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserCategory);
    await prefs.remove(_keyUserData);
  }
}


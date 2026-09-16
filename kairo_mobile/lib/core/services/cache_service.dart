import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Generic Methods ---
  
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    if (_prefs == null) await init();
    await _prefs!.setString(key, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getData(String key) async {
    if (_prefs == null) await init();
    final String? jsonStr = _prefs!.getString(key);
    if (jsonStr != null) {
      try {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> removeData(String key) async {
    if (_prefs == null) await init();
    await _prefs!.remove(key);
  }
  
  Future<void> clearAll() async {
    if (_prefs == null) await init();
    await _prefs!.clear();
  }

  // --- Specific Cache Keys ---
  static const String keyUserProfile = 'cache_user_profile';
  static const String keyOpportunities = 'cache_opportunities';

  // Helpers pour le Profile
  Future<void> cacheUserProfile(Map<String, dynamic> userMap) async {
    await saveData(keyUserProfile, userMap);
  }

  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    return await getData(keyUserProfile);
  }
}

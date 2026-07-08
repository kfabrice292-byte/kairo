import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  SharedPreferences? _prefs;

  String _language = 'fr'; // 'fr' ou 'en'
  String _privacy = 'public'; // 'public', 'connections', 'private'
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  String get language => _language;
  String get privacy => _privacy;
  bool get pushNotifications => _pushNotifications;
  bool get emailNotifications => _emailNotifications;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _language = _prefs?.getString('language') ?? 'fr';
    _privacy = _prefs?.getString('privacy') ?? 'public';
    _pushNotifications = _prefs?.getBool('pushNotifications') ?? true;
    _emailNotifications = _prefs?.getBool('emailNotifications') ?? false;
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    await _prefs?.setString('language', value);
    notifyListeners();
  }

  Future<void> setPrivacy(String value) async {
    _privacy = value;
    await _prefs?.setString('privacy', value);
    notifyListeners();
  }

  Future<void> setPushNotifications(bool value) async {
    _pushNotifications = value;
    await _prefs?.setBool('pushNotifications', value);
    notifyListeners();
  }

  Future<void> setEmailNotifications(bool value) async {
    _emailNotifications = value;
    await _prefs?.setBool('emailNotifications', value);
    notifyListeners();
  }
}

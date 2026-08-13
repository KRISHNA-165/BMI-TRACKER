import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_model.dart';
import '../models/weight_entry_model.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static const String _keyActiveProfileId = 'active_profile_id';
  static const String _keyDemoUser = 'demo_user_email';
  static const String _keyDemoUserId = 'demo_user_id';
  static const String _keyProfiles = 'local_profiles_cache_';
  static const String _keyWeightHistory = 'local_weight_history_';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Active Profile ID
  static String? getActiveProfileId() {
    return _prefs.getString(_keyActiveProfileId);
  }

  static Future<void> setActiveProfileId(String profileId) async {
    await _prefs.setString(_keyActiveProfileId, profileId);
  }

  // Demo / Offline User Session
  static String? getDemoUserEmail() {
    return _prefs.getString(_keyDemoUser);
  }

  static String? getDemoUserId() {
    return _prefs.getString(_keyDemoUserId);
  }

  static Future<void> setDemoUserSession(String email, String userId) async {
    await _prefs.setString(_keyDemoUser, email);
    await _prefs.setString(_keyDemoUserId, userId);
  }

  static Future<void> clearDemoUserSession() async {
    await _prefs.remove(_keyDemoUser);
    await _prefs.remove(_keyDemoUserId);
    await _prefs.remove(_keyActiveProfileId);
  }

  // Local Profiles Cache with ISO8601 String Dates (JSON safe)
  static Future<void> saveProfilesLocally(String userId, List<UserProfile> profiles) async {
    final list = profiles.map((p) => p.toLocalMap()).toList();
    await _prefs.setString(_keyProfiles + userId, jsonEncode(list));
  }

  static List<UserProfile> getLocalProfiles(String userId) {
    final raw = _prefs.getString(_keyProfiles + userId);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item);
        final id = map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
        return UserProfile.fromMap(id, map);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // Local Weight History Cache with ISO8601 String Dates (JSON safe)
  static Future<void> saveWeightHistoryLocally(String profileId, List<WeightEntry> entries) async {
    final list = entries.map((e) => e.toLocalMap()).toList();
    await _prefs.setString(_keyWeightHistory + profileId, jsonEncode(list));
  }

  static List<WeightEntry> getLocalWeightHistory(String profileId) {
    final raw = _prefs.getString(_keyWeightHistory + profileId);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((item) {
        final map = Map<String, dynamic>.from(item);
        final id = map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
        return WeightEntry.fromMap(id, map);
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

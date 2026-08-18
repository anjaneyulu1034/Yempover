import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the last "deep" screen (chat/post) the user had open so a cold
/// start after the OS kills the app in the background (e.g. during a phone
/// call) can reopen it instead of always landing back on Home.
///
/// A screen saves itself in initState and clears itself in dispose. Because
/// dispose runs on a normal pop but is skipped when the OS kills the whole
/// process, the record only survives to the next cold start when the app
/// was actually killed mid-screen — exactly the case this is for.
class ResumeStateService {
  static const _prefsKey = 'resume_last_screen_v1';

  static Future<void> saveChat(String chatId) =>
      _save({'type': 'chat', 'id': chatId});

  static Future<void> savePost(String postId, {required bool isService}) =>
      _save({'type': 'post', 'id': postId, 'isService': isService.toString()});

  static Future<void> _save(Map<String, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  /// Clears the record only if it still points at [type]/[id] — avoids
  /// wiping a newer screen's record if this one has already been replaced
  /// (e.g. navigating from post A straight to post B).
  static Future<void> clearIfCurrent(String type, String id) async {
    final current = await read();
    if (current != null && current['type'] == type && current['id'] == id) {
      await clear();
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  static Future<Map<String, String>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return null;
    }
  }
}

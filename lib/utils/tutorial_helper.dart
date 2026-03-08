import 'package:shared_preferences/shared_preferences.dart';

class TutorialHelper {
  static String _keyForUser(String uid) => 'tutorial_seen_$uid';

  static Future<bool> hasSeenTutorial(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyForUser(uid)) ?? false;
  }

  static Future<void> setTutorialSeen(String uid, [bool seen = true]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyForUser(uid), seen);
  }

  static Future<void> clearTutorialSeen(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyForUser(uid));
  }
}
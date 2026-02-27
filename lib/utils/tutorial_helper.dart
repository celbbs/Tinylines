import 'package:shared_preferences/shared_preferences.dart';

class TutorialHelper {
  static const _key = 'tutorial_seen';

  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setTutorialSeen([bool seen = true]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, seen);
  }
}
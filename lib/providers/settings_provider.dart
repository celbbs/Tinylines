import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Owns all user-facing settings state
/// Registered at app root so every screen rebuilds when settings change
class SettingsProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  // defaults
  static const String defaultTheme = 'Light';
  static const Color defaultAccentColor = Color(0xFF4A90E2);
  static const String defaultFontSize = 'Medium';
  static const String defaultFontStyle = 'Sans Serif';
  static const bool defaultDailyPrompt = true;
  static const String defaultAutoSave = '30 seconds';
  static const TimeOfDay defaultReminderTime = TimeOfDay(hour: 19, minute: 0);
  static const bool defaultRemindersEnabled = true;
  static const bool defaultHidePreviews = false;

  // mutable state
  String selectedTheme = defaultTheme;
  Color selectedAccentColor = defaultAccentColor;
  String selectedFontSize = defaultFontSize;
  String selectedFontStyle = defaultFontStyle;
  bool dailyPromptEnabled = defaultDailyPrompt;
  String autoSaveInterval = defaultAutoSave;
  TimeOfDay dailyReminderTime = defaultReminderTime;
  bool remindersEnabled = defaultRemindersEnabled;
  bool hidePreviewsEnabled = defaultHidePreviews;

  String? _uid;

  // key helpers
  /// UID scoped storage key, same formula used by passcode page
  String storageKey(String name) => 'settings_${_uid ?? 'guest'}_$name';

  // Firestore helpers
  DocumentReference<Map<String, dynamic>>? get _firestoreDoc {
    if (_uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('settings')
        .doc('preferences');
  }

  Future<Map<String, dynamic>?> _loadFromFirestore() async {
    try {
      final snap = await _firestoreDoc?.get();
      if (snap != null && snap.exists && snap.data() != null) return snap.data();
    } catch (_) {
      // Offline or missing security rules — fall back to local storage silently
    }
    return null;
  }

  void _syncToFirestore(String key, String value) {
    _firestoreDoc
        ?.set({key: value}, SetOptions(merge: true))
        .catchError((_) {});
  }

  // load / save

  /// Called by AuthGate when a user signs in. loads from Firestore first and
  /// falls back to local secure storage when offline
  Future<void> loadForUser(String uid) async {
    _uid = uid;

    final remote = await _loadFromFirestore();
    String? r(String key) => remote?[key]?.toString();

    final theme            = r('theme')               ?? await _storage.read(key: storageKey('theme'));
    final fontSize         = r('fontSize')            ?? await _storage.read(key: storageKey('fontSize'));
    final fontStyle        = r('fontStyle')           ?? await _storage.read(key: storageKey('fontStyle'));
    final dailyPrompt      = r('dailyPromptEnabled')  ?? await _storage.read(key: storageKey('dailyPromptEnabled'));
    final autoSave         = r('autoSaveInterval')    ?? await _storage.read(key: storageKey('autoSaveInterval'));
    final remindersVal     = r('remindersEnabled')    ?? await _storage.read(key: storageKey('remindersEnabled'));
    final hidePreviewsVal  = r('hidePreviewsEnabled') ?? await _storage.read(key: storageKey('hidePreviewsEnabled'));
    final reminderHour     = r('reminderHour')        ?? await _storage.read(key: storageKey('reminderHour'));
    final reminderMinute   = r('reminderMinute')      ?? await _storage.read(key: storageKey('reminderMinute'));
    final accentColorValue = r('accentColor')         ?? await _storage.read(key: storageKey('accentColor'));

    selectedTheme       = theme     ?? defaultTheme;
    selectedFontSize    = fontSize  ?? defaultFontSize;
    selectedFontStyle   = fontStyle ?? defaultFontStyle;
    dailyPromptEnabled  = dailyPrompt   == null ? defaultDailyPrompt       : dailyPrompt   == 'true';
    autoSaveInterval    = autoSave      ?? defaultAutoSave;
    remindersEnabled    = remindersVal  == null ? defaultRemindersEnabled   : remindersVal  == 'true';
    hidePreviewsEnabled = hidePreviewsVal == null ? defaultHidePreviews     : hidePreviewsVal == 'true';

    if (reminderHour != null && reminderMinute != null) {
      dailyReminderTime = TimeOfDay(
        hour:   int.tryParse(reminderHour)   ?? defaultReminderTime.hour,
        minute: int.tryParse(reminderMinute) ?? defaultReminderTime.minute,
      );
    }

    if (accentColorValue != null) {
      selectedAccentColor =
          Color(int.tryParse(accentColorValue) ?? defaultAccentColor.value);
    }

    notifyListeners();
  }

  Future<void> _save(String key, String value) async {
    await _storage.write(key: storageKey(key), value: value);
    _syncToFirestore(key, value);
  }

  // public setters
  Future<void> setTheme(String theme) async {
    selectedTheme = theme;
    notifyListeners();
    await _save('theme', theme);
  }

  Future<void> setAccentColor(Color color) async {
    selectedAccentColor = color;
    notifyListeners();
    await _save('accentColor', color.value.toString());
  }

  Future<void> setFontSize(String size) async {
    selectedFontSize = size;
    notifyListeners();
    await _save('fontSize', size);
  }

  Future<void> setFontStyle(String style) async {
    selectedFontStyle = style;
    notifyListeners();
    await _save('fontStyle', style);
  }

  Future<void> setDailyPrompt(bool enabled) async {
    dailyPromptEnabled = enabled;
    notifyListeners();
    await _save('dailyPromptEnabled', enabled.toString());
  }

  Future<void> setAutoSave(String interval) async {
    autoSaveInterval = interval;
    notifyListeners();
    await _save('autoSaveInterval', interval);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    dailyReminderTime = time;
    notifyListeners();
    await _save('reminderHour', time.hour.toString());
    await _save('reminderMinute', time.minute.toString());
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    remindersEnabled = enabled;
    notifyListeners();
    await _save('remindersEnabled', enabled.toString());
  }

  Future<void> setHidePreviews(bool hide) async {
    hidePreviewsEnabled = hide;
    notifyListeners();
    await _save('hidePreviewsEnabled', hide.toString());
  }

  Future<void> resetToDefaults() async {
    selectedTheme       = defaultTheme;
    selectedAccentColor = defaultAccentColor;
    selectedFontSize    = defaultFontSize;
    selectedFontStyle   = defaultFontStyle;
    dailyPromptEnabled  = defaultDailyPrompt;
    autoSaveInterval    = defaultAutoSave;
    dailyReminderTime   = defaultReminderTime;
    remindersEnabled    = defaultRemindersEnabled;
    hidePreviewsEnabled = defaultHidePreviews;
    notifyListeners();

    await _save('theme',               selectedTheme);
    await _save('accentColor',         selectedAccentColor.value.toString());
    await _save('fontSize',            selectedFontSize);
    await _save('fontStyle',           selectedFontStyle);
    await _save('dailyPromptEnabled',  dailyPromptEnabled.toString());
    await _save('autoSaveInterval',    autoSaveInterval);
    await _save('remindersEnabled',    remindersEnabled.toString());
    await _save('hidePreviewsEnabled', hidePreviewsEnabled.toString());
    await _save('reminderHour',        dailyReminderTime.hour.toString());
    await _save('reminderMinute',      dailyReminderTime.minute.toString());
  }

  /// Call on sign-out so app reverts to defaults until the next user loads
  void resetForSignOut() {
    _uid                = null;
    selectedTheme       = defaultTheme;
    selectedAccentColor = defaultAccentColor;
    selectedFontSize    = defaultFontSize;
    selectedFontStyle   = defaultFontStyle;
    dailyPromptEnabled  = defaultDailyPrompt;
    autoSaveInterval    = defaultAutoSave;
    dailyReminderTime   = defaultReminderTime;
    remindersEnabled    = defaultRemindersEnabled;
    hidePreviewsEnabled = defaultHidePreviews;
    notifyListeners();
  }

  // derived display values
  double get baseFontSize {
    switch (selectedFontSize) {
      case 'Small': return 13.0;
      case 'Large': return 18.0;
      default:      return 15.0;
    }
  }

  String? get fontFamily {
    switch (selectedFontStyle) {
      case 'Serif':       return GoogleFonts.merriweather().fontFamily;
      case 'Handwriting': return GoogleFonts.caveat().fontFamily;
      default:            return null; // null = system sans-serif
    }
  }

  Color get backgroundColor {
    switch (selectedTheme) {
      case 'Dark':   return const Color(0xFF1a1a1a);
      case 'Pastel': return const Color(0xFFFFF5F7);
      default:       return Colors.white;
    }
  }

  Color get textColor {
    switch (selectedTheme) {
      case 'Dark':   return Colors.white;
      case 'Pastel': return const Color(0xFF5a4a5a);
      default:       return Colors.black87;
    }
  }

  Color get secondaryTextColor {
    switch (selectedTheme) {
      case 'Dark':   return Colors.white70;
      case 'Pastel': return const Color(0xFF8a7a8a);
      default:       return Colors.black54;
    }
  }

  Color get cardColor {
    switch (selectedTheme) {
      case 'Dark':   return const Color(0xFF2a2a2a);
      case 'Pastel': return const Color(0xFFffe4eb);
      default:       return Colors.grey.shade100;
    }
  }

  // ThemeData
  /// Full MaterialApp-compatible ThemeData derived from current settings
  /// Wrap MaterialApp with Consumer<SettingsProvider> and pass this as `theme`
  ThemeData get themeData {
    final isDark = selectedTheme == 'Dark';
    final base = isDark ? ThemeData.dark() : ThemeData.light();

    TextStyle styled(TextStyle s) =>
        s.copyWith(fontFamily: fontFamily, color: textColor);

    final tt = base.textTheme;
    final textTheme = tt.copyWith(
      displayLarge:   styled(tt.displayLarge!),
      displayMedium:  styled(tt.displayMedium!),
      displaySmall:   styled(tt.displaySmall!),
      headlineLarge:  styled(tt.headlineLarge!),
      headlineMedium: styled(tt.headlineMedium!),
      headlineSmall:  styled(tt.headlineSmall!),
      titleLarge:     styled(tt.titleLarge!),
      titleMedium:    styled(tt.titleMedium!),
      titleSmall:     styled(tt.titleSmall!),
      bodyLarge:      styled(tt.bodyLarge!).copyWith(fontSize: baseFontSize + 1),
      bodyMedium:     styled(tt.bodyMedium!).copyWith(fontSize: baseFontSize),
      bodySmall:      styled(tt.bodySmall!).copyWith(fontSize: baseFontSize - 1),
      labelLarge:     styled(tt.labelLarge!),
      labelMedium:    styled(tt.labelMedium!),
      labelSmall:     styled(tt.labelSmall!),
    );

    return base.copyWith(
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: selectedAccentColor,
        secondary: selectedAccentColor,
        surface: cardColor,
        onSurface: textColor,
        onPrimary: Colors.white,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? selectedAccentColor : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? selectedAccentColor.withOpacity(0.5)
              : null,
        ),
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
    );
  }
}
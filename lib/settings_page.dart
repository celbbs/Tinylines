import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tutorial_page.dart';
import 'passcode_page.dart';
import '../services/notification_service.dart';
import 'package:tinylines/utils/tutorial_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _storage = const FlutterSecureStorage();

  // state variables
  String selectedTheme = 'Light';
  Color selectedAccentColor = const Color(0xFF4A90E2);
  String selectedFontSize = 'Medium';
  String selectedFontStyle = 'Sans Serif';
  bool dailyPromptEnabled = true;
  String autoSaveInterval = '30 seconds';
  TimeOfDay dailyReminderTime = const TimeOfDay(hour: 19, minute: 0);
  bool remindersEnabled = true;
  bool hidePreviewsEnabled = false;
  bool _pinIsSet = false;

  // default values
  static const String _defaultTheme = 'Light';
  static const Color _defaultAccentColor = Color(0xFF4A90E2);
  static const String _defaultFontSize = 'Medium';
  static const String _defaultFontStyle = 'Sans Serif';
  static const bool _defaultDailyPrompt = true;
  static const String _defaultAutoSave = '30 seconds';
  static const TimeOfDay _defaultReminderTime = TimeOfDay(hour: 19, minute: 0);
  static const bool _defaultRemindersEnabled = true;
  static const bool _defaultHidePreviews = false;

  // accent colors
  final List<Color> accentColors = [
    const Color(0xFF4A90E2),
    const Color(0xFF50C878),
    const Color(0xFFE74C3C),
    const Color(0xFF9B59B6),
    const Color(0xFFF39C12),
    const Color(0xFF1ABC9C),
  ];

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final pin = await _storage.read(key: 'app_passcode');
    if (mounted) {
      setState(() => _pinIsSet = pin != null && pin.isNotEmpty);
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out')),
      );
    }
  }

  double get baseFontSize {
    switch (selectedFontSize) {
      case 'Small':
        return 13.0;
      case 'Large':
        return 18.0;
      default:
        return 15.0;
    }
  }

  String? get selectedFontFamily {
    switch (selectedFontStyle) {
      case 'Serif':
        return 'serif';
      case 'Handwriting':
        return GoogleFonts.caveat().fontFamily;
      default:
        return null;
    }
  }

  Color get backgroundColor {
    switch (selectedTheme) {
      case 'Light':
        return Colors.white;
      case 'Dark':
        return const Color(0xFF1a1a1a);
      case 'Pastel':
        return const Color(0xFFFFF5F7);
      default:
        return Colors.white;
    }
  }

  Color get textColor {
    switch (selectedTheme) {
      case 'Light':
        return Colors.black87;
      case 'Dark':
        return Colors.white;
      case 'Pastel':
        return const Color(0xFF5a4a5a);
      default:
        return Colors.black87;
    }
  }

  Color get secondaryTextColor {
    switch (selectedTheme) {
      case 'Light':
        return Colors.black54;
      case 'Dark':
        return Colors.white70;
      case 'Pastel':
        return const Color(0xFF8a7a8a);
      default:
        return Colors.black54;
    }
  }

  Color get cardColor {
    switch (selectedTheme) {
      case 'Light':
        return Colors.grey.shade100;
      case 'Dark':
        return const Color(0xFF2a2a2a);
      case 'Pastel':
        return const Color(0xFFffe4eb);
      default:
        return Colors.grey.shade100;
    }
  }

  Color get appBarColor {
    switch (selectedTheme) {
      case 'Light':
        return Colors.white;
      case 'Dark':
        return const Color(0xFF1a1a1a);
      case 'Pastel':
        return const Color(0xFFFFF5F7);
      default:
        return Colors.white;
    }
  }

  Future<void> _openPasscodePage() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PasscodePage(
          isChanging: _pinIsSet,
          backgroundColor: backgroundColor,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          cardColor: cardColor,
          accentColor: selectedAccentColor,
          fontFamily: selectedFontFamily,
          fontSize: baseFontSize,
        ),
      ),
    );
    if (saved == true) {
      _checkPinStatus();
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Reset Settings',
          style: TextStyle(color: textColor, fontFamily: selectedFontFamily),
        ),
        content: Text(
          'This will restore all settings to their defaults:\n\n'
          '• Theme: Dark\n'
          '• Font: Medium / Sans Serif\n'
          '• Accent Color: Blue\n'
          '• Daily Prompt: On\n'
          '• Auto-Save: 30 seconds\n'
          '• Reminders: On at 7:00 PM\n'
          '• Hide Previews: Off',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: baseFontSize,
            fontFamily: selectedFontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: secondaryTextColor)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                selectedTheme = _defaultTheme;
                selectedAccentColor = _defaultAccentColor;
                selectedFontSize = _defaultFontSize;
                selectedFontStyle = _defaultFontStyle;
                dailyPromptEnabled = _defaultDailyPrompt;
                autoSaveInterval = _defaultAutoSave;
                dailyReminderTime = _defaultReminderTime;
                remindersEnabled = _defaultRemindersEnabled;
                hidePreviewsEnabled = _defaultHidePreviews;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults.')),
              );
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Delete Account',
          style: TextStyle(color: Colors.red, fontFamily: selectedFontFamily),
        ),
        content: Text(
          'Are you sure you want to permanently delete your account? '
          'All your journal entries and settings will be lost and cannot be recovered.',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: baseFontSize,
            fontFamily: selectedFontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: secondaryTextColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: selectedFontFamily,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('APPEARANCE'),
            const SizedBox(height: 12),

            _buildSettingLabel('Theme'),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildThemeOption('Light', Icons.wb_sunny_outlined),
                const SizedBox(width: 12),
                _buildThemeOption('Dark', Icons.nightlight_round),
                const SizedBox(width: 12),
                _buildThemeOption('Pastel', Icons.palette_outlined),
              ],
            ),
            const SizedBox(height: 20),

            _buildSettingLabel('Accent Color'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: accentColors.map(_buildColorOption).toList(),
              ),
            ),
            const SizedBox(height: 20),

            _buildDropdownSetting(
              'Font Size',
              selectedFontSize,
              ['Small', 'Medium', 'Large'],
              (value) => setState(() => selectedFontSize = value!),
            ),
            const SizedBox(height: 16),

            _buildDropdownSetting(
              'Font Style',
              selectedFontStyle,
              ['Sans Serif', 'Serif', 'Handwriting'],
              (value) => setState(() => selectedFontStyle = value!),
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('JOURNALING'),
            const SizedBox(height: 12),
            _buildToggleSetting(
              'Daily Prompt',
              dailyPromptEnabled,
              (value) => setState(() => dailyPromptEnabled = value),
            ),
            const SizedBox(height: 16),
            _buildDropdownSetting(
              'Auto-Save',
              autoSaveInterval,
              ['10 seconds', '30 seconds', '60 seconds'],
              (value) => setState(() => autoSaveInterval = value!),
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('APP TUTORIAL'),
            const SizedBox(height: 12),
            _buildTappableSetting(
              'Show Tutorial',
              onTap: () async {
                await TutorialHelper.setTutorialSeen(false);
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TutorialPage()),
                );
              },
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('NOTIFICATIONS'),
            const SizedBox(height: 12),
            _buildTimeSetting(
              'Daily Reminder',
              dailyReminderTime,
              () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: dailyReminderTime,
                );
                if (picked != null) {
                  setState(() => dailyReminderTime = picked);
                  if (remindersEnabled) {
                    await NotificationService.instance.scheduleDailyReminder(
                      hour: picked.hour,
                      minute: picked.minute,
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            _buildToggleSetting(
              'Reminders Enabled',
              remindersEnabled,
              (value) async {
                setState(() => remindersEnabled = value);
                if (value) {
                  await NotificationService.instance.scheduleDailyReminder(
                    hour: dailyReminderTime.hour,
                    minute: dailyReminderTime.minute,
                  );
                } else {
                  await NotificationService.instance.cancelDailyReminder();
                }
              },
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('PRIVACY'),
            const SizedBox(height: 12),
            _buildNavigationSetting(
              'App Passcode',
              _pinIsSet ? 'Change' : 'Set',
              onTap: _openPasscodePage,
            ),
            const SizedBox(height: 16),
            _buildToggleSetting(
              'Hide Previews',
              hidePreviewsEnabled,
              (value) => setState(() => hidePreviewsEnabled = value),
            ),
            const SizedBox(height: 32),

            _buildSectionHeader('ACCOUNT'),
            const SizedBox(height: 12),

            _buildNavigationSetting('Profile Name', 'Arianna'),
            const SizedBox(height: 16),

            _buildTappableSetting('Reset Settings', onTap: _showResetDialog),
            const SizedBox(height: 16),

            _buildTappableSetting(
              'Log Out',
              onTap: _signOut,
            ),
            const SizedBox(height: 16),

            _buildDeleteAccountSetting(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(
        title,
        style: TextStyle(
          color: selectedAccentColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontFamily: selectedFontFamily,
        ),
      );

  Widget _buildSettingLabel(String label) => Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: baseFontSize,
          fontWeight: FontWeight.w500,
          fontFamily: selectedFontFamily,
        ),
      );

  Widget _buildThemeOption(String theme, IconData icon) {
    final isSelected = selectedTheme == theme;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTheme = theme),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedAccentColor : cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : secondaryTextColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                theme,
                style: TextStyle(
                  color: isSelected ? Colors.white : secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: selectedFontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = selectedAccentColor == color;
    return GestureDetector(
      onTap: () => setState(() => selectedAccentColor = color),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: textColor, width: 3) : null,
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSettingLabel(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, size: 20, color: textColor),
            style: TextStyle(
              color: textColor,
              fontSize: baseFontSize,
              fontFamily: selectedFontFamily,
            ),
            dropdownColor: cardColor,
            onChanged: onChanged,
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: TextStyle(
                        color: textColor,
                        fontSize: baseFontSize,
                        fontFamily: selectedFontFamily,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting(
    String label,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSettingLabel(label),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: selectedAccentColor,
        ),
      ],
    );
  }

  Widget _buildTimeSetting(String label, TimeOfDay time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSettingLabel(label),
          Text(
            time.format(context),
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: baseFontSize,
              fontFamily: selectedFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSetting(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSettingLabel(label),
          Row(
            children: [
              if (value.isNotEmpty)
                Text(
                  value,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: baseFontSize,
                    fontFamily: selectedFontFamily,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: secondaryTextColor.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTappableSetting(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSettingLabel(label),
          Icon(
            Icons.chevron_right,
            color: secondaryTextColor.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountSetting() {
    return GestureDetector(
      onTap: _showDeleteAccountDialog,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Delete Account',
            style: TextStyle(
              color: Colors.red,
              fontSize: baseFontSize,
              fontWeight: FontWeight.w500,
              fontFamily: selectedFontFamily,
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: secondaryTextColor.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    );
  }
}
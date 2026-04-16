import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'tutorial_page.dart';
import 'passcode_page.dart';
import 'screens/auth_screen.dart';
import '../services/notification_service.dart';
import 'package:tinylines/utils/tutorial_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _storage = const FlutterSecureStorage();

  // tracks whether a pin has been set
  bool _pinIsSet = false;

  // available accent colors
  final List<Color> accentColors = [
    const Color(0xFF4A90E2),
    const Color(0xFF50C878),
    const Color(0xFFE74C3C),
    const Color(0xFF9B59B6),
    const Color(0xFFF39C12),
    const Color(0xFF1ABC9C),
  ];

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // returns display name, email, or uid as fallback
  String get _profileName {
    final user = _currentUser;
    if (user == null) return 'Not signed in';
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null && user.email!.trim().isNotEmpty) {
      return user.email!;
    }
    return user.uid;
  }

  // returns the user's email or a fallback string
  String get _userEmail {
    final user = _currentUser;
    if (user == null) return '';
    return user.email ?? '';
  }

  String _key(String name) =>
      context.read<SettingsProvider>().storageKey(name);

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final pin = await _storage.read(key: _key('app_passcode'));
    if (mounted) {
      setState(() => _pinIsSet = pin != null && pin.isNotEmpty);
    }
  }

Future<void> _signOut() async {
  try {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to log out. Please try again.')),
    );
  }
}

  // sends a password reset email to the user's address
  Future<void> _sendPasswordReset() async {
    final user = _currentUser;
    if (user == null || user.email == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to ${user.email}'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send reset email. Please try again.')),
      );
    }
  }

  Future<void> _openPasscodePage() async {
    final s = context.read<SettingsProvider>();
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PasscodePage(
          isChanging: _pinIsSet,
          pinStorageKey: s.storageKey('app_passcode'),
          backgroundColor: s.backgroundColor,
          textColor: s.textColor,
          secondaryTextColor: s.secondaryTextColor,
          cardColor: s.cardColor,
          accentColor: s.selectedAccentColor,
          fontFamily: s.fontFamily,
          fontSize: s.baseFontSize,
        ),
      ),
    );
    if (saved == true) {
      _checkPinStatus();
    }
  }

  void _showResetDialog() {
    final s = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: s.cardColor,
        title: Text(
          'Reset Settings',
          style: TextStyle(color: s.textColor, fontFamily: s.fontFamily),
        ),
        content: Text(
          'This will restore all settings to their defaults.',
          style: TextStyle(
            color: s.secondaryTextColor,
            fontSize: s.baseFontSize,
            fontFamily: s.fontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: s.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () async {
              await s.resetToDefaults();
              if (!mounted) return;
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
    final s = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: s.cardColor,
        title: Text(
          'Delete Account',
          style: TextStyle(color: Colors.red, fontFamily: s.fontFamily),
        ),
        content: Text(
          'Are you sure you want to permanently delete your account? '
          'All your journal entries and settings will be lost and cannot be recovered.',
          style: TextStyle(
            color: s.secondaryTextColor,
            fontSize: s.baseFontSize,
            fontFamily: s.fontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: s.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
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

  Future<void> _deleteAccount() async {
    final user = _currentUser;
    if (user == null) return;

    final uid = user.uid;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // delete firestore document first
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .delete()
          .onError((_, __) => null);

      // wipe local storage
      await _storage.deleteAll();

      // delete firebase auth account — triggers authgate to navigate to auth screen
      await user.delete();

      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (!mounted) return;

      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'For security, please sign out and sign back in before deleting your account.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete account: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // rebuilds live when settings change
    final s = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: s.backgroundColor,
      appBar: AppBar(
        backgroundColor: s.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: s.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: s.fontFamily,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // appearance section
            _buildSectionHeader('APPEARANCE', s),
            const SizedBox(height: 12),

            _buildSettingLabel('Theme', s),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildThemeOption('Light', Icons.wb_sunny_outlined, s),
                const SizedBox(width: 12),
                _buildThemeOption('Dark', Icons.nightlight_round, s),
                const SizedBox(width: 12),
                _buildThemeOption('Pastel', Icons.palette_outlined, s),
              ],
            ),
            const SizedBox(height: 20),

            _buildSettingLabel('Accent Color', s),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: accentColors.map((c) => _buildColorOption(c, s)).toList(),
              ),
            ),
            const SizedBox(height: 20),

            _buildDropdownSetting(
              'Font Size',
              s.selectedFontSize,
              ['Small', 'Medium', 'Large'],
              s,
              (value) => s.setFontSize(value!),
            ),
            const SizedBox(height: 16),

            _buildDropdownSetting(
              'Font Style',
              s.selectedFontStyle,
              ['Sans Serif', 'Serif', 'Handwriting'],
              s,
              (value) => s.setFontStyle(value!),
            ),
            const SizedBox(height: 32),

            // journaling section
            _buildSectionHeader('JOURNALING', s),
            const SizedBox(height: 12),
            _buildToggleSetting(
              'Daily Prompt',
              s.dailyPromptEnabled,
              s,
              (value) => s.setDailyPrompt(value),
            ),
            const SizedBox(height: 16),
            _buildDropdownSetting(
              'Auto-Save',
              s.autoSaveInterval,
              ['10 seconds', '30 seconds', '60 seconds'],
              s,
              (value) => s.setAutoSave(value!),
            ),
            const SizedBox(height: 32),

            // notifications section
            _buildSectionHeader('NOTIFICATIONS', s),
            const SizedBox(height: 12),
            _buildTimeSetting(
              'Daily Reminder',
              s.dailyReminderTime,
              s,
              () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: s.dailyReminderTime,
                );
                if (picked != null) {
                  await s.setReminderTime(picked);
                  if (s.remindersEnabled) {
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
              s.remindersEnabled,
              s,
              (value) async {
                await s.setRemindersEnabled(value);
                if (value) {
                  await NotificationService.instance.scheduleDailyReminder(
                    hour: s.dailyReminderTime.hour,
                    minute: s.dailyReminderTime.minute,
                  );
                } else {
                  await NotificationService.instance.cancelDailyReminder();
                }
              },
            ),
            const SizedBox(height: 32),

            // privacy section
            _buildSectionHeader('PRIVACY', s),
            const SizedBox(height: 12),
            _buildNavigationSetting(
              'App Passcode',
              _pinIsSet ? 'Change' : 'Set',
              s,
              onTap: _openPasscodePage,
            ),
            const SizedBox(height: 16),
            _buildToggleSetting(
              'Hide Previews',
              s.hidePreviewsEnabled,
              s,
              (value) => s.setHidePreviews(value),
            ),
            const SizedBox(height: 32),

            // app tutorial section
            _buildSectionHeader('APP TUTORIAL', s),
            const SizedBox(height: 12),
            _buildTappableSetting(
              'Show Tutorial',
              s,
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

            // account section
            _buildSectionHeader('ACCOUNT', s),
            const SizedBox(height: 12),

            // shows display name
            _buildNavigationSetting('Profile Name', _profileName, s),
            const SizedBox(height: 16),

            // shows email as read-only
            _buildNavigationSetting('Email', _userEmail, s),
            const SizedBox(height: 16),

            // sends a password reset email
            _buildTappableSetting(
              'Change Password',
              s,
              onTap: _sendPasswordReset,
            ),
            const SizedBox(height: 16),

            _buildTappableSetting('Reset Settings', s, onTap: _showResetDialog),
            const SizedBox(height: 16),

            _buildTappableSetting('Log Out', s, onTap: _signOut),
            const SizedBox(height: 16),

            _buildDeleteAccountSetting(s),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, SettingsProvider s) => Text(
        title,
        style: TextStyle(
          color: s.selectedAccentColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontFamily: s.fontFamily,
        ),
      );

  Widget _buildSettingLabel(String label, SettingsProvider s) => Text(
        label,
        style: TextStyle(
          color: s.textColor,
          fontSize: s.baseFontSize,
          fontWeight: FontWeight.w500,
          fontFamily: s.fontFamily,
        ),
      );

  Widget _buildThemeOption(String theme, IconData icon, SettingsProvider s) {
    final isSelected = s.selectedTheme == theme;
    return Expanded(
      child: GestureDetector(
        onTap: () => s.setTheme(theme),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? s.selectedAccentColor : s.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : s.secondaryTextColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                theme,
                style: TextStyle(
                  color: isSelected ? Colors.white : s.secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: s.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color, SettingsProvider s) {
    final isSelected = s.selectedAccentColor == color;
    return GestureDetector(
      onTap: () => s.setAccentColor(color),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: s.textColor, width: 3) : null,
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(
    String label,
    String value,
    List<String> options,
    SettingsProvider s,
    void Function(String?) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSettingLabel(label, s),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: s.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, size: 20, color: s.textColor),
            style: TextStyle(
              color: s.textColor,
              fontSize: s.baseFontSize,
              fontFamily: s.fontFamily,
            ),
            dropdownColor: s.cardColor,
            onChanged: onChanged,
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: TextStyle(
                        color: s.textColor,
                        fontSize: s.baseFontSize,
                        fontFamily: s.fontFamily,
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
    SettingsProvider s,
    void Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSettingLabel(label, s),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: s.selectedAccentColor,
        ),
      ],
    );
  }

  Widget _buildTimeSetting(
      String label, TimeOfDay time, SettingsProvider s, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSettingLabel(label, s),
          Text(
            time.format(context),
            style: TextStyle(
              color: s.secondaryTextColor,
              fontSize: s.baseFontSize,
              fontFamily: s.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSetting(String label, String value, SettingsProvider s,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSettingLabel(label, s),
          Row(
            children: [
              if (value.isNotEmpty)
                Text(
                  value,
                  style: TextStyle(
                    color: s.secondaryTextColor,
                    fontSize: s.baseFontSize,
                    fontFamily: s.fontFamily,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: s.secondaryTextColor.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTappableSetting(String label, SettingsProvider s,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSettingLabel(label, s),
          Icon(
            Icons.chevron_right,
            color: s.secondaryTextColor.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountSetting(SettingsProvider s) {
    return GestureDetector(
      onTap: _showDeleteAccountDialog,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Delete Account',
            style: TextStyle(
              color: Colors.red,
              fontSize: s.baseFontSize,
              fontWeight: FontWeight.w500,
              fontFamily: s.fontFamily,
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: s.secondaryTextColor.withOpacity(0.5),
            size: 20,
          ),
        ],
      ),
    );
  }
}
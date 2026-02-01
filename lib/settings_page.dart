import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // State variables
  String selectedTheme = 'Dark';
  Color selectedAccentColor = const Color(0xFF4A90E2);
  String selectedFontSize = 'Medium';
  String selectedFontStyle = 'Sans Serif';
  bool dailyPromptEnabled = true;
  String autoSaveInterval = '30 seconds';
  TimeOfDay dailyReminderTime = const TimeOfDay(hour: 19, minute: 0);
  bool remindersEnabled = true;
  bool hidePreviewsEnabled = false;

  // all accent colors
  final List<Color> accentColors = [
    const Color(0xFF4A90E2), // blue
    const Color(0xFF50C878), // green
    const Color(0xFFE74C3C), // red
    const Color(0xFF9B59B6), // purple
    const Color(0xFFF39C12), // orange
    const Color(0xFF1ABC9C), // teal
  ];

  // get theme colors based on selected theme
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
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // APPEARANCE Section
          _buildSectionHeader('APPEARANCE'),
          const SizedBox(height: 12),
          
          // Theme
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

          // Accent color
          _buildSettingLabel('Accent Color'),
          const SizedBox(height: 8),
          Row(
            children: accentColors.map((color) => 
              _buildColorOption(color)
            ).toList(),
          ),
          const SizedBox(height: 20),

          // font size
          _buildDropdownSetting(
            'Font Size',
            selectedFontSize,
            ['Small', 'Medium', 'Large'],
            (value) => setState(() => selectedFontSize = value!),
          ),
          const SizedBox(height: 16),

          // Font style
          _buildDropdownSetting(
            'Font Style',
            selectedFontStyle,
            ['Sans Serif', 'Serif', 'Handwriting'],
            (value) => setState(() => selectedFontStyle = value!),
          ),
          const SizedBox(height: 32),

          // JOURNALING Section
          _buildSectionHeader('JOURNALING'),
          const SizedBox(height: 12),

          // daily prompt
          _buildToggleSetting(
            'Daily Prompt',
            dailyPromptEnabled,
            (value) => setState(() => dailyPromptEnabled = value),
          ),
          const SizedBox(height: 16),

          // auto save
          _buildDropdownSetting(
            'Auto-Save',
            autoSaveInterval,
            ['10 seconds', '30 seconds', '60 seconds'],
            (value) => setState(() => autoSaveInterval = value!),
          ),
          const SizedBox(height: 32),

          // notifs section
          _buildSectionHeader('NOTIFICATIONS'),
          const SizedBox(height: 12),

          // Daily reminder
          _buildTimeSetting(
            'Daily Reminder',
            dailyReminderTime,
            () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: dailyReminderTime,
              );
              if (picked != null) {
                setState(() => dailyReminderTime = picked);
              }
            },
          ),
          const SizedBox(height: 16),

          // reminders enabled
          _buildToggleSetting(
            'Reminders Enabled',
            remindersEnabled,
            (value) => setState(() => remindersEnabled = value),
          ),
          const SizedBox(height: 32),

          // privacy Section
          _buildSectionHeader('PRIVACY'),
          const SizedBox(height: 12),

          // App passcode
          _buildNavigationSetting('App Passcode', 'Set'),
          const SizedBox(height: 16),

          // Hide previews
          _buildToggleSetting(
            'Hide Previews',
            hidePreviewsEnabled,
            (value) => setState(() => hidePreviewsEnabled = value),
          ),
          const SizedBox(height: 32),

          // Account Section
          _buildSectionHeader('ACCOUNT'),
          const SizedBox(height: 12),

          // Profile Name
          _buildNavigationSetting('Profile Name', 'Arianna'),
          const SizedBox(height: 16),

          // Reset Settings
          _buildNavigationSetting('Reset Settings', ''),
          const SizedBox(height: 16),

          // Delete Account
          _buildDeleteAccountSetting(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: selectedAccentColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }

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
          border: isSelected 
            ? Border.all(color: textColor, width: 3)
            : null,
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
              fontSize: 14,
            ),
            dropdownColor: cardColor,
            onChanged: onChanged,
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
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

  Widget _buildTimeSetting(
    String label,
    TimeOfDay time,
    VoidCallback onTap,
  ) {
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
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSetting(String label, String value) {
    return GestureDetector(
      onTap: () {
        // navigate to respective settings page
      },
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
                    fontSize: 15,
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

  Widget _buildDeleteAccountSetting() {
    return GestureDetector(
      onTap: () {
        // show delete acct confirmation dialog
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Delete Account',
            style: TextStyle(
              color: Colors.red,
              fontSize: 15,
              fontWeight: FontWeight.w500,
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
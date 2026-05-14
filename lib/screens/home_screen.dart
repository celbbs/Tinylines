import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import '../utils/app_theme.dart';
import 'entry_editor_screen.dart';
import 'on_this_day_screen.dart';
import '../settings_page.dart';
import '../providers/settings_provider.dart';

// shows calendar and recent entries
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // returns a greeting based on time of day and user's display name
  String _getGreeting() {
    final hour = DateTime.now().hour;
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.split(' ').first ?? 'there';

    if (hour < 12) return 'Good morning, $name';
    if (hour < 17) return 'Good afternoon, $name';
    return 'Good evening, $name';
  }

  // builds the greeting text widget
  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingM, AppTheme.spacingM, AppTheme.spacingM, 0,
      ),
      child: Text(
        _getGreeting(),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TinyLines'),
        // settings button in top left
        leading: IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
          },
        ),
        // on this day button in top right
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_stories),
            tooltip: 'On This Day',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OnThisDayScreen(),
                ),
              );
            },
          ),
        ],
      ),
      // listens to both journal and settings providers
      body: Consumer2<JournalProvider, SettingsProvider>(
        builder: (context, provider, settings, child) {
          // show loading spinner while entries are being fetched
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(),
                const SizedBox(height: AppTheme.spacingM),
                _buildCalendar(provider),
                const SizedBox(height: AppTheme.spacingL),
                _buildRecentEntries(provider, settings.hidePreviewsEnabled),
              ],
            ),
          );
        },
      ),
      // create a new entry for today
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewEntry(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // builds the monthly calendar
  Widget _buildCalendar(JournalProvider provider) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: TableCalendar(
        firstDay: DateTime(2020, 1, 1),
        lastDay: DateTime(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _onDaySelected(selectedDay, provider);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          // today shown 
          todayDecoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          // selected day shown with primary color
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          // dot marker shown on days with entries
          markerDecoration: const BoxDecoration(
            color: AppTheme.successColor,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
          ),
          weekendTextStyle: TextStyle(
            color: AppTheme.textPrimary.withValues(alpha: 0.6),
          ),
          outsideTextStyle: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.4),
          ),
        ),
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: AppTheme.primaryColor,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: AppTheme.primaryColor,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        // adds a marker dot on days that have a journal entry
        eventLoader: (day) {
          return provider.hasEntryForDate(day) ? [true] : [];
        },
      ),
    );
  }

  // builds the recent entries list, or an empty state if none exist
  Widget _buildRecentEntries(JournalProvider provider, bool hidePreview) {
    final recentEntries = provider.getRecentEntries(limit: 5);

    // show empty state if user has no entries yet
    if (recentEntries.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 64,
                color: AppTheme.textHint,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'No entries yet',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Tap + to create your first entry',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // show list of recent entries
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          child: Text(
            'Recent Entries',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        ...recentEntries.map((entry) => _buildEntryCard(entry, hidePreview)),
        const SizedBox(height: AppTheme.spacingXxl),
      ],
    );
  }

  // builds a single entry card with date, content preview, and image indicator
  Widget _buildEntryCard(JournalEntry entry, bool hidePreview) {
    return Card(
      child: InkWell(
        onTap: () => _viewEntry(entry),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // entry date in primary color
                  Text(
                    entry.formattedDate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  // show image icon if entry has a photo
                  if (entry.imagePath != null)
                    const Icon(
                      Icons.image,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              // hide content preview if privacy setting is on
              if (hidePreview)
                Text(
                  'Preview hidden',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                )
              else
                Text(
                  entry.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // opens existing entry or creates new one when a day is tapped
  void _onDaySelected(DateTime selectedDay, JournalProvider provider) {
    final entry = provider.getEntryForDate(selectedDay);
    if (entry != null) {
      _viewEntry(entry);
    } else {
      _createEntryForDate(selectedDay);
    }
  }

  // opens today's entry or creates a new one
  void _createNewEntry(BuildContext context) {
    final provider = Provider.of<JournalProvider>(context, listen: false);
    final today = DateTime.now();
    final todayEntry = provider.getEntryForDate(today);

    if (todayEntry != null) {
      _viewEntry(todayEntry);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EntryEditorScreen(),
        ),
      );
    }
  }

  // navigates to entry editor for a specific date
  void _createEntryForDate(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryEditorScreen(date: date),
      ),
    );
  }

  // opens an existing entry in the editor
  void _viewEntry(JournalEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryEditorScreen(entry: entry),
      ),
    );
  }
}
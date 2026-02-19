import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import '../utils/app_theme.dart';
import 'entry_editor_screen.dart';
import 'on_this_day_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  title: const Text('TinyLines'),
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
      body: Consumer<JournalProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildCalendar(provider),
                const SizedBox(height: AppTheme.spacingL),
                _buildRecentEntries(provider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewEntry(context),
        child: const Icon(Icons.add),
      ),
    );
  }

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
          // Today's date styling
          todayDecoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          // Selected day styling
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          // Days with entries
          markerDecoration: const BoxDecoration(
            color: AppTheme.successColor,
            shape: BoxShape.circle,
          ),
          // Default day styling
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
        // Event loader - shows dots for days with entries
        eventLoader: (day) {
          return provider.hasEntryForDate(day) ? [true] : [];
        },
      ),
    );
  }

  Widget _buildRecentEntries(JournalProvider provider) {
    final recentEntries = provider.getRecentEntries(limit: 5);

    if (recentEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'No entries yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Tap + to create your first entry',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

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
        ...recentEntries.map((entry) => _buildEntryCard(entry)),
        const SizedBox(height: AppTheme.spacingXxl),
      ],
    );
  }

  Widget _buildEntryCard(JournalEntry entry) {
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
                  Text(
                    entry.formattedDate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  if (entry.imagePath != null)
                    const Icon(
                      Icons.image,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
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

  void _onDaySelected(DateTime selectedDay, JournalProvider provider) {
    final entry = provider.getEntryForDate(selectedDay);
    if (entry != null) {
      _viewEntry(entry);
    } else {
      _createEntryForDate(selectedDay);
    }
  }

  void _createNewEntry(BuildContext context) {
    final provider = Provider.of<JournalProvider>(context, listen: false);
    final today = DateTime.now();
    final todayEntry = provider.getEntryForDate(today);

    if (todayEntry != null) {
      // Entry already exists for today, open it for editing
      _viewEntry(todayEntry);
    } else {
      // No entry for today, create new one
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EntryEditorScreen(),
        ),
      );
    }
  }

  void _createEntryForDate(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryEditorScreen(date: date),
      ),
    );
  }

  void _viewEntry(JournalEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryEditorScreen(entry: entry),
      ),
    );
  }
}

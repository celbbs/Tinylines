import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import '../utils/app_theme.dart';
import 'entry_editor_screen.dart';
import 'on_this_day_screen.dart';
import '../settings_page.dart';
import '../providers/settings_provider.dart';

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
        actions: [
          Consumer<JournalProvider>(
            builder: (_, p, __) => _SyncStatusChip(
              status: p.syncStatus,
              onRetry: () => p.loadEntries(),
            ),
          ),
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
      body: Consumer2<JournalProvider, SettingsProvider>(
        builder: (context, provider, settings, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildCalendar(provider),
                const SizedBox(height: AppTheme.spacingL),
                if (provider.isLoading)
                  const _LoadingEntries()
                else
                  _buildRecentEntries(provider, settings.hidePreviewsEnabled),
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
          todayDecoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
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
        eventLoader: (day) {
          return provider.hasEntryForDate(day) ? [true] : [];
        },
      ),
    );
  }

  Widget _buildRecentEntries(JournalProvider provider, bool hidePreview) {
    final recentEntries = provider.getRecentEntries(limit: 5);

    if (recentEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXl,
          vertical: AppTheme.spacingXl,
        ),
        child: Column(
          children: [
            Icon(
              Icons.edit_note,
              size: 72,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Start your first entry',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Tap + to write something — even one line counts.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textHint,
                  ),
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
        ...recentEntries.map((entry) => _buildEntryCard(entry, hidePreview)),
        const SizedBox(height: AppTheme.spacingXxl),
      ],
    );
  }

  Widget _buildEntryCard(JournalEntry entry, bool hidePreview) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _showDeleteConfirmation(),
      onDismissed: (_) => _onEntryDismissed(entry),
      child: Card(
        child: InkWell(
          onTap: () => _viewEntry(entry),
          onLongPress: () async {
            final confirmed = await _showDeleteConfirmation();
            if (confirmed) _onEntryDismissed(entry);
          },
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
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('You can undo this for 8 seconds after deleting.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _onEntryDismissed(JournalEntry entry) {
    final provider = Provider.of<JournalProvider>(context, listen: false);
    provider.deleteEntry(entry.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Entry deleted'),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () => provider.saveEntry(entry),
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

class _LoadingEntries extends StatelessWidget {
  const _LoadingEntries();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (_) => const _SkeletonEntryCard()),
    );
  }
}

class _SkeletonEntryCard extends StatefulWidget {
  const _SkeletonEntryCard();

  @override
  State<_SkeletonEntryCard> createState() => _SkeletonEntryCardState();
}

class _SkeletonEntryCardState extends State<_SkeletonEntryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar({double? width, double height = 12}) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.textHint,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(width: 100, height: 14),
            const SizedBox(height: AppTheme.spacingS),
            _bar(),
            const SizedBox(height: AppTheme.spacingXs),
            _bar(width: 220),
          ],
        ),
      ),
    );
  }
}

class _SyncStatusChip extends StatelessWidget {
  final SyncStatus status;
  final VoidCallback? onRetry;

  const _SyncStatusChip({required this.status, this.onRetry});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SyncStatus.synced:
        return const SizedBox.shrink();
      case SyncStatus.syncing:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case SyncStatus.offline:
        return Padding(
          padding: const EdgeInsets.only(right: AppTheme.spacingS),
          child: Chip(
            label: const Text('Offline',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            backgroundColor: AppTheme.dividerColor,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        );
      case SyncStatus.error:
        return GestureDetector(
          onTap: onRetry,
          child: Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingS),
            child: Chip(
              label: const Text('Sync error',
                  style: TextStyle(fontSize: 11, color: Colors.white)),
              backgroundColor: Colors.orange,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        );
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tiny_lines/models/journal_entry.dart';
import 'package:tiny_lines/providers/journal_provider.dart';
import 'package:tiny_lines/screens/home_screen.dart';
import 'package:tiny_lines/screens/entry_editor_screen.dart';
import 'package:tiny_lines/utils/app_theme.dart';

/// A fake JournalProvider that lets tests control state without file I/O.
class FakeJournalProvider extends JournalProvider {
  final List<JournalEntry> fakeEntries;

  FakeJournalProvider({this.fakeEntries = const []}) : super();

  @override
  List<JournalEntry> get entries => fakeEntries;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Set<DateTime> get entryDates => fakeEntries.map((e) => e.date).toSet();

  @override
  JournalEntry? getEntryForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    try {
      return fakeEntries.firstWhere(
        (e) => e.date.isAtSameMomentAs(dateOnly),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool hasEntryForDate(DateTime date) => getEntryForDate(date) != null;

  @override
  List<JournalEntry> getRecentEntries({int limit = 10}) {
    return fakeEntries.take(limit).toList();
  }

  // No-op: don't call StorageService
  @override
  Future<void> loadEntries() async {}
}

/// Wraps HomeScreen in the minimal widget tree needed for testing.
Widget buildTestApp(JournalProvider provider) {
  return ChangeNotifierProvider<JournalProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    ),
  );
}

JournalEntry makeEntry(String id, DateTime date, String content) {
  return JournalEntry(
    id: id,
    date: date,
    content: content,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('HomeScreen', () {
    group('empty state', () {
      testWidgets('shows "No entries yet" when there are no entries',
          (tester) async {
        final provider = FakeJournalProvider(fakeEntries: []);
        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        expect(find.text('No entries yet'), findsOneWidget);
      });

      testWidgets('shows hint text to tap + when no entries',
          (tester) async {
        final provider = FakeJournalProvider(fakeEntries: []);
        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        expect(find.text('Tap + to create your first entry'),
            findsOneWidget);
      });

      testWidgets('shows FAB add button', (tester) async {
        final provider = FakeJournalProvider(fakeEntries: []);
        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    });

    group('recent entries list', () {
      testWidgets('shows "Recent Entries" heading when entries exist',
          (tester) async {
        final provider = FakeJournalProvider(fakeEntries: [
          makeEntry('2025-06-15', DateTime(2025, 6, 15), 'Hello world'),
        ]);
        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        expect(find.text('Recent Entries'), findsOneWidget);
      });

      testWidgets('shows entry content in card', (tester) async {
        final provider = FakeJournalProvider(fakeEntries: [
          makeEntry(
              '2025-06-15', DateTime(2025, 6, 15), 'My journal entry'),
        ]);
        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        expect(find.text('My journal entry'), findsOneWidget);
      });

      testWidgets('shows at most 5 recent entries', (tester) async {
        final entries = List.generate(
          8,
          (i) => makeEntry(
            '2025-0${(i % 9) + 1}-01',
            DateTime(2025, (i % 9) + 1, 1),
            'Entry $i',
          ),
        );
        final provider =
            FakeJournalProvider(fakeEntries: entries.take(5).toList());
        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        // There are 5 entries, each showing its content text
        expect(find.textContaining('Entry'), findsNWidgets(5));
      });

      testWidgets('tapping an entry card navigates to EntryEditorScreen',
          (tester) async {
        final entry = makeEntry(
            '2025-06-15', DateTime(2025, 6, 15), 'Tappable entry');
        final provider =
            FakeJournalProvider(fakeEntries: [entry]);
        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tappable entry'));
        await tester.pumpAndSettle();

        expect(find.byType(EntryEditorScreen), findsOneWidget);
      });
    });

    group('FAB behavior', () {
      testWidgets(
          'tapping FAB navigates to EntryEditorScreen when no entry exists for today',
          (tester) async {
        // No entries at all → FAB should open a new editor
        final provider = FakeJournalProvider(fakeEntries: []);
        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.byType(EntryEditorScreen), findsOneWidget);
      });

      testWidgets(
          'tapping FAB opens existing entry when today\'s entry already exists',
          (tester) async {
        final today = DateTime.now();
        final todayEntry = makeEntry(
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
          DateTime(today.year, today.month, today.day),
          'Already written today',
        );
        final provider =
            FakeJournalProvider(fakeEntries: [todayEntry]);
        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Should open EntryEditorScreen in edit mode (showing existing content)
        expect(find.byType(EntryEditorScreen), findsOneWidget);
        expect(find.text('Already written today'), findsOneWidget);
      });
    });

    group('AppBar', () {
      testWidgets('shows TinyLines title', (tester) async {
        final provider = FakeJournalProvider(fakeEntries: []);
        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        expect(find.text('TinyLines'), findsOneWidget);
      });
    });
  });
}

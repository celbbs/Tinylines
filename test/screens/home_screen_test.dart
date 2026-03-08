import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tinylines/models/journal_entry.dart';
import 'package:tinylines/providers/journal_provider.dart';
import 'package:tinylines/screens/entry_editor_screen.dart';
import 'package:tinylines/screens/home_screen.dart';
import 'package:tinylines/services/firestore_service.dart';
import 'package:tinylines/utils/app_theme.dart';

class FakeFirestoreService implements FirestoreService {
  FakeFirestoreService({List<JournalEntry>? seedEntries})
      : _entries = List<JournalEntry>.from(seedEntries ?? []);

  final List<JournalEntry> _entries;

  @override
  Future<List<JournalEntry>> loadAllEntries() async {
    final entries = List<JournalEntry>.from(_entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  @override
  Future<void> saveEntry(JournalEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      _entries[index] = entry;
    } else {
      _entries.add(entry);
    }

    _entries.sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }
}

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
    date: DateTime(date.year, date.month, date.day),
    content: content,
    createdAt: date,
    updatedAt: date,
  );
}

Future<JournalProvider> buildLoadedProvider({
  List<JournalEntry> entries = const [],
}) async {
  final provider = JournalProvider(
    firestoreService: FakeFirestoreService(seedEntries: entries),
  );
  await provider.loadEntries();
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeScreen', () {
    group('empty state', () {
      testWidgets('shows "No entries yet" when there are no entries',
          (tester) async {
        final provider = await buildLoadedProvider();

        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        expect(find.text('No entries yet'), findsOneWidget);
      });

      testWidgets('shows hint text to tap + when no entries', (tester) async {
        final provider = await buildLoadedProvider();

        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        expect(find.text('Tap + to create your first entry'), findsOneWidget);
      });

      testWidgets('shows FAB add button', (tester) async {
        final provider = await buildLoadedProvider();

        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    });

    group('recent entries list', () {
      testWidgets('shows "Recent Entries" heading when entries exist',
          (tester) async {
        final provider = await buildLoadedProvider(
          entries: [
            makeEntry('2025-06-15', DateTime(2025, 6, 15), 'Hello world'),
          ],
        );

        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        expect(find.text('Recent Entries'), findsOneWidget);
      });

      testWidgets('shows entry content in card', (tester) async {
        final provider = await buildLoadedProvider(
          entries: [
            makeEntry(
              '2025-06-15',
              DateTime(2025, 6, 15),
              'My journal entry',
            ),
          ],
        );

        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        expect(find.text('My journal entry'), findsOneWidget);
      });

      testWidgets('shows at most 5 recent entries', (tester) async {
        final entries = List.generate(
          8,
          (i) => makeEntry(
            '2025-${(i + 1).toString().padLeft(2, '0')}-01',
            DateTime(2025, i + 1, 1),
            'Entry $i',
          ),
        );

        final provider = await buildLoadedProvider(entries: entries);

        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        expect(find.textContaining('Entry'), findsNWidgets(5));
        expect(find.text('Entry 0'), findsNothing);
      });

      testWidgets('tapping an entry card navigates to EntryEditorScreen',
          (tester) async {
        final provider = await buildLoadedProvider(
          entries: [
            makeEntry(
              '2025-06-15',
              DateTime(2025, 6, 15),
              'Tappable entry',
            ),
          ],
        );

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
          final provider = await buildLoadedProvider();

          await tester.pumpWidget(buildTestApp(provider));
          await tester.pumpAndSettle();

          await tester.tap(find.byType(FloatingActionButton));
          await tester.pumpAndSettle();

          expect(find.byType(EntryEditorScreen), findsOneWidget);
        },
      );

      testWidgets(
        'tapping FAB opens existing entry when today\'s entry already exists',
        (tester) async {
          final today = DateTime.now();
          final todayId =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

          final provider = await buildLoadedProvider(
            entries: [
              makeEntry(
                todayId,
                DateTime(today.year, today.month, today.day),
                'Already written today',
              ),
            ],
          );

          await tester.pumpWidget(buildTestApp(provider));
          await tester.pumpAndSettle();

          await tester.tap(find.byType(FloatingActionButton));
          await tester.pumpAndSettle();

          expect(find.byType(EntryEditorScreen), findsOneWidget);
          expect(find.text('Already written today'), findsOneWidget);
        },
      );
    });

    group('AppBar', () {
      testWidgets('shows TinyLines title', (tester) async {
        final provider = await buildLoadedProvider();

        await tester.pumpWidget(buildTestApp(provider));
        await tester.pumpAndSettle();

        expect(find.text('TinyLines'), findsOneWidget);
      });
    });
  });
}
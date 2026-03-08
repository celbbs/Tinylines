import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tinylines/models/journal_entry.dart';
import 'package:tinylines/providers/journal_provider.dart';
import 'package:tinylines/screens/entry_editor_screen.dart';
import 'package:tinylines/screens/on_this_day_screen.dart';
import 'package:tinylines/services/firestore_service.dart';

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

Future<JournalProvider> buildLoadedProvider({
  List<JournalEntry> entries = const [],
}) async {
  final provider = JournalProvider(
    firestoreService: FakeFirestoreService(seedEntries: entries),
  );
  await provider.loadEntries();
  return provider;
}

Widget buildTestApp(JournalProvider provider) {
  return ChangeNotifierProvider<JournalProvider>.value(
    value: provider,
    child: const MaterialApp(home: OnThisDayScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnThisDayScreen', () {
    testWidgets('displays entries that match today', (tester) async {
      final today = DateTime.now();
      final entry = JournalEntry.forDate(
        date: today,
        content: 'Today memory',
      );

      final provider = await buildLoadedProvider(entries: [entry]);

      await tester.pumpWidget(buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.text('Today memory'), findsOneWidget);
    });

    testWidgets('does not display entries that do not match today',
        (tester) async {
      final notToday = DateTime.now().subtract(const Duration(days: 1));
      final entry = JournalEntry.forDate(
        date: notToday,
        content: 'Yesterday memory',
      );

      final provider = await buildLoadedProvider(entries: [entry]);

      await tester.pumpWidget(buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.text('Yesterday memory'), findsNothing);
      expect(find.text('No entries for this day'), findsOneWidget);
    });

    testWidgets('second entry for same day replaces first', (tester) async {
      final today = DateTime.now();

      final entry1 = JournalEntry(
        id:
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
        date: DateTime(today.year, today.month, today.day),
        content: 'Memory 2',
      );

      final provider = await buildLoadedProvider(entries: [entry1]);

      await tester.pumpWidget(buildTestApp(provider));
      await tester.pumpAndSettle();

      expect(find.text('Memory 2'), findsOneWidget);
      expect(find.text('Memory 1'), findsNothing);
    });

    testWidgets('tapping entry opens EntryEditorScreen', (tester) async {
      final today = DateTime.now();
      final entry = JournalEntry.forDate(
        date: today,
        content: 'Tap me',
      );

      final provider = await buildLoadedProvider(entries: [entry]);

      await tester.pumpWidget(buildTestApp(provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();

      expect(find.byType(EntryEditorScreen), findsOneWidget);
    });
  });
}
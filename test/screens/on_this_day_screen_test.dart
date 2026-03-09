import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tinylines/models/journal_entry.dart';
import 'package:tinylines/providers/journal_provider.dart';
import 'package:tinylines/screens/on_this_day_screen.dart';
import 'package:tinylines/services/firestore_service.dart';
import 'package:mockito/mockito.dart';

/// Minimal FirestoreService mock that never touches Firebase.
class _MockFirestoreService extends Mock implements FirestoreService {
  final List<JournalEntry> _entries = [];

  @override
  Future<List<JournalEntry>> loadAllEntries() async => List.of(_entries);

  @override
  Future<void> saveEntry(JournalEntry entry) async {
    _entries.removeWhere((e) => e.id == entry.id);
    _entries.add(entry);
  }

  @override
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnThisDayScreen', () {
    late _MockFirestoreService mockFirestore;
    late JournalProvider provider;

    setUp(() {
      mockFirestore = _MockFirestoreService();
      provider = JournalProvider(firestoreService: mockFirestore);
    });

    testWidgets('displays entries that match today', (tester) async {
      final today = DateTime.now();
      final entry = JournalEntry.forDate(date: today, content: 'Today memory');
      await provider.saveEntry(entry);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: OnThisDayScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Today memory'), findsOneWidget);
    });

    testWidgets('does not display entries that do not match today', (tester) async {
      final notToday = DateTime.now().subtract(const Duration(days: 1));
      final entry = JournalEntry.forDate(date: notToday, content: 'Yesterday memory');
      await provider.saveEntry(entry);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: OnThisDayScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Yesterday memory'), findsNothing);
      expect(find.text('No entries for this day'), findsOneWidget);
    });

    testWidgets('second entry for same day replaces first', (tester) async {
      final today = DateTime.now();
      final entry1 = JournalEntry.forDate(date: today, content: 'Memory 1');
      final entry2 = JournalEntry.forDate(date: today, content: 'Memory 2');
      await provider.saveEntry(entry1);
      await provider.saveEntry(entry2);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: OnThisDayScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Memory 2'), findsOneWidget);
      expect(find.text('Memory 1'), findsNothing);
    });
  });
}

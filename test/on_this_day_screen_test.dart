import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tiny_lines/models/journal_entry.dart';
import 'package:tiny_lines/providers/journal_provider.dart';
import 'package:tiny_lines/screens/on_this_day_screen.dart';
import 'package:tiny_lines/services/storage_service.dart';

// Mock storage service for tests
class MockStorageService extends StorageService {
  final Map<String, JournalEntry> _store = {};

  @override
  Future<List<JournalEntry>> loadAllEntries() async {
    return _store.values.toList();
  }

  @override
  Future<void> saveEntry(JournalEntry entry) async {
    _store[entry.id] = entry;
  }

  @override
  Future<void> deleteEntry(String id) async {
    _store.remove(id);
  }

  @override
  Future<String> saveImage(File file, String id) async {
    return 'mock_path/$id.png';
  }

  @override
  Future<void> deleteImage(String path) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnThisDayScreen', () {
    late JournalProvider provider;

    setUp(() {
      provider = JournalProvider(storage: MockStorageService());
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

    testWidgets('displays multiple entries matching today', (tester) async {
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

      expect(find.text('Memory 1'), findsOneWidget);
      expect(find.text('Memory 2'), findsOneWidget);
    });
  });
}

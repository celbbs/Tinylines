import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_lines/models/journal_entry.dart';
import 'package:tiny_lines/providers/journal_provider.dart';
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

  group('JournalProvider - One Entry Per Day', () {
    late JournalProvider provider;

    setUp(() {
      provider = JournalProvider(storageService: MockStorageService());
    });

    test('saving two entries for same date keeps only one', () async {
      final date = DateTime(2026, 1, 28);
      final entry1 = JournalEntry.forDate(date: date, content: 'First');
      final entry2 = JournalEntry.forDate(date: date, content: 'Second');

      await provider.saveEntry(entry1);
      await provider.saveEntry(entry2);

      expect(provider.entries.length, 1);
      expect(provider.entries.first.content, 'Second');
    });

    test('saveEntry adds a new entry when none exists', () async {
      final entry = JournalEntry.forDate(
        date: DateTime(2026, 2, 1),
        content: 'Hello',
      );

      await provider.saveEntry(entry);

      expect(provider.entries.length, 1);
      expect(provider.entries.first.id, entry.id);
    });

    test('deleting an entry removes it', () async {
      final entry = JournalEntry.forDate(
        date: DateTime(2026, 1, 10),
        content: 'To delete',
      );

      await provider.saveEntry(entry);
      await provider.deleteEntry(entry.id);

      expect(provider.entries.isEmpty, true);
    });

    test('getEntriesForMonth filters correctly', () async {
      await provider.saveEntry(JournalEntry.forDate(
        date: DateTime(2026, 7, 1),
        content: 'July',
      ));

      await provider.saveEntry(JournalEntry.forDate(
        date: DateTime(2026, 8, 1),
        content: 'August',
      ));

      final july = provider.getEntriesForMonth(2026, 7);
      expect(july.length, 1);
      expect(july.first.content, 'July');
    });

    test('getEntryForDate returns correct entry', () async {
      final date = DateTime(2026, 3, 3);
      final entry = JournalEntry.forDate(date: date, content: 'Test');

      await provider.saveEntry(entry);

      final result = provider.getEntryForDate(date);
      expect(result, isNotNull);
      expect(result!.content, 'Test');
    });
  });
}

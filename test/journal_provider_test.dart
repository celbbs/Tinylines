import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_lines/models/journal_entry.dart';
import 'package:tiny_lines/providers/journal_provider.dart';
import 'package:tiny_lines/services/storage_service.dart';

// mock storage service so that the tests pass locally via VM and dont fail for lack of plugins
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

// the tests
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JournalProvider - One Entry Per Day', () {
    late JournalProvider provider;

    setUp(() {
      // mock storage 
      provider = JournalProvider(storage: MockStorageService());
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
      final date = DateTime(2026, 1, 29);
      final entry = JournalEntry.forDate(date: date, content: 'New');

      await provider.saveEntry(entry);

      expect(provider.entries.length, 1);
      expect(provider.entries.first.content, 'New');
    });

    test('deleting an entry removes it', () async {
      final entry = JournalEntry.forDate(date: DateTime(2026, 1, 30), content: 'Delete me');

      await provider.saveEntry(entry);
      await provider.deleteEntry(entry.id);

      expect(provider.entries.length, 0);
    });

    test('getEntriesForMonth filters correctly', () async {
      final janEntry = JournalEntry.forDate(date: DateTime(2026, 1, 1), content: 'Jan');
      final febEntry = JournalEntry.forDate(date: DateTime(2026, 2, 1), content: 'Feb');

      await provider.saveEntry(janEntry);
      await provider.saveEntry(febEntry);

      final janEntries = provider.getEntriesForMonth(2026, 1);
      expect(janEntries.length, 1);
      expect(janEntries.first.content, 'Jan');
    });

    test('getEntryForDate returns correct entry', () async {
      final date = DateTime(2026, 1, 31);
      final entry = JournalEntry.forDate(date: date, content: 'Look me up');

      await provider.saveEntry(entry);

      final found = provider.getEntryForDate(date);
      expect(found, isNotNull);
      expect(found!.content, 'Look me up');
    });

    test('entries are sorted newest first', () async {
      final older = JournalEntry.forDate(date: DateTime(2026, 1, 1), content: 'Old');
      final newer = JournalEntry.forDate(date: DateTime(2026, 1, 2), content: 'New');

      await provider.saveEntry(older);
      await provider.saveEntry(newer);

      expect(provider.entries.first.content, 'New');
      expect(provider.entries.last.content, 'Old');
    });
  });
}

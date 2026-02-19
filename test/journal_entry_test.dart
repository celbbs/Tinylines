import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_lines/models/journal_entry.dart';
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
  group('JournalEntry', () {

    //journal entry w the current date
    test('create entry with current date', () {
      final entry = JournalEntry.create(content: 'Today’s note');

      // today's date
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // make sure stored and saved correctly
      expect(entry.date, today);
      expect(entry.content, 'Today’s note');

      // check format
      expect(
        entry.id,
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}',
      );

      // no image is attached by default
      expect(entry.imagePath, null);
    });

    // unit test for creating a journal entry for a specific date
    test('create entry for a specific date', () {
      final date = DateTime(2025, 12, 25);

      // christmas test
      final entry = JournalEntry.forDate(date: date, content: 'Merry Christmas');

      // stored date is correct
      expect(entry.date, DateTime(2025, 12, 25));

      // content should be right
      expect(entry.content, 'Merry Christmas');
      expect(entry.id, '2025-12-25');
    });

    // correctly update fields
    test('copyWith updates fields correctly', () {
      final entry = JournalEntry.create(content: 'Original');

      // copy
      final updated =
          entry.copyWith(content: 'Updated', imagePath: 'path/to/img.png');

      // Verify updated fields changed
      expect(updated.content, 'Updated');
      expect(updated.imagePath, 'path/to/img.png');

      // Verify unchanged fields remain the same
      expect(updated.date, entry.date);
      expect(updated.id, entry.id);
    });

    // Test JSON 
    test('toJson and fromJson round-trip', () {
      // Create an entry
      final entry = JournalEntry.create(content: 'JSON test', imagePath: 'img.png');

      // Convert to JSON
      final json = entry.toJson();

      // Convert back from JSON
      final newEntry = JournalEntry.fromJson(json);

      // recreated entry matches the original
      expect(newEntry, entry);
      expect(newEntry.content, 'JSON test');
      expect(newEntry.imagePath, 'img.png');
    });

    test('formattedDate and shortDate getters', () {
      final date = DateTime(2025, 7, 4);

      // july 4th test
      final entry =
          JournalEntry.forDate(date: date, content: 'Independence Day');

      // check dates
      expect(entry.formattedDate, 'July 4, 2025');
      expect(entry.shortDate, 'Jul 4');
    });

    test('equality operator works based on id', () {
      // two diff entries with the same date generate the same ID
      final entry1 =
          JournalEntry.forDate(date: DateTime(2025, 1, 1), content: 'A');
      final entry2 =
          JournalEntry.forDate(date: DateTime(2025, 1, 1), content: 'B');

      expect(entry1 == entry2, true);
    });

    
  });
}

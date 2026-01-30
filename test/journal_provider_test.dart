import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_lines/providers/journal_provider.dart';
import 'package:tiny_lines/models/journal_entry.dart';

// test confirms overwrite of daily journal entry, ensuring no duplicates

void main() {
  // flutter services
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JournalProvider - One Entry Per Day', () {
    test('saving two entries for same date keeps only one', () async {
      final provider = JournalProvider();

      final date = DateTime(2026, 1, 28);

      final entry1 = JournalEntry.forDate(
        date: date,
        content: 'First',
      );

      final entry2 = JournalEntry.forDate(
        date: date,
        content: 'Second',
      );

      await provider.saveEntry(entry1);
      await provider.saveEntry(entry2);

      expect(provider.entries.length, 1);
      expect(provider.entries.first.content, 'Second');
    });
  });
}

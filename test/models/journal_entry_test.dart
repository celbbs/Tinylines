import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:tiny_lines/models/journal_entry.dart';

void main() {
  group('JournalEntry', () {
    group('factory constructors', () {
      test('create() produces entry with today\'s date as ID', () {
        final today = DateTime.now();
        final expected = DateFormat('yyyy-MM-dd').format(today);

        final entry = JournalEntry.create(content: 'Hello');

        expect(entry.id, equals(expected));
        expect(entry.date.year, equals(today.year));
        expect(entry.date.month, equals(today.month));
        expect(entry.date.day, equals(today.day));
        // Time component should be stripped
        expect(entry.date.hour, equals(0));
        expect(entry.date.minute, equals(0));
        expect(entry.date.second, equals(0));
      });

      test('create() stores provided content', () {
        final entry = JournalEntry.create(content: 'My journal entry');
        expect(entry.content, equals('My journal entry'));
      });

      test('create() with imagePath stores it', () {
        final entry = JournalEntry.create(
          content: 'With image',
          imagePath: '/path/to/image.jpg',
        );
        expect(entry.imagePath, equals('/path/to/image.jpg'));
      });

      test('create() without imagePath leaves it null', () {
        final entry = JournalEntry.create(content: 'No image');
        expect(entry.imagePath, isNull);
      });

      test('forDate() produces entry with correct date-based ID', () {
        final date = DateTime(2025, 6, 15);
        final entry = JournalEntry.forDate(date: date, content: 'Summer');

        expect(entry.id, equals('2025-06-15'));
        expect(entry.date, equals(DateTime(2025, 6, 15)));
      });

      test('forDate() strips time component from date', () {
        final dateWithTime = DateTime(2025, 3, 5, 14, 30, 59);
        final entry = JournalEntry.forDate(date: dateWithTime, content: 'Test');

        expect(entry.date, equals(DateTime(2025, 3, 5)));
        expect(entry.id, equals('2025-03-05'));
      });

      test('forDate() zero-pads month and day in ID', () {
        final entry = JournalEntry.forDate(
          date: DateTime(2025, 1, 7),
          content: 'Padded',
        );
        expect(entry.id, equals('2025-01-07'));
      });
    });

    group('JSON serialization', () {
      test('toJson() and fromJson() round-trip is lossless', () {
        final original = JournalEntry(
          id: '2025-08-20',
          date: DateTime(2025, 8, 20),
          content: 'A great day',
          imagePath: '/some/path.jpg',
          createdAt: DateTime(2025, 8, 20, 9, 0, 0),
          updatedAt: DateTime(2025, 8, 20, 10, 30, 0),
        );

        final json = original.toJson();
        final restored = JournalEntry.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.date, equals(original.date));
        expect(restored.content, equals(original.content));
        expect(restored.imagePath, equals(original.imagePath));
        expect(restored.createdAt, equals(original.createdAt));
        expect(restored.updatedAt, equals(original.updatedAt));
      });

      test('fromJson() handles null imagePath gracefully', () {
        final json = {
          'id': '2025-09-01',
          'date': '2025-09-01T00:00:00.000',
          'content': 'No image',
          'imagePath': null,
          'createdAt': '2025-09-01T08:00:00.000',
          'updatedAt': '2025-09-01T08:00:00.000',
        };

        final entry = JournalEntry.fromJson(json);
        expect(entry.imagePath, isNull);
      });

      test('toJson() includes all expected keys', () {
        final entry = JournalEntry.create(content: 'Check keys');
        final json = entry.toJson();

        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('date'), isTrue);
        expect(json.containsKey('content'), isTrue);
        expect(json.containsKey('imagePath'), isTrue);
        expect(json.containsKey('createdAt'), isTrue);
        expect(json.containsKey('updatedAt'), isTrue);
      });
    });

    group('copyWith()', () {
      final base = JournalEntry(
        id: '2025-05-10',
        date: DateTime(2025, 5, 10),
        content: 'Original content',
        imagePath: '/original.jpg',
        createdAt: DateTime(2025, 5, 10, 8, 0),
        updatedAt: DateTime(2025, 5, 10, 8, 0),
      );

      test('updates only content when specified', () {
        final updated = base.copyWith(content: 'New content');
        expect(updated.content, equals('New content'));
        expect(updated.id, equals(base.id));
        expect(updated.date, equals(base.date));
        expect(updated.imagePath, equals(base.imagePath));
        expect(updated.createdAt, equals(base.createdAt));
      });

      test('updates imagePath when specified', () {
        final updated = base.copyWith(imagePath: '/new.jpg');
        expect(updated.imagePath, equals('/new.jpg'));
        expect(updated.content, equals(base.content));
      });

      test('clearImagePath: true removes the image path', () {
        final updated = base.copyWith(clearImagePath: true);
        expect(updated.imagePath, isNull);
        expect(updated.content, equals(base.content));
      });

      test('omitting imagePath preserves existing imagePath', () {
        final updated = base.copyWith(content: 'Keep image');
        expect(updated.imagePath, equals(base.imagePath));
      });

      test('preserves all fields when no arguments passed', () {
        final copy = base.copyWith();
        expect(copy.id, equals(base.id));
        expect(copy.date, equals(base.date));
        expect(copy.content, equals(base.content));
        expect(copy.imagePath, equals(base.imagePath));
        expect(copy.createdAt, equals(base.createdAt));
      });
    });

    group('date formatting', () {
      test('formattedDate returns MMMM d, yyyy format', () {
        final entry = JournalEntry(
          id: '2025-12-25',
          date: DateTime(2025, 12, 25),
          content: 'Christmas',
        );
        expect(entry.formattedDate, equals('December 25, 2025'));
      });

      test('shortDate returns MMM d format', () {
        final entry = JournalEntry(
          id: '2025-01-03',
          date: DateTime(2025, 1, 3),
          content: 'New year',
        );
        expect(entry.shortDate, equals('Jan 3'));
      });
    });

    group('equality and hashCode', () {
      test('entries with the same id are equal', () {
        final a = JournalEntry(
          id: '2025-07-04',
          date: DateTime(2025, 7, 4),
          content: 'Same id',
        );
        final b = JournalEntry(
          id: '2025-07-04',
          date: DateTime(2025, 7, 4),
          content: 'Different content',
          imagePath: '/some/image.png',
        );
        expect(a, equals(b));
      });

      test('entries with different ids are not equal', () {
        final a = JournalEntry(
          id: '2025-07-04',
          date: DateTime(2025, 7, 4),
          content: 'Entry A',
        );
        final b = JournalEntry(
          id: '2025-07-05',
          date: DateTime(2025, 7, 5),
          content: 'Entry A',
        );
        expect(a, isNot(equals(b)));
      });

      test('hashCode is consistent with equality', () {
        final a = JournalEntry(
          id: '2025-07-04',
          date: DateTime(2025, 7, 4),
          content: 'Hash test',
        );
        final b = JournalEntry(
          id: '2025-07-04',
          date: DateTime(2025, 7, 4),
          content: 'Different content',
        );
        expect(a.hashCode, equals(b.hashCode));
      });

      test('identical entries satisfy identical()', () {
        final entry = JournalEntry.create(content: 'Identical');
        expect(identical(entry, entry), isTrue);
        expect(entry == entry, isTrue);
      });
    });
  });
}

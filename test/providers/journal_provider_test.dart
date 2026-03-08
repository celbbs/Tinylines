import 'package:flutter_test/flutter_test.dart';
import 'package:tinylines/models/journal_entry.dart';
import 'package:tinylines/providers/journal_provider.dart';

import 'journal_provider_test.mocks.dart';

void main() {
  JournalEntry makeEntry(String id, DateTime date, String content) {
    return JournalEntry(
      id: id,
      date: DateTime(date.year, date.month, date.day),
      content: content,
      createdAt: date,
      updatedAt: date,
    );
  }

  group('JournalProvider', () {
    late FakeFirestoreService fakeFirestore;
    late JournalProvider provider;

    setUp(() {
      fakeFirestore = FakeFirestoreService();
      provider = JournalProvider(firestoreService: fakeFirestore);
    });

    group('loadEntries', () {
      test('loads entries from Firestore service', () async {
        fakeFirestore = FakeFirestoreService(
          seedEntries: [
            makeEntry('2025-06-15', DateTime(2025, 6, 15), 'Hello'),
          ],
        );
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();

        expect(provider.entries, hasLength(1));
        expect(provider.entries.first.id, equals('2025-06-15'));
        expect(provider.entries.first.content, equals('Hello'));
      });

      test('isLoading is false after load completes', () async {
        await provider.loadEntries();
        expect(provider.isLoading, isFalse);
      });

      test('sets error when load fails', () async {
        fakeFirestore.throwOnLoad = true;

        await provider.loadEntries();

        expect(provider.error, isNotNull);
        expect(provider.error, contains('Failed to load entries'));
        expect(provider.isLoading, isFalse);
      });
    });

    group('getEntryForDate', () {
      test('returns entry when one exists for that date', () async {
        fakeFirestore = FakeFirestoreService(
          seedEntries: [
            makeEntry('2025-06-15', DateTime(2025, 6, 15), 'Found me'),
          ],
        );
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();

        final result = provider.getEntryForDate(DateTime(2025, 6, 15));

        expect(result, isNotNull);
        expect(result!.content, equals('Found me'));
      });

      test('returns null when no entry exists for that date', () async {
        await provider.loadEntries();

        final result = provider.getEntryForDate(DateTime(2025, 6, 15));
        expect(result, isNull);
      });

      test('ignores time component when matching date', () async {
        fakeFirestore = FakeFirestoreService(
          seedEntries: [
            makeEntry('2025-06-15', DateTime(2025, 6, 15), 'Date only'),
          ],
        );
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();

        final result =
            provider.getEntryForDate(DateTime(2025, 6, 15, 23, 59, 59));

        expect(result, isNotNull);
        expect(result!.content, equals('Date only'));
      });
    });

    group('getEntryById', () {
      test('returns entry when one exists for that id', () async {
        final entry =
            makeEntry('2025-06-15', DateTime(2025, 6, 15), 'By id');
        fakeFirestore = FakeFirestoreService(seedEntries: [entry]);
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();

        expect(provider.getEntryById('2025-06-15'), equals(entry));
      });

      test('returns null when no entry exists for that id', () async {
        await provider.loadEntries();
        expect(provider.getEntryById('missing-id'), isNull);
      });
    });

    group('hasEntryForDate', () {
      test('returns true when entry exists', () async {
        fakeFirestore = FakeFirestoreService(
          seedEntries: [
            makeEntry('2025-06-15', DateTime(2025, 6, 15), 'Exists'),
          ],
        );
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();

        expect(provider.hasEntryForDate(DateTime(2025, 6, 15)), isTrue);
      });

      test('returns false when entry does not exist', () async {
        await provider.loadEntries();
        expect(provider.hasEntryForDate(DateTime(2025, 6, 15)), isFalse);
      });
    });

    group('entryDates', () {
      test('returns set of dates matching loaded entries', () async {
        fakeFirestore = FakeFirestoreService(
          seedEntries: [
            makeEntry('2025-06-15', DateTime(2025, 6, 15), 'A'),
            makeEntry('2025-07-04', DateTime(2025, 7, 4), 'B'),
          ],
        );
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();

        expect(
          provider.entryDates,
          containsAll([DateTime(2025, 6, 15), DateTime(2025, 7, 4)]),
        );
        expect(provider.entryDates.length, equals(2));
      });
    });

    group('saveEntry', () {
      test('adds a new entry', () async {
        await provider.loadEntries();

        final entry =
            makeEntry('2025-09-01', DateTime(2025, 9, 1), 'New entry');
        await provider.saveEntry(entry);

        expect(provider.entries, contains(entry));
        expect(fakeFirestore.storedEntries, contains(entry));
      });

      test('updates existing entry rather than duplicating', () async {
        final original =
            makeEntry('2025-09-01', DateTime(2025, 9, 1), 'Original');
        fakeFirestore = FakeFirestoreService(seedEntries: [original]);
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();

        final updated = original.copyWith(content: 'Updated');
        await provider.saveEntry(updated);

        expect(provider.entries, hasLength(1));
        expect(provider.entries.first.content, equals('Updated'));
      });

      test('sets error and rethrows when save fails', () async {
        fakeFirestore.throwOnSave = true;
        final entry =
            makeEntry('2025-09-01', DateTime(2025, 9, 1), 'Will fail');

        await expectLater(
          provider.saveEntry(entry),
          throwsException,
        );

        expect(provider.error, isNotNull);
        expect(provider.error, contains('Failed to save entry'));
      });
    });

    group('createEntry', () {
      test('creates an entry for today', () async {
        await provider.createEntry('Today entry');

        expect(provider.entries, hasLength(1));
        expect(provider.getEntryForDate(DateTime.now()), isNotNull);
        expect(provider.entries.first.content, equals('Today entry'));
      });
    });

    group('createEntryForDate', () {
      test('creates an entry for the provided date', () async {
        final date = DateTime(2025, 3, 1);

        await provider.createEntryForDate(date, 'Specific date entry');

        final saved = provider.getEntryForDate(date);
        expect(saved, isNotNull);
        expect(saved!.id, equals('2025-03-01'));
        expect(saved.content, equals('Specific date entry'));
      });
    });

    group('deleteEntry', () {
      test('removes entry from provider and service', () async {
        final entry =
            makeEntry('2025-09-01', DateTime(2025, 9, 1), 'To delete');
        fakeFirestore = FakeFirestoreService(seedEntries: [entry]);
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();
        await provider.deleteEntry('2025-09-01');

        expect(provider.entries, isEmpty);
        expect(fakeFirestore.storedEntries, isEmpty);
      });

      test('sets error and rethrows when delete fails', () async {
        final entry =
            makeEntry('2025-09-01', DateTime(2025, 9, 1), 'To delete');
        fakeFirestore = FakeFirestoreService(seedEntries: [entry]);
        fakeFirestore.throwOnDelete = true;
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();

        await expectLater(
          provider.deleteEntry('2025-09-01'),
          throwsException,
        );

        expect(provider.error, isNotNull);
        expect(provider.error, contains('Failed to delete entry'));
      });
    });

    group('updateEntry', () {
      test('updates content of existing entry', () async {
        final entry =
            makeEntry('2025-09-01', DateTime(2025, 9, 1), 'Old content');
        fakeFirestore = FakeFirestoreService(seedEntries: [entry]);
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();
        await provider.updateEntry('2025-09-01', 'New content');

        expect(provider.entries.first.content, equals('New content'));
      });

      test('removeImage clears imagePath', () async {
        final entry = JournalEntry(
          id: '2025-09-01',
          date: DateTime(2025, 9, 1),
          content: 'Has image',
          imagePath: '/path/to/image.jpg',
          createdAt: DateTime(2025, 9, 1),
          updatedAt: DateTime(2025, 9, 1),
        );
        fakeFirestore = FakeFirestoreService(seedEntries: [entry]);
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();
        await provider.updateEntry(
          '2025-09-01',
          'Removed image',
          removeImage: true,
        );

        expect(provider.entries.first.imagePath, isNull);
      });

      test('throws when entry id does not exist', () async {
        await provider.loadEntries();

        expect(
          () => provider.updateEntry('9999-01-01', 'Content'),
          throwsException,
        );
      });
    });

    group('getRecentEntries', () {
      test('returns correct count in newest-first order', () async {
        fakeFirestore = FakeFirestoreService(
          seedEntries: List.generate(
            6,
            (i) => makeEntry(
              '2025-0${i + 1}-01',
              DateTime(2025, i + 1, 1),
              'Entry $i',
            ),
          ),
        );
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();

        final recent = provider.getRecentEntries(limit: 3);

        expect(recent, hasLength(3));
        expect(recent.first.date.isAfter(recent.last.date), isTrue);
      });

      test('returns all entries when limit exceeds total count', () async {
        fakeFirestore = FakeFirestoreService(
          seedEntries: [
            makeEntry('2025-06-15', DateTime(2025, 6, 15), 'Only one'),
          ],
        );
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();

        final recent = provider.getRecentEntries(limit: 10);
        expect(recent, hasLength(1));
      });
    });

    group('getEntriesForMonth', () {
      test('filters correctly by year and month', () async {
        fakeFirestore = FakeFirestoreService(
          seedEntries: [
            makeEntry('2025-06-01', DateTime(2025, 6, 1), 'June 1'),
            makeEntry('2025-06-15', DateTime(2025, 6, 15), 'June 15'),
            makeEntry('2025-07-01', DateTime(2025, 7, 1), 'July 1'),
            makeEntry('2024-06-01', DateTime(2024, 6, 1), 'Last June'),
          ],
        );
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();

        final june2025 = provider.getEntriesForMonth(2025, 6);
        expect(june2025, hasLength(2));
        expect(
          june2025.every((e) => e.date.year == 2025 && e.date.month == 6),
          isTrue,
        );
      });

      test('returns empty list when no entries exist in that month', () async {
        await provider.loadEntries();

        final result = provider.getEntriesForMonth(2025, 6);
        expect(result, isEmpty);
      });
    });

    group('clearError', () {
      test('clears error state', () async {
        fakeFirestore.throwOnLoad = true;

        await provider.loadEntries();
        expect(provider.error, isNotNull);

        provider.clearError();
        expect(provider.error, isNull);
      });
    });

    group('resetForAuthChange', () {
      test('clears entries, loading, and error', () async {
        fakeFirestore = FakeFirestoreService(
          seedEntries: [
            makeEntry('2025-06-15', DateTime(2025, 6, 15), 'Hello'),
          ],
        );
        provider = JournalProvider(firestoreService: fakeFirestore);

        await provider.loadEntries();
        provider.resetForAuthChange();

        expect(provider.entries, isEmpty);
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });
    });
  });
}
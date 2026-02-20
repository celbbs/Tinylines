import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tiny_lines/models/journal_entry.dart';
import 'package:tiny_lines/providers/journal_provider.dart';
import 'package:tiny_lines/services/storage_service.dart';

import 'journal_provider_test.mocks.dart';

@GenerateMocks([StorageService])
void main() {
  late MockStorageService mockStorage;

  // Helper to build a test entry for a specific date
  JournalEntry makeEntry(String id, DateTime date, String content) {
    return JournalEntry(
      id: id,
      date: date,
      content: content,
      createdAt: date,
      updatedAt: date,
    );
  }

  setUp(() {
    mockStorage = MockStorageService();
    // Default: loadAllEntries returns empty list
    when(mockStorage.loadAllEntries()).thenAnswer((_) async => []);
  });

  group('JournalProvider initialization', () {
    test('calls loadAllEntries on construction', () async {
      JournalProvider(storageService: mockStorage);
      // Allow async loadEntries() to complete
      await Future.delayed(Duration.zero);

      verify(mockStorage.loadAllEntries()).called(1);
    });

    test('entries list is populated after load', () async {
      final entry = makeEntry(
          '2025-06-15', DateTime(2025, 6, 15), 'Hello');
      when(mockStorage.loadAllEntries())
          .thenAnswer((_) async => [entry]);

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      expect(provider.entries, hasLength(1));
      expect(provider.entries.first.id, equals('2025-06-15'));
    });

    test('isLoading is false after load completes', () async {
      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      expect(provider.isLoading, isFalse);
    });

    test('sets error when loadAllEntries throws', () async {
      when(mockStorage.loadAllEntries())
          .thenThrow(Exception('disk error'));

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      expect(provider.error, isNotNull);
      expect(provider.error, contains('Failed to load entries'));
      expect(provider.isLoading, isFalse);
    });
  });

  group('getEntryForDate', () {
    test('returns entry when one exists for that date', () async {
      final entry = makeEntry(
          '2025-06-15', DateTime(2025, 6, 15), 'Found me');
      when(mockStorage.loadAllEntries())
          .thenAnswer((_) async => [entry]);

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      final result =
          provider.getEntryForDate(DateTime(2025, 6, 15));
      expect(result, isNotNull);
      expect(result!.content, equals('Found me'));
    });

    test('returns null when no entry exists for that date', () async {
      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      final result =
          provider.getEntryForDate(DateTime(2025, 6, 15));
      expect(result, isNull);
    });

    test('ignores time component when matching date', () async {
      final entry = makeEntry(
          '2025-06-15', DateTime(2025, 6, 15), 'Date only');
      when(mockStorage.loadAllEntries())
          .thenAnswer((_) async => [entry]);

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      // Querying with a time component should still match
      final result = provider
          .getEntryForDate(DateTime(2025, 6, 15, 23, 59, 59));
      expect(result, isNotNull);
    });
  });

  group('hasEntryForDate', () {
    test('returns true when entry exists', () async {
      final entry = makeEntry(
          '2025-06-15', DateTime(2025, 6, 15), 'Exists');
      when(mockStorage.loadAllEntries())
          .thenAnswer((_) async => [entry]);

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      expect(provider.hasEntryForDate(DateTime(2025, 6, 15)),
          isTrue);
    });

    test('returns false when entry does not exist', () async {
      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      expect(provider.hasEntryForDate(DateTime(2025, 6, 15)),
          isFalse);
    });
  });

  group('entryDates getter', () {
    test('returns set of dates matching loaded entries', () async {
      final entries = [
        makeEntry('2025-06-15', DateTime(2025, 6, 15), 'A'),
        makeEntry('2025-07-04', DateTime(2025, 7, 4), 'B'),
      ];
      when(mockStorage.loadAllEntries())
          .thenAnswer((_) async => entries);

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      expect(provider.entryDates,
          containsAll([DateTime(2025, 6, 15), DateTime(2025, 7, 4)]));
      expect(provider.entryDates.length, equals(2));
    });
  });

  group('saveEntry', () {
    test('calls StorageService.saveEntry and adds to entries',
        () async {
      when(mockStorage.saveEntry(any)).thenAnswer((_) => Future<void>.value());

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      final entry = makeEntry(
          '2025-09-01', DateTime(2025, 9, 1), 'New entry');
      await provider.saveEntry(entry);

      verify(mockStorage.saveEntry(entry)).called(1);
      expect(provider.entries, contains(entry));
    });

    test('updates existing entry rather than duplicating', () async {
      final original = makeEntry(
          '2025-09-01', DateTime(2025, 9, 1), 'Original');
      when(mockStorage.loadAllEntries())
          .thenAnswer((_) async => [original]);
      when(mockStorage.saveEntry(any)).thenAnswer((_) => Future<void>.value());

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      final updated = original.copyWith(content: 'Updated');
      await provider.saveEntry(updated);

      expect(provider.entries, hasLength(1));
      expect(provider.entries.first.content, equals('Updated'));
    });

    test('calls saveImage when imageFile is provided', () async {
      when(mockStorage.saveEntry(any)).thenAnswer((_) => Future<void>.value());
      when(mockStorage.saveImage(any, any))
          .thenAnswer((_) async => '/saved/image.jpg');

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      final entry = makeEntry(
          '2025-09-01', DateTime(2025, 9, 1), 'With image');
      final fakeFile = File('/fake/image.jpg');

      await provider.saveEntry(entry, imageFile: fakeFile);

      verify(mockStorage.saveImage(fakeFile, '2025-09-01')).called(1);
    });
  });

  group('deleteEntry', () {
    test('calls StorageService.deleteEntry and removes from list',
        () async {
      final entry = makeEntry(
          '2025-09-01', DateTime(2025, 9, 1), 'To delete');
      when(mockStorage.loadAllEntries())
          .thenAnswer((_) async => [entry]);
      when(mockStorage.deleteEntry(any)).thenAnswer((_) => Future<void>.value());

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      await provider.deleteEntry('2025-09-01');

      verify(mockStorage.deleteEntry('2025-09-01')).called(1);
      expect(provider.entries, isEmpty);
    });
  });

  group('updateEntry', () {
    test('updates content of existing entry', () async {
      final entry = makeEntry(
          '2025-09-01', DateTime(2025, 9, 1), 'Old content');
      when(mockStorage.loadAllEntries())
          .thenAnswer((_) async => [entry]);
      when(mockStorage.saveEntry(any)).thenAnswer((_) => Future<void>.value());

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      await provider.updateEntry('2025-09-01', 'New content');

      expect(provider.entries.first.content, equals('New content'));
    });

    test('calls deleteImage when removeImage is true', () async {
      final entry = JournalEntry(
        id: '2025-09-01',
        date: DateTime(2025, 9, 1),
        content: 'Has image',
        imagePath: '/path/to/image.jpg',
        createdAt: DateTime(2025, 9, 1),
        updatedAt: DateTime(2025, 9, 1),
      );
      when(mockStorage.loadAllEntries())
          .thenAnswer((_) async => [entry]);
      when(mockStorage.saveEntry(any)).thenAnswer((_) => Future<void>.value());
      when(mockStorage.deleteImage(any)).thenAnswer((_) => Future<void>.value());

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      await provider.updateEntry('2025-09-01', 'Removed image',
          removeImage: true);

      verify(mockStorage.deleteImage('/path/to/image.jpg')).called(1);
      expect(provider.entries.first.imagePath, isNull);
    });

    test('throws when entry id does not exist', () async {
      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      expect(
        () => provider.updateEntry('9999-01-01', 'Content'),
        throwsException,
      );
    });
  });

  group('getRecentEntries', () {
    test('returns correct count in newest-first order', () async {
      final entries = List.generate(
        6,
        (i) => makeEntry(
          '2025-0${i + 1}-01',
          DateTime(2025, i + 1, 1),
          'Entry $i',
        ),
      )..sort((a, b) => b.date.compareTo(a.date));

      when(mockStorage.loadAllEntries())
          .thenAnswer((_) async => entries);

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      final recent = provider.getRecentEntries(limit: 3);
      expect(recent, hasLength(3));
      // Should be newest-first
      expect(recent.first.date.isAfter(recent.last.date), isTrue);
    });

    test('returns all entries when limit exceeds total count', () async {
      final entries = [
        makeEntry('2025-06-15', DateTime(2025, 6, 15), 'Only one'),
      ];
      when(mockStorage.loadAllEntries())
          .thenAnswer((_) async => entries);

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      final recent = provider.getRecentEntries(limit: 10);
      expect(recent, hasLength(1));
    });
  });

  group('getEntriesForMonth', () {
    test('filters correctly by year and month', () async {
      final entries = [
        makeEntry('2025-06-01', DateTime(2025, 6, 1), 'June 1'),
        makeEntry('2025-06-15', DateTime(2025, 6, 15), 'June 15'),
        makeEntry('2025-07-01', DateTime(2025, 7, 1), 'July 1'),
        makeEntry('2024-06-01', DateTime(2024, 6, 1), 'Last June'),
      ];
      when(mockStorage.loadAllEntries())
          .thenAnswer((_) async => entries);

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      final june2025 = provider.getEntriesForMonth(2025, 6);
      expect(june2025, hasLength(2));
      expect(june2025.every((e) => e.date.year == 2025 && e.date.month == 6),
          isTrue);
    });

    test('returns empty list when no entries in that month', () async {
      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      final result = provider.getEntriesForMonth(2025, 6);
      expect(result, isEmpty);
    });
  });

  group('clearError', () {
    test('clears error state', () async {
      when(mockStorage.loadAllEntries())
          .thenThrow(Exception('disk error'));

      final provider =
          JournalProvider(storageService: mockStorage);
      await Future.delayed(Duration.zero);

      expect(provider.error, isNotNull);
      provider.clearError();
      expect(provider.error, isNull);
    });
  });
}

import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:tiny_lines/models/journal_entry.dart';
import 'package:tiny_lines/services/storage_service.dart';

/// Fake path provider that returns a temporary directory for tests.
class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
}

void main() {
  late Directory tempDir;
  late StorageService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tinylines_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    service = StorageService();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('StorageService', () {
    final testDate = DateTime(2025, 6, 15);
    final testEntry = JournalEntry(
      id: '2025-06-15',
      date: testDate,
      content: 'A sunny day',
      createdAt: DateTime(2025, 6, 15, 8, 0),
      updatedAt: DateTime(2025, 6, 15, 9, 0),
    );

    group('saveEntry and loadEntry', () {
      test('saveEntry creates both .md and .json files', () async {
        await service.saveEntry(testEntry);

        final entriesDir =
            Directory('${tempDir.path}/journal_entries');
        final mdFile = File('${entriesDir.path}/2025-06-15.md');
        final jsonFile = File('${entriesDir.path}/2025-06-15.json');

        expect(await mdFile.exists(), isTrue);
        expect(await jsonFile.exists(), isTrue);
      });

      test('saveEntry writes content to .md file', () async {
        await service.saveEntry(testEntry);

        final entriesDir =
            Directory('${tempDir.path}/journal_entries');
        final mdFile = File('${entriesDir.path}/2025-06-15.md');
        final content = await mdFile.readAsString();

        expect(content, equals('A sunny day'));
      });

      test('saveEntry writes valid JSON metadata to .json file', () async {
        await service.saveEntry(testEntry);

        final entriesDir =
            Directory('${tempDir.path}/journal_entries');
        final jsonFile = File('${entriesDir.path}/2025-06-15.json');
        final raw = await jsonFile.readAsString();
        final decoded = jsonDecode(raw) as Map<String, dynamic>;

        expect(decoded['id'], equals('2025-06-15'));
        expect(decoded['content'], equals('A sunny day'));
      });

      test('loadEntry returns correct entry after save', () async {
        await service.saveEntry(testEntry);

        final loaded = await service.loadEntry('2025-06-15');

        expect(loaded, isNotNull);
        expect(loaded!.id, equals('2025-06-15'));
        expect(loaded.content, equals('A sunny day'));
        expect(loaded.date, equals(testDate));
      });

      test('loadEntry returns null for non-existent ID', () async {
        final result = await service.loadEntry('1999-01-01');
        expect(result, isNull);
      });

      test('saving entry with imagePath persists it', () async {
        final entryWithImage = JournalEntry(
          id: '2025-06-15',
          date: testDate,
          content: 'With image',
          imagePath: '/some/path.jpg',
          createdAt: DateTime(2025, 6, 15, 8, 0),
          updatedAt: DateTime(2025, 6, 15, 9, 0),
        );

        await service.saveEntry(entryWithImage);
        final loaded = await service.loadEntry('2025-06-15');

        expect(loaded!.imagePath, equals('/some/path.jpg'));
      });
    });

    group('loadAllEntries', () {
      test('returns empty list when no entries exist', () async {
        final entries = await service.loadAllEntries();
        expect(entries, isEmpty);
      });

      test('returns all saved entries', () async {
        final entry1 = JournalEntry(
          id: '2025-06-15',
          date: DateTime(2025, 6, 15),
          content: 'First',
          createdAt: DateTime(2025, 6, 15),
          updatedAt: DateTime(2025, 6, 15),
        );
        final entry2 = JournalEntry(
          id: '2025-06-16',
          date: DateTime(2025, 6, 16),
          content: 'Second',
          createdAt: DateTime(2025, 6, 16),
          updatedAt: DateTime(2025, 6, 16),
        );

        await service.saveEntry(entry1);
        await service.saveEntry(entry2);

        final entries = await service.loadAllEntries();
        expect(entries.length, equals(2));
      });

      test('returns entries sorted newest-first', () async {
        final older = JournalEntry(
          id: '2025-01-01',
          date: DateTime(2025, 1, 1),
          content: 'Old entry',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );
        final newer = JournalEntry(
          id: '2025-06-15',
          date: DateTime(2025, 6, 15),
          content: 'Newer entry',
          createdAt: DateTime(2025, 6, 15),
          updatedAt: DateTime(2025, 6, 15),
        );

        await service.saveEntry(older);
        await service.saveEntry(newer);

        final entries = await service.loadAllEntries();
        expect(entries.first.id, equals('2025-06-15'));
        expect(entries.last.id, equals('2025-01-01'));
      });
    });

    group('deleteEntry', () {
      test('removes both .md and .json files', () async {
        await service.saveEntry(testEntry);
        await service.deleteEntry('2025-06-15');

        final entriesDir =
            Directory('${tempDir.path}/journal_entries');
        final mdFile = File('${entriesDir.path}/2025-06-15.md');
        final jsonFile = File('${entriesDir.path}/2025-06-15.json');

        expect(await mdFile.exists(), isFalse);
        expect(await jsonFile.exists(), isFalse);
      });

      test('loadEntry returns null after delete', () async {
        await service.saveEntry(testEntry);
        await service.deleteEntry('2025-06-15');

        final result = await service.loadEntry('2025-06-15');
        expect(result, isNull);
      });

      test('deleteEntry on non-existent id does not throw', () async {
        expect(() => service.deleteEntry('9999-12-31'), returnsNormally);
      });
    });

    group('hasEntryForDate', () {
      test('returns true after saving entry for date', () async {
        await service.saveEntry(testEntry);
        final result = await service.hasEntryForDate(testDate);
        expect(result, isTrue);
      });

      test('returns false when no entry exists for date', () async {
        final result =
            await service.hasEntryForDate(DateTime(1999, 1, 1));
        expect(result, isFalse);
      });

      test('returns false after entry is deleted', () async {
        await service.saveEntry(testEntry);
        await service.deleteEntry('2025-06-15');
        final result = await service.hasEntryForDate(testDate);
        expect(result, isFalse);
      });
    });

    group('getEntryDates', () {
      test('returns empty set when no entries saved', () async {
        final dates = await service.getEntryDates();
        expect(dates, isEmpty);
      });

      test('returns set of dates with saved entries', () async {
        final entry1 = JournalEntry(
          id: '2025-06-15',
          date: DateTime(2025, 6, 15),
          content: 'First',
          createdAt: DateTime(2025, 6, 15),
          updatedAt: DateTime(2025, 6, 15),
        );
        final entry2 = JournalEntry(
          id: '2025-07-20',
          date: DateTime(2025, 7, 20),
          content: 'Second',
          createdAt: DateTime(2025, 7, 20),
          updatedAt: DateTime(2025, 7, 20),
        );

        await service.saveEntry(entry1);
        await service.saveEntry(entry2);

        final dates = await service.getEntryDates();
        expect(dates, contains(DateTime(2025, 6, 15)));
        expect(dates, contains(DateTime(2025, 7, 20)));
        expect(dates.length, equals(2));
      });
    });

    group('saveImage and deleteImage', () {
      test('saveImage copies file to entries directory', () async {
        // Create a fake source image file
        final sourceFile = File('${tempDir.path}/source_image.jpg');
        await sourceFile.writeAsString('fake image data');

        final savedPath =
            await service.saveImage(sourceFile, '2025-06-15');

        expect(await File(savedPath).exists(), isTrue);
      });

      test('saveImage returns path within journal_entries directory',
          () async {
        final sourceFile = File('${tempDir.path}/source_image.png');
        await sourceFile.writeAsString('fake png data');

        final savedPath =
            await service.saveImage(sourceFile, '2025-06-15');

        expect(savedPath, contains('journal_entries'));
        expect(savedPath, contains('2025-06-15'));
      });

      test('deleteImage removes the image file', () async {
        final sourceFile = File('${tempDir.path}/to_delete.jpg');
        await sourceFile.writeAsString('delete me');

        final savedPath =
            await service.saveImage(sourceFile, '2025-06-15');
        expect(await File(savedPath).exists(), isTrue);

        await service.deleteImage(savedPath);
        expect(await File(savedPath).exists(), isFalse);
      });

      test('deleteImage on non-existent path does not throw', () async {
        expect(
          () => service.deleteImage('/nonexistent/path/image.jpg'),
          returnsNormally,
        );
      });
    });
  });
}

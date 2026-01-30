import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/journal_entry.dart';

/// Service for managing local storage of journal entries
class StorageService {
  static const String _entriesDir = 'journal_entries';

  /// Gets the directory where entries are stored
  Future<Directory> get _entriesDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final entriesDir = Directory('${appDir.path}/$_entriesDir');
    if (!await entriesDir.exists()) {
      await entriesDir.create(recursive: true);
    }
    return entriesDir;
  }

  /// Saves a journal entry to local storage
  /// Entry content is stored as markdown, metadata as JSON
  Future<void> saveEntry(JournalEntry entry) async {
    final dir = await _entriesDirectory;

    // Save entry content as markdown
    final contentFile = File('${dir.path}/${entry.id}.md');
    await contentFile.writeAsString(entry.content);

    // Save metadata (date, imagePath, timestamps) as JSON
    final metadataFile = File('${dir.path}/${entry.id}.json');
    await metadataFile.writeAsString(jsonEncode(entry.toJson()));
  }

  /// Loads a specific entry by ID (date)
  Future<JournalEntry?> loadEntry(String id) async {
    try {
      final dir = await _entriesDirectory;
      final metadataFile = File('${dir.path}/$id.json');
      final contentFile = File('${dir.path}/$id.md');

      if (!await metadataFile.exists() || !await contentFile.exists()) {
        return null;
      }

      final metadataJson = jsonDecode(await metadataFile.readAsString());
      final content = await contentFile.readAsString();

      // Create entry from metadata and content
      final entry = JournalEntry.fromJson(metadataJson);
      return entry.copyWith(content: content);
    } catch (e) {
      print('Error loading entry $id: $e');
      return null;
    }
  }

  /// Loads all journal entries
  Future<List<JournalEntry>> loadAllEntries() async {
    try {
      final dir = await _entriesDirectory;
      final entries = <JournalEntry>[];

      final files = await dir.list().toList();
      final jsonFiles = files
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      for (final file in jsonFiles) {
        final id = file.path.split(Platform.pathSeparator).last.replaceAll('.json', '');
        final entry = await loadEntry(id);
        if (entry != null) {
          entries.add(entry);
        }
      }

      // Sort by date, newest first
      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
    } catch (e) {
      print('Error loading entries: $e');
      return [];
    }
  }

  /// Deletes a journal entry
  Future<void> deleteEntry(String id) async {
    try {
      final dir = await _entriesDirectory;
      final metadataFile = File('${dir.path}/$id.json');
      final contentFile = File('${dir.path}/$id.md');

      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }
      if (await contentFile.exists()) {
        await contentFile.delete();
      }

      // Also delete associated image if it exists
      final entry = await loadEntry(id);
      if (entry?.imagePath != null) {
        final imageFile = File(entry!.imagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }
    } catch (e) {
      print('Error deleting entry $id: $e');
    }
  }

  /// Gets all dates that have entries
  Future<Set<DateTime>> getEntryDates() async {
    final entries = await loadAllEntries();
    return entries.map((e) => e.date).toSet();
  }

  /// Checks if an entry exists for a specific date
  Future<bool> hasEntryForDate(DateTime date) async {
    final id = _formatDateId(date);
    final entry = await loadEntry(id);
    return entry != null;
  }

  /// Saves an image file and returns its path
  Future<String> saveImage(File imageFile, String entryId) async {
    try {
      final dir = await _entriesDirectory;
      final extension = imageFile.path.split('.').last;
      final newPath = '${dir.path}/$entryId.$extension';

      final savedImage = await imageFile.copy(newPath);
      return savedImage.path;
    } catch (e) {
      print('Error saving image: $e');
      rethrow;
    }
  }

  /// Deletes an image file
  Future<void> deleteImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  /// Helper to format date to ID
  String _formatDateId(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return '${dateOnly.year.toString().padLeft(4, '0')}-'
        '${dateOnly.month.toString().padLeft(2, '0')}-'
        '${dateOnly.day.toString().padLeft(2, '0')}';
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../services/storage_service.dart';

/// Provider for managing journal entries state
class JournalProvider with ChangeNotifier {
  final StorageService _storageService;
  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String? _error;

  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Gets all dates that have entries (for calendar highlighting)
  Set<DateTime> get entryDates => _entries.map((e) => e.date).toSet();

  JournalProvider({StorageService? storageService})
      : _storageService = storageService ?? StorageService() {
    loadEntries();
  }

  /// Loads all journal entries from storage
  Future<void> loadEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _storageService.loadAllEntries();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load entries: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets an entry for a specific date
  JournalEntry? getEntryForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    try {
      return _entries.firstWhere(
        (entry) => entry.date.isAtSameMomentAs(dateOnly),
      );
    } catch (e) {
      return null;
    }
  }

  /// Gets an entry by ID
  JournalEntry? getEntryById(String id) {
    try {
      return _entries.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Checks if an entry exists for a date
  bool hasEntryForDate(DateTime date) {
    return getEntryForDate(date) != null;
  }

  /// Adds or updates a journal entry
  Future<void> saveEntry(JournalEntry entry, {File? imageFile}) async {
    try {
      // Handle image if provided
      String? imagePath = entry.imagePath;
      if (imageFile != null) {
        imagePath = await _storageService.saveImage(imageFile, entry.id);
      }

      // Update entry with image path
      final entryToSave = imagePath != entry.imagePath
          ? entry.copyWith(imagePath: imagePath)
          : entry;

      await _storageService.saveEntry(entryToSave);

      // Update local state
      final index = _entries.indexWhere((e) => e.id == entryToSave.id);
      if (index >= 0) {
        _entries[index] = entryToSave;
      } else {
        _entries.add(entryToSave);
        _entries.sort((a, b) => b.date.compareTo(a.date));
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to save entry: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Creates a new entry for today
  Future<void> createEntry(String content, {File? imageFile}) async {
    final entry = JournalEntry.create(content: content);
    await saveEntry(entry, imageFile: imageFile);
  }

  /// Creates an entry for a specific date
  Future<void> createEntryForDate(
    DateTime date,
    String content, {
    File? imageFile,
  }) async {
    final entry = JournalEntry.forDate(
      date: date,
      content: content,
    );
    await saveEntry(entry, imageFile: imageFile);
  }

  /// Updates an existing entry
  Future<void> updateEntry(
    String id,
    String newContent, {
    File? newImageFile,
    bool removeImage = false,
  }) async {
    final existingEntry = getEntryById(id);
    if (existingEntry == null) {
      throw Exception('Entry not found');
    }

    // Handle image removal
    if (removeImage && existingEntry.imagePath != null) {
      await _storageService.deleteImage(existingEntry.imagePath!);
    }

    final updatedEntry = existingEntry.copyWith(
      content: newContent,
      clearImagePath: removeImage,
    );

    await saveEntry(updatedEntry, imageFile: newImageFile);
  }

  /// Deletes an entry
  Future<void> deleteEntry(String id) async {
    try {
      await _storageService.deleteEntry(id);
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete entry: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Gets entries for a specific month
  List<JournalEntry> getEntriesForMonth(int year, int month) {
    return _entries.where((entry) {
      return entry.date.year == year && entry.date.month == month;
    }).toList();
  }

  /// Gets recent entries (limited number)
  List<JournalEntry> getRecentEntries({int limit = 10}) {
    return _entries.take(limit).toList();
  }

  /// Clears any error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

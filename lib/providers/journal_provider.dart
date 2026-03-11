import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

/// Provider for managing journal entries state
class JournalProvider with ChangeNotifier {
  final FirestoreService? _firestoreServiceOverride;
  final StorageService? _storageServiceOverride;

  FirestoreService get _firestoreService =>
      _firestoreServiceOverride ?? FirestoreService();
  StorageService get _storageService =>
      _storageServiceOverride ?? StorageService();

  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String? _error;

  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Gets all dates that have entries (for calendar highlighting)
  Set<DateTime> get entryDates => _entries.map((e) => e.date).toSet();

  JournalProvider({
    FirestoreService? firestoreService,
    StorageService? storageService,
  })  : _firestoreServiceOverride = firestoreService,
        _storageServiceOverride = storageService;

  /// Resets provider state when auth status changes
  void resetForAuthChange() {
    _entries = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Loads all journal entries from Firestore (source of truth)
  Future<void> loadEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _firestoreService.loadAllEntries();
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

  /// Adds or updates a journal entry.
  /// If [imageFile] is provided, saves it to local storage first and embeds
  /// the resulting path into the entry before writing to both stores.
  Future<void> saveEntry(JournalEntry entry, {File? imageFile}) async {
    try {
      var entryToSave = entry;

      // Save image to local disk first; embed the returned path into the entry
      if (imageFile != null) {
        final imagePath =
            await _storageService.saveImage(imageFile, entry.id);
        entryToSave = entry.copyWith(imagePath: imagePath);
      }

      // Write to Firestore (source of truth)
      await _firestoreService.saveEntry(entryToSave);

      // Write to local storage (best-effort cache)
      try {
        await _storageService.saveEntry(entryToSave);
      } catch (e) {
        debugPrint('Local storage save failed (non-fatal): $e');
      }

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

    final updatedEntry = existingEntry.copyWith(
      content: newContent,
      clearImagePath: removeImage,
    );

    // Delete the old image file from local storage when removing an image
    if (removeImage && existingEntry.imagePath != null) {
      try {
        await _storageService.deleteImage(existingEntry.imagePath!);
      } catch (e) {
        debugPrint('Local image delete failed (non-fatal): $e');
      }
    }

    await saveEntry(updatedEntry, imageFile: newImageFile);
  }

  /// Deletes an entry from both Firestore and local storage
  Future<void> deleteEntry(String id) async {
    try {
      final entry = getEntryById(id);

      await _firestoreService.deleteEntry(id);

      // Clean up local storage (best-effort)
      try {
        // Delete the image file explicitly first so StorageService.deleteEntry
        // doesn't try to re-load the metadata to find it
        if (entry?.imagePath != null) {
          await _storageService.deleteImage(entry!.imagePath!);
        }
        await _storageService.deleteEntry(id);
      } catch (e) {
        debugPrint('Local storage delete failed (non-fatal): $e');
      }

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

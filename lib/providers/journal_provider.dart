import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/journal_entry.dart';
import '../services/firestore_service.dart';

/// Provider for managing journal entries state (Cloud-only)
class JournalProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String? _error;

  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Set<DateTime> get entryDates => _entries.map((e) => e.date).toSet();

  JournalProvider() {
    // We can load immediately if already signed in,
    // but it's best to trigger load from AuthGate on auth changes.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      loadEntries();
    }
  }

  /// Clear provider state when auth changes (prevents cross-account bleed)
  void resetForAuthChange() {
    _entries = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Loads all journal entries from Firestore (cloud only)
  Future<void> loadEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _entries = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      _entries = await _firestoreService.fetchAllEntries();
      _entries.sort((a, b) => b.date.compareTo(a.date));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load entries: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  JournalEntry? getEntryForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    try {
      return _entries.firstWhere((e) => e.date.isAtSameMomentAs(dateOnly));
    } catch (_) {
      return null;
    }
  }

  JournalEntry? getEntryById(String id) {
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  bool hasEntryForDate(DateTime date) => getEntryForDate(date) != null;

  /// Cloud-only save/upsert
  Future<void> saveEntry(JournalEntry entry, {File? imageFile}) async {
    // imageFile ignored for now (Firebase Storage is a separate step)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Must be signed in to save entries.');
      }

      await _firestoreService.upsertEntry(entry);

      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index >= 0) {
        _entries[index] = entry;
      } else {
        _entries.add(entry);
      }

      _entries.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save entry: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createEntry(String content, {File? imageFile}) async {
    final entry = JournalEntry.create(content: content);
    await saveEntry(entry, imageFile: imageFile);
  }

  Future<void> createEntryForDate(
    DateTime date,
    String content, {
    File? imageFile,
  }) async {
    final entry = JournalEntry.forDate(date: date, content: content);
    await saveEntry(entry, imageFile: imageFile);
  }

  Future<void> updateEntry(
    String id,
    String newContent, {
    File? newImageFile,
    bool removeImage = false,
  }) async {
    final existing = getEntryById(id);
    if (existing == null) throw Exception('Entry not found');

    final updated = existing.copyWith(
      content: newContent,
      imagePath: removeImage ? null : existing.imagePath,
    );

    await saveEntry(updated, imageFile: newImageFile);
  }

  Future<void> deleteEntry(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Must be signed in to delete entries.');
      }

      await _firestoreService.deleteEntry(id);
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete entry: $e';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
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

}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';
import '../services/storage_service.dart';

class JournalProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<JournalEntry> _entries = [];
  bool _isLoading = false;

  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  // Load all entries (from Firestore or local storage)
  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load entries from Firestore or local storage (if offline)
      _entries = await _storageService.loadAllEntries();
    } catch (e) {
      print('Error loading entries: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Save an entry (both to Firestore and local storage)
  Future<void> saveEntry(JournalEntry entry) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Save entry to Firestore and local storage
      await _storageService.saveEntry(entry);

      // Add the saved entry to the list (for local state management)
      _entries.insert(0, entry);
    } catch (e) {
      print('Error saving entry: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Delete an entry (both from Firestore and local storage)
  Future<void> deleteEntry(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Delete the entry from Firestore and local state
      await _storageService.deleteEntry(id);

      // Remove from the local entries list
      _entries.removeWhere((entry) => entry.id == id);
    } catch (e) {
      print('Error deleting entry: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}

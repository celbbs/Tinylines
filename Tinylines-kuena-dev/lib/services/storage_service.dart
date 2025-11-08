import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';

/// Service for managing local storage of journal entries
class StorageService {
  static const String _entriesDir = 'journal_entries';

  // Get the directory where entries are stored (for offline)
  Future<Directory> get _entriesDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final entriesDir = Directory('${appDir.path}/$_entriesDir');
    if (!await entriesDir.exists()) {
      await entriesDir.create(recursive: true);
    }
    return entriesDir;
  }

  // Saves a journal entry to both Firestore and local storage (for offline support)
  Future<void> saveEntry(JournalEntry entry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User is not logged in");
      return;
    }

    try {
      final firestoreRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('entries');

      // Save entry content to Firestore
      await firestoreRef.add({
        'content': entry.content,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Also save entry locally
      final dir = await _entriesDirectory;
      final contentFile = File('${dir.path}/${entry.id}.md');
      await contentFile.writeAsString(entry.content);

      final metadataFile = File('${dir.path}/${entry.id}.json');
      await metadataFile.writeAsString(jsonEncode(entry.toJson()));

      print("Entry saved successfully!");
    } catch (e) {
      print("Error saving entry: $e");
    }
  }

  // Loads a specific entry from Firestore or local storage
  Future<JournalEntry?> loadEntry(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final firestoreRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('entries')
          .doc(id);

      // First, try loading from Firestore
      final docSnapshot = await firestoreRef.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final entry = JournalEntry.fromJson(data);
        return entry;
      }

      // If not found in Firestore, load from local storage (for offline support)
      final dir = await _entriesDirectory;
      final metadataFile = File('${dir.path}/$id.json');
      final contentFile = File('${dir.path}/$id.md');

      if (!await metadataFile.exists() || !await contentFile.exists()) {
        return null;
      }

      final metadataJson = jsonDecode(await metadataFile.readAsString());
      final content = await contentFile.readAsString();

      final entry = JournalEntry.fromJson(metadataJson);
      return entry.copyWith(content: content);
    } catch (e) {
      print('Error loading entry $id: $e');
      return null;
    }
  }

  // Load all journal entries (from Firestore)
  Future<List<JournalEntry>> loadAllEntries() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final firestoreRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('entries')
          .orderBy('timestamp', descending: true);

      final querySnapshot = await firestoreRef.get();
      final entries = querySnapshot.docs.map((doc) {
        return JournalEntry.fromJson(doc.data());
      }).toList();

      return entries;
    } catch (e) {
      print('Error loading entries: $e');
      return [];
    }
  }

  // Deletes a journal entry (from Firestore and local storage)
  Future<void> deleteEntry(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User is not logged in");
      return;
    }

    try {
      final firestoreRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('entries')
          .doc(id);

      // Delete from Firestore
      await firestoreRef.delete();

      // Delete from local storage (if applicable)
      final dir = await _entriesDirectory;
      final metadataFile = File('${dir.path}/$id.json');
      final contentFile = File('${dir.path}/$id.md');

      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }
      if (await contentFile.exists()) {
        await contentFile.delete();
      }

      print("Entry deleted successfully!");
    } catch (e) {
      print('Error deleting entry $id: $e');
    }
  }
}

import 'package:tinylines/models/journal_entry.dart';
import 'package:tinylines/services/firestore_service.dart';

class FakeFirestoreService implements FirestoreService {
  FakeFirestoreService({
    List<JournalEntry>? seedEntries,
    this.throwOnLoad = false,
    this.throwOnSave = false,
    this.throwOnDelete = false,
  }) : _entries = List<JournalEntry>.from(seedEntries ?? []);

  final List<JournalEntry> _entries;

  bool throwOnLoad;
  bool throwOnSave;
  bool throwOnDelete;

  List<JournalEntry> get storedEntries => List<JournalEntry>.from(_entries);

  @override
  Future<List<JournalEntry>> loadAllEntries() async {
    if (throwOnLoad) {
      throw Exception('load failed');
    }

    final entries = List<JournalEntry>.from(_entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  @override
  Future<void> saveEntry(JournalEntry entry) async {
    if (throwOnSave) {
      throw Exception('save failed');
    }

    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      _entries[index] = entry;
    } else {
      _entries.add(entry);
    }

    _entries.sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> deleteEntry(String id) async {
    if (throwOnDelete) {
      throw Exception('delete failed');
    }

    _entries.removeWhere((e) => e.id == id);
  }
}
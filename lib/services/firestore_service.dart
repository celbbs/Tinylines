import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/journal_entry.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User get _user {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }
    return user;
  }

  CollectionReference<Map<String, dynamic>> get _entriesRef {
    return _db.collection('users').doc(_user.uid).collection('entries');
  }

  Future<void> upsertEntry(JournalEntry entry) async {
    // Store cloud-safe fields only.
    // (We keep local imagePath local for now; we’ll add Firebase Storage later.)
    await _entriesRef.doc(entry.id).set(
      {
        'id': entry.id,
        'date': Timestamp.fromDate(entry.date),
        'content': entry.content,
        'createdAt': Timestamp.fromDate(entry.createdAt),
        'updatedAt': Timestamp.fromDate(entry.updatedAt),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteEntry(String id) async {
    await _entriesRef.doc(id).delete();
  }

  Future<List<JournalEntry>> fetchAllEntries() async {
    final snapshot = await _entriesRef.get();
    return snapshot.docs.map(_docToEntry).toList();
  }

  Future<JournalEntry?> fetchEntryById(String id) async {
    final doc = await _entriesRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return _docToEntry(doc);
  }

  JournalEntry _docToEntry(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final dateTs = data['date'] as Timestamp;
    final createdTs = (data['createdAt'] as Timestamp?) ?? dateTs;
    final updatedTs = (data['updatedAt'] as Timestamp?) ?? dateTs;

    return JournalEntry(
      id: data['id'] as String? ?? doc.id,
      date: dateTs.toDate(),
      content: data['content'] as String? ?? '',
      // imagePath remains local-only for now
      imagePath: null,
      createdAt: createdTs.toDate(),
      updatedAt: updatedTs.toDate(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _entriesCollection {
    final user = _currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('entries');
  }

  Future<List<JournalEntry>> loadAllEntries() async {
    final snapshot = await _entriesCollection.orderBy('date', descending: true).get();

    return snapshot.docs
        .map((doc) => JournalEntry.fromJson(doc.data()))
        .toList();
  }

  Future<void> saveEntry(JournalEntry entry) async {
    await _entriesCollection.doc(entry.id).set(entry.toJson());
  }

  Future<void> deleteEntry(String id) async {
    await _entriesCollection.doc(id).delete();
  }
}
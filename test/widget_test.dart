import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tinylines/models/journal_entry.dart';
import 'package:tinylines/providers/journal_provider.dart';
import 'package:tinylines/screens/home_screen.dart';
import 'package:tinylines/services/firestore_service.dart';

class FakeFirestoreService implements FirestoreService {
  FakeFirestoreService({List<JournalEntry>? seedEntries})
      : _entries = List<JournalEntry>.from(seedEntries ?? []);

  final List<JournalEntry> _entries;

  @override
  Future<List<JournalEntry>> loadAllEntries() async {
    final entries = List<JournalEntry>.from(_entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  @override
  Future<void> saveEntry(JournalEntry entry) async {
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
    _entries.removeWhere((e) => e.id == id);
  }
}

void main() {
  testWidgets('HomeScreen smoke test', (WidgetTester tester) async {
    final provider = JournalProvider(
      firestoreService: FakeFirestoreService(),
    );
    await provider.loadEntries();

    await tester.pumpWidget(
      ChangeNotifierProvider<JournalProvider>.value(
        value: provider,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('TinyLines'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('No entries yet'), findsOneWidget);
  });
}
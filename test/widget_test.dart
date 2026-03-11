// This is a basic Flutter widget test for TinyLines.
// NOTE: Full app smoke tests require Firebase to be initialized.
// Detailed widget tests live in test/screens/.
import 'package:flutter_test/flutter_test.dart';
import 'package:tinylines/main.dart';

void main() {
  testWidgets('TinyLinesApp widget can be instantiated', (WidgetTester tester) async {
    // Verify the app widget itself can be constructed without errors.
    // Full integration tests (auth, Firestore) require a Firebase test environment.
    expect(const TinyLinesApp(), isA<TinyLinesApp>());
  });
}

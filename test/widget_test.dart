// This is a basic Flutter widget test for TinyLines.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiny_lines/main.dart';

void main() {
  testWidgets('TinyLines app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TinyLinesApp());

    // Verify that TinyLines title appears.
    expect(find.text('TinyLines'), findsOneWidget);

    // Verify that the FAB (add button) is present.
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}

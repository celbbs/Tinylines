import 'package:flutter/material.dart';
import 'journal_entry_page.dart';
import 'settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TinyLines',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const SettingsPage(),
    );
  }
}
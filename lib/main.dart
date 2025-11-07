import 'package:flutter/material.dart';
import 'screens/journal_entry.dart';

void main() 
{
  runApp(const MyApp());
}

class MyApp extends StatelessWidget 
{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) 
  {
    return MaterialApp(
      title: 'TinyLines Journal', //title 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 122, 29, 29)),
      ),
      home: const JournalApp(), // journal entry page as the home screen
    );
  }
}

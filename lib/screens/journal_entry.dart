import 'package:flutter/material.dart';

// https://docs.flutter.dev/get-started/fundamentals/user-input
// https://docs.flutter.dev/cookbook/forms/text-input
// https://www.youtube.com/watch?v=2QxzqkLzAG8
// https://www.youtube.com/watch?v=feMMp7qR-ME
// https://www.geeksforgeeks.org/flutter/flutter-tutorial/#

void main() 
{
  runApp(const JournalApp());
}

class JournalApp extends StatelessWidget 
{
  const JournalApp({super.key});

  @override
  Widget build(BuildContext context) 
  {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Daily Journal Entry')), // title at top of page
        body: const Padding(
          padding: EdgeInsets.all(16), //padding
          child: JournalEntry(),
        ),
      ),
    );
  }
}

//text input and save button
class JournalEntry extends StatelessWidget 
{
  const JournalEntry({super.key});

  @override
  Widget build(BuildContext context) 
  {
    // controls the text in the box
    final TextEditingController _controller = TextEditingController();

    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null, // unlimited lines for input for now.....
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Write your thoughts here...',
            ),
          ),
        ),
        const SizedBox(height: 16), //padding
        ElevatedButton( //input button
          onPressed: () 
          {
            _controller.clear(); // deletes input, pretend it saves for now
          },
          child: const Text('Save Entry'),
        ),
      ],
    );
  }
}

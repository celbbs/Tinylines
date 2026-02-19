import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JournalEntryPage extends StatefulWidget {
  const JournalEntryPage({super.key});

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  final TextEditingController _entryController = TextEditingController();
  String _savedEntry = '';
  bool _isEditing = false;

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    setState(() {
      _savedEntry = _entryController.text;
      _isEditing = false;
    });
    
    // confirmation that journal entry saved
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry saved!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _editEntry() {
    setState(() {
      _isEditing = true;
      _entryController.text = _savedEntry;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _entryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('MM/dd/yyyy').format(DateTime.now());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Journal Entry'),
        backgroundColor: const Color(0xFFFFB74D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // show date
            Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // entry text field
            TextField(
              controller: _entryController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Write your line of the day here',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            // save/cancel buttons
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB74D),
                      minimumSize: const Size(150, 50),
                    ),
                    child: const Text(
                      'Save Entry',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _cancelEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        minimumSize: const Size(150, 50),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // show saved entry w edit button
            if (_savedEntry.isNotEmpty && !_isEditing)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Saved Entry:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _editEntry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB74D),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(_savedEntry),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
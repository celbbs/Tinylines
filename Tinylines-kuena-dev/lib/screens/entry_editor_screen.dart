import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import '../utils/app_theme.dart';

class EntryEditorScreen extends StatefulWidget {
  final JournalEntry? entry; // null for new entry
  final DateTime? date; // specified date for new entry

  const EntryEditorScreen({
    super.key,
    this.entry,
    this.date,
  });

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late TextEditingController _contentController;
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _existingImagePath;
  bool _isEdited = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.entry?.content ?? '');
    _existingImagePath = widget.entry?.imagePath;
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (!_isEdited) {
      setState(() {
        _isEdited = true;
      });
    }
  }

  bool get _isNewEntry => widget.entry == null;

  String get _title {
    if (widget.entry != null) {
      return widget.entry!.formattedDate;
    } else if (widget.date != null) {
      final dateOnly = DateTime(widget.date!.year, widget.date!.month, widget.date!.day);
      final entry = JournalEntry.forDate(date: dateOnly, content: '');
      return entry.formattedDate;
    } else {
      return 'New Entry';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !(_isEdited && _contentController.text.isNotEmpty),
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop && _isEdited && _contentController.text.isNotEmpty) {
          final shouldPop = await _showDiscardDialog();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: [
            if (!_isNewEntry)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _showDeleteDialog,
              ),
            if (_isEdited && _contentController.text.isNotEmpty)
              TextButton(
                onPressed: _isSaving ? null : _saveEntry,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: AppTheme.spacingM),
                    _buildContentField(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final hasImage = _selectedImage != null || _existingImagePath != null;

    if (!hasImage) {
      return InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: AppTheme.dividerColor, width: 2),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: AppTheme.textHint,
                ),
                SizedBox(height: AppTheme.spacingS),
                Text(
                  'Add photo (optional)',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: _selectedImage != null
              ? Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  File(_existingImagePath!),
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: AppTheme.spacingS,
          right: AppTheme.spacingS,
          child: Row(
            children: [
              _buildImageButton(
                icon: Icons.edit,
                onTap: _pickImage,
              ),
              const SizedBox(width: AppTheme.spacingS),
              _buildImageButton(
                icon: Icons.delete,
                onTap: _removeImage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
        padding: const EdgeInsets.all(AppTheme.spacingS),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildContentField() {
    return TextField(
      controller: _contentController,
      maxLines: null,
      minLines: 10,
      autofocus: _isNewEntry,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: const InputDecoration(
        hintText: 'What\'s on your mind today?',
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildBottomBar() {
    final wordCount = _contentController.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final charCount = _contentController.text.length;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$wordCount words • $charCount characters',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          if (_isNewEntry)
            ElevatedButton.icon(
              onPressed: _contentController.text.isEmpty || _isSaving ? null : _saveEntry,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check, size: 20),
              label: Text(_isSaving ? 'Saving...' : 'Save Entry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isEdited = true;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _existingImagePath = null;
      _isEdited = true;
    });
  }

  Future<void> _saveEntry() async {
    if (_contentController.text.isEmpty) {
      _showErrorSnackBar('Please write something before saving');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = Provider.of<JournalProvider>(context, listen: false);
      final content = _contentController.text;

      if (_isNewEntry) {
        // Create new entry
        if (widget.date != null) {
          await provider.createEntryForDate(
            widget.date!,
            content,
            imageFile: _selectedImage,
          );
        } else {
          await provider.createEntry(content, imageFile: _selectedImage);
        }
      } else {
        // Update existing entry
        await provider.updateEntry(
          widget.entry!.id,
          content,
          newImageFile: _selectedImage,
          removeImage: _existingImagePath != null && _selectedImage == null,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry saved'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save entry: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteEntry() async {
    try {
      final provider = Provider.of<JournalProvider>(context, listen: false);
      await provider.deleteEntry(widget.entry!.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry deleted'),
            backgroundColor: AppTheme.errorColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete entry: $e');
    }
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showDeleteDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteEntry();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/journal_provider.dart';
import '../providers/settings_provider.dart';
import '../models/journal_entry.dart';
import '../utils/app_theme.dart';

enum _SaveStatus { clean, unsaved, saving, saved }

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
  bool _removeExistingImage = false;
  bool _isEdited = false;
  bool _isSaving = false;
  _SaveStatus _saveStatus = _SaveStatus.clean;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.entry?.content ?? '');
    _existingImagePath = widget.entry?.imagePath;
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    setState(() {
      _isEdited = true;
      if (!_isNewEntry) _saveStatus = _SaveStatus.unsaved;
    });
    if (!_isNewEntry) _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final seconds =
        int.tryParse(settings.autoSaveInterval.split(' ').first) ?? 30;
    _autoSaveTimer = Timer(Duration(seconds: seconds), _performAutoSave);
  }

  Future<void> _performAutoSave() async {
    if (!mounted || _contentController.text.isEmpty) return;
    setState(() {
      _saveStatus = _SaveStatus.saving;
      _isSaving = true;
    });
    try {
      final provider = Provider.of<JournalProvider>(context, listen: false);
      await provider.updateEntry(
        widget.entry!.id,
        _contentController.text,
        newImageFile: _selectedImage,
        removeImage: _existingImagePath != null && _selectedImage == null,
      );
      if (mounted) {
        setState(() {
          _isEdited = false;
          _saveStatus = _SaveStatus.saved;
          _isSaving = false;
        });
        Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saveStatus = _SaveStatus.clean);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveStatus = _SaveStatus.unsaved;
          _isSaving = false;
        });
      }
    }
  }

  bool get _isNewEntry => widget.entry == null;

  bool get _hasUsableExistingImage {
    if (_existingImagePath == null || _existingImagePath!.isEmpty) {
      return false;
    }
    return File(_existingImagePath!).existsSync();
  }

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
    final hasImage = _selectedImage != null || _hasUsableExistingImage;

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
      maxLength: 500,
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

  Widget _buildSaveStatusText() {
    switch (_saveStatus) {
      case _SaveStatus.unsaved:
        return Text(
          'Unsaved changes',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
        );
      case _SaveStatus.saving:
        return Text(
          'Saving...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        );
      case _SaveStatus.saved:
        return Text(
          'Saved ✓',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w600,
              ),
        );
      case _SaveStatus.clean:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar() {
    final wordCount = _contentController.text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
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
            )
          else
            _buildSaveStatusText(),
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
          _removeExistingImage = false;
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
      _removeExistingImage = widget.entry?.imagePath != null;
      _existingImagePath = null;
      _isEdited = true;
    });
  }

  Future<void> _saveEntry() async {
    if (_contentController.text.isEmpty) {
      _showErrorSnackBar('Please write something before saving');
      return;
    }

    _autoSaveTimer?.cancel();
    setState(() {
      _isSaving = true;
    });

    try {
      final provider = Provider.of<JournalProvider>(context, listen: false);
      final content = _contentController.text;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      if (_isNewEntry) {
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
        await provider.updateEntry(
          widget.entry!.id,
          content,
          newImageFile: _selectedImage,
          removeImage: _removeExistingImage,
        );
      }

      if (!mounted) return;

      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Entry saved'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );
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
    final entry = widget.entry!;
    final provider = Provider.of<JournalProvider>(context, listen: false);

    // Capture before popping so context remains valid
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    navigator.pop();

    bool undone = false;
    Timer? deleteTimer;

    messenger.showSnackBar(
      SnackBar(
        content: const Text('Entry deleted'),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            undone = true;
            deleteTimer?.cancel();
          },
        ),
      ),
    );

    deleteTimer = Timer(const Duration(seconds: 8), () async {
      if (!undone) {
        try {
          await provider.deleteEntry(entry.id);
        } catch (e) {
          debugPrint('Failed to delete entry: $e');
        }
      }
    });
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
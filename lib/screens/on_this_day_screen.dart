import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import '../utils/app_theme.dart';
import 'entry_editor_screen.dart';

class OnThisDayScreen extends StatelessWidget
{
  const OnThisDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<JournalProvider>(context);
    final now = DateTime.now();

    // filter same month/day (any year)
    final entries = provider.entries.where(
      (entry) => entry.date.month == now.month && entry.date.day == now.day,
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('On This Day'),
      ),
      body: entries.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _buildEntryCard(context, entry);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: AppTheme.spacingM),
            const Text(
              'No entries for this day',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            const Text(
              'Check back later or add a new entry today!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, JournalEntry entry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EntryEditorScreen(entry: entry),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date + optional image icon
              Row(
                children: [
                  Text(
                    entry.formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  if (entry.imagePath != null)
                    const Icon(
                      Icons.image,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              // Entry content snippet
              Text(
                entry.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (entry.imagePath != null) ...[
                const SizedBox(height: AppTheme.spacingS),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  child: Image.file(
                    File(entry.imagePath!),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

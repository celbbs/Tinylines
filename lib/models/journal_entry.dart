import 'package:intl/intl.dart';

/// Represents a single journal entry
class JournalEntry {
  final String id; // Date-based ID (YYYY-MM-DD format)
  final DateTime date;
  final String content;
  final String? imagePath; // Optional path to attached image
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry({
    required this.id,
    required this.date,
    required this.content,
    this.imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Creates a new entry with the current date
  factory JournalEntry.create({
    required String content,
    String? imagePath,
  }) {
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    return JournalEntry(
      id: _formatDateId(dateOnly),
      date: dateOnly,
      content: content,
      imagePath: imagePath,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates an entry for a specific date
  factory JournalEntry.forDate({
    required DateTime date,
    required String content,
    String? imagePath,
  }) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    return JournalEntry(
      id: _formatDateId(dateOnly),
      date: dateOnly,
      content: content,
      imagePath: imagePath,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Formats date to ID string (YYYY-MM-DD)
  static String _formatDateId(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Returns a formatted date string for display
  String get formattedDate => DateFormat('MMMM d, yyyy').format(date);

  /// Returns a short formatted date (e.g., "Jan 1")
  String get shortDate => DateFormat('MMM d').format(date);

  /// Creates a copy with updated fields
  JournalEntry copyWith({
    String? id,
    DateTime? date,
    String? content,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Converts entry to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'content': content,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates entry from JSON map
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      content: json['content'] as String,
      imagePath: json['imagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  String toString() => 'JournalEntry(id: $id, date: $formattedDate, content length: ${content.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

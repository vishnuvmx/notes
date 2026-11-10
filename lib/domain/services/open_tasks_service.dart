import '../models/base_item.dart';
import '../models/text_note.dart';
import '../models/sticky_note.dart';

/// A derived task extracted from a Markdown checklist line (`- [ ]` or `- [x]`)
/// inside a note. Markdown remains the single source of truth (`04` F3, `08` §5).
class DerivedTaskItem {
  final String noteId;
  final String noteTitle;
  final String paletteId;
  final int lineIndex;
  final String text;
  final bool isDone;
  final DateTime noteUpdatedAt;

  const DerivedTaskItem({
    required this.noteId,
    required this.noteTitle,
    required this.paletteId,
    required this.lineIndex,
    required this.text,
    required this.isDone,
    required this.noteUpdatedAt,
  });

  String get id => '$noteId:$lineIndex';
}

/// Service for extracting and toggling Markdown checklist tasks across workspace notes,
/// and propagating wiki-link title renames (`04` M2/F3/F5, `08` §5).
class OpenTasksService {
  static final RegExp _taskLineRegex = RegExp(
    r'^(\s*[-*]\s+\[)([ xX])(\]\s+)(.+)$',
  );

  /// Extracts all tasks from active (non-trash, non-inbox) notes.
  static List<DerivedTaskItem> extractTasks(
    Iterable<BaseWorkspaceItem> items, {
    bool includeCompleted = false,
  }) {
    final results = <DerivedTaskItem>[];

    for (final item in items) {
      if (item.isTrash || item.isInbox) continue;
      String? body;
      if (item is TextNote) {
        body = item.content;
      } else if (item is StickyNote) {
        body = item.content;
      }
      if (body == null || body.isEmpty) continue;

      final lines = body.split('\n');
      bool inCodeFence = false;

      for (int i = 0; i < lines.length; i++) {
        final rawLine = lines[i];
        final trimmed = rawLine.trimLeft();
        if (trimmed.startsWith('```')) {
          inCodeFence = !inCodeFence;
          continue;
        }
        if (inCodeFence) continue;

        final match = _taskLineRegex.firstMatch(rawLine);
        if (match != null) {
          final mark = match.group(2)!;
          final isDone = mark.toLowerCase() == 'x';
          if (!includeCompleted && isDone) continue;

          final taskText = match.group(4)!.trim();
          if (taskText.isEmpty) continue;

          results.add(
            DerivedTaskItem(
              noteId: item.id,
              noteTitle: item.title.trim().isEmpty ? 'Untitled' : item.title,
              paletteId: item.paletteId,
              lineIndex: i,
              text: taskText,
              isDone: isDone,
              noteUpdatedAt: item.updatedAt,
            ),
          );
        }
      }
    }

    return results;
  }

  /// Toggles the checkbox state on [lineIndex] of [markdownContent].
  /// Returns the updated Markdown string, or `null` if [lineIndex] is no longer a task line.
  static String? toggleTaskAtLine(String markdownContent, int lineIndex) {
    final lines = markdownContent.split('\n');
    if (lineIndex < 0 || lineIndex >= lines.length) return null;

    final match = _taskLineRegex.firstMatch(lines[lineIndex]);
    if (match == null) return null;

    final prefix = match.group(1)!;
    final currentMark = match.group(2)!;
    final middle = match.group(3)!;
    final rest = match.group(4)!;

    final nextMark = currentMark.toLowerCase() == 'x' ? ' ' : 'x';
    lines[lineIndex] = '$prefix$nextMark$middle$rest';
    return lines.join('\n');
  }

  /// Rewrites `[[oldTitle]]`, `[[oldTitle|alias]]`, `[[oldTitle#heading]]`, and
  /// `![[oldTitle...]]` references inside [markdown] to [newTitle].
  static String rewriteWikiLinks(
    String markdown, {
    required String oldTitle,
    required String newTitle,
  }) {
    final oldTrimmed = oldTitle.trim();
    final newTrimmed = newTitle.trim();
    if (oldTrimmed.isEmpty ||
        newTrimmed.isEmpty ||
        oldTrimmed.toLowerCase() == newTrimmed.toLowerCase()) {
      return markdown;
    }

    final escapedOld = RegExp.escape(oldTrimmed);
    final pattern = RegExp(
      r'(!?\[\[)(' + escapedOld + r')((?:#[^\]|]+)?(?:\|[^\]]+)?)(\]\])',
      caseSensitive: false,
    );

    return markdown.replaceAllMapped(pattern, (m) {
      final open = m.group(1)!;
      final suffix = m.group(3) ?? '';
      final close = m.group(4)!;
      return '$open$newTrimmed$suffix$close';
    });
  }
}


import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Reusable service for note exporting, formatting, and clipboard operations.
class NoteExportService {
  NoteExportService._();

  /// Formats note title and content as structured Markdown.
  static String formatMarkdown({
    required String title,
    required String content,
    List<String> tags = const [],
  }) {
    final buffer = StringBuffer();
    if (title.trim().isNotEmpty) {
      buffer.writeln('# $title');
      buffer.writeln();
    }
    if (tags.isNotEmpty) {
      buffer.writeln(tags.map((t) => '#$t').join(' '));
      buffer.writeln();
    }
    buffer.write(content);
    return buffer.toString();
  }

  /// Strips markdown syntax and checklist markers for clean plain text.
  static String formatPlainText({
    required String title,
    required String content,
  }) {
    final stripped = content
        .replaceAll(RegExp(r'[*#_~`>]'), '')
        .replaceAll(RegExp(r'\[[ xX]\]'), '•');
    if (title.trim().isEmpty) return stripped.trim();
    return '$title\n\n$stripped'.trim();
  }

  /// Copies formatted markdown string to clipboard.
  static Future<void> copyMarkdown({
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final text = formatMarkdown(title: title, content: content, tags: tags);
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Copies stripped plain text string to clipboard.
  static Future<void> copyPlainText({
    required String title,
    required String content,
  }) async {
    final text = formatPlainText(title: title, content: content);
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Shares note content using the system share sheet.
  static Future<void> shareNote({
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final text = formatMarkdown(title: title, content: content, tags: tags);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: title.isNotEmpty ? title : 'Note from Tack',
      ),
    );
  }
}

import 'package:flutter/services.dart';

/// Block types supported by Tack's "Turn Into" block transformation engine.
enum BlockKind {
  paragraph('Paragraph', 'Plain body text'),
  h1('Heading 1', 'Large section title (#)'),
  h2('Heading 2', 'Medium section title (##)'),
  h3('Heading 3', 'Sub-section heading (###)'),
  todo('To-Do Item', 'Interactive task ([ ])'),
  bullet('Bullet List', 'Unordered list item (-)'),
  numbered('Numbered List', 'Ordered step (1.)'),
  quote('Blockquote', 'Indented quote (>)'),
  toggle('Toggle Block', 'Collapsible section (>▸)'),
  calloutNote('Note Callout', 'Highlighted info box ([!NOTE])'),
  calloutTip('Tip Callout', 'Helpful green tip ([!TIP])'),
  calloutWarning('Warning Callout', 'Amber caution box ([!WARNING])');

  final String label;
  final String subtitle;
  const BlockKind(this.label, this.subtitle);
}

/// Pure text transformation service for block-level "Turn Into", Move Up/Down,
/// and Duplicate Line operations on Markdown notes.
class BlockTransformService {
  BlockTransformService._();

  static final RegExp _prefixStripper = RegExp(
    r'^(\s*)(?:'
    r'#{1,6}\s+'
    r'|[-*+]\s+\[[ xX]\]\s*'
    r'|\[[ xX]\]\s*'
    r'|[-*+•]\s+'
    r'|\d+[\.\)]\s+'
    r'|>+\s*\[!(?:NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*'
    r'|>+\s*▸\s*'
    r'|>+\s*'
    r')',
    caseSensitive: false,
  );

  /// Detects the `BlockKind` of the line where the cursor currently sits.
  static BlockKind detectBlockKind(String text, int cursorOffset) {
    if (text.isEmpty) return BlockKind.paragraph;
    final safeCursor = cursorOffset.clamp(0, text.length);
    final bounds = _lineBoundsAt(text, safeCursor);
    final line = text.substring(bounds.start, bounds.end).trimLeft();

    if (RegExp(r'^>\s*\[!NOTE\]', caseSensitive: false).hasMatch(line)) {
      return BlockKind.calloutNote;
    }
    if (RegExp(r'^>\s*\[!TIP\]', caseSensitive: false).hasMatch(line)) {
      return BlockKind.calloutTip;
    }
    if (RegExp(r'^>\s*\[!(?:WARNING|CAUTION)\]', caseSensitive: false).hasMatch(line)) {
      return BlockKind.calloutWarning;
    }
    if (line.startsWith('### ')) return BlockKind.h3;
    if (line.startsWith('## ')) return BlockKind.h2;
    if (line.startsWith('# ')) return BlockKind.h1;
    if (RegExp(r'^(?:[-*+]\s+)?\[[ xX]\]').hasMatch(line)) return BlockKind.todo;
    if (RegExp(r'^\d+[\.\)]\s+').hasMatch(line)) return BlockKind.numbered;
    if (RegExp(r'^[-*+•]\s+').hasMatch(line)) return BlockKind.bullet;
    if (RegExp(r'^>\s*▸').hasMatch(line)) return BlockKind.toggle;
    if (line.startsWith('>')) return BlockKind.quote;

    return BlockKind.paragraph;
  }

  /// Converts the current line (or all selected lines) into [targetKind].
  static TextEditingValue turnInto(TextEditingValue value, BlockKind targetKind) {
    final text = value.text;
    final sel = value.selection;
    final int selStart = sel.isValid ? sel.start.clamp(0, text.length) : text.length;
    final int selEnd = sel.isValid ? sel.end.clamp(0, text.length) : text.length;

    final firstLineBounds = _lineBoundsAt(text, selStart);
    final lastLineBounds = _lineBoundsAt(text, selEnd);

    final blockSlice = text.substring(firstLineBounds.start, lastLineBounds.end);
    final rawLines = blockSlice.split('\n');

    final transformedLines = <String>[];
    for (int i = 0; i < rawLines.length; i++) {
      final rawLine = rawLines[i];
      final stripped = _stripExistingPrefix(rawLine);
      final indent = stripped.indent;
      final body = stripped.body;

      switch (targetKind) {
        case BlockKind.paragraph:
          transformedLines.add('$indent$body');
          break;
        case BlockKind.h1:
          transformedLines.add('# $body');
          break;
        case BlockKind.h2:
          transformedLines.add('## $body');
          break;
        case BlockKind.h3:
          transformedLines.add('### $body');
          break;
        case BlockKind.todo:
          transformedLines.add('$indent- [ ] $body');
          break;
        case BlockKind.bullet:
          transformedLines.add('$indent- $body');
          break;
        case BlockKind.numbered:
          transformedLines.add('$indent${i + 1}. $body');
          break;
        case BlockKind.quote:
          transformedLines.add('> $body');
          break;
        case BlockKind.toggle:
          if (i == 0) {
            transformedLines.add(
              body.isEmpty ? '>▸ Toggle title\n> ' : '>▸ $body\n> ',
            );
          } else {
            transformedLines.add('> $body');
          }
          break;
        case BlockKind.calloutNote:
          if (i == 0) {
            transformedLines.add(body.isEmpty ? '> [!NOTE]\n> ' : '> [!NOTE]\n> $body');
          } else {
            transformedLines.add('> $body');
          }
          break;
        case BlockKind.calloutTip:
          if (i == 0) {
            transformedLines.add(body.isEmpty ? '> [!TIP]\n> ' : '> [!TIP]\n> $body');
          } else {
            transformedLines.add('> $body');
          }
          break;
        case BlockKind.calloutWarning:
          if (i == 0) {
            transformedLines.add(body.isEmpty ? '> [!WARNING]\n> ' : '> [!WARNING]\n> $body');
          } else {
            transformedLines.add('> $body');
          }
          break;
      }
    }

    final replacement = transformedLines.join('\n');
    final newText = text.replaceRange(firstLineBounds.start, lastLineBounds.end, replacement);
    final newCursor = (firstLineBounds.start + replacement.length).clamp(0, newText.length);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  /// Moves the current line/block one line up.
  static TextEditingValue moveBlockUp(TextEditingValue value) {
    final text = value.text;
    if (text.isEmpty) return value;
    final cursor = value.selection.isValid ? value.selection.baseOffset.clamp(0, text.length) : text.length;

    final lines = text.split('\n');
    final lineIdx = _lineIndexAt(text, cursor);
    if (lineIdx <= 0 || lineIdx >= lines.length) return value;

    final colInLine = cursor - _lineStartForIndex(lines, lineIdx);

    final temp = lines[lineIdx - 1];
    lines[lineIdx - 1] = lines[lineIdx];
    lines[lineIdx] = temp;

    final newText = lines.join('\n');
    final newLineStart = _lineStartForIndex(lines, lineIdx - 1);
    final newCursor = (newLineStart + colInLine.clamp(0, lines[lineIdx - 1].length)).clamp(0, newText.length);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  /// Moves the current line/block one line down.
  static TextEditingValue moveBlockDown(TextEditingValue value) {
    final text = value.text;
    if (text.isEmpty) return value;
    final cursor = value.selection.isValid ? value.selection.baseOffset.clamp(0, text.length) : text.length;

    final lines = text.split('\n');
    final lineIdx = _lineIndexAt(text, cursor);
    if (lineIdx < 0 || lineIdx >= lines.length - 1) return value;

    final colInLine = cursor - _lineStartForIndex(lines, lineIdx);

    final temp = lines[lineIdx + 1];
    lines[lineIdx + 1] = lines[lineIdx];
    lines[lineIdx] = temp;

    final newText = lines.join('\n');
    final newLineStart = _lineStartForIndex(lines, lineIdx + 1);
    final newCursor = (newLineStart + colInLine.clamp(0, lines[lineIdx + 1].length)).clamp(0, newText.length);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  /// Duplicates the current line directly underneath itself.
  static TextEditingValue duplicateBlock(TextEditingValue value) {
    final text = value.text;
    final cursor = value.selection.isValid ? value.selection.baseOffset.clamp(0, text.length) : text.length;
    final bounds = _lineBoundsAt(text, cursor);
    final lineText = text.substring(bounds.start, bounds.end);

    final insertion = '\n$lineText';
    final newText = text.replaceRange(bounds.end, bounds.end, insertion);
    final newCursor = (bounds.end + insertion.length).clamp(0, newText.length);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  static ({String indent, String body}) _stripExistingPrefix(String rawLine) {
    final match = _prefixStripper.firstMatch(rawLine);
    if (match != null) {
      final indent = match.group(1) ?? '';
      final body = rawLine.substring(match.end);
      return (indent: indent, body: body);
    }
    final leadingMatch = RegExp(r'^(\s*)').firstMatch(rawLine);
    final indent = leadingMatch?.group(1) ?? '';
    return (indent: indent, body: rawLine.substring(indent.length));
  }

  static ({int start, int end}) _lineBoundsAt(String text, int offset) {
    final safe = offset.clamp(0, text.length);
    final before = text.substring(0, safe);
    final start = before.lastIndexOf('\n') + 1;
    final nextNewline = text.indexOf('\n', safe);
    final end = nextNewline == -1 ? text.length : nextNewline;
    return (start: start, end: end);
  }

  static int _lineIndexAt(String text, int offset) {
    final safe = offset.clamp(0, text.length);
    return '\n'.allMatches(text.substring(0, safe)).length;
  }

  static int _lineStartForIndex(List<String> lines, int targetIdx) {
    int offset = 0;
    for (int i = 0; i < targetIdx && i < lines.length; i++) {
      offset += lines[i].length + 1;
    }
    return offset;
  }
}


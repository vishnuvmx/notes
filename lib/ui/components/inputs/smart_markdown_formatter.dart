import 'package:flutter/services.dart';

/// Intelligent Markdown & List Continuation Formatter.
///
/// Features:
/// 1. **Auto-List Continuation on Enter**:
///    - Numbered lists: `1. Task` -> `2. `
///    - Checklists: `- [ ] Buy milk` -> `- [ ] `
///    - Bullet lists: `- Item` / `* Item` -> `- ` / `* `
///    - Blockquotes: `> Quote` -> `> `
/// 2. **Smart List Exit**:
///    - Pressing Enter on an empty prefix removes the prefix and exits the list cleanly.
/// 3. **Smart Selection Wrap**:
///    - Typing `*`, `_`, `` ` ``, `~`, `(`, `[`, `{`, `"`, `'` around selected text wraps it.
/// 4. **Auto-Closing Pairs**:
///    - Typing `(`, `[`, `{`, `` ` `` inserts closing pair and positions cursor in-between.
///    - Over-typing closing character steps cursor forward without duplicating.
class SmartMarkdownContinuationFormatter extends TextInputFormatter {
  const SmartMarkdownContinuationFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldSel = oldValue.selection;

    // -------------------------------------------------------------
    // 1. Smart Selection Wrap (wrap selected text in matching pairs)
    // -------------------------------------------------------------
    if (oldSel.isValid && oldSel.start != oldSel.end) {
      final selectedLen = oldSel.end - oldSel.start;
      if (newValue.text.length == oldValue.text.length - selectedLen + 1) {
        final typed = newValue.text.substring(oldSel.start, oldSel.start + 1);
        final selectedText = oldValue.text.substring(oldSel.start, oldSel.end);
        String? open;
        String? close;

        switch (typed) {
          case '(':
            open = '(';
            close = ')';
            break;
          case '[':
            open = '[';
            close = ']';
            break;
          case '{':
            open = '{';
            close = '}';
            break;
          case '"':
            open = '"';
            close = '"';
            break;
          case "'":
            open = "'";
            close = "'";
            break;
          case '`':
            open = '`';
            close = '`';
            break;
          case '*':
            open = '*';
            close = '*';
            break;
          case '_':
            open = '_';
            close = '_';
            break;
          case '~':
            open = '~';
            close = '~';
            break;
        }

        if (open != null && close != null) {
          final wrapped = '$open$selectedText$close';
          final newText = oldValue.text.replaceRange(oldSel.start, oldSel.end, wrapped);
          return TextEditingValue(
            text: newText,
            selection: TextSelection(
              baseOffset: oldSel.start + 1,
              extentOffset: oldSel.end + 1,
            ),
          );
        }
      }
    }

    // -------------------------------------------------------------
    // 2. Auto-Closing Pairs (when no text is selected)
    // -------------------------------------------------------------
    if (oldSel.isValid && oldSel.start == oldSel.end && newValue.text.length == oldValue.text.length + 1) {
      final typed = newValue.text.substring(oldSel.start, oldSel.start + 1);

      // Over-type existing closing character without duplicating
      if (oldValue.text.length > oldSel.start &&
          (typed == ')' || typed == ']' || typed == '}' || typed == '`') &&
          oldValue.text[oldSel.start] == typed) {
        return TextEditingValue(
          text: oldValue.text,
          selection: TextSelection.collapsed(offset: oldSel.start + 1),
        );
      }

      String? close;
      if (typed == '(') {
        close = ')';
      } else if (typed == '[') {
        close = ']';
      } else if (typed == '{') {
        close = '}';
      } else if (typed == '`') {
        close = '`';
      }

      if (close != null) {
        final newText = '${newValue.text.substring(0, oldSel.start + 1)}$close${newValue.text.substring(oldSel.start + 1)}';
        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: oldSel.start + 1),
        );
      }
    }

    // -------------------------------------------------------------
    // 3. Auto-List Continuation & Smart Exit on Enter
    // -------------------------------------------------------------
    if (newValue.text.length <= oldValue.text.length || !oldSel.isValid || oldSel.start != oldSel.end) {
      return newValue;
    }

    final insertOffset = oldSel.start;
    final insertedText = newValue.text.substring(
      insertOffset,
      insertOffset + (newValue.text.length - oldValue.text.length),
    );

    // Only inspect when Enter is pressed
    if (insertedText != '\n') {
      return newValue;
    }

    // Find the text of the line immediately preceding this new newline
    final textBeforeNewline = oldValue.text.substring(0, insertOffset);
    final lastNewlineIndex = textBeforeNewline.lastIndexOf('\n');
    final lineStart = lastNewlineIndex == -1 ? 0 : lastNewlineIndex + 1;
    final prevLine = textBeforeNewline.substring(lineStart);

    // A. Checklists: e.g. "   - [ ] task" or "   [ ] task" or "   - [x] task"
    final checklistMatch = RegExp(r'^(\s*)([-*+]?\s*)(\[[ xX]\]\s*)(.*)$').firstMatch(prevLine);
    if (checklistMatch != null) {
      final indent = checklistMatch.group(1)!;
      final bullet = checklistMatch.group(2)!;
      final taskContent = checklistMatch.group(4)!.trim();

      // Exit checklist if Enter was pressed on an empty item
      if (taskContent.isEmpty) {
        final newPrefix = oldValue.text.substring(0, lineStart);
        final newSuffix = oldValue.text.substring(insertOffset);
        final resultText = '$newPrefix$newSuffix';
        return TextEditingValue(
          text: resultText,
          selection: TextSelection.collapsed(offset: lineStart),
        );
      } else {
        // Auto-continue with clean unchecked box
        final continuation = '$indent${bullet.isNotEmpty ? bullet : "- "}[ ] ';
        final newText = '${newValue.text.substring(0, insertOffset + 1)}$continuation${newValue.text.substring(insertOffset + 1)}';
        final newCursor = insertOffset + 1 + continuation.length;
        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newCursor),
        );
      }
    }

    // B. Numbered lists: e.g. "   1. task" or "   12) task"
    final numberedMatch = RegExp(r'^(\s*)(\d+)([\.\)])(\s+)(.*)$').firstMatch(prevLine);
    if (numberedMatch != null) {
      final indent = numberedMatch.group(1)!;
      final numVal = int.tryParse(numberedMatch.group(2)!) ?? 1;
      final delimiter = numberedMatch.group(3)!;
      final spacing = numberedMatch.group(4)!;
      final itemContent = numberedMatch.group(5)!.trim();

      // Exit list if Enter was pressed on an empty numbered item
      if (itemContent.isEmpty) {
        final newPrefix = oldValue.text.substring(0, lineStart);
        final newSuffix = oldValue.text.substring(insertOffset);
        final resultText = '$newPrefix$newSuffix';
        return TextEditingValue(
          text: resultText,
          selection: TextSelection.collapsed(offset: lineStart),
        );
      } else {
        final nextNum = numVal + 1;
        final continuation = '$indent$nextNum$delimiter$spacing';
        final newText = '${newValue.text.substring(0, insertOffset + 1)}$continuation${newValue.text.substring(insertOffset + 1)}';
        final newCursor = insertOffset + 1 + continuation.length;
        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newCursor),
        );
      }
    }

    // C. Bullet lists: e.g. "   - task" or "   * task" or "   + task"
    final bulletMatch = RegExp(r'^(\s*)([-*+])(\s+)(.*)$').firstMatch(prevLine);
    if (bulletMatch != null) {
      final indent = bulletMatch.group(1)!;
      final bulletChar = bulletMatch.group(2)!;
      final spacing = bulletMatch.group(3)!;
      final itemContent = bulletMatch.group(4)!.trim();

      // Exit list if Enter was pressed on an empty bullet
      if (itemContent.isEmpty) {
        final newPrefix = oldValue.text.substring(0, lineStart);
        final newSuffix = oldValue.text.substring(insertOffset);
        final resultText = '$newPrefix$newSuffix';
        return TextEditingValue(
          text: resultText,
          selection: TextSelection.collapsed(offset: lineStart),
        );
      } else {
        final continuation = '$indent$bulletChar$spacing';
        final newText = '${newValue.text.substring(0, insertOffset + 1)}$continuation${newValue.text.substring(insertOffset + 1)}';
        final newCursor = insertOffset + 1 + continuation.length;
        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newCursor),
        );
      }
    }

    // D. Blockquotes & Callout Alerts: e.g. "   > quote" or "   >> quote"
    final quoteMatch = RegExp(r'^(\s*)(>{1,3})(\s*)(.*)$').firstMatch(prevLine);
    if (quoteMatch != null) {
      final indent = quoteMatch.group(1)!;
      final arrows = quoteMatch.group(2)!;
      final content = quoteMatch.group(4)!.trim();

      // Exit quote if Enter was pressed on an empty quote line
      if (content.isEmpty) {
        final newPrefix = oldValue.text.substring(0, lineStart);
        final newSuffix = oldValue.text.substring(insertOffset);
        final resultText = '$newPrefix$newSuffix';
        return TextEditingValue(
          text: resultText,
          selection: TextSelection.collapsed(offset: lineStart),
        );
      } else {
        final continuation = '$indent$arrows ';
        final newText = '${newValue.text.substring(0, insertOffset + 1)}$continuation${newValue.text.substring(insertOffset + 1)}';
        final newCursor = insertOffset + 1 + continuation.length;
        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newCursor),
        );
      }
    }

    return newValue;
  }
}

import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_math_fork/tex.dart';

/// Parsed inline LaTeX math match (`$...$` or inline `$$...$$`).
class ParsedInlineMath {
  final String expression;
  final String rawSource;
  final bool isDisplay;
  final int endIndex;

  const ParsedInlineMath({
    required this.expression,
    required this.rawSource,
    required this.isDisplay,
    required this.endIndex,
  });
}

/// Parsed standalone block LaTeX math match (`$$...$$`).
class ParsedBlockMath {
  final String expression;
  final String rawSource;
  final int nextLineIndex;

  const ParsedBlockMath({
    required this.expression,
    required this.rawSource,
    required this.nextLineIndex,
  });
}

/// Pure-Dart LaTeX block/inline scanner and syntax validator for Markdown preview.
///
/// Detection follows standard Markdown + Obsidian + Pandoc delimiter rules:
/// - Block equations (`$$...$$`) support both single-line (`$$E = mc^2$$`) and
///   multi-line (`$$\n...\n$$`) syntax.
/// - Inline equations (`$...$`) avoid false positives on currency strings such as
///   `"$5 and $10"`, `"$5-$10"`, escaped `\$`, and whitespace-padded `$ x $`.
class LatexMathService {
  LatexMathService._();

  /// Returns `true` if the character at [index] is escaped by an odd number of
  /// immediately preceding backslashes (`\`).
  static bool isEscapedAt(String text, int index) {
    int backslashes = 0;
    int cursor = index - 1;
    while (cursor >= 0 && text.codeUnitAt(cursor) == 92) {
      backslashes++;
      cursor--;
    }
    return backslashes.isOdd;
  }

  /// Validates a LaTeX math [expression] with [TexParser].
  /// Returns `null` when valid, or a human-readable error message when invalid.
  static String? validate(String expression) {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) return 'Empty LaTeX expression';
    try {
      TexParser(trimmed, const TexParserSettings()).parse();
      return null;
    } on ParseException catch (e) {
      return e.message;
    } on Object catch (e) {
      return e.toString();
    }
  }

  /// Parses [expression] into a [SyntaxTree], returning any [ParseException].
  static ({SyntaxTree? ast, ParseException? error}) parseTex(String expression) {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) {
      return (ast: null, error: ParseException('Empty LaTeX expression'));
    }
    try {
      final greenRoot = TexParser(trimmed, const TexParserSettings()).parse();
      return (ast: SyntaxTree(greenRoot: greenRoot), error: null);
    } on ParseException catch (e) {
      return (ast: null, error: e);
    } on Object catch (e) {
      return (ast: null, error: ParseException(e.toString()));
    }
  }

  /// Attempts to consume a standalone block math equation (`$$...$$`) starting at
  /// [startIndex] in [lines]. Returns `null` if line [startIndex] does not open a
  /// standalone block math region or lacks a closing `$$`.
  static ParsedBlockMath? tryConsumeBlockMath(
    List<String> lines,
    int startIndex,
  ) {
    if (startIndex < 0 || startIndex >= lines.length) return null;

    final firstLine = lines[startIndex];
    final trimmed = firstLine.trim();
    if (!trimmed.startsWith(r'$$')) return null;

    // Single-line form: $$ ... $$ with no stray unescaped $$ before the end.
    final sameLineClose = _findUnescapedDoubleDollar(trimmed, 2);
    if (sameLineClose != -1) {
      if (sameLineClose != trimmed.length - 2) {
        // Contains extra content or multiple $$...$$ spans on one line; let inline parser handle it.
        return null;
      }
      final expression = trimmed.substring(2, sameLineClose).trim();
      if (expression.isEmpty) return null;
      return ParsedBlockMath(
        expression: expression,
        rawSource: firstLine,
        nextLineIndex: startIndex + 1,
      );
    }

    // Multi-line form: scan forward until a line closes with unescaped $$.
    for (int j = startIndex + 1; j < lines.length; j++) {
      final candidate = lines[j];
      final closePos = _findUnescapedDoubleDollar(candidate, 0);
      if (closePos == -1) continue;

      // Require only trailing whitespace after closing $$.
      if (candidate.substring(closePos + 2).trim().isNotEmpty) {
        return null;
      }

      final exprLines = <String>[];
      final firstTail = trimmed.substring(2);
      if (firstTail.trim().isNotEmpty) {
        exprLines.add(firstTail);
      }
      for (int k = startIndex + 1; k < j; k++) {
        exprLines.add(lines[k]);
      }
      final lastHead = candidate.substring(0, closePos);
      if (lastHead.trim().isNotEmpty) {
        exprLines.add(lastHead);
      }

      final expression = exprLines.join('\n').trim();
      if (expression.isEmpty) return null;

      return ParsedBlockMath(
        expression: expression,
        rawSource: lines.sublist(startIndex, j + 1).join('\n'),
        nextLineIndex: j + 1,
      );
    }

    return null;
  }

  /// Attempts to match an inline equation (`$...$` or inline `$$...$$`) at
  /// [startIndex] inside [text]. Returns `null` if [startIndex] does not open a
  /// valid inline equation.
  static ParsedInlineMath? tryMatchInlineMath(String text, int startIndex) {
    if (startIndex < 0 || startIndex >= text.length) return null;
    if (text.codeUnitAt(startIndex) != 36) return null; // '$'
    if (isEscapedAt(text, startIndex)) return null;

    // Inline display-style equation: $$...$$ on a single line.
    if (text.startsWith(r'$$', startIndex)) {
      int k = startIndex + 2;
      while (k <= text.length - 2) {
        final ch = text.codeUnitAt(k);
        if (ch == 10 || ch == 13) return null;
        if (text.startsWith(r'$$', k) && !isEscapedAt(text, k)) {
          final expression = text.substring(startIndex + 2, k).trim();
          if (expression.isEmpty) return null;
          return ParsedInlineMath(
            expression: expression,
            rawSource: text.substring(startIndex, k + 2),
            isDisplay: true,
            endIndex: k + 2,
          );
        }
        k++;
      }
      return null;
    }

    // Single-dollar inline math: $...$
    if (startIndex + 1 >= text.length) return null;
    if (_isHorizontalWhitespace(text.codeUnitAt(startIndex + 1))) {
      return null;
    }

    int k = startIndex + 1;
    while (k < text.length) {
      final ch = text.codeUnitAt(k);
      if (ch == 10 || ch == 13) return null;

      if (ch == 36 && !isEscapedAt(text, k)) {
        if (text.startsWith(r'$$', k)) {
          return null;
        }
        final prevIsSpace = _isHorizontalWhitespace(text.codeUnitAt(k - 1));
        final nextIsDigit =
            k + 1 < text.length && _isAsciiDigit(text.codeUnitAt(k + 1));
        if (prevIsSpace || nextIsDigit) {
          // Do not scan past an unescaped '$' delimiter that fails closing rules
          // (e.g. "$5 and $10, plus $x^2$").
          return null;
        }
        final expression = text.substring(startIndex + 1, k).trim();
        if (expression.isEmpty) return null;
        return ParsedInlineMath(
          expression: expression,
          rawSource: text.substring(startIndex, k + 1),
          isDisplay: false,
          endIndex: k + 1,
        );
      }
      k++;
    }

    return null;
  }

  static int _findUnescapedDoubleDollar(String text, int fromIndex) {
    int i = fromIndex;
    while (i <= text.length - 2) {
      if (text.startsWith(r'$$', i) && !isEscapedAt(text, i)) {
        return i;
      }
      i++;
    }
    return -1;
  }

  static bool _isHorizontalWhitespace(int codeUnit) =>
      codeUnit == 32 || codeUnit == 9;

  static bool _isAsciiDigit(int codeUnit) =>
      codeUnit >= 48 && codeUnit <= 57;
}

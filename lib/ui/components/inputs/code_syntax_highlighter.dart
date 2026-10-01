import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Prettier-style modern code syntax highlighter with JetBrains Mono font support.
class CodeSyntaxHighlighter {
  CodeSyntaxHighlighter._();

  // Tokenizing Regex:
  // 1: Comments (//, /* */, #)
  // 2: Strings ("...", '...', `...`)
  // 3: Annotations/decorators (@...)
  // 4: Keywords
  // 5: Types & built-in classes
  // 6: Numbers & booleans
  // 7: Function calls (identifier followed by '(')
  // 8: Operators & symbols
  static final RegExp _lexer = RegExp(
    r'(//[^\n]*|/\*[\s\S]*?\*/|#[^\n]*)'
    r'|("(?:\\.|[^"\\])*"|' r"'(?:\\.|[^'\\])*'|" r'`(?:\\.|[^`\\])*`)'
    r'|(@[a-zA-Z_][a-zA-Z0-9_]*)'
    r'|(\b(?:abstract|as|assert|async|await|break|case|catch|class|const|continue|covariant|debugger|default|def|defer|deferred|delete|do|dynamic|echo|else|enum|export|extends|extension|external|factory|fallthrough|false|final|finally|fn|for|from|function|func|get|goto|guard|hide|if|implements|import|in|inline|instanceof|interface|is|lambda|late|let|match|mixin|module|mut|native|new|nil|none|null|of|on|operator|package|part|pass|print|private|protected|pub|public|readonly|ref|rethrow|return|select|self|set|show|sizeof|static|struct|super|switch|sync|then|this|throw|true|try|type|typedef|typeof|union|unsafe|use|val|var|void|volatile|where|while|with|yield)\b)'
    r'|(\b(?:bool|boolean|byte|char|double|float|int|integer|long|num|short|void|String|List|Map|Set|Future|Stream|Widget|BuildContext|State|Object|dynamic|Iterable|Symbol|Duration|DateTime|Uri|RegExp|Promise|Array|Record|Any|Number|Dict|Tuple|Option|Result|Vec)\b|\b[A-Z][a-zA-Z0-9_]*\b)'
    r'|(\b0x[0-9a-fA-F]+\b|\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b)'
    r'|(\b[a-zA-Z_][a-zA-Z0-9_]*(?=\s*\())'
    r'|(=>|->|===|!==|==|!=|<=|>=|&&|\|\||\?\?|\+\+|--|[+\-*/%=<>!&|^~?:])',
  );

  /// Highlights a code string into a list of [TextSpan]s with JetBrains Mono typography.
  static List<TextSpan> highlight(
    String code, {
    required bool isDark,
    TextStyle? baseStyle,
  }) {
    final style = baseStyle ??
        GoogleFonts.jetBrainsMono(
          fontSize: 12.5,
          height: 1.52,
          letterSpacing: -0.1,
          color: isDark ? const Color(0xFFABB2BF) : const Color(0xFF2E3440),
        );

    if (code.isEmpty) {
      return [TextSpan(text: '', style: style)];
    }

    final spans = <TextSpan>[];

    // Prettier / OneDark Color Tokens
    final commentStyle = style.copyWith(
      color: isDark ? const Color(0xFF7E8494) : const Color(0xFF8C93A4),
      fontStyle: FontStyle.italic,
    );
    final stringStyle = style.copyWith(
      color: isDark ? const Color(0xFF98C379) : const Color(0xFF439446),
    );
    final annotationStyle = style.copyWith(
      color: isDark ? const Color(0xFFE5C07B) : const Color(0xFFB57D05),
      fontWeight: FontWeight.w600,
    );
    final keywordStyle = style.copyWith(
      color: isDark ? const Color(0xFFC678DD) : const Color(0xFFA626A4),
      fontWeight: FontWeight.w700,
    );
    final typeStyle = style.copyWith(
      color: isDark ? const Color(0xFFE5C07B) : const Color(0xFFC18401),
      fontWeight: FontWeight.w600,
    );
    final numberStyle = style.copyWith(
      color: isDark ? const Color(0xFFD19A66) : const Color(0xFFB26200),
      fontWeight: FontWeight.w600,
    );
    final functionStyle = style.copyWith(
      color: isDark ? const Color(0xFF61AFEF) : const Color(0xFF3271D8),
      fontWeight: FontWeight.w600,
    );
    final operatorStyle = style.copyWith(
      color: isDark ? const Color(0xFF56B6C2) : const Color(0xFF06839C),
    );

    int lastIndex = 0;
    for (final match in _lexer.allMatches(code)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: code.substring(lastIndex, match.start),
          style: style,
        ));
      }

      if (match.group(1) != null) {
        // Comment
        spans.add(TextSpan(text: match.group(1), style: commentStyle));
      } else if (match.group(2) != null) {
        // String
        spans.add(TextSpan(text: match.group(2), style: stringStyle));
      } else if (match.group(3) != null) {
        // Annotation
        spans.add(TextSpan(text: match.group(3), style: annotationStyle));
      } else if (match.group(4) != null) {
        // Keyword
        final kw = match.group(4)!;
        if (kw == 'true' || kw == 'false' || kw == 'null' || kw == 'nil' || kw == 'none') {
          spans.add(TextSpan(text: kw, style: numberStyle));
        } else {
          spans.add(TextSpan(text: kw, style: keywordStyle));
        }
      } else if (match.group(5) != null) {
        // Type / Class
        spans.add(TextSpan(text: match.group(5), style: typeStyle));
      } else if (match.group(6) != null) {
        // Number
        spans.add(TextSpan(text: match.group(6), style: numberStyle));
      } else if (match.group(7) != null) {
        // Function call
        spans.add(TextSpan(text: match.group(7), style: functionStyle));
      } else if (match.group(8) != null) {
        // Operator
        spans.add(TextSpan(text: match.group(8), style: operatorStyle));
      } else {
        spans.add(TextSpan(text: match.group(0), style: style));
      }

      lastIndex = match.end;
    }

    if (lastIndex < code.length) {
      spans.add(TextSpan(
        text: code.substring(lastIndex),
        style: style,
      ));
    }

    return spans;
  }
}

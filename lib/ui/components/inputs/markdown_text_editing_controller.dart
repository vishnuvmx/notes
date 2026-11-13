import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'code_syntax_highlighter.dart';

/// Syntax-highlighted text controller that renders bold, italic, strikethrough,
/// underline, highlights, and tags inside any editor or input TextField.
class MarkdownTextEditingController extends TextEditingController {
  String? _paletteId;

  MarkdownTextEditingController({super.text, String? paletteId}) {
    _paletteId = paletteId;
  }

  String? get paletteId => _paletteId;
  set paletteId(String? val) {
    if (_paletteId != val) {
      _paletteId = val;
      notifyListeners();
    }
  }

  static final RegExp _fenceRegex = RegExp(r'```[\s\S]*?```|```[^\n]*');
  static final RegExp _wikiRegex = RegExp(r'!?\[\[[^\[\]\n]+\]\]');
  static final RegExp _imgRegex = RegExp(r'!\[[^\]\n]*\]\([^)\n]+\)');
  static final RegExp _footnoteRefRegex = RegExp(r'\[\^[^\[\]\s\n]+\](?!:)');
  static final RegExp _htmlTagRegex = RegExp(
    r'(<(sup|sub|u)>)(.*?)(<\/\2>)',
    caseSensitive: false,
  );
  static final RegExp _hashRegex = RegExp(r'#[a-zA-Z0-9_-]+');
  static final RegExp _wordCharRegex = RegExp(r'[A-Za-z0-9_]');
  static final RegExp _lineFootnoteDefRegex =
      RegExp(r'^(\s*)(\[\^[^\[\]\s\n]+\]:)(.*)$');
  static final RegExp _lineDefMarkerRegex = RegExp(r'^(\s{0,3}:)(\s+.*)$');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = AppColors.getPaletteById(_paletteId);
    final text = this.text;
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final spans = <TextSpan>[];
    final delimiterStyle = style?.copyWith(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.28),
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.normal,
      decoration: TextDecoration.none,
    );

    int lastMatchEnd = 0;
    for (final match in _fenceRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        _appendBlockAndInlineSpans(
          text.substring(lastMatchEnd, match.start),
          style,
          delimiterStyle,
          palette,
          isDark,
          spans,
        );
      }

      final matchedText = match.group(0)!;
      if (matchedText.endsWith('```') && matchedText.length >= 6) {
        final firstNewline = matchedText.indexOf('\n');
        final lastFence = matchedText.lastIndexOf('```');
        if (firstNewline != -1 && firstNewline < lastFence) {
          final header = matchedText.substring(0, firstNewline + 1);
          final fenceLang = header.replaceFirst('```', '').trim();
          final innerCode = matchedText.substring(firstNewline + 1, lastFence);
          final closing = matchedText.substring(lastFence);

          spans.add(TextSpan(
            text: header,
            style: GoogleFonts.jetBrainsMono(
              textStyle: style,
              fontWeight: FontWeight.w700,
              color: palette.resolveCodeAccent(isDark),
            ),
          ));
          spans.addAll(CodeSyntaxHighlighter.highlight(
            innerCode,
            isDark: isDark,
            language: fenceLang,
            baseStyle: GoogleFonts.jetBrainsMono(
              textStyle: style,
              fontSize: (style?.fontSize ?? 14) * 0.92,
              color: isDark ? const Color(0xFFABB2BF) : const Color(0xFF2E3440),
            ),
          ));
          spans.add(TextSpan(
            text: closing,
            style: GoogleFonts.jetBrainsMono(
              textStyle: style,
              fontWeight: FontWeight.w700,
              color: palette.resolveCodeAccent(isDark),
            ),
          ));
        } else {
          spans.add(TextSpan(
            text: matchedText,
            style: GoogleFonts.jetBrainsMono(
              textStyle: style,
              fontWeight: FontWeight.w700,
              color: palette.resolveCodeAccent(isDark),
            ),
          ));
        }
      } else {
        spans.add(TextSpan(
          text: matchedText,
          style: GoogleFonts.jetBrainsMono(
            textStyle: style,
            fontWeight: FontWeight.w700,
            color: palette.resolveCodeAccent(isDark),
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      _appendBlockAndInlineSpans(
        text.substring(lastMatchEnd),
        style,
        delimiterStyle,
        palette,
        isDark,
        spans,
      );
    }

    return TextSpan(children: spans, style: style);
  }

  void _appendBlockAndInlineSpans(
    String chunk,
    TextStyle? baseStyle,
    TextStyle? delimiterStyle,
    TackColorPalette palette,
    bool isDark,
    List<TextSpan> out,
  ) {
    int lineStart = 0;
    while (lineStart < chunk.length) {
      final nl = chunk.indexOf('\n', lineStart);
      final lineEnd = nl == -1 ? chunk.length : nl;
      final line = chunk.substring(lineStart, lineEnd);

      final fnDef = _lineFootnoteDefRegex.firstMatch(line);
      if (fnDef != null) {
        final leading = fnDef.group(1)!;
        final token = fnDef.group(2)!;
        final rest = fnDef.group(3)!;
        if (leading.isNotEmpty) {
          out.add(TextSpan(text: leading, style: baseStyle));
        }
        out.add(TextSpan(
          text: token,
          style: baseStyle?.copyWith(
            color: palette.resolveAccentColor(isDark),
            fontWeight: FontWeight.w700,
            backgroundColor: palette
                .resolveAccentColor(isDark)
                .withValues(alpha: isDark ? 0.16 : 0.10),
          ),
        ));
        if (rest.isNotEmpty) {
          _appendInlineSpans(
            rest,
            baseStyle,
            delimiterStyle,
            palette,
            isDark,
            out,
          );
        }
      } else {
        final defMarker = _lineDefMarkerRegex.firstMatch(line);
        if (defMarker != null) {
          final marker = defMarker.group(1)!;
          final rest = defMarker.group(2)!;
          out.add(TextSpan(
            text: marker,
            style: baseStyle?.copyWith(
              color: palette.resolveAccentColor(isDark),
              fontWeight: FontWeight.w800,
            ),
          ));
          _appendInlineSpans(
            rest,
            baseStyle,
            delimiterStyle,
            palette,
            isDark,
            out,
          );
        } else if (line.isNotEmpty) {
          _appendInlineSpans(
            line,
            baseStyle,
            delimiterStyle,
            palette,
            isDark,
            out,
          );
        }
      }

      if (nl != -1) {
        out.add(TextSpan(text: '\n', style: baseStyle));
        lineStart = nl + 1;
      } else {
        break;
      }
    }
  }

  void _appendInlineSpans(
    String text,
    TextStyle? currentStyle,
    TextStyle? delimiterStyle,
    TackColorPalette palette,
    bool isDark,
    List<TextSpan> out, {
    int depth = 0,
  }) {
    if (text.isEmpty) return;
    if (depth >= 8) {
      out.add(TextSpan(text: text, style: currentStyle));
      return;
    }

    final buffer = StringBuffer();
    void flush() {
      if (buffer.isNotEmpty) {
        out.add(TextSpan(text: buffer.toString(), style: currentStyle));
        buffer.clear();
      }
    }

    int i = 0;
    while (i < text.length) {
      final codeUnit = text.codeUnitAt(i);

      // 1. Inline code: `code` (atomic)
      if (codeUnit == 96) {
        final closeIdx = text.indexOf('`', i + 1);
        if (closeIdx > i + 1) {
          flush();
          out.add(TextSpan(text: '`', style: delimiterStyle));
          out.add(TextSpan(
            text: text.substring(i + 1, closeIdx),
            style: GoogleFonts.jetBrainsMono(
              textStyle: currentStyle,
              fontSize: (currentStyle?.fontSize ?? 14) * 0.92,
              fontWeight: currentStyle?.fontWeight == FontWeight.bold ||
                      currentStyle?.fontWeight == FontWeight.w800
                  ? FontWeight.w700
                  : FontWeight.w600,
              fontStyle: currentStyle?.fontStyle,
              decoration: currentStyle?.decoration,
              backgroundColor: palette.resolveInlineCodeBg(isDark),
              color: palette.resolveInlineCodeText(isDark),
            ),
          ));
          out.add(TextSpan(text: '`', style: delimiterStyle));
          i = closeIdx + 1;
          continue;
        }
      }

      // 2. Wiki link / embed
      if (text.startsWith('[[', i) || text.startsWith('![[', i)) {
        final m = _wikiRegex.matchAsPrefix(text, i);
        if (m != null) {
          flush();
          final matched = m.group(0)!;
          final openLen = matched.startsWith('![[') ? 3 : 2;
          out.add(TextSpan(text: matched.substring(0, openLen), style: delimiterStyle));
          out.add(TextSpan(
            text: matched.substring(openLen, matched.length - 2),
            style: currentStyle?.copyWith(
              color: palette.resolveAccentColor(isDark),
              fontWeight: FontWeight.w700,
              backgroundColor: palette
                  .resolveAccentColor(isDark)
                  .withValues(alpha: isDark ? 0.14 : 0.10),
            ),
          ));
          out.add(TextSpan(text: ']]', style: delimiterStyle));
          i = m.end;
          continue;
        }
      }

      // 3. Inline image ![alt](url)
      if (text.startsWith('![', i)) {
        final m = _imgRegex.matchAsPrefix(text, i);
        if (m != null) {
          flush();
          final matched = m.group(0)!;
          final midIndex = matched.indexOf('](');
          final altText = matched.substring(2, midIndex);
          final urlText = matched.substring(midIndex + 2, matched.length - 1);
          out.add(TextSpan(text: '![', style: delimiterStyle));
          out.add(TextSpan(
            text: altText,
            style: currentStyle?.copyWith(
              color: isDark ? AppColors.pastelLimeLight : AppColors.pastelLimeDark,
              fontStyle: FontStyle.italic,
            ),
          ));
          out.add(TextSpan(text: '](', style: delimiterStyle));
          out.add(TextSpan(
            text: urlText,
            style: currentStyle?.copyWith(
              color: delimiterStyle?.color,
              fontSize: (currentStyle.fontSize ?? 14) * 0.9,
            ),
          ));
          out.add(TextSpan(text: ')', style: delimiterStyle));
          i = m.end;
          continue;
        }
      }

      // 4. Footnote reference [^id]
      if (text.startsWith('[^', i)) {
        final fn = _footnoteRefRegex.matchAsPrefix(text, i);
        if (fn != null &&
            (fn.end >= text.length || text.codeUnitAt(fn.end) != 40)) {
          flush();
          final matched = fn.group(0)!;
          final id = matched.substring(2, matched.length - 1);
          final accent = palette.resolveAccentColor(isDark);
          final fnBg = accent.withValues(alpha: isDark ? 0.16 : 0.10);
          out.add(TextSpan(text: '[^', style: delimiterStyle?.copyWith(backgroundColor: fnBg)));
          out.add(TextSpan(
            text: id,
            style: currentStyle?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: (currentStyle.fontSize ?? 14) * 0.86,
              backgroundColor: fnBg,
            ),
          ));
          out.add(TextSpan(text: ']', style: delimiterStyle?.copyWith(backgroundColor: fnBg)));
          i = fn.end;
          continue;
        }
      }

      // 5. Markdown link [label](url) with recursive label formatting
      if (codeUnit == 91) {
        final link = _tryMatchMarkdownLink(text, i);
        if (link != null) {
          flush();
          final accent = palette.resolveAccentColor(isDark);
          final linkStyle = _mergeStyle(
            currentStyle,
            fontWeight: FontWeight.w600,
            addDecoration: TextDecoration.underline,
            color: accent,
          );
          out.add(TextSpan(text: '[', style: delimiterStyle));
          _appendInlineSpans(
            link.label,
            linkStyle,
            delimiterStyle,
            palette,
            isDark,
            out,
            depth: depth + 1,
          );
          out.add(TextSpan(text: '](', style: delimiterStyle));
          out.add(TextSpan(
            text: link.url,
            style: currentStyle?.copyWith(
              color: delimiterStyle?.color,
              fontSize: (currentStyle.fontSize ?? 14) * 0.9,
            ),
          ));
          out.add(TextSpan(text: ')', style: delimiterStyle));
          i = link.endIndex;
          continue;
        }
      }

      // 6. HTML tags <sup>, <sub>, <u>
      if (codeUnit == 60) {
        final m = _htmlTagRegex.matchAsPrefix(text, i);
        if (m != null) {
          final openTag = m.group(1)!;
          final tag = m.group(2)!.toLowerCase();
          final inner = m.group(3)!;
          final closeTag = m.group(4)!;
          if (inner.isNotEmpty) {
            flush();
            out.add(TextSpan(text: openTag, style: delimiterStyle));
            if (tag == 'u') {
              _appendInlineSpans(
                inner,
                _mergeStyle(currentStyle, addDecoration: TextDecoration.underline),
                delimiterStyle,
                palette,
                isDark,
                out,
                depth: depth + 1,
              );
            } else {
              final scriptStyle = currentStyle?.copyWith(
                fontSize: (currentStyle.fontSize ?? 14) * 0.84,
                color: palette.resolveAccentColor(isDark),
              );
              _appendInlineSpans(
                inner,
                scriptStyle,
                delimiterStyle,
                palette,
                isDark,
                out,
                depth: depth + 1,
              );
            }
            out.add(TextSpan(text: closeTag, style: delimiterStyle));
            i = m.end;
            continue;
          }
        }
      }

      // 7. Highlight ==...==
      if (text.startsWith('==', i) && !_isWhitespace(text, i + 2)) {
        final endIdx = _findClosingMarker(text, i + 2, '==');
        if (endIdx > i + 2) {
          flush();
          final innerText = text.substring(i + 2, endIdx);
          final colonIdx = innerText.indexOf(':');
          Color highlightBg = AppColors.getHighlightColor(_paletteId, isDark: isDark);
          if (colonIdx > 0 && colonIdx < 15) {
            final prefix = innerText.substring(0, colonIdx).toLowerCase();
            if (AppColors.presetPalettes.any((p) => p.id == prefix)) {
              highlightBg = AppColors.getHighlightColor(prefix, isDark: isDark);
            }
          }
          out.add(TextSpan(text: '==', style: delimiterStyle));
          _appendInlineSpans(
            innerText,
            _mergeStyle(
              currentStyle,
              fontWeight: currentStyle?.fontWeight ?? FontWeight.w600,
              backgroundColor: highlightBg,
            ),
            delimiterStyle,
            palette,
            isDark,
            out,
            depth: depth + 1,
          );
          out.add(TextSpan(text: '==', style: delimiterStyle));
          i = endIdx + 2;
          continue;
        }
      }

      // 8a. Bold + Italic ***...***
      if (text.startsWith('***', i) && !_isWhitespace(text, i + 3)) {
        final endIdx = _findClosingMarker(text, i + 3, '***');
        if (endIdx > i + 3) {
          flush();
          out.add(TextSpan(text: '***', style: delimiterStyle));
          _appendInlineSpans(
            text.substring(i + 3, endIdx),
            _mergeStyle(
              currentStyle,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
            delimiterStyle,
            palette,
            isDark,
            out,
            depth: depth + 1,
          );
          out.add(TextSpan(text: '***', style: delimiterStyle));
          i = endIdx + 3;
          continue;
        }
      }

      // 8b. Underline + Italic ___...___
      if (text.startsWith('___', i) &&
          _canOpenUnderscore(text, i) &&
          !_isWhitespace(text, i + 3)) {
        final endIdx = _findClosingMarker(
          text,
          i + 3,
          '___',
          requireUnderscoreBoundary: true,
        );
        if (endIdx > i + 3) {
          flush();
          out.add(TextSpan(text: '___', style: delimiterStyle));
          _appendInlineSpans(
            text.substring(i + 3, endIdx),
            _mergeStyle(
              currentStyle,
              fontStyle: FontStyle.italic,
              addDecoration: TextDecoration.underline,
            ),
            delimiterStyle,
            palette,
            isDark,
            out,
            depth: depth + 1,
          );
          out.add(TextSpan(text: '___', style: delimiterStyle));
          i = endIdx + 3;
          continue;
        }
      }

      // 8c. Bold **...**
      if (text.startsWith('**', i) &&
          !text.startsWith('***', i) &&
          !_isWhitespace(text, i + 2)) {
        final endIdx = _findClosingMarker(
          text,
          i + 2,
          '**',
          allowNestedSingleStar: true,
        );
        if (endIdx > i + 2) {
          flush();
          out.add(TextSpan(text: '**', style: delimiterStyle));
          _appendInlineSpans(
            text.substring(i + 2, endIdx),
            _mergeStyle(currentStyle, fontWeight: FontWeight.bold),
            delimiterStyle,
            palette,
            isDark,
            out,
            depth: depth + 1,
          );
          out.add(TextSpan(text: '**', style: delimiterStyle));
          i = endIdx + 2;
          continue;
        }
      }

      // 8d. Underline __...__
      if (text.startsWith('__', i) &&
          !text.startsWith('___', i) &&
          _canOpenUnderscore(text, i) &&
          !_isWhitespace(text, i + 2)) {
        final endIdx = _findClosingMarker(
          text,
          i + 2,
          '__',
          requireUnderscoreBoundary: true,
        );
        if (endIdx > i + 2) {
          flush();
          out.add(TextSpan(text: '__', style: delimiterStyle));
          _appendInlineSpans(
            text.substring(i + 2, endIdx),
            _mergeStyle(currentStyle, addDecoration: TextDecoration.underline),
            delimiterStyle,
            palette,
            isDark,
            out,
            depth: depth + 1,
          );
          out.add(TextSpan(text: '__', style: delimiterStyle));
          i = endIdx + 2;
          continue;
        }
      }

      // 8e. Strikethrough ~~...~~
      if (text.startsWith('~~', i) && !_isWhitespace(text, i + 2)) {
        final endIdx = _findClosingMarker(text, i + 2, '~~');
        if (endIdx > i + 2) {
          flush();
          out.add(TextSpan(text: '~~', style: delimiterStyle));
          _appendInlineSpans(
            text.substring(i + 2, endIdx),
            _mergeStyle(currentStyle, addDecoration: TextDecoration.lineThrough),
            delimiterStyle,
            palette,
            isDark,
            out,
            depth: depth + 1,
          );
          out.add(TextSpan(text: '~~', style: delimiterStyle));
          i = endIdx + 2;
          continue;
        }
      }

      // 8f. Italic *...*
      if (codeUnit == 42 &&
          (!text.startsWith('**', i) || text.startsWith('***', i)) &&
          !_isWhitespace(text, i + 1)) {
        final endIdx = _findClosingMarker(
          text,
          i + 1,
          '*',
          allowNestedMarker: '**',
        );
        if (endIdx > i + 1) {
          flush();
          out.add(TextSpan(text: '*', style: delimiterStyle));
          _appendInlineSpans(
            text.substring(i + 1, endIdx),
            _mergeStyle(currentStyle, fontStyle: FontStyle.italic),
            delimiterStyle,
            palette,
            isDark,
            out,
            depth: depth + 1,
          );
          out.add(TextSpan(text: '*', style: delimiterStyle));
          i = endIdx + 1;
          continue;
        }
      }

      // 8g. Italic _..._
      if (codeUnit == 95 &&
          (!text.startsWith('__', i) || text.startsWith('___', i)) &&
          _canOpenUnderscore(text, i) &&
          !_isWhitespace(text, i + 1)) {
        final endIdx = _findClosingMarker(
          text,
          i + 1,
          '_',
          requireUnderscoreBoundary: true,
          allowNestedMarker: '__',
        );
        if (endIdx > i + 1) {
          flush();
          out.add(TextSpan(text: '_', style: delimiterStyle));
          _appendInlineSpans(
            text.substring(i + 1, endIdx),
            _mergeStyle(currentStyle, fontStyle: FontStyle.italic),
            delimiterStyle,
            palette,
            isDark,
            out,
            depth: depth + 1,
          );
          out.add(TextSpan(text: '_', style: delimiterStyle));
          i = endIdx + 1;
          continue;
        }
      }

      // 9a. Superscript ^sup^
      if (codeUnit == 94 &&
          (i == 0 || text.codeUnitAt(i - 1) != 91) &&
          !_isWhitespace(text, i + 1)) {
        final endIdx = _findClosingMarker(text, i + 1, '^');
        if (endIdx > i + 1) {
          flush();
          out.add(TextSpan(text: '^', style: delimiterStyle));
          _appendInlineSpans(
            text.substring(i + 1, endIdx),
            currentStyle?.copyWith(
              fontSize: (currentStyle.fontSize ?? 14) * 0.84,
              color: palette.resolveAccentColor(isDark),
            ),
            delimiterStyle,
            palette,
            isDark,
            out,
            depth: depth + 1,
          );
          out.add(TextSpan(text: '^', style: delimiterStyle));
          i = endIdx + 1;
          continue;
        }
      }

      // 9b. Subscript ~sub~
      if (codeUnit == 126 &&
          !text.startsWith('~~', i) &&
          (i == 0 || text.codeUnitAt(i - 1) != 126) &&
          !_isWhitespace(text, i + 1)) {
        final endIdx = _findClosingMarker(text, i + 1, '~');
        if (endIdx > i + 1) {
          flush();
          out.add(TextSpan(text: '~', style: delimiterStyle));
          _appendInlineSpans(
            text.substring(i + 1, endIdx),
            currentStyle?.copyWith(
              fontSize: (currentStyle.fontSize ?? 14) * 0.84,
              color: palette.resolveAccentColor(isDark),
            ),
            delimiterStyle,
            palette,
            isDark,
            out,
            depth: depth + 1,
          );
          out.add(TextSpan(text: '~', style: delimiterStyle));
          i = endIdx + 1;
          continue;
        }
      }

      // 10. Hashtag & #RRGGBB hex color preview
      if (codeUnit == 35 && i + 1 < text.length) {
        final hashMatch = _hashRegex.matchAsPrefix(text, i);
        if (hashMatch != null) {
          flush();
          final matchedText = hashMatch.group(0)!;
          final hexColor = AppColors.tryParseHexColor(matchedText);
          if (hexColor != null) {
            final luminance = hexColor.computeLuminance();
            final textColor =
                luminance > 0.55 ? const Color(0xFF191A23) : Colors.white;
            out.add(TextSpan(
              text: matchedText,
              style: GoogleFonts.jetBrainsMono(
                textStyle: currentStyle,
                backgroundColor: hexColor.withValues(alpha: 0.5),
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ));
          } else {
            out.add(TextSpan(
              text: matchedText,
              style: currentStyle?.copyWith(
                color: palette.resolveAccentColor(isDark),
                fontWeight: FontWeight.w700,
              ),
            ));
          }
          i = hashMatch.end;
          continue;
        }
      }

      buffer.writeCharCode(codeUnit);
      i++;
    }

    flush();
  }

  TextStyle? _mergeStyle(
    TextStyle? base, {
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? addDecoration,
    Color? backgroundColor,
    Color? color,
  }) {
    if (base == null) {
      return TextStyle(
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        decoration: addDecoration,
        backgroundColor: backgroundColor,
        color: color,
      );
    }

    TextDecoration? mergedDecoration = base.decoration;
    if (addDecoration != null && addDecoration != TextDecoration.none) {
      final list = <TextDecoration>[
        if (mergedDecoration != null && mergedDecoration != TextDecoration.none)
          mergedDecoration,
        addDecoration,
      ];
      mergedDecoration =
          list.length == 1 ? list.first : TextDecoration.combine(list);
    }

    return base.copyWith(
      fontWeight: fontWeight ?? base.fontWeight,
      fontStyle: fontStyle ?? base.fontStyle,
      decoration: mergedDecoration,
      backgroundColor: backgroundColor ?? base.backgroundColor,
      color: color ?? base.color,
    );
  }

  bool _isWhitespace(String text, int index) {
    if (index < 0 || index >= text.length) return true;
    final ch = text.codeUnitAt(index);
    return ch == 32 || ch == 9 || ch == 10 || ch == 13;
  }

  bool _isWordChar(String ch) => _wordCharRegex.hasMatch(ch);

  bool _canOpenUnderscore(String text, int index) {
    if (index > 0 && _isWordChar(text[index - 1])) return false;
    return true;
  }

  ({String label, String url, int endIndex})? _tryMatchMarkdownLink(
    String text,
    int startIndex,
  ) {
    int k = startIndex + 1;
    while (k < text.length) {
      final ch = text.codeUnitAt(k);
      if (ch == 10 || ch == 13) return null;
      if (ch == 96) {
        final closeTick = text.indexOf('`', k + 1);
        if (closeTick != -1 && !text.substring(k + 1, closeTick).contains('\n')) {
          k = closeTick + 1;
          continue;
        }
      }
      if (ch == 93) {
        if (k > startIndex + 1 && text.startsWith('](', k)) {
          final urlStart = k + 2;
          final urlEnd = text.indexOf(')', urlStart);
          if (urlEnd > urlStart &&
              !text.substring(urlStart, urlEnd).contains('\n')) {
            return (
              label: text.substring(startIndex + 1, k),
              url: text.substring(urlStart, urlEnd),
              endIndex: urlEnd + 1,
            );
          }
        }
        return null;
      }
      k++;
    }
    return null;
  }

  int _findClosingMarker(
    String text,
    int start,
    String marker, {
    bool allowNestedSingleStar = false,
    bool requireUnderscoreBoundary = false,
    String? allowNestedMarker,
  }) {
    final len = marker.length;
    bool openSingleStar = false;
    int j = start;
    while (j <= text.length - len) {
      final ch = text.codeUnitAt(j);
      if (ch == 10 || ch == 13) return -1;

      if (ch == 96) {
        final closeTick = text.indexOf('`', j + 1);
        if (closeTick != -1 && !text.substring(j + 1, closeTick).contains('\n')) {
          j = closeTick + 1;
          continue;
        }
      }

      if (allowNestedMarker != null && text.startsWith(allowNestedMarker, j)) {
        final nl = allowNestedMarker.length;
        final isTripleEdge =
            (allowNestedMarker == '**' && text.startsWith('***', j)) ||
            (allowNestedMarker == '__' && text.startsWith('___', j));
        if (!isTripleEdge) {
          final innerClose = text.indexOf(allowNestedMarker, j + nl);
          if (innerClose != -1 && !text.substring(j + nl, innerClose).contains('\n')) {
            j = innerClose + nl;
            continue;
          }
        }
      }

      if (allowNestedSingleStar && ch == 42 && !text.startsWith('**', j)) {
        final canOpen = !_isWhitespace(text, j + 1);
        final canClose = j > start && !_isWhitespace(text, j - 1);
        if (!openSingleStar && canOpen) {
          openSingleStar = true;
        } else if (openSingleStar && canClose) {
          openSingleStar = false;
        }
        j++;
        continue;
      }

      if (text.startsWith(marker, j) && j > start && !_isWhitespace(text, j - 1)) {
        if (allowNestedSingleStar &&
            marker == '**' &&
            openSingleStar &&
            text.startsWith('***', j)) {
          openSingleStar = false;
          j++;
          continue;
        }
        if (marker == '~' &&
            j + 1 < text.length &&
            text.codeUnitAt(j + 1) == 126) {
          j++;
          continue;
        }
        if (requireUnderscoreBoundary &&
            j + len < text.length &&
            _isWordChar(text[j + len])) {
          j++;
          continue;
        }
        return j;
      }

      j++;
    }
    return -1;
  }
}

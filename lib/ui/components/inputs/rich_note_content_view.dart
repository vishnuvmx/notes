import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// Rich Interactive Content View for Tack Notes.
/// Renders Headings (H1-H6), Blockquotes, Interactive Checklists, Bullet & Numbered Lists,
/// GFM Tables, Fenced Code Blocks, Inline Code, Clickable Links, Images, and Horizontal Rules.
class RichNoteContentView extends StatelessWidget {
  final String content;
  final ValueChanged<String>? onContentChanged;
  final bool isInteractive;
  final String? paletteId;

  const RichNoteContentView({
    super.key,
    required this.content,
    this.onContentChanged,
    this.isInteractive = true,
    this.paletteId,
  });

  void _toggleCheckbox(int lineIndex) {
    if (onContentChanged == null) return;
    HapticFeedback.lightImpact();

    final lines = content.split('\n');
    if (lineIndex >= 0 && lineIndex < lines.length) {
      final line = lines[lineIndex];
      if (line.contains('[ ]')) {
        lines[lineIndex] = line.replaceFirst('[ ]', '[x]');
      } else if (line.contains('[x]')) {
        lines[lineIndex] = line.replaceFirst('[x]', '[ ]');
      } else if (line.contains('[X]')) {
        lines[lineIndex] = line.replaceFirst('[X]', '[ ]');
      }
      onContentChanged!(lines.join('\n'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (content.trim().isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Text(
            'No content yet. Switch to edit mode to write...',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ),
      );
    }

    final lines = content.split('\n');
    final widgets = <Widget>[];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // 1. Fenced code block: ```lang ... ```
      if (trimmed.startsWith('```')) {
        final lang = trimmed.substring(3).trim();
        final codeLines = <String>[];
        int j = i + 1;
        while (j < lines.length && !lines[j].trim().startsWith('```')) {
          codeLines.add(lines[j]);
          j++;
        }
        final code = codeLines.join('\n');
        widgets.add(_buildFencedCodeBlock(context, lang, code, isDark, theme));
        i = (j < lines.length) ? j + 1 : j;
        continue;
      }

      // 2. Table: line has '|' and next line is a separator line (e.g. |---|---|)
      if (line.contains('|') && (i + 1 < lines.length)) {
        final nextTrimmed = lines[i + 1].trim();
        if (nextTrimmed.contains('|') &&
            RegExp(r'^\|?(\s*:?-+:?\s*\|)+\s*:?-+:?\s*\|?$').hasMatch(nextTrimmed)) {
          final tableLines = <String>[line, lines[i + 1]];
          int j = i + 2;
          while (j < lines.length && lines[j].trim().isNotEmpty && lines[j].contains('|')) {
            tableLines.add(lines[j]);
            j++;
          }
          widgets.add(_buildTable(context, tableLines, isDark, theme));
          i = j;
          continue;
        }
      }

      // 3. Standalone Image: ![alt](url)
      final imgMatch = RegExp(r'^\s*!\[(.*?)\]\((.*?)\)\s*$').firstMatch(line);
      if (imgMatch != null) {
        final alt = imgMatch.group(1) ?? '';
        final url = imgMatch.group(2) ?? '';
        widgets.add(_buildImageBlock(context, alt, url, isDark));
        i++;
        continue;
      }

      // 4. Horizontal Rule: ---, ***, ___ (at least 3 characters)
      if (RegExp(r'^\s*(-{3,}|\*{3,}|_{3,})\s*$').hasMatch(line)) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(
            height: 1,
            thickness: 1.2,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ));
        i++;
        continue;
      }

      // 5. Line-based elements (Headings, Checklists, Blockquotes, Lists, Paragraphs)
      widgets.add(_buildLineWidget(context, line, i, isDark));
      i++;
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  Widget _buildLineWidget(BuildContext context, String line, int lineIndex, bool isDark) {
    final theme = Theme.of(context);
    final trimmed = line.trim();

    if (trimmed.isEmpty) {
      return const SizedBox(height: 10);
    }

    // Headings H1 to H6 (# to ######)
    final headingMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
    if (headingMatch != null) {
      final level = headingMatch.group(1)!.length;
      final text = headingMatch.group(2)!;
      TextStyle? style;
      EdgeInsets padding;
      switch (level) {
        case 1:
          style = theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          );
          padding = const EdgeInsets.only(top: 14, bottom: 6);
          break;
        case 2:
          style = theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          );
          padding = const EdgeInsets.only(top: 12, bottom: 4);
          break;
        case 3:
          style = theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          );
          padding = const EdgeInsets.only(top: 10, bottom: 4);
          break;
        case 4:
          style = theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          );
          padding = const EdgeInsets.only(top: 8, bottom: 3);
          break;
        case 5:
          style = theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          );
          padding = const EdgeInsets.only(top: 6, bottom: 2);
          break;
        case 6:
        default:
          style = theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          );
          padding = const EdgeInsets.only(top: 6, bottom: 2);
          break;
      }
      return Padding(
        padding: padding,
        child: _buildRichTextSpans(
          text,
          isDark,
          theme,
          baseStyle: style,
          context: context,
        ),
      );
    }

    // Interactive Checklist item ([ ] or [x] or [X]) with indentation support
    final isUnchecked = line.contains('[ ]');
    final isChecked = line.contains('[x]') || line.contains('[X]');

    if (isUnchecked || isChecked) {
      final leadingSpaces = line.indexOf(RegExp(r'\[|\S'));
      final indent = (leadingSpaces > 0 ? (leadingSpaces / 2).floor() : 0).clamp(0, 5);
      final taskText = line
          .replaceAll(RegExp(r'^\s*[-*+]?\s*\[[ xX]\]\s*'), '')
          .replaceAll(RegExp(r'\[[ xX]\]'), '')
          .trim();

      return Padding(
        padding: EdgeInsets.only(top: 3, bottom: 3, left: indent * 16.0),
        child: InkWell(
          onTap: isInteractive ? () => _toggleCheckbox(lineIndex) : null,
          borderRadius: AppSpacing.roundedSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppSpacing.fastAnim,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isChecked
                        ? (isDark ? AppColors.pastelLimeLight : AppColors.success)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isChecked
                          ? (isDark ? AppColors.pastelLimeLight : AppColors.success)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: 1.8,
                    ),
                  ),
                  child: isChecked
                      ? const Center(
                          child: TackIcon(
                            TackIcons.check,
                            size: 14,
                            color: Colors.white,
                            style: HeroIconStyle.solid,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildRichTextSpans(
                    taskText,
                    isDark,
                    theme,
                    context: context,
                    baseStyle: theme.textTheme.bodyLarge?.copyWith(
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked
                          ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      fontWeight: isChecked ? FontWeight.w400 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Blockquote (> Quote text or >> Nested Quote)
    if (trimmed.startsWith('>')) {
      int depth = 0;
      while (depth < trimmed.length && trimmed[depth] == '>') {
        depth++;
      }
      final quoteText = trimmed.substring(depth).trim();
      return Container(
        margin: EdgeInsets.only(top: 6, bottom: 6, left: (depth - 1) * 12.0),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.pastelPeachSoft,
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: AppColors.pastelPeachLight, width: 3.5),
          ),
        ),
        child: _buildRichTextSpans(
          quoteText,
          isDark,
          theme,
          context: context,
          baseStyle: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            height: 1.45,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      );
    }

    // Numbered item (e.g. 1. item) with indentation
    final numMatch = RegExp(r'^(\s*)(\d+\.)\s*(.*)$').firstMatch(line);
    if (numMatch != null) {
      final leadingSpaces = numMatch.group(1)?.length ?? 0;
      final indent = (leadingSpaces / 2).floor().clamp(0, 5);
      final numPrefix = numMatch.group(2) ?? '';
      final body = numMatch.group(3) ?? '';

      return Padding(
        padding: EdgeInsets.only(top: 3, bottom: 3, left: indent * 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                numPrefix,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.pastelAmberLight : AppColors.accentAmber,
                ),
              ),
            ),
            Expanded(child: _buildRichTextSpans(body, isDark, theme, context: context)),
          ],
        ),
      );
    }

    // Bullet item (- item, • item, * item, + item) with multi-level indentation
    final bulletMatch = RegExp(r'^(\s*)([-•*+])\s*(.*)$').firstMatch(line);
    if (bulletMatch != null) {
      final leadingSpaces = bulletMatch.group(1)?.length ?? 0;
      final indent = (leadingSpaces / 2).floor().clamp(0, 5);
      final body = bulletMatch.group(3) ?? '';

      Widget bulletWidget;
      final bulletColor = isDark ? AppColors.pastelCyanLight : AppColors.pastelCyanDark;
      if (indent % 3 == 1) {
        bulletWidget = Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: bulletColor, width: 1.5),
          ),
        );
      } else if (indent % 3 == 2) {
        bulletWidget = Container(
          width: 5,
          height: 5,
          color: bulletColor,
        );
      } else {
        bulletWidget = Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: bulletColor,
            shape: BoxShape.circle,
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.only(top: 3, bottom: 3, left: indent * 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 8),
              child: bulletWidget,
            ),
            Expanded(child: _buildRichTextSpans(body, isDark, theme, context: context)),
          ],
        ),
      );
    }

    // Regular paragraph
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _buildRichTextSpans(line, isDark, theme, context: context),
    );
  }

  Widget _buildFencedCodeBlock(
    BuildContext context,
    String lang,
    String code,
    bool isDark,
    ThemeData theme,
  ) {
    final langLabel = lang.trim().toUpperCase();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1C22) : const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFEAEFF4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  langLabel.isEmpty ? 'CODE' : langLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.accentCyan,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard!'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TackIcon(
                          TackIcons.copy,
                          size: 13,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.45,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    List<String> lines,
    bool isDark,
    ThemeData theme,
  ) {
    if (lines.length < 2) return const SizedBox.shrink();

    List<String> parseCells(String line) {
      var raw = line.trim();
      if (raw.startsWith('|')) raw = raw.substring(1);
      if (raw.endsWith('|')) raw = raw.substring(0, raw.length - 1);
      return raw.split('|').map((c) => c.trim()).toList();
    }

    final headers = parseCells(lines[0]);
    final separatorCells = parseCells(lines[1]);
    final alignments = <TextAlign>[];
    for (final s in separatorCells) {
      final trimmed = s.trim();
      if (trimmed.startsWith(':') && trimmed.endsWith(':')) {
        alignments.add(TextAlign.center);
      } else if (trimmed.endsWith(':')) {
        alignments.add(TextAlign.right);
      } else {
        alignments.add(TextAlign.left);
      }
    }

    final rows = <List<String>>[];
    for (int i = 2; i < lines.length; i++) {
      rows.add(parseCells(lines[i]));
    }

    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final headerBg = isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF0F3F6);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder(
            horizontalInside: BorderSide(color: borderColor, width: 0.8),
            verticalInside: BorderSide(color: borderColor, width: 0.8),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerBg),
              children: List.generate(headers.length, (colIdx) {
                final align = colIdx < alignments.length ? alignments[colIdx] : TextAlign.left;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    headers[colIdx],
                    textAlign: align,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                );
              }),
            ),
            ...rows.map((row) {
              return TableRow(
                children: List.generate(headers.length, (colIdx) {
                  final text = colIdx < row.length ? row[colIdx] : '';
                  final align = colIdx < alignments.length ? alignments[colIdx] : TextAlign.left;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Align(
                      alignment: align == TextAlign.center
                          ? Alignment.center
                          : (align == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
                      child: _buildRichTextSpans(text, isDark, theme, context: context),
                    ),
                  );
                }),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBlock(BuildContext context, String alt, String url, bool isDark) {
    Widget imgWidget;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      imgWidget = Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 140,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildImageError(alt, isDark),
      );
    } else if (!kIsWeb) {
      final file = File(url);
      if (file.existsSync()) {
        imgWidget = Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildImageError(alt, isDark),
        );
      } else {
        imgWidget = _buildImageError(alt, isDark);
      }
    } else {
      imgWidget = _buildImageError(alt, isDark);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: imgWidget,
            ),
          ),
          if (alt.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              alt.trim(),
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageError(String alt, bool isDark) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 24,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
          const SizedBox(width: 8),
          Text(
            alt.isNotEmpty ? alt : 'Image could not be loaded',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichTextSpans(
    String text,
    bool isDark,
    ThemeData theme, {
    TextStyle? baseStyle,
    BuildContext? context,
  }) {
    final spans = <InlineSpan>[];
    final defaultStyle = baseStyle ??
        theme.textTheme.bodyLarge?.copyWith(
          height: 1.5,
          fontSize: 15,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontFamily: AppTypography.fontFamily,
        );

    final pattern = RegExp(
      r'(`[^`\n]+`)'
      r'|(!\[[^\]\n]*\]\([^)\n]+\))'
      r'|(\[[^\]\n]+\]\([^)\n]+\))'
      r'|(==.*?==)'
      r'|(\*\*.*?\*\*)'
      r'|(__.*?__)'
      r'|(\*.*?\*)'
      r'|(_.*?_)'
      r'|(~~.*?~~)'
      r'|(<u>.*?</u>)'
      r'|(#[a-zA-Z0-9_-]+)',
      dotAll: false,
    );

    int lastIndex = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: defaultStyle,
        ));
      }

      final matched = match.group(0)!;
      if (matched.startsWith('`') && matched.endsWith('`') && matched.length >= 2) {
        final codeText = matched.substring(1, matched.length - 1);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262730) : const Color(0xFFE9ECEF),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.8,
                ),
              ),
              child: Text(
                codeText,
                style: TextStyle(
                  fontSize: (defaultStyle?.fontSize ?? 15) * 0.88,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.pastelCyanLight : AppColors.pastelCyanDark,
                ),
              ),
            ),
          ),
        );
      } else if (matched.startsWith('![') && matched.contains('](') && matched.endsWith(')')) {
        final midIndex = matched.indexOf('](');
        final url = matched.substring(midIndex + 2, matched.length - 1);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  url,
                  height: 24,
                  errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported, size: 18),
                ),
              ),
            ),
          ),
        );
      } else if (matched.startsWith('[') && matched.contains('](') && matched.endsWith(')')) {
        final midIndex = matched.indexOf('](');
        final label = matched.substring(1, midIndex);
        final url = matched.substring(midIndex + 2, matched.length - 1);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: url));
                HapticFeedback.lightImpact();
                if (context != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link copied: $url'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isDark ? AppColors.pastelCyanLight : AppColors.accentCyan,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: isDark ? AppColors.pastelCyanLight : AppColors.accentCyan,
                        fontSize: defaultStyle?.fontSize,
                      ),
                    ),
                    const SizedBox(width: 3),
                    TackIcon(
                      TackIcons.link,
                      size: 11,
                      color: isDark ? AppColors.pastelCyanLight : AppColors.accentCyan,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else if (matched.startsWith('==') && matched.endsWith('==') && matched.length >= 4) {
        final innerText = matched.substring(2, matched.length - 2);
        final colonIdx = innerText.indexOf(':');
        String displayText = innerText;
        Color highlightBg;
        if (colonIdx > 0 && colonIdx < 15) {
          final prefix = innerText.substring(0, colonIdx).toLowerCase();
          final known = AppColors.presetPalettes.any((p) => p.id == prefix);
          if (known) {
            displayText = innerText.substring(colonIdx + 1);
            highlightBg = AppColors.getHighlightColor(prefix, isDark: isDark);
          } else {
            highlightBg = AppColors.getHighlightColor(paletteId, isDark: isDark);
          }
        } else {
          highlightBg = AppColors.getHighlightColor(paletteId, isDark: isDark);
        }

        spans.add(TextSpan(
          text: displayText,
          style: defaultStyle?.copyWith(
            backgroundColor: highlightBg,
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (matched.startsWith('**') && matched.endsWith('**') && matched.length >= 4) {
        spans.add(TextSpan(
          text: matched.substring(2, matched.length - 2),
          style: defaultStyle?.copyWith(fontWeight: FontWeight.w800),
        ));
      } else if (matched.startsWith('__') && matched.endsWith('__') && matched.length >= 4) {
        spans.add(TextSpan(
          text: matched.substring(2, matched.length - 2),
          style: defaultStyle?.copyWith(decoration: TextDecoration.underline),
        ));
      } else if (matched.startsWith('<u>') && matched.endsWith('</u>') && matched.length >= 7) {
        spans.add(TextSpan(
          text: matched.substring(3, matched.length - 4),
          style: defaultStyle?.copyWith(decoration: TextDecoration.underline),
        ));
      } else if (matched.startsWith('*') && matched.endsWith('*') && matched.length >= 2) {
        spans.add(TextSpan(
          text: matched.substring(1, matched.length - 1),
          style: defaultStyle?.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (matched.startsWith('_') && matched.endsWith('_') && matched.length >= 2) {
        spans.add(TextSpan(
          text: matched.substring(1, matched.length - 1),
          style: defaultStyle?.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (matched.startsWith('~~') && matched.endsWith('~~') && matched.length >= 4) {
        spans.add(TextSpan(
          text: matched.substring(2, matched.length - 2),
          style: defaultStyle?.copyWith(decoration: TextDecoration.lineThrough),
        ));
      } else if (matched.startsWith('#') && matched.length > 1) {
        final hexColor = AppColors.tryParseHexColor(matched);
        if (hexColor != null) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: hexColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: hexColor.withValues(alpha: 0.8),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: hexColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      matched,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        color: isDark ? Colors.white : const Color(0xFF18191F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceAlt : AppColors.pastelLavenderSoft,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? AppColors.pastelLavenderLight.withValues(alpha: 0.4)
                        : AppColors.pastelLavenderLight,
                    width: 1,
                  ),
                ),
                child: Text(
                  matched,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.pastelLavenderLight : AppColors.pastelLavenderDark,
                  ),
                ),
              ),
            ),
          );
        }
      } else {
        spans.add(TextSpan(text: matched, style: defaultStyle));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: defaultStyle,
      ));
    }

    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: spans,
      ),
    );
  }
}


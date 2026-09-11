import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// Rich Interactive Content View for Tack Notes.
/// Renders Headings, Blockquotes, Interactive Checklists, Bullet Lists, and Hashtags.
class RichNoteContentView extends StatelessWidget {
  final String content;
  final ValueChanged<String>? onContentChanged;
  final bool isInteractive;

  const RichNoteContentView({
    super.key,
    required this.content,
    this.onContentChanged,
    this.isInteractive = true,
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
    final lines = content.split('\n');

    if (content.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          'No content yet. Switch to edit mode to write...',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontStyle: FontStyle.italic,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines.length, (index) {
        final line = lines[index];
        return _buildLineWidget(context, line, index, isDark);
      }),
    );
  }

  Widget _buildLineWidget(BuildContext context, String line, int lineIndex, bool isDark) {
    final theme = Theme.of(context);
    final trimmed = line.trim();

    if (trimmed.isEmpty) {
      return const SizedBox(height: 10);
    }

    // 1. Heading 1 (# Heading)
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: _buildRichTextSpans(
          line.substring(2),
          isDark,
          theme,
          baseStyle: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      );
    }

    // 2. Heading 2 (## Subheading)
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: _buildRichTextSpans(
          line.substring(3),
          isDark,
          theme,
          baseStyle: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      );
    }

    // 3. Heading 3 (### Small Heading)
    if (line.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: _buildRichTextSpans(
          line.substring(4),
          isDark,
          theme,
          baseStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      );
    }

    // 4. Interactive Checklist item ([ ] or [x])
    final isUnchecked = line.contains('[ ]');
    final isChecked = line.contains('[x]') || line.contains('[X]');

    if (isUnchecked || isChecked) {
      final taskText = line
          .replaceAll(RegExp(r'^\s*[-*]?\s*\[[ xX]\]\s*'), '')
          .replaceAll(RegExp(r'\[[ xX]\]'), '')
          .trim();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
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

    // 5. Blockquote (> Quote text)
    if (line.startsWith('> ')) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.pastelPeachSoft,
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: AppColors.pastelPeachLight, width: 3.5),
          ),
        ),
        child: _buildRichTextSpans(
          line.substring(2),
          isDark,
          theme,
          baseStyle: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            height: 1.45,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      );
    }

    // 6. Numbered item (1. item) or Bullet item (• item or - item)
    if (RegExp(r'^\d+\.\s').hasMatch(line)) {
      final match = RegExp(r'^(\d+\.)\s*(.*)$').firstMatch(line);
      final numPrefix = match?.group(1) ?? '';
      final body = match?.group(2) ?? line;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
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
            Expanded(child: _buildRichTextSpans(body, isDark, theme)),
          ],
        ),
      );
    }

    if (line.startsWith('• ') || line.startsWith('- ')) {
      final body = line.substring(2);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 8),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.pastelCyanLight : AppColors.pastelCyanDark,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(child: _buildRichTextSpans(body, isDark, theme)),
          ],
        ),
      );
    }

    // 7. Regular paragraph with bold, italic, and hashtag support
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _buildRichTextSpans(line, isDark, theme),
    );
  }

  Widget _buildRichTextSpans(
    String text,
    bool isDark,
    ThemeData theme, {
    TextStyle? baseStyle,
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
      r'(==.*?==)|(\*\*.*?\*\*)|(__.*?__)|(\*.*?\*)|(_.*?_)|(~~.*?~~)|(<u>.*?</u>)|(#[a-zA-Z0-9_-]+)',
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
      if (matched.startsWith('==') && matched.endsWith('==') && matched.length >= 4) {
        spans.add(TextSpan(
          text: matched.substring(2, matched.length - 2),
          style: defaultStyle?.copyWith(
            backgroundColor: isDark
                ? AppColors.pastelAmberLight.withValues(alpha: 0.35)
                : AppColors.pastelYellowLight.withValues(alpha: 0.6),
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
                    color: isDark ? AppColors.pastelLavenderLight.withValues(alpha: 0.4) : AppColors.pastelLavenderLight,
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

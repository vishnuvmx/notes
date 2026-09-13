import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Syntax-highlighted text controller that renders bold, italic, strikethrough,
/// underline, highlights, and tags inside any editor or input TextField.
class MarkdownTextEditingController extends TextEditingController {
  MarkdownTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = this.text;
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final spans = <TextSpan>[];
    final pattern = RegExp(
      r'(==.*?==)|(\*\*.*?\*\*)|(__.*?__)|(\*.*?\*)|(_.*?_)|(~~.*?~~)|(<u>.*?</u>)|(#[a-zA-Z0-9_-]+)',
      dotAll: false,
    );

    final delimiterStyle = style?.copyWith(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.28),
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.normal,
      decoration: TextDecoration.none,
    );

    int lastMatchEnd = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: style,
        ));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('==') && matchedText.endsWith('==') && matchedText.length >= 4) {
        spans.add(TextSpan(text: '==', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: style?.copyWith(
            backgroundColor: isDark
                ? AppColors.pastelAmberLight.withValues(alpha: 0.35)
                : AppColors.pastelYellowLight.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ));
        spans.add(TextSpan(text: '==', style: delimiterStyle));
      } else if (matchedText.startsWith('**') && matchedText.endsWith('**') && matchedText.length >= 4) {
        spans.add(TextSpan(text: '**', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: style?.copyWith(fontWeight: FontWeight.bold),
        ));
        spans.add(TextSpan(text: '**', style: delimiterStyle));
      } else if (matchedText.startsWith('__') && matchedText.endsWith('__') && matchedText.length >= 4) {
        spans.add(TextSpan(text: '__', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: style?.copyWith(decoration: TextDecoration.underline),
        ));
        spans.add(TextSpan(text: '__', style: delimiterStyle));
      } else if (matchedText.startsWith('<u>') && matchedText.endsWith('</u>') && matchedText.length >= 7) {
        spans.add(TextSpan(text: '<u>', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(3, matchedText.length - 4),
          style: style?.copyWith(decoration: TextDecoration.underline),
        ));
        spans.add(TextSpan(text: '</u>', style: delimiterStyle));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*') && matchedText.length >= 2) {
        spans.add(TextSpan(text: '*', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: style?.copyWith(fontStyle: FontStyle.italic),
        ));
        spans.add(TextSpan(text: '*', style: delimiterStyle));
      } else if (matchedText.startsWith('_') && matchedText.endsWith('_') && matchedText.length >= 2) {
        spans.add(TextSpan(text: '_', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: style?.copyWith(fontStyle: FontStyle.italic),
        ));
        spans.add(TextSpan(text: '_', style: delimiterStyle));
      } else if (matchedText.startsWith('~~') && matchedText.endsWith('~~') && matchedText.length >= 4) {
        spans.add(TextSpan(text: '~~', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: style?.copyWith(decoration: TextDecoration.lineThrough),
        ));
        spans.add(TextSpan(text: '~~', style: delimiterStyle));
      } else if (matchedText.startsWith('#')) {
        final hexColor = AppColors.tryParseHexColor(matchedText);
        if (hexColor != null) {
          final luminance = hexColor.computeLuminance();
          final textColor = luminance > 0.55 ? const Color(0xFF191A23) : Colors.white;
          spans.add(TextSpan(
            text: matchedText,
            style: style?.copyWith(
              backgroundColor: hexColor.withValues(alpha: 0.5),
              color: textColor,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ));
        } else {
          spans.add(TextSpan(
            text: matchedText,
            style: style?.copyWith(
              color: isDark ? AppColors.pastelLavenderLight : AppColors.pastelLavenderDark,
              fontWeight: FontWeight.w700,
            ),
          ));
        }
      } else {
        spans.add(TextSpan(text: matchedText, style: style));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }

    return TextSpan(children: spans, style: style);
  }
}

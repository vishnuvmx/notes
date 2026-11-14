import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../services/latex_math_service.dart';

/// Shared helper resolving the effective text scale factor from [MediaQuery.textScalerOf].
double _resolveMathScaleFactor(BuildContext context, double baseFontSize) {
  if (baseFontSize <= 0) return 1.0;
  final scaledSize = MediaQuery.textScalerOf(context).scale(baseFontSize);
  return scaledSize / baseFontSize;
}

/// Renders an inline LaTeX math expression (`$...$` or inline `$$...$$`) as a
/// native Flutter widget inside [RichNoteContentView] spans.
///
/// Supports light/dark themes, accessibility [TextScaler], inherited surrounding
/// [TextStyle], and graceful fallback to [rawSource] when LaTeX parsing fails.
class InlineMathView extends StatelessWidget {
  final String expression;
  final String rawSource;
  final TextStyle? baseStyle;
  final MathStyle mathStyle;

  const InlineMathView({
    super.key,
    required this.expression,
    required this.rawSource,
    this.baseStyle,
    this.mathStyle = MathStyle.text,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final inherited = DefaultTextStyle.of(context).style;
    final merged = inherited.merge(baseStyle);
    final baseFontSize = merged.fontSize ?? 15.0;
    final textColor = merged.color ?? tokens.textPrimary;
    final effectiveStyle = merged.copyWith(
      fontSize: baseFontSize,
      color: textColor,
    );

    final parsed = LatexMathService.parseTex(expression);
    if (parsed.error != null || parsed.ast == null) {
      return _buildRawFallback(effectiveStyle);
    }

    final scaleFactor = _resolveMathScaleFactor(context, baseFontSize);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Math(
        ast: parsed.ast,
        mathStyle: mathStyle,
        textStyle: effectiveStyle,
        textScaleFactor: scaleFactor,
        onErrorFallback: (_) => _buildRawFallback(effectiveStyle),
      ),
    );
  }

  Widget _buildRawFallback(TextStyle style) {
    return Text(
      rawSource,
      style: style,
    );
  }
}

/// Renders a standalone display LaTeX block (`$$...$$`) inside a themed card
/// matching Tack's Paper & Pin design system.
///
/// Centers equations that fit cleanly within the viewport, allows smooth
/// horizontal scrolling for wide matrices/derivations, scales with [TextScaler],
/// and falls back gracefully to [rawSource] on invalid LaTeX.
class BlockMathView extends StatelessWidget {
  final String expression;
  final String rawSource;
  final String? paletteId;
  final TextStyle? baseStyle;

  const BlockMathView({
    super.key,
    required this.expression,
    required this.rawSource,
    this.paletteId,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final defaultBodySize = theme.textTheme.bodyLarge?.fontSize ?? 16.0;
    final baseFontSize = baseStyle?.fontSize ?? (defaultBodySize + 1.0);
    final textColor = baseStyle?.color ?? tokens.textPrimary;
    final effectiveStyle = (baseStyle ?? const TextStyle()).copyWith(
      fontFamily: AppTypography.fontFamily,
      fontSize: baseFontSize,
      color: textColor,
    );

    final parsed = LatexMathService.parseTex(expression);
    final isInvalid = parsed.error != null || parsed.ast == null;
    final scaleFactor = _resolveMathScaleFactor(context, baseFontSize);

    final containerBg = tokens.isDark
        ? tokens.canvasSunken.withValues(alpha: 0.72)
        : tokens.canvasSunken.withValues(alpha: 0.50);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: tokens.borderSubtle,
          width: 1,
        ),
      ),
      child: isInvalid
          ? _buildRawFallback(baseFontSize, textColor)
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth.isFinite
                          ? constraints.maxWidth
                          : 0,
                    ),
                    child: Center(
                      child: Math(
                        ast: parsed.ast,
                        mathStyle: MathStyle.display,
                        textStyle: effectiveStyle,
                        textScaleFactor: scaleFactor,
                        onErrorFallback: (_) =>
                            _buildRawFallback(baseFontSize, textColor),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRawFallback(double baseFontSize, Color textColor) {
    return Text(
      rawSource,
      style: AppTypography.mono(
        fontSize: math.max(12.0, baseFontSize * 0.85),
        color: textColor,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tack_icons.dart';

/// Accessible touch target wrapper (`minTouchTarget` = 48x48dp by default)
/// that guarantees Material hover, highlight, and splash animations paint
/// strictly inside the smaller visual rounded rectangle or circle.
///
/// Architectural invariant:
/// Never place an `InkWell` directly outside a `48dp` `ConstrainedBox` around
/// a shorter visual pill or icon badge—otherwise the ink overlay renders on the
/// outer 48dp box and bleeds past the pill's rounded edges. Here the outer
/// `GestureDetector` absorbs the accessible hit area invisibly, while `Material`
/// with `Clip.antiAlias` and `InkWell` sit strictly inside the visual shape.
class TactileInkTarget extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;
  final bool useCircleShape;
  final double minWidth;
  final double minHeight;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final TextStyle? textStyle;
  final Color? splashColor;
  final Color? highlightColor;
  final Color? hoverColor;
  final Duration duration;
  final Curve curve;
  final bool triggerHaptics;
  final String? semanticsLabel;
  final bool? isSelected;
  final Widget child;

  const TactileInkTarget({
    super.key,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.borderRadius = AppSpacing.roundedPill,
    this.useCircleShape = false,
    this.minWidth = AppSpacing.minTouchTarget,
    this.minHeight = AppSpacing.minTouchTarget,
    this.width,
    this.height,
    this.padding,
    this.color,
    this.border,
    this.boxShadow,
    this.textStyle,
    this.splashColor,
    this.highlightColor,
    this.hoverColor,
    this.duration = AppSpacing.durationFast,
    this.curve = Curves.easeOutCubic,
    this.triggerHaptics = false,
    this.semanticsLabel,
    this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final BorderSide borderSide =
        (border is Border && (border as Border).isUniform)
        ? (border as Border).top
        : BorderSide.none;

    final ShapeBorder shape = useCircleShape
        ? const CircleBorder()
        : AppSpacing.smoothBorder(borderRadius);

    final ShapeBorder decorationShape = useCircleShape
        ? CircleBorder(side: borderSide)
        : AppSpacing.smoothBorder(borderRadius, side: borderSide);

    void handleTap() {
      if (onTap == null) return;
      if (triggerHaptics) {
        HapticFeedback.selectionClick();
      }
      onTap!();
    }

    final Widget paddedChild = Center(
      widthFactor: width == null ? 1 : null,
      heightFactor: height == null ? 1 : null,
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

    final Widget styledChild = textStyle != null
        ? AnimatedDefaultTextStyle(
            duration: duration,
            curve: curve,
            style: textStyle!,
            child: paddedChild,
          )
        : paddedChild;

    final Widget visualControl = AnimatedContainer(
      duration: duration,
      curve: curve,
      width: width,
      height: height,
      decoration: ShapeDecoration(
        shape: decorationShape,
        color: color,
        shadows: boxShadow ?? const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          excludeFromSemantics: true,
          onTap: onTap != null ? handleTap : null,
          onLongPress: onLongPress,
          customBorder: shape,
          splashColor: splashColor,
          highlightColor: highlightColor,
          hoverColor: hoverColor,
          child: styledChild,
        ),
      ),
    );

    final Widget hitBox = GestureDetector(
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      onTap: onTap != null ? handleTap : null,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
        child: Center(widthFactor: 1, heightFactor: 1, child: visualControl),
      ),
    );

    return Semantics(
      button: true,
      enabled: onTap != null || onLongPress != null,
      selected: isSelected,
      label: semanticsLabel,
      onTap: onTap != null ? handleTap : null,
      onLongPress: onLongPress,
      excludeSemantics: semanticsLabel != null,
      child: hitBox,
    );
  }
}

/// Shared Paper & Pin selectable filter/choice pill built on [TactileInkTarget].
/// Syncs fill, border, text, and optional icon color transitions together
/// while keeping hover/ripple ink strictly inside the visual capsule.
class TactileFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final dynamic icon;
  final Widget? leadingWidget;
  final bool showChevron;
  final String? semanticsLabel;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedFg;
  final Color? unselectedFg;
  final Color? selectedBorderColor;
  final Color? unselectedBorderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double? height;
  final double minWidth;
  final double minHeight;
  final TextStyle? textStyle;
  final bool triggerHaptics;

  const TactileFilterPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.leadingWidget,
    this.showChevron = false,
    this.semanticsLabel,
    this.selectedColor,
    this.unselectedColor,
    this.selectedFg,
    this.unselectedFg,
    this.selectedBorderColor,
    this.unselectedBorderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.borderRadius = AppSpacing.roundedPill,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.s4,
      vertical: AppSpacing.s2 + 2,
    ),
    this.height,
    this.minWidth = AppSpacing.minTouchTarget,
    this.minHeight = AppSpacing.minTouchTarget,
    this.textStyle,
    this.triggerHaptics = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bg = isSelected
        ? (selectedColor ?? tokens.actionPrimary)
        : (unselectedColor ?? tokens.surfacePrimary);
    final fg = isSelected
        ? (selectedFg ?? tokens.actionPrimaryFg)
        : (unselectedFg ?? tokens.textSecondary);
    final borderColor = isSelected
        ? (selectedBorderColor ?? Colors.transparent)
        : (unselectedBorderColor ?? tokens.borderSubtle);

    final baseStyle =
        textStyle ??
        AppTypography.label(
          color: fg,
          weight: isSelected ? FontWeight.w600 : FontWeight.w500,
        );

    return TactileInkTarget(
      semanticsLabel: semanticsLabel ?? label,
      isSelected: isSelected,
      onTap: onTap,
      triggerHaptics: triggerHaptics,
      borderRadius: borderRadius,
      minWidth: minWidth,
      minHeight: minHeight,
      height: height,
      padding: padding,
      color: bg,
      border: borderWidth <= 0
          ? null
          : Border.all(color: borderColor, width: borderWidth),
      boxShadow: boxShadow,
      textStyle: baseStyle.copyWith(color: fg),
      splashColor: fg.withValues(alpha: 0.14),
      highlightColor: fg.withValues(alpha: 0.08),
      hoverColor: fg.withValues(alpha: 0.06),
      child: Builder(
        builder: (ctx) {
          final animatedFg = DefaultTextStyle.of(ctx).style.color ?? fg;
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingWidget != null) ...[
                leadingWidget!,
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                TackIcon(icon, size: 14, color: animatedFg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 4),
                TackIcon(TackIcons.chevronDown, size: 13, color: animatedFg),
              ],
            ],
          );
        },
      ),
    );
  }
}

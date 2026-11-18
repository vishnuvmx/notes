import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tack_icons.dart';

/// Item definition for [TackDropdown].
class TackDropdownItem<T> {
  final T value;
  final String label;
  final dynamic icon;
  final Color? iconColor;

  const TackDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });
}

/// Tactile, modern neo-pop dropdown matching the signature "All Notes" homescreen UI.
/// Reusable across the app for folder switching, sorting, tool options, and canvas properties.
class TackDropdown<T> extends StatelessWidget {
  final T? value;
  final String? customLabel;
  final dynamic leadingIcon;
  final Color? leadingIconColor;
  final List<TackDropdownItem<T>> items;
  final ValueChanged<T> onSelected;
  final String? hint;
  final bool isExpanded;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double iconSize;
  final double chevronSize;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final String? tooltip;

  const TackDropdown({
    super.key,
    required this.items,
    required this.onSelected,
    this.value,
    this.customLabel,
    this.leadingIcon,
    this.leadingIconColor,
    this.hint,
    this.isExpanded = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    this.fontSize = 13.5,
    this.iconSize = 15,
    this.chevronSize = 15,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final effectiveBorderColor = borderColor ?? tokens.borderStrong;
    final effectiveRadius = borderRadius ?? AppSpacing.roundedSm;

    // Resolve current selected item
    final selectedItem = items.where((i) => i.value == value).firstOrNull;
    final displayLabel = customLabel ?? selectedItem?.label ?? hint ?? '';
    final effectiveLeadingIcon = leadingIcon ?? selectedItem?.icon;
    final effectiveLeadingIconColor =
        leadingIconColor ?? selectedItem?.iconColor;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<T>(
        initialValue: value,
        tooltip: tooltip ?? displayLabel,
        position: PopupMenuPosition.under,
        offset: const Offset(0, AppSpacing.s1),
        elevation: 8,
        borderRadius: effectiveRadius,
        shadowColor: Colors.black.withValues(
          alpha: tokens.isDark ? 0.45 : 0.12,
        ),
        shape: AppSpacing.smoothMd(
          side: BorderSide(color: effectiveBorderColor, width: 1.2),
        ),
        color: tokens.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        onSelected: (val) {
          HapticFeedback.selectionClick();
          onSelected(val);
        },
        itemBuilder: (context) => items.map((item) {
          final isSelected = item.value == value;
          return PopupMenuItem<T>(
            value: item.value,
            height: AppSpacing.minTouchTarget,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (item.icon != null) ...[
                  TackIcon(
                    item.icon!,
                    size: iconSize,
                    color:
                        item.iconColor ??
                        (isSelected
                            ? tokens.actionPrimary
                            : tokens.textSecondary),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(
                      fontSize: fontSize,
                      weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  TackIcon(
                    TackIcons.check,
                    size: 14,
                    color: tokens.actionPrimary,
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSpacing.minTouchTarget,
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(
            widthFactor: isExpanded ? null : 1,
            heightFactor: 1,
            child: Container(
              padding: padding,
              decoration: ShapeDecoration(
                color: backgroundColor ?? tokens.canvasSunken,
                shape: AppSpacing.smoothBorder(
                  effectiveRadius,
                  side: BorderSide(color: effectiveBorderColor, width: 1.2),
                ),
              ),
              child: Row(
                mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: isExpanded
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.start,
                children: [
                  Flexible(
                    fit: isExpanded ? FlexFit.tight : FlexFit.loose,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (effectiveLeadingIcon != null) ...[
                          TackIcon(
                            effectiveLeadingIcon,
                            size: iconSize,
                            color:
                                effectiveLeadingIconColor ??
                                tokens.textSecondary,
                          ),
                          if (displayLabel.isNotEmpty) const SizedBox(width: 6),
                        ],
                        if (displayLabel.isNotEmpty)
                          Flexible(
                            child: Text(
                              displayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label(
                                fontSize: fontSize,
                                weight: FontWeight.w700,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  TackIcon(
                    TackIcons.chevronDown,
                    size: chevronSize,
                    color: tokens.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

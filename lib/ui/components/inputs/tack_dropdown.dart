import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderColor = borderColor ??
        (isDark ? AppColors.darkBorder : const Color(0xFF191A23));
    final effectiveRadius = borderRadius ?? BorderRadius.circular(14);

    // Resolve current selected item
    final selectedItem = items.where((i) => i.value == value).firstOrNull;
    final displayLabel = customLabel ?? selectedItem?.label ?? hint ?? '';
    final effectiveLeadingIcon = leadingIcon ?? selectedItem?.icon;
    final effectiveLeadingIconColor = leadingIconColor ?? selectedItem?.iconColor;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<T>(
        initialValue: value,
        tooltip: tooltip ?? displayLabel,
        onSelected: (val) {
          HapticFeedback.selectionClick();
          onSelected(val);
        },
        offset: const Offset(0, 42),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: effectiveBorderColor, width: 1.5),
        ),
        color: isDark ? AppColors.darkSurface : Colors.white,
        itemBuilder: (context) => items.map((item) {
          final isSelected = item.value == value;
          return PopupMenuItem<T>(
            value: item.value,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (item.icon != null) ...[
                  TackIcon(
                    item.icon!,
                    size: iconSize,
                    color: item.iconColor ??
                        (isSelected
                            ? AppColors.accentAmber
                            : (isDark ? AppColors.darkTextSecondary : const Color(0xFF191A23))),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: fontSize,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF191A23),
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  TackIcon(
                    TackIcons.check,
                    size: 14,
                    color: isDark ? AppColors.pastelLimeLight : const Color(0xFF191A23),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ??
                (isDark ? AppColors.darkSurface : const Color(0xFFF1F3F7)),
            borderRadius: effectiveRadius,
            border: Border.all(color: effectiveBorderColor, width: 1.4),
          ),
          child: Row(
            mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment:
                isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
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
                        color: effectiveLeadingIconColor ??
                            (isDark ? AppColors.darkTextSecondary : const Color(0xFF191A23)),
                      ),
                      if (displayLabel.isNotEmpty) const SizedBox(width: 6),
                    ],
                    if (displayLabel.isNotEmpty)
                      Flexible(
                        child: Text(
                          displayLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF191A23),
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
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF191A23),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

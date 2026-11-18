import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tack_icons.dart';

/// Strongly-typed action item for iOS-style context menus.
class IosMenuItem<T> {
  final T value;
  final String title;
  final dynamic icon;
  final dynamic iconStyle;
  final Color? iconColor;
  final bool isDestructive;

  const IosMenuItem({
    required this.value,
    required this.title,
    required this.icon,
    this.iconStyle,
    this.iconColor,
    this.isDestructive = false,
  });
}

/// iOS-styled Three-Dot Context Menu Button (UIMenu aesthetic).
/// Features:
/// 1. Tactile spring scale microanimation (0.88x on press) and haptics.
/// 2. Clean anchored positioning directly under the button.
/// 3. iOS layout: Left-aligned label with right-aligned glyph and hairline dividers.
/// 4. Destructive styling in vivid error red.
class IosThreeDotMenu<T> extends StatefulWidget {
  final List<IosMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final double size;
  final dynamic icon;
  final Color? iconColor;
  final Color? buttonBackgroundColor;
  final String tooltip;

  const IosThreeDotMenu({
    super.key,
    required this.items,
    required this.onSelected,
    this.size = 36,
    this.icon = TackIcons.more,
    this.iconColor,
    this.buttonBackgroundColor,
    this.tooltip = 'More options',
  });

  @override
  State<IosThreeDotMenu<T>> createState() => _IosThreeDotMenuState<T>();
}

class _IosThreeDotMenuState<T> extends State<IosThreeDotMenu<T>> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = tokens.isDark;

    final defaultIconColor = widget.iconColor ?? tokens.textPrimary;

    return PopupMenuButton<T>(
      tooltip: widget.tooltip,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      elevation: 16,
      borderRadius: AppSpacing.roundedPill,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.55 : 0.14),
      color: tokens.surfacePrimary,
      surfaceTintColor: Colors.transparent,
      shape: AppSpacing.smoothMd(
        side: BorderSide(
          color: tokens.borderSubtle,
          width: 1.2,
        ),
      ),
      constraints: const BoxConstraints(minWidth: 195, maxWidth: 240),
      onOpened: () {
        HapticFeedback.selectionClick();
      },
      onSelected: (val) {
        HapticFeedback.selectionClick();
        widget.onSelected(val);
      },
      itemBuilder: (context) {
        final entries = <PopupMenuEntry<T>>[];
        for (int i = 0; i < widget.items.length; i++) {
          final item = widget.items[i];

          entries.add(
            PopupMenuItem<T>(
              value: item.value,
              height: AppSpacing.minTouchTarget,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm(
                        weight: FontWeight.w500,
                        color: item.isDestructive
                            ? tokens.stateDanger
                            : tokens.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  TackIcon(
                    item.icon,
                    size: 18,
                    style: item.iconStyle,
                    color: item.isDestructive
                        ? tokens.stateDanger
                        : (item.iconColor ?? tokens.textSecondary),
                  ),
                ],
              ),
            ),
          );

          // Add hairline divider between items, matching iOS UIMenu style
          if (i < widget.items.length - 1) {
            entries.add(
              const PopupMenuDivider(
                height: 1,
              ),
            );
          }
        }
        return entries;
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTouchTarget,
          minHeight: AppSpacing.minTouchTarget,
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Listener(
            onPointerDown: (_) => setState(() => _isPressed = true),
            onPointerUp: (_) {
              if (mounted) setState(() => _isPressed = false);
            },
            onPointerCancel: (_) {
              if (mounted) setState(() => _isPressed = false);
            },
            child: AnimatedScale(
              scale: _isPressed ? 0.88 : 1.0,
              duration: AppSpacing.pressAnim,
              curve: AppSpacing.smoothCurve,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.buttonBackgroundColor?.withValues(
                        alpha: _isPressed ? 0.18 : 0.11,
                      ) ??
                      tokens.textPrimary.withValues(
                        alpha: _isPressed ? 0.10 : 0.04,
                      ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: TackIcon(
                  widget.icon,
                  size: widget.size * 0.55,
                  color: defaultIconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

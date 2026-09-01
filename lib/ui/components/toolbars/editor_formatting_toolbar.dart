import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Keyboard-docked formatting toolbar matching Screenshot 2.
/// Includes Bold, Italic, Underline, Strikethrough, Bullet List, Numbered List, Checkbox, Link, Image, and Quote.
class EditorFormattingToolbar extends StatelessWidget {
  final Function(String action)? onFormatAction;

  const EditorFormattingToolbar({super.key, this.onFormatAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tools = [
      (icon: Icons.format_bold_rounded, label: 'Bold', action: 'bold'),
      (icon: Icons.format_italic_rounded, label: 'Italic', action: 'italic'),
      (icon: Icons.format_underlined_rounded, label: 'Underline', action: 'underline'),
      (icon: Icons.format_strikethrough_rounded, label: 'Strikethrough', action: 'strikethrough'),
      (icon: null, label: '|', action: 'divider'),
      (icon: Icons.format_list_bulleted_rounded, label: 'Bullet List', action: 'bullet'),
      (icon: Icons.format_list_numbered_rounded, label: 'Numbered List', action: 'numbered'),
      (icon: Icons.check_box_outlined, label: 'Checkbox', action: 'checkbox'),
      (icon: null, label: '|', action: 'divider'),
      (icon: Icons.link_rounded, label: 'Link', action: 'link'),
      (icon: Icons.image_outlined, label: 'Image', action: 'image'),
      (icon: Icons.format_quote_rounded, label: 'Quote', action: 'quote'),
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: AppSpacing.floatingControlShadow,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final item = tools[index];

          if (item.action == 'divider') {
            return Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            );
          }

          return IconButton(
            icon: Icon(
              item.icon,
              size: 20,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            tooltip: item.label,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            onPressed: () {
              HapticFeedback.selectionClick();
              onFormatAction?.call(item.action);
            },
          );
        },
      ),
    );
  }
}

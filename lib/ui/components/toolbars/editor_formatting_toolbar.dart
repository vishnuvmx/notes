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

          return _ToolbarButton(
            icon: item.icon!,
            label: item.label,
            isDark: isDark,
            onTap: () => onFormatAction?.call(item.action),
          );
        },
      ),
    );
  }
}

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          setState(() => _pressed = true);
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.84 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _pressed
                  ? (widget.isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

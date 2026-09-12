import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/tack_icons.dart';

/// Supported item types in the formatting toolbar using OOP sealed hierarchy.
sealed class ToolbarActionItem {
  final String label;
  final String action;
  const ToolbarActionItem({required this.label, required this.action});
}

class IconToolbarItem extends ToolbarActionItem {
  final IconData icon;
  const IconToolbarItem({required super.label, required super.action, required this.icon});
}

class TextToolbarItem extends ToolbarActionItem {
  final String display;
  final TextStyle? customStyle;
  const TextToolbarItem({
    required super.label,
    required super.action,
    required this.display,
    this.customStyle,
  });
}

class DividerToolbarItem extends ToolbarActionItem {
  const DividerToolbarItem() : super(label: '', action: 'divider');
}

/// Tactile, HeroIcons-aligned formatting toolbar for Tack Note Editor.
/// Features Heading toggles (H1, H2), Bold, Italic, Pastel Highlighter,
/// Checklists, Lists, and Quotes without any generic Material icons.
class EditorFormattingToolbar extends StatelessWidget {
  final Function(String action)? onFormatAction;

  const EditorFormattingToolbar({super.key, this.onFormatAction});

  static const List<ToolbarActionItem> tools = [
    TextToolbarItem(
      label: 'Heading 1',
      action: 'h1',
      display: 'H1',
      customStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.5),
    ),
    TextToolbarItem(
      label: 'Heading 2',
      action: 'h2',
      display: 'H2',
      customStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.5),
    ),
    DividerToolbarItem(),
    TextToolbarItem(
      label: 'Bold',
      action: 'bold',
      display: 'B',
      customStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, fontFamily: 'serif'),
    ),
    TextToolbarItem(
      label: 'Italic',
      action: 'italic',
      display: 'I',
      customStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, fontStyle: FontStyle.italic, fontFamily: 'serif'),
    ),
    TextToolbarItem(
      label: 'Underline',
      action: 'underline',
      display: 'U',
      customStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, decoration: TextDecoration.underline, fontFamily: 'serif'),
    ),
    TextToolbarItem(
      label: 'Strikethrough',
      action: 'strikethrough',
      display: 'S',
      customStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, decoration: TextDecoration.lineThrough, fontFamily: 'serif'),
    ),
    TextToolbarItem(
      label: 'Highlight',
      action: 'highlight',
      display: 'HL',
      customStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 11,
        color: Color(0xFF5A4112),
        backgroundColor: Color(0xFFFFC661),
      ),
    ),
    DividerToolbarItem(),
    IconToolbarItem(label: 'Checkbox', action: 'checkbox', icon: TackIcons.checkCircle),
    IconToolbarItem(label: 'Bullet List', action: 'bullet', icon: TackIcons.menu),
    IconToolbarItem(label: 'Numbered List', action: 'numbered', icon: TackIcons.listView),
    DividerToolbarItem(),
    TextToolbarItem(
      label: 'Quote',
      action: 'quote',
      display: '”',
      customStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, height: 1.0, fontFamily: 'serif'),
    ),
    IconToolbarItem(label: 'Image', action: 'image', icon: TackIcons.photo),
    DividerToolbarItem(),
    IconToolbarItem(label: 'Smart Actions', action: 'smart_actions', icon: TackIcons.bolt),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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

          if (item is DividerToolbarItem) {
            return Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            );
          }

          return Tooltip(
            message: item.label,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onFormatAction?.call(item.action);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    child: switch (item) {
                      IconToolbarItem iconItem => TackIcon(
                          iconItem.icon,
                          size: 19,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      TextToolbarItem textItem => Text(
                          textItem.display,
                          style: (textItem.customStyle ?? const TextStyle()).copyWith(
                            color: textItem.action == 'highlight'
                                ? (isDark ? Colors.black : const Color(0xFF5A4112))
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ),
                      DividerToolbarItem() => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

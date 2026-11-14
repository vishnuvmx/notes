import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// Supported item types in the formatting toolbar using OOP sealed hierarchy.
sealed class ToolbarActionItem {
  final String label;
  final String action;
  const ToolbarActionItem({required this.label, required this.action});
}

class IconToolbarItem extends ToolbarActionItem {
  final dynamic icon;
  const IconToolbarItem({
    required super.label,
    required super.action,
    required this.icon,
  });
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

/// Keyboard-docked formatting toolbar for Tack Note Editor (`04` M6, `07` §7).
///
/// Consolidates `/` and `⇄` into a single **Insert & Transform (`/`)** button,
/// and provides `[[` wiki-link, task `- [ ]`, headings, inline styles, table,
/// diagram, callout, and image triggers with accessible touch targets.
class EditorFormattingToolbar extends StatelessWidget {
  final void Function(String action)? onFormatAction;

  const EditorFormattingToolbar({super.key, this.onFormatAction});

  static const List<ToolbarActionItem> tools = [
    TextToolbarItem(
      label: 'Insert & Transform (/)',
      action: 'slash',
      display: '/',
      customStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    ),
    TextToolbarItem(
      label: 'Link Note or Board [[',
      action: 'wikilink',
      display: '[[',
      customStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: -0.8,
      ),
    ),
    IconToolbarItem(
      label: 'Task Checkbox',
      action: 'checkbox',
      icon: TackIcons.checkCircle,
    ),
    DividerToolbarItem(),
    TextToolbarItem(
      label: 'Heading 1',
      action: 'h1',
      display: 'H1',
      customStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: -0.4,
      ),
    ),
    TextToolbarItem(
      label: 'Heading 2',
      action: 'h2',
      display: 'H2',
      customStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        letterSpacing: -0.4,
      ),
    ),
    DividerToolbarItem(),
    TextToolbarItem(
      label: 'Bold',
      action: 'bold',
      display: 'B',
      customStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        fontFamily: 'serif',
      ),
    ),
    TextToolbarItem(
      label: 'Italic',
      action: 'italic',
      display: 'I',
      customStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        fontStyle: FontStyle.italic,
        fontFamily: 'serif',
      ),
    ),
    TextToolbarItem(
      label: 'Strikethrough',
      action: 'strikethrough',
      display: 'S',
      customStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        decoration: TextDecoration.lineThrough,
        fontFamily: 'serif',
      ),
    ),
    TextToolbarItem(
      label: 'Highlight',
      action: 'highlight',
      display: 'HL',
      customStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 11,
        color: AppColors.lightTextPrimary,
        backgroundColor: AppColors.objectAmber,
      ),
    ),
    DividerToolbarItem(),
    IconToolbarItem(
      label: 'Bullet List',
      action: 'bullet',
      icon: TackIcons.menu,
    ),
    IconToolbarItem(
      label: 'Numbered List',
      action: 'numbered',
      icon: TackIcons.listView,
    ),
    TextToolbarItem(
      label: 'Quote',
      action: 'quote',
      display: '”',
      customStyle: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 20,
        height: 1.0,
        fontFamily: 'serif',
      ),
    ),
    TextToolbarItem(
      label: 'Table',
      action: 'table',
      display: '⊞',
      customStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 1.0,
      ),
    ),
    IconToolbarItem(
      label: 'Diagram / Flowchart',
      action: 'diagram',
      icon: TackIcons.flow,
    ),
    IconToolbarItem(
      label: 'Callout Block',
      action: 'alert',
      icon: TackIcons.alert,
    ),
    IconToolbarItem(
      label: 'Image',
      action: 'image',
      icon: TackIcons.imageSvg,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      height: AppSpacing.minTouchTarget,
      decoration: BoxDecoration(
        color: tokens.surfacePrimary,
        border: Border(
          top: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final item = tools[index];

          if (item is DividerToolbarItem) {
            return Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s1,
                vertical: 14,
              ),
              color: tokens.borderSubtle,
            );
          }

          final isPrimaryCommand = item.action == 'slash';

          return Tooltip(
            message: item.label,
            child: InkWell(
              borderRadius: AppSpacing.roundedSm,
              onTap: () {
                HapticFeedback.selectionClick();
                onFormatAction?.call(item.action);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: AppSpacing.minTouchTarget,
                ),
                child: Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: isPrimaryCommand
                        ? BoxDecoration(
                            color: tokens.canvasSunken,
                            borderRadius: AppSpacing.roundedXs,
                            border: Border.all(
                              color: tokens.borderStrong,
                              width: 1,
                            ),
                          )
                        : null,
                    child: switch (item) {
                      IconToolbarItem iconItem => TackIcon(
                          iconItem.icon,
                          size: 19,
                          color: tokens.textPrimary,
                        ),
                      TextToolbarItem textItem => Text(
                          textItem.display,
                          style: (textItem.customStyle ??
                                  AppTypography.label(color: tokens.textPrimary))
                              .copyWith(
                            color: textItem.action == 'highlight'
                                ? AppColors.lightTextPrimary
                                : tokens.textPrimary,
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

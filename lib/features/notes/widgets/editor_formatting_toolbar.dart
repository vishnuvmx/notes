import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../shared/widgets/tactile_ink_target.dart';

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
  final String? paletteId;

  const EditorFormattingToolbar({
    super.key,
    this.onFormatAction,
    this.paletteId,
  });

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
      customStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
    ),
    TextToolbarItem(
      label: 'Italic',
      action: 'italic',
      display: 'I',
      customStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        fontStyle: FontStyle.italic,
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
      ),
    ),
    TextToolbarItem(
      label: 'Highlight',
      action: 'highlight',
      display: 'HL',
      customStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
    ),
    DividerToolbarItem(),
    IconToolbarItem(
      label: 'Bullet List',
      action: 'bullet',
      icon: TackIcons.bulletList,
    ),
    IconToolbarItem(
      label: 'Numbered List',
      action: 'numbered',
      icon: TackIcons.numberedList,
    ),
    IconToolbarItem(label: 'Quote', action: 'quote', icon: TackIcons.quote),
    IconToolbarItem(label: 'Table', action: 'table', icon: TackIcons.table),
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
    IconToolbarItem(label: 'Image', action: 'image', icon: TackIcons.imageSvg),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(paletteId);
    final accent = palette.resolveAccentColor(tokens.isDark);
    final fg = tokens.textPrimary;

    return Container(
      height: AppSpacing.minTouchTarget,
      decoration: BoxDecoration(
        color: tokens.surfacePrimary,
        border: Border(top: BorderSide(color: tokens.borderSubtle, width: 1)),
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
          final isHighlight = item.action == 'highlight';

          return Semantics(
            button: true,
            label: item.label,
            child: Tooltip(
              message: item.label,
              child: TactileInkTarget(
                borderRadius: AppSpacing.roundedXs,
                width: 34,
                height: 34,
                triggerHaptics: true,
                color: isPrimaryCommand
                    ? tokens.canvasSunken
                    : (isHighlight
                          ? (tokens.isDark
                                ? accent.withValues(alpha: 0.24)
                                : palette.lightColor.withValues(alpha: 0.65))
                          : null),
                border: isPrimaryCommand
                    ? Border.all(color: tokens.borderSubtle, width: 1)
                    : null,
                splashColor: fg.withValues(alpha: 0.10),
                highlightColor: fg.withValues(alpha: 0.06),
                hoverColor: fg.withValues(alpha: 0.05),
                onTap: () => onFormatAction?.call(item.action),
                child: switch (item) {
                  IconToolbarItem iconItem => TackIcon(
                    iconItem.icon,
                    size: 19,
                    color: fg,
                  ),
                  TextToolbarItem textItem => Text(
                    textItem.display,
                    style:
                        (textItem.customStyle ?? AppTypography.label(color: fg))
                            .copyWith(
                              fontFamily: AppTypography.fontFamily,
                              color: isHighlight
                                  ? (tokens.isDark ? accent : fg)
                                  : fg,
                            ),
                  ),
                  DividerToolbarItem() => const SizedBox.shrink(),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

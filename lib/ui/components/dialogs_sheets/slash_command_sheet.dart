import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/services/block_transform_service.dart';
import '../../../domain/services/wiki_link_service.dart';
import '../inputs/app_search_field.dart';
import 'app_bottom_sheet.dart';

/// Definition of a `/` Slash Block Command inspired by Figma Specs & Notion.
class SlashCommandItem {
  final String id;
  final String command; // e.g. 'spec', 'h1', 'todo'
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String? markdownSnippet;

  const SlashCommandItem({
    required this.id,
    required this.command,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.markdownSnippet,
  });
}

class SlashCommandsCatalog {
  SlashCommandsCatalog._();

  static const List<SlashCommandItem> all = [
    SlashCommandItem(
      id: 'todo',
      command: 'todo',
      label: 'To-Do List',
      subtitle: 'Interactive task checkbox',
      icon: LucideIcons.circleCheck,
      accentColor: Color(0xFF10B981),
      markdownSnippet: '- [ ] ',
    ),
    SlashCommandItem(
      id: 'h1',
      command: 'h1',
      label: 'Heading 1',
      subtitle: 'Big section heading',
      icon: LucideIcons.heading1,
      accentColor: Color(0xFFFF8F6B),
      markdownSnippet: '# ',
    ),
    SlashCommandItem(
      id: 'h2',
      command: 'h2',
      label: 'Heading 2',
      subtitle: 'Medium section heading',
      icon: LucideIcons.heading2,
      accentColor: Color(0xFFF5B842),
      markdownSnippet: '## ',
    ),
    SlashCommandItem(
      id: 'h3',
      command: 'h3',
      label: 'Heading 3',
      subtitle: 'Compact sub-heading',
      icon: LucideIcons.heading3,
      accentColor: Color(0xFF9D84D6),
      markdownSnippet: '### ',
    ),
    SlashCommandItem(
      id: 'spec',
      command: 'spec',
      label: 'Spec Brief',
      subtitle: 'Figma Specs-style structured PRD outline',
      icon: LucideIcons.fileCheck2,
      accentColor: Color(0xFF1BA5BA),
      markdownSnippet:
          '## Overview\nWrite the core problem & goal here.\n\n'
          '## Requirements\n- [ ] Core flow requirement\n- [ ] Edge cases & states\n\n'
          '> [!IMPORTANT]\n> Key design or technical constraint.\n',
    ),
    SlashCommandItem(
      id: 'link',
      command: 'link',
      label: 'Link Note [[',
      subtitle: 'Connect another note or board',
      icon: LucideIcons.link2,
      accentColor: Color(0xFF0284C7),
      markdownSnippet: '[[',
    ),
    SlashCommandItem(
      id: 'board',
      command: 'board',
      label: 'Embed Whiteboard',
      subtitle: 'Live canvas preview inside note',
      icon: LucideIcons.workflow,
      accentColor: Color(0xFF7C3AED),
    ),
    SlashCommandItem(
      id: 'bullet',
      command: 'bullet',
      label: 'Bullet List',
      subtitle: 'Simple bulleted items',
      icon: LucideIcons.list,
      accentColor: Color(0xFFF59E0B),
      markdownSnippet: '- ',
    ),
    SlashCommandItem(
      id: 'numbered',
      command: 'num',
      label: 'Numbered List',
      subtitle: 'Ordered sequence 1, 2, 3...',
      icon: LucideIcons.listOrdered,
      accentColor: Color(0xFFF59E0B),
      markdownSnippet: '1. ',
    ),
    SlashCommandItem(
      id: 'toggle',
      command: 'toggle',
      label: 'Toggle List',
      subtitle: 'Collapsible disclosure section',
      icon: LucideIcons.chevronRight,
      accentColor: Color(0xFF14B8A6),
      markdownSnippet: '>▸ Toggle heading\n> Hidden details...\n',
    ),
    SlashCommandItem(
      id: 'toc',
      command: 'toc',
      label: 'Table of Contents',
      subtitle: 'Auto-synced [TOC] outline block',
      icon: LucideIcons.listTree,
      accentColor: Color(0xFF0EA5E9),
      markdownSnippet: '[TOC]\n',
    ),
    SlashCommandItem(
      id: 'callout',
      command: 'callout',
      label: 'Callout Box',
      subtitle: 'Highlighted [!NOTE] box',
      icon: LucideIcons.info,
      accentColor: Color(0xFF0284C7),
      markdownSnippet: '> [!NOTE]\n> ',
    ),
    SlashCommandItem(
      id: 'code',
      command: 'code',
      label: 'Code Block',
      subtitle: 'Syntax-highlighted code snippet',
      icon: LucideIcons.code,
      accentColor: Color(0xFF6366F1),
      markdownSnippet: '```dart\n\n```',
    ),
    SlashCommandItem(
      id: 'table',
      command: 'table',
      label: 'Table',
      subtitle: '3-column Markdown table',
      icon: LucideIcons.table,
      accentColor: Color(0xFFEC4899),
      markdownSnippet:
          '| Column 1 | Column 2 | Column 3 |\n| :--- | :--- | :--- |\n| Item | Detail | Status |\n',
    ),
    SlashCommandItem(
      id: 'diagram',
      command: 'diagram',
      label: 'Flowchart Diagram',
      subtitle: 'Native Mermaid diagram block',
      icon: LucideIcons.gitFork,
      accentColor: Color(0xFF14B8A6),
    ),
    SlashCommandItem(
      id: 'quote',
      command: 'quote',
      label: 'Quote',
      subtitle: 'Indented blockquote',
      icon: LucideIcons.quote,
      accentColor: Color(0xFF8B5CF6),
      markdownSnippet: '> ',
    ),
    SlashCommandItem(
      id: 'divider',
      command: 'divider',
      label: 'Divider',
      subtitle: 'Visual section separator (---)',
      icon: LucideIcons.minus,
      accentColor: Color(0xFF64748B),
      markdownSnippet: '---\n',
    ),
  ];

  static List<SlashCommandItem> filter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((item) {
      return item.command.contains(q) ||
          item.label.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q);
    }).toList();
  }
}

/// Non-intrusive keyboard-docked bar shown automatically when typing `/...` at line start.
class SlashCommandInlineBar extends StatelessWidget {
  final ActiveSlashTrigger trigger;
  final ValueChanged<SlashCommandItem> onSelectCommand;
  final VoidCallback onOpenFullSheet;

  const SlashCommandInlineBar({
    super.key,
    required this.trigger,
    required this.onSelectCommand,
    required this.onOpenFullSheet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matches = SlashCommandsCatalog.filter(trigger.query);
    if (matches.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: AppSpacing.floatingControlShadow,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onOpenFullSheet,
            borderRadius: AppSpacing.roundedPill,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentAmber.withValues(alpha: 0.18),
                borderRadius: AppSpacing.roundedPill,
              ),
              child: Text(
                '/${trigger.query}',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.pastelAmberLight : const Color(0xFF191A23),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: matches.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final cmd = matches[index];
                return Center(
                  child: Material(
                    color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF3F5F8),
                    borderRadius: AppSpacing.roundedPill,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelectCommand(cmd);
                      },
                      borderRadius: AppSpacing.roundedPill,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cmd.icon, size: 14, color: cmd.accentColor),
                            const SizedBox(width: 6),
                            Text(
                              cmd.label,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified Bottom Sheet for Slash (`/`) Insert Blocks + Figma-Specs / Notion "Turn Into" & Line Moves.
class SlashAndBlockActionsSheet extends StatefulWidget {
  final BlockKind currentBlockKind;
  final ValueChanged<SlashCommandItem> onInsertCommand;
  final ValueChanged<BlockKind> onTurnInto;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDuplicateBlock;
  final bool startOnTurnIntoTab;

  const SlashAndBlockActionsSheet({
    super.key,
    required this.currentBlockKind,
    required this.onInsertCommand,
    required this.onTurnInto,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDuplicateBlock,
    this.startOnTurnIntoTab = false,
  });

  static Future<void> show(
    BuildContext context, {
    required BlockKind currentBlockKind,
    required ValueChanged<SlashCommandItem> onInsertCommand,
    required ValueChanged<BlockKind> onTurnInto,
    required VoidCallback onMoveUp,
    required VoidCallback onMoveDown,
    required VoidCallback onDuplicateBlock,
    bool startOnTurnIntoTab = false,
  }) {
    HapticFeedback.lightImpact();
    return AppBottomSheet.show(
      context: context,
      maxHeightFactor: 0.85,
      builder: (_) => SlashAndBlockActionsSheet(
        currentBlockKind: currentBlockKind,
        onInsertCommand: onInsertCommand,
        onTurnInto: onTurnInto,
        onMoveUp: onMoveUp,
        onMoveDown: onMoveDown,
        onDuplicateBlock: onDuplicateBlock,
        startOnTurnIntoTab: startOnTurnIntoTab,
      ),
    );
  }

  @override
  State<SlashAndBlockActionsSheet> createState() => _SlashAndBlockActionsSheetState();
}

class _SlashAndBlockActionsSheetState extends State<SlashAndBlockActionsSheet> {
  final TextEditingController _searchController = TextEditingController();
  late bool _showTurnInto;

  @override
  void initState() {
    super.initState();
    _showTurnInto = widget.startOnTurnIntoTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredCommands = SlashCommandsCatalog.filter(_searchController.text);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Mobile Line Actions Row (Move Up, Move Down, Duplicate)
            Row(
              children: [
                _buildQuickActionPill(
                  isDark: isDark,
                  icon: LucideIcons.arrowUp,
                  label: 'Move Up',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onMoveUp();
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickActionPill(
                  isDark: isDark,
                  icon: LucideIcons.arrowDown,
                  label: 'Move Down',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onMoveDown();
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickActionPill(
                  isDark: isDark,
                  icon: LucideIcons.copyPlus,
                  label: 'Duplicate',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    widget.onDuplicateBlock();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mode Switcher: Slash Insert (/) vs Turn Block Into (⇄)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF1F3F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      label: '/ Insert Block',
                      selected: !_showTurnInto,
                      isDark: isDark,
                      onTap: () => setState(() => _showTurnInto = false),
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      label: 'Turn Line Into',
                      selected: _showTurnInto,
                      isDark: isDark,
                      onTap: () => setState(() => _showTurnInto = true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (!_showTurnInto) ...[
              // Filter Search Input
              AppSearchField(
                controller: _searchController,
                hintText: 'Filter blocks (e.g. spec, board, todo, table)...',
                onChanged: (_) => setState(() {}),
                onClear: () => setState(() {}),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredCommands.length,
                  itemBuilder: (context, index) {
                    final cmd = filteredCommands[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cmd.accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(cmd.icon, size: 18, color: cmd.accentColor),
                      ),
                      title: Text(
                        cmd.label,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      subtitle: Text(
                        cmd.subtitle,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      trailing: Text(
                        '/${cmd.command}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                        widget.onInsertCommand(cmd);
                      },
                    );
                  },
                ),
              ),
            ] else ...[
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final kind in BlockKind.values)
                      ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        selected: kind == widget.currentBlockKind,
                        leading: Icon(
                          _iconForBlockKind(kind),
                          size: 18,
                          color: kind == widget.currentBlockKind
                              ? AppColors.accentAmber
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        title: Text(
                          kind.label,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            fontWeight: kind == widget.currentBlockKind ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          kind.subtitle,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        trailing: kind == widget.currentBlockKind
                            ? const TackIcon(TackIcons.checkCircle, size: 17, color: AppColors.accentAmber)
                            : null,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                          widget.onTurnInto(kind);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
  }

  Widget _buildQuickActionPill({
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: isDark ? Colors.white : const Color(0xFF191A23)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : const Color(0xFF191A23),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? (isDark ? AppColors.darkCard : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: -0.2,
              color: selected
                  ? (isDark ? Colors.white : const Color(0xFF191A23))
                  : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForBlockKind(BlockKind kind) {
    switch (kind) {
      case BlockKind.paragraph:
        return LucideIcons.pilcrow;
      case BlockKind.h1:
        return LucideIcons.heading1;
      case BlockKind.h2:
        return LucideIcons.heading2;
      case BlockKind.h3:
        return LucideIcons.heading3;
      case BlockKind.todo:
        return LucideIcons.circleCheck;
      case BlockKind.bullet:
        return LucideIcons.list;
      case BlockKind.numbered:
        return LucideIcons.listOrdered;
      case BlockKind.quote:
        return LucideIcons.quote;
      case BlockKind.toggle:
        return LucideIcons.chevronRight;
      case BlockKind.calloutNote:
        return LucideIcons.info;
      case BlockKind.calloutTip:
        return LucideIcons.lightbulb;
      case BlockKind.calloutWarning:
        return LucideIcons.triangleAlert;
    }
  }
}


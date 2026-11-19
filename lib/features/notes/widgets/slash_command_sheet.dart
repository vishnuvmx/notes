import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/sliding_pill_track.dart';
import '../services/block_transform_service.dart';
import '../services/wiki_link_service.dart';

enum SlashCommandGroup {
  writing('WRITING'),
  structure('STRUCTURE & MEDIA'),
  workspace('WORKSPACE');

  final String header;
  const SlashCommandGroup(this.header);
}

/// Definition of a `/` Slash Block Command.
class SlashCommandItem {
  final String id;
  final String command; // e.g. 'spec', 'h1', 'todo'
  final String label;
  final String subtitle;
  final TackGlyph icon;
  final SlashCommandGroup group;
  final String? markdownSnippet;

  const SlashCommandItem({
    required this.id,
    required this.command,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.group,
    this.markdownSnippet,
  });
}

class SlashCommandsCatalog {
  SlashCommandsCatalog._();

  static const List<SlashCommandItem> all = [
    // Writing
    SlashCommandItem(
      id: 'todo',
      command: 'todo',
      label: 'To-Do',
      subtitle: 'Interactive checklist item',
      icon: TackIcons.taskOpen,
      group: SlashCommandGroup.writing,
      markdownSnippet: '- [ ] ',
    ),
    SlashCommandItem(
      id: 'due_task',
      command: 'due',
      label: 'Scheduled Task',
      subtitle: 'Task with @due reminder & repeat',
      icon: TackIcons.notification,
      group: SlashCommandGroup.writing,
    ),
    SlashCommandItem(
      id: 'h1',
      command: 'h1',
      label: 'Heading 1',
      subtitle: 'Large section title',
      icon: TackIcons.heading1,
      group: SlashCommandGroup.writing,
      markdownSnippet: '# ',
    ),
    SlashCommandItem(
      id: 'h2',
      command: 'h2',
      label: 'Heading 2',
      subtitle: 'Medium section heading',
      icon: TackIcons.heading2,
      group: SlashCommandGroup.writing,
      markdownSnippet: '## ',
    ),
    SlashCommandItem(
      id: 'h3',
      command: 'h3',
      label: 'Heading 3',
      subtitle: 'Compact sub-heading',
      icon: TackIcons.heading3,
      group: SlashCommandGroup.writing,
      markdownSnippet: '### ',
    ),
    SlashCommandItem(
      id: 'bullet',
      command: 'bullet',
      label: 'Bullet List',
      subtitle: 'Bulleted list item',
      icon: TackIcons.bulletList,
      group: SlashCommandGroup.writing,
      markdownSnippet: '- ',
    ),
    SlashCommandItem(
      id: 'numbered',
      command: 'num',
      label: 'Numbered List',
      subtitle: 'Ordered list step',
      icon: TackIcons.numberedList,
      group: SlashCommandGroup.writing,
      markdownSnippet: '1. ',
    ),
    SlashCommandItem(
      id: 'toggle',
      command: 'toggle',
      label: 'Toggle Section',
      subtitle: 'Collapsible >▸ block',
      icon: TackIcons.chevronRight,
      group: SlashCommandGroup.writing,
      markdownSnippet: '>▸ Toggle heading\n> Hidden details...\n',
    ),

    // Structure & Media
    SlashCommandItem(
      id: 'spec',
      command: 'spec',
      label: 'Spec Brief',
      subtitle: 'PRD scaffold with checklist & callout',
      icon: TackIcons.notes,
      group: SlashCommandGroup.structure,
      markdownSnippet:
          '## Overview\nWrite the core problem & goal here.\n\n'
          '## Requirements\n- [ ] Core flow requirement\n- [ ] Edge cases & states\n\n'
          '> [!IMPORTANT]\n> Key design or technical constraint.\n',
    ),
    SlashCommandItem(
      id: 'table',
      command: 'table',
      label: 'Table',
      subtitle: '3-column editable Markdown table',
      icon: TackIcons.table,
      group: SlashCommandGroup.structure,
      markdownSnippet: '| Column 1 | Column 2 | Column 3 |\n| :--- | :--- | :--- |\n| Item | Detail | Status |\n',
    ),
    SlashCommandItem(
      id: 'diagram',
      command: 'diagram',
      label: 'Flowchart',
      subtitle: 'Mermaid diagram card',
      icon: TackIcons.flow,
      group: SlashCommandGroup.structure,
    ),
    SlashCommandItem(
      id: 'callout',
      command: 'callout',
      label: 'Callout',
      subtitle: 'Highlighted [!NOTE] box',
      icon: TackIcons.info,
      group: SlashCommandGroup.structure,
      markdownSnippet: '> [!NOTE]\n> ',
    ),
    SlashCommandItem(
      id: 'code',
      command: 'code',
      label: 'Code Block',
      subtitle: 'Fenced snippet with copy button',
      icon: TackIcons.code,
      group: SlashCommandGroup.structure,
      markdownSnippet: '```dart\n\n```',
    ),
    SlashCommandItem(
      id: 'quote',
      command: 'quote',
      label: 'Blockquote',
      subtitle: 'Indented pull quote',
      icon: TackIcons.quote,
      group: SlashCommandGroup.structure,
      markdownSnippet: '> ',
    ),
    SlashCommandItem(
      id: 'divider',
      command: 'divider',
      label: 'Divider',
      subtitle: 'Horizontal rule (---)',
      icon: TackIcons.minus,
      group: SlashCommandGroup.structure,
      markdownSnippet: '---\n',
    ),

    // Workspace
    SlashCommandItem(
      id: 'toc',
      command: 'toc',
      label: 'Table of Contents',
      subtitle: 'Auto-synced [TOC] jump card',
      icon: TackIcons.nestedList,
      group: SlashCommandGroup.workspace,
      markdownSnippet: '[TOC]\n',
    ),
    SlashCommandItem(
      id: 'link',
      command: 'link',
      label: 'Link Note',
      subtitle: 'WikiLink [[...]] reference',
      icon: TackIcons.link,
      group: SlashCommandGroup.workspace,
      markdownSnippet: '[[',
    ),
    SlashCommandItem(
      id: 'board',
      command: 'board',
      label: 'Embed Board',
      subtitle: 'Live canvas preview inside note',
      icon: TackIcons.workflow,
      group: SlashCommandGroup.workspace,
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
  final String? paletteId;
  final ValueChanged<SlashCommandItem> onSelectCommand;
  final VoidCallback onOpenFullSheet;

  const SlashCommandInlineBar({
    super.key,
    required this.trigger,
    this.paletteId,
    required this.onSelectCommand,
    required this.onOpenFullSheet,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final matches = SlashCommandsCatalog.filter(trigger.query);
    if (matches.isEmpty) return const SizedBox.shrink();

    final palette = paletteId != null
        ? AppColors.getPaletteById(paletteId)
        : null;
    final chipAccent =
        palette?.resolveAccentColor(tokens.isDark) ?? tokens.accentPinText;
    final chipBg =
        palette?.resolveChipFill(tokens.isDark) ??
        tokens.accentPin.withValues(alpha: tokens.isDark ? 0.18 : 0.12);

    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 3,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(color: tokens.borderSubtle),
        boxShadow: AppSpacing.elev2(tokens.isDark),
      ),
      child: Row(
        children: [
          Tooltip(
            message: 'Browse all commands',
            child: Material(
              color: chipBg,
              borderRadius: AppSpacing.roundedPill,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onOpenFullSheet,
                borderRadius: AppSpacing.roundedPill,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 112,
                    minHeight: 36,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        '/${trigger.query}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          fontSize: 12,
                          weight: FontWeight.w700,
                          color: chipAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: matches.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final cmd = matches[index];
                  return Center(
                    child: Material(
                      color: tokens.canvasSunken,
                      borderRadius: AppSpacing.roundedPill,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelectCommand(cmd);
                        },
                        borderRadius: AppSpacing.roundedPill,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TackIcon(
                                cmd.icon,
                                size: 14,
                                color: tokens.textPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cmd.label,
                                style: AppTypography.caption(
                                  fontSize: 12,
                                  color: tokens.textPrimary,
                                  weight: FontWeight.w600,
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
          ),
        ],
      ),
    );
  }
}

/// Unified Paper & Pin bottom sheet for inserting blocks (`/`) and transforming
/// or reordering the current line.
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
  State<SlashAndBlockActionsSheet> createState() =>
      _SlashAndBlockActionsSheetState();
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
    final tokens = context.tokens;
    final query = _searchController.text;
    final filteredCommands = SlashCommandsCatalog.filter(query);

    return Padding(
      padding: AppSpacing.modalSheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Editorial Header Row + Close
          Row(
            children: [
              Expanded(
                child: Text(
                  _showTurnInto ? 'Transform block' : 'Insert block',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSm(
                    color: tokens.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              if (_showTurnInto) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 132),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s2 + 2,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.canvasSunken,
                      borderRadius: AppSpacing.roundedPill,
                    ),
                    child: Text(
                      widget.currentBlockKind.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(
                        color: tokens.textSecondary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s1),
              ],
              IconButton(
                tooltip: 'Close',
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.minTouchTarget,
                  minHeight: AppSpacing.minTouchTarget,
                ),
                icon: TackIcon(
                  TackIcons.close,
                  size: 18,
                  color: tokens.textSecondary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s2),

          // 2. Gliding Black-Pill Switcher (`Insert` · `Transform`)
          SlidingPillTrack(
            itemCount: 2,
            selectedIndex: _showTurnInto ? 1 : 0,
            trackColor: tokens.canvasSunken,
            indicatorColor: tokens.actionPrimary,
            children: [
              _ModeSegmentPill(
                icon: TackIcons.plus,
                label: 'Insert',
                selected: !_showTurnInto,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showTurnInto = false);
                },
              ),
              _ModeSegmentPill(
                icon: TackIcons.arrowLeftRight,
                label: 'Transform',
                selected: _showTurnInto,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showTurnInto = true);
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s4),

          // 3. Smooth 120Hz Mode Content
          Flexible(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              reverseDuration: const Duration(milliseconds: 180),
              curve: AppSpacing.silky120Hz,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                reverseDuration: const Duration(milliseconds: 140),
                switchInCurve: AppSpacing.silky120Hz,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previousChildren, ?currentChild],
                ),
                transitionBuilder: (child, animation) {
                  final isInsert = child.key == const ValueKey('sheet_insert');
                  final slide = Tween<Offset>(
                    begin: Offset(isInsert ? -0.045 : 0.045, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slide,
                      child: RepaintBoundary(child: child),
                    ),
                  );
                },
                child: !_showTurnInto
                    ? _buildInsertTab(tokens, query, filteredCommands)
                    : _buildTransformTab(tokens),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsertTab(
    TackTokens tokens,
    String query,
    List<SlashCommandItem> filteredCommands,
  ) {
    final isFiltering = query.trim().isNotEmpty;

    return Column(
      key: const ValueKey('sheet_insert'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchField(
          controller: _searchController,
          hintText: 'Filter blocks or /command…',
          onChanged: (_) => setState(() {}),
          onClear: () => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.s3),
        Flexible(
          child: filteredCommands.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s6,
                      horizontal: AppSpacing.s4,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TackIcon(
                          TackIcons.search,
                          size: 24,
                          color: tokens.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          'No blocks match "${query.trim()}"',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm(
                            color: tokens.textSecondary,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(
                              0,
                              AppSpacing.minTouchTarget,
                            ),
                          ),
                          onPressed: () =>
                              setState(() => _searchController.clear()),
                          child: const Text('Clear search'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: isFiltering
                      ? [
                          _GroupedCommandListCard(
                            commands: filteredCommands,
                            onSelect: _selectInsertCommand,
                          ),
                        ]
                      : [
                          for (final group in SlashCommandGroup.values) ...[
                            _SectionCaption(group.header),
                            const SizedBox(height: AppSpacing.s2),
                            _GroupedCommandListCard(
                              commands: filteredCommands
                                  .where((c) => c.group == group)
                                  .toList(),
                              onSelect: _selectInsertCommand,
                            ),
                            const SizedBox(height: AppSpacing.s4),
                          ],
                        ],
                ),
        ),
      ],
    );
  }

  void _selectInsertCommand(SlashCommandItem cmd) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    widget.onInsertCommand(cmd);
  }

  Widget _buildTransformTab(TackTokens tokens) {
    return ListView(
      key: const ValueKey('sheet_transform'),
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      children: [
        // Line reorder / duplicate bar
        Container(
          decoration: ShapeDecoration(
            color: tokens.canvasSunken.withValues(alpha: 0.7),
            shape: SmoothRectangleBorder(
              borderRadius: AppSpacing.roundedMd,
              smoothness: AppSpacing.defaultSmoothing,
              side: BorderSide(color: tokens.borderSubtle, width: 1),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              children: [
                _ReorderSegmentButton(
                  icon: TackIcons.arrowUp,
                  label: 'Move up',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onMoveUp();
                  },
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: tokens.borderSubtle,
                ),
                _ReorderSegmentButton(
                  icon: TackIcons.arrowDown,
                  label: 'Move down',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onMoveDown();
                  },
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: tokens.borderSubtle,
                ),
                _ReorderSegmentButton(
                  icon: TackIcons.add,
                  label: 'Duplicate',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    widget.onDuplicateBlock();
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.s4),
        const _SectionCaption('CONVERT LINE TO'),
        const SizedBox(height: AppSpacing.s2),

        // Compact 2-column grid of block conversion options
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - AppSpacing.s2) / 2;
            return Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                for (final kind in BlockKind.values)
                  SizedBox(
                    width: tileWidth,
                    child: _TransformBlockTile(
                      kind: kind,
                      icon: _iconForBlockKind(kind),
                      isSelected: kind == widget.currentBlockKind,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                        widget.onTurnInto(kind);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.s2),
      ],
    );
  }

  TackGlyph _iconForBlockKind(BlockKind kind) {
    switch (kind) {
      case BlockKind.paragraph:
        return TackIcons.paragraph;
      case BlockKind.h1:
        return TackIcons.heading1;
      case BlockKind.h2:
        return TackIcons.heading2;
      case BlockKind.h3:
        return TackIcons.heading3;
      case BlockKind.todo:
        return TackIcons.taskOpen;
      case BlockKind.bullet:
        return TackIcons.bulletList;
      case BlockKind.numbered:
        return TackIcons.numberedList;
      case BlockKind.quote:
        return TackIcons.quote;
      case BlockKind.toggle:
        return TackIcons.chevronRight;
      case BlockKind.calloutNote:
        return TackIcons.info;
      case BlockKind.calloutTip:
        return TackIcons.lightbulb;
      case BlockKind.calloutWarning:
        return TackIcons.warning;
    }
  }
}

class _ModeSegmentPill extends StatelessWidget {
  final TackGlyph icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeSegmentPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fg = selected ? tokens.actionPrimaryFg : tokens.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.s2,
              horizontal: AppSpacing.s2,
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: AppTypography.caption(
                color: fg,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Builder(
                builder: (context) {
                  final syncedFg =
                      DefaultTextStyle.of(context).style.color ?? fg;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TackIcon(icon, size: 14, color: syncedFg),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCaption extends StatelessWidget {
  final String text;

  const _SectionCaption(this.text);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: AppTypography.caption(
          fontSize: 11,
          weight: FontWeight.w700,
          color: tokens.textTertiary,
        ).copyWith(letterSpacing: 0.4),
      ),
    );
  }
}

class _GroupedCommandListCard extends StatelessWidget {
  final List<SlashCommandItem> commands;
  final ValueChanged<SlashCommandItem> onSelect;

  const _GroupedCommandListCard({
    required this.commands,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (commands.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: ShapeDecoration(
        color: tokens.canvasSunken.withValues(alpha: 0.55),
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          smoothness: AppSpacing.defaultSmoothing,
          side: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < commands.length; i++) ...[
              if (i > 0)
                Divider(height: 1, indent: 52, color: tokens.borderSubtle),
              _CommandOptionRow(
                command: commands[i],
                onTap: () => onSelect(commands[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommandOptionRow extends StatelessWidget {
  final SlashCommandItem command;
  final VoidCallback onTap;

  const _CommandOptionRow({required this.command, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s3,
            vertical: AppSpacing.s2 + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tokens.surfacePrimary,
                  borderRadius: AppSpacing.roundedXs,
                  border: Border.all(color: tokens.borderSubtle, width: 0.9),
                ),
                child: Center(
                  child: TackIcon(
                    command.icon,
                    size: 16,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      command.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm(
                        color: tokens.textPrimary,
                        weight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      command.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(color: tokens.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.surfacePrimary,
                  borderRadius: AppSpacing.roundedXs,
                  border: Border.all(color: tokens.borderSubtle, width: 0.8),
                ),
                child: Text(
                  '/${command.command}',
                  style: AppTypography.caption(
                    fontSize: 11,
                    weight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReorderSegmentButton extends StatelessWidget {
  final TackGlyph icon;
  final String label;
  final VoidCallback onTap;

  const _ReorderSegmentButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TackIcon(icon, size: 15, color: tokens.textPrimary),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(
                        color: tokens.textPrimary,
                        weight: FontWeight.w600,
                      ),
                    ),
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

class _TransformBlockTile extends StatelessWidget {
  final BlockKind kind;
  final TackGlyph icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TransformBlockTile({
    required this.kind,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bgColor = isSelected
        ? tokens.accentPin.withValues(alpha: tokens.isDark ? 0.16 : 0.10)
        : tokens.canvasSunken.withValues(alpha: 0.55);
    final borderColor = isSelected ? tokens.accentPin : tokens.borderSubtle;
    final fgColor = isSelected ? tokens.accentPinText : tokens.textPrimary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: kind.label,
      child: Material(
        color: bgColor,
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedSm,
          smoothness: AppSpacing.defaultSmoothing,
          side: BorderSide(color: borderColor, width: isSelected ? 1.4 : 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s3,
                vertical: AppSpacing.s2,
              ),
              child: Row(
                children: [
                  TackIcon(icon, size: 16, color: fgColor),
                  const SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: Text(
                      kind.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm(
                        color: fgColor,
                        weight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isSelected)
                    TackIcon(
                      TackIcons.check,
                      size: 14,
                      color: tokens.accentPin,
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

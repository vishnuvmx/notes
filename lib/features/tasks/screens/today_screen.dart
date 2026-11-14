import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/base_item.dart';
import '../../notes/models/text_note.dart';
import '../../whiteboard/models/whiteboard_item.dart';
import '../services/open_tasks_service.dart';
import '../../../shared/providers/workspace_provider.dart';
import '../../whiteboard/widgets/board_grid_card.dart';
import '../../../shared/widgets/neo_note_card.dart';
import '../../../shared/widgets/responsive_card_grid.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/card_peek_sheet.dart';
import '../../../shared/widgets/sliding_pill_track.dart';
import '../../../shared/widgets/z_order_column.dart';
import '../../notes/screens/note_editor_screen.dart';
import '../../whiteboard/screens/whiteboard_canvas_screen.dart';

enum _TodayTaskTab { todo, completed, inbox }

/// The **Today** screen redesigned in Soft Monochrome (`docs/design/11-reference-ui-style.md`, Screenshots 1, 2, 3):
/// 1. **Horizontal Week Strip Card** (`Mon .. Sun` with active day squircle + coral dot)
/// 2. **Today's Daily Note Card** (Joi date header `10 •` + Regent-style soft tinted inner block with 3.5dp bar)
/// 3. **DailyLoop Task & Inbox Card** with Black-Pill Segmented Control (`To do` · `Completed` · `Inbox`),
///    collapsible note group headers (`▾`), square checkboxes, and stacked Inbox triage deck
/// 4. **Pinned** items grid (Notes & Boards)
/// 5. **Worth Revisiting** resurfacing note card
class TodayScreen extends StatefulWidget {
  final void Function(BaseWorkspaceItem item, {bool startInEditMode}) onOpenItem;

  const TodayScreen({
    super.key,
    required this.onOpenItem,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  _TodayTaskTab _activeTab = _TodayTaskTab.todo;
  final Set<String> _collapsedGroups = {};

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final workspace = context.watch<WorkspaceProvider>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gutter = AppSpacing.screenGutter(screenWidth);
    final cols = AppSpacing.gridColumnsForWidth(screenWidth);

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final expectedDailyTitle = 'Daily Note • $dateStr';
    final existingDaily = workspace.allActiveItems
        .whereType<TextNote>()
        .where((n) => !n.isTrash && n.title == expectedDailyTitle)
        .firstOrNull;

    final inbox = workspace.inboxItems;
    final allTasks = OpenTasksService.extractTasks(
      workspace.allActiveItems,
      includeCompleted: true,
    );
    final openTasks = allTasks.where((t) => !t.isDone).toList();
    final completedTasks = allTasks.where((t) => t.isDone).toList();
    final pinned = workspace.pinnedItems;
    final revisitNote = workspace.worthRevisitingNote;

    return CustomScrollView(
      clipBehavior: Clip.none,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.s2,
            gutter,
            AppSpacing.s4,
          ),
          sliver: SliverToBoxAdapter(
            child: ZOrderColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Horizontal Week Strip Card (Screenshot 2)
                _WeekStripCard(
                  now: now,
                  hasDailyNote: existingDaily != null,
                  onTapToday: () async {
                    HapticFeedback.lightImpact();
                    final isNew = existingDaily == null;
                    final note = await workspace.openOrCreateTodaysNote();
                    widget.onOpenItem(note, startInEditMode: isNew);
                  },
                ),

                const SizedBox(height: AppSpacing.s5),

                // 2. Today's Daily Note Hero Card (Screenshot 1 & 3)
                _TodaysDailyNoteCard(
                  now: now,
                  existingDaily: existingDaily,
                  dateLabel: DateFormatter.formatOrdinalDate(now),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final isNew = existingDaily == null;
                    final note = await workspace.openOrCreateTodaysNote();
                    widget.onOpenItem(note, startInEditMode: isNew);
                  },
                ),

                const SizedBox(height: AppSpacing.s5),

                // 3. DailyLoop Segmented Tasks & Inbox Triage Card (Screenshot 2)
                _SegmentedTasksAndInboxCard(
                  activeTab: _activeTab,
                  onSelectTab: (tab) {
                    HapticFeedback.selectionClick();
                    setState(() => _activeTab = tab);
                  },
                  openTasks: openTasks,
                  completedTasks: completedTasks,
                  inboxItems: inbox,
                  collapsedGroups: _collapsedGroups,
                  onToggleGroup: (groupTitle) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (_collapsedGroups.contains(groupTitle)) {
                        _collapsedGroups.remove(groupTitle);
                      } else {
                        _collapsedGroups.add(groupTitle);
                      }
                    });
                  },
                  onToggleTask: (task) {
                    HapticFeedback.selectionClick();
                    workspace.toggleTask(task);
                  },
                  onOpenSourceNote: (noteId) {
                    final note = workspace.getItemByIdSync(noteId);
                    if (note != null) widget.onOpenItem(note);
                  },
                  onOpenInboxItem: (item) => widget.onOpenItem(item),
                ),

                // 4. Pinned Section Header
                if (pinned.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s6),
                  Row(
                    children: [
                      TackPinBadge(color: tokens.accentPin, size: 13),
                      const SizedBox(width: AppSpacing.s2),
                      Text(
                        'Pinned notes',
                        style: AppTypography.titleSm(color: tokens.textPrimary),
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surfacePrimary,
                          borderRadius: AppSpacing.roundedPill,
                        ),
                        child: Text(
                          '${pinned.length}',
                          style: AppTypography.caption(
                            color: tokens.textSecondary,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s3),
                ],
              ],
            ),
          ),
        ),

        // 4b. Pinned Grid
        if (pinned.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: SliverResponsiveCardGrid(
              crossAxisCount: cols,
              mainAxisSpacing: AppSpacing.cardGridGap,
              crossAxisSpacing: AppSpacing.cardGridGap,
              itemCount: pinned.length,
              itemBuilder: (context, index) {
                final item = pinned[index];
                if (item is WhiteboardCanvasItem) {
                  return BoardGridCard(
                    key: ValueKey('today_pin_${item.id}'),
                    board: item,
                    onTap: () => widget.onOpenItem(item),
                    onLongPress: () => CardPeekSheet.show(
                      context: context,
                      item: item,
                      onOpen: () => widget.onOpenItem(item),
                    ),
                  );
                }
                return NeoNoteCard(
                  key: ValueKey('today_pin_${item.id}'),
                  item: item,
                  onTap: () => widget.onOpenItem(item),
                  onLongPress: () => CardPeekSheet.show(
                    context: context,
                    item: item,
                    onOpen: () => widget.onOpenItem(item),
                  ),
                );
              },
            ),
          ),

        // 5. Worth Revisiting Section
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.s6,
            gutter,
            AppSpacing.s9,
          ),
          sliver: SliverToBoxAdapter(
            child: revisitNote != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Worth revisiting',
                            style: AppTypography.titleSm(
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s2),
                          Text(
                            '1 older note',
                            style: AppTypography.serifItalic(
                              color: tokens.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      _WorthRevisitingCard(
                        note: revisitNote,
                        onTap: () => widget.onOpenItem(revisitNote),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// 7-day Horizontal Week Strip Card matching Screenshot 2 (*DailyLoop*).
class _WeekStripCard extends StatelessWidget {
  final DateTime now;
  final bool hasDailyNote;
  final VoidCallback onTapToday;

  const _WeekStripCard({
    required this.now,
    required this.hasDailyNote,
    required this.onTapToday,
  });

  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // Monday = 1 .. Sunday = 7
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s3,
      ),
      decoration: ShapeDecoration(
        color: tokens.surfacePrimary,
        shadows: AppSpacing.elev1(tokens.isDark),
        shape: const SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedLg,
          smoothness: 0.60,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: List.generate(7, (i) {
          final dayDate = monday.add(Duration(days: i));
          final isToday = dayDate.year == now.year &&
              dayDate.month == now.month &&
              dayDate.day == now.day;
          final isPast = dayDate.isBefore(
            DateTime(now.year, now.month, now.day),
          );

          return Expanded(
            child: GestureDetector(
              onTap: isToday ? onTapToday : null,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: AppSpacing.durationFast,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: ShapeDecoration(
                  color: isToday ? tokens.canvasSunken : Colors.transparent,
                  shape: const SmoothRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    smoothness: 0.60,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _dayLabels[i],
                        style: AppTypography.caption(
                          color: isToday
                              ? tokens.textSecondary
                              : (isPast
                                  ? tokens.textTertiary.withValues(alpha: 0.7)
                                  : tokens.textTertiary),
                          weight: isToday ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dayDate.day}',
                        style: AppTypography.titleSm(
                          color: isToday
                              ? tokens.textPrimary
                              : (isPast
                                  ? tokens.textTertiary
                                  : tokens.textSecondary),
                          fontSize: 16,
                          weight: isToday ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isToday && hasDailyNote
                              ? tokens.accentPin
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Regent & Joi-style Today's Daily Note Card (Screenshots 1 & 3).
class _TodaysDailyNoteCard extends StatelessWidget {
  final DateTime now;
  final TextNote? existingDaily;
  final String dateLabel;
  final VoidCallback onTap;

  const _TodaysDailyNoteCard({
    required this.now,
    required this.existingDaily,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById('coral');
    final softTint = palette.resolveSoftBackground(tokens.isDark);
    final accentColor = palette.resolveAccentColor(tokens.isDark);
    final hasNote = existingDaily != null;
    final summary = hasNote ? existingDaily!.getSummary() : '';
    final dayNum = now.day.toString().padLeft(2, '0');

    return Container(
      decoration: ShapeDecoration(
        color: tokens.surfacePrimary,
        shadows: AppSpacing.elev1(tokens.isDark),
        shape: const SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedLg,
          smoothness: 0.60,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('today_daily_note_card'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Joi-Style Date Header Row (`09 •` + right date)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      dayNum,
                      style: AppTypography.titleLg(
                        color: tokens.textPrimary,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tokens.accentPin,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateLabel.toUpperCase(),
                      style: AppTypography.mono(
                        fontSize: 11,
                        weight: FontWeight.w600,
                        color: tokens.textTertiary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.s3),

                // 2. Regent-Style Tinted Inner Block with 3.5dp Leading Bar & Action Pill
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s3),
                  decoration: BoxDecoration(
                    color: softTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 3.5,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: AppSpacing.roundedPill,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Daily Note",
                              style: AppTypography.titleSm(
                                color: tokens.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasNote &&
                                      summary.isNotEmpty &&
                                      summary != 'Empty note'
                                  ? summary
                                  : 'Tap to start today’s note — open tasks carry forward automatically.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm(
                                color: accentColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.14),
                          borderRadius: AppSpacing.roundedPill,
                        ),
                        child: Text(
                          hasNote ? 'Open' : 'Start',
                          style: AppTypography.caption(
                            color: accentColor,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// DailyLoop-Style Segmented Tasks & Inbox Card (`To do` · `Completed` · `Inbox`, Screenshot 2).
class _SegmentedTasksAndInboxCard extends StatelessWidget {
  final _TodayTaskTab activeTab;
  final ValueChanged<_TodayTaskTab> onSelectTab;
  final List<DerivedTaskItem> openTasks;
  final List<DerivedTaskItem> completedTasks;
  final List<BaseWorkspaceItem> inboxItems;
  final Set<String> collapsedGroups;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<DerivedTaskItem> onToggleTask;
  final ValueChanged<String> onOpenSourceNote;
  final ValueChanged<BaseWorkspaceItem> onOpenInboxItem;

  const _SegmentedTasksAndInboxCard({
    required this.activeTab,
    required this.onSelectTab,
    required this.openTasks,
    required this.completedTasks,
    required this.inboxItems,
    required this.collapsedGroups,
    required this.onToggleGroup,
    required this.onToggleTask,
    required this.onOpenSourceNote,
    required this.onOpenInboxItem,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: ShapeDecoration(
        color: tokens.surfacePrimary,
        shadows: AppSpacing.elev1(tokens.isDark),
        shape: const SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedLg,
          smoothness: 0.60,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Gliding Black-Pill Segmented Control Bar (`To do` · `Completed` · `Inbox`)
          SlidingPillTrack(
            itemCount: 3,
            selectedIndex: activeTab.index,
            trackColor: tokens.canvasSunken,
            indicatorColor: tokens.actionPrimary,
            children: [
              _buildSegmentPill(
                tokens: tokens,
                tab: _TodayTaskTab.todo,
                icon: TackIcons.sparkles,
                label: 'To do',
                count: openTasks.length,
              ),
              _buildSegmentPill(
                tokens: tokens,
                tab: _TodayTaskTab.completed,
                icon: TackIcons.check,
                label: 'Completed',
                count: completedTasks.length,
              ),
              _buildSegmentPill(
                tokens: tokens,
                tab: _TodayTaskTab.inbox,
                icon: TackIcons.inbox,
                label: 'Inbox',
                count: inboxItems.length,
                highlightDot: inboxItems.isNotEmpty,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s4),

          // 2. Smoothly Cross-Faded Active Tab Body
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 170),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(activeTab),
              child: activeTab == _TodayTaskTab.todo
                  ? _buildGroupedTaskList(
                      context,
                      tokens,
                      openTasks,
                      emptyMessage:
                          'No open tasks across your notes. Add `- [ ]` to any note to track tasks here.',
                    )
                  : (activeTab == _TodayTaskTab.completed
                      ? _buildGroupedTaskList(
                          context,
                          tokens,
                          completedTasks,
                          emptyMessage: 'No completed tasks yet today.',
                        )
                      : _buildInboxSection(context, tokens)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentPill({
    required TackTokens tokens,
    required _TodayTaskTab tab,
    required dynamic icon,
    required String label,
    required int count,
    bool highlightDot = false,
  }) {
    final isSelected = activeTab == tab;
    final fg = isSelected ? tokens.actionPrimaryFg : tokens.textSecondary;

    return GestureDetector(
      onTap: () => onSelectTab(tab),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TackIcon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(
                  color: fg,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (highlightDot && !isSelected) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tokens.accentPin,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedTaskList(
    BuildContext context,
    TackTokens tokens,
    List<DerivedTaskItem> tasks, {
    required String emptyMessage,
  }) {
    if (tasks.isEmpty) {
      return _QuietEmptyBox(message: emptyMessage);
    }

    // Group tasks by source note title (like "▾ Morning", "▾ Workload" in Screenshot 2)
    final grouped = <String, List<DerivedTaskItem>>{};
    for (final t in tasks.take(12)) {
      grouped.putIfAbsent(t.noteTitle, () => []).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in grouped.entries) ...[
          InkWell(
            onTap: () => onToggleGroup(entry.key),
            borderRadius: AppSpacing.roundedSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(
                children: [
                  TackIcon(
                    collapsedGroups.contains(entry.key)
                        ? TackIcons.chevronRight
                        : TackIcons.chevronDown,
                    size: 14,
                    color: tokens.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSm(
                        color: tokens.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  GestureDetector(
                    onTap: () => onOpenSourceNote(entry.value.first.noteId),
                    child: Text(
                      'Open note',
                      style: AppTypography.caption(
                        color: tokens.textTertiary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!collapsedGroups.contains(entry.key))
            for (final task in entry.value)
              _TaskRow(
                task: task,
                onToggle: () => onToggleTask(task),
                onOpenSource: () => onOpenSourceNote(task.noteId),
              ),
          const SizedBox(height: AppSpacing.s2),
        ],
      ],
    );
  }

  Widget _buildInboxSection(BuildContext context, TackTokens tokens) {
    if (inboxItems.isEmpty) {
      return const _QuietEmptyBox(
        message:
            'Your Inbox is clear. Tap (+) below to save quick thoughts to Inbox.',
      );
    }
    return _InboxTriageCard(
      item: inboxItems.first,
      remainingCount: inboxItems.length,
      onOpen: () => onOpenInboxItem(inboxItems.first),
    );
  }
}

/// Stacked Deck Inbox Triage Card (`Keep as note` · `Add to note` · `Make task` · `Trash`).
class _InboxTriageCard extends StatelessWidget {
  final BaseWorkspaceItem item;
  final int remainingCount;
  final VoidCallback onOpen;

  const _InboxTriageCard({
    required this.item,
    required this.remainingCount,
    required this.onOpen,
  });

  Future<void> _pickNoteToAppend(BuildContext context) async {
    final workspace = context.read<WorkspaceProvider>();
    final notes = workspace.libraryNotes;
    if (notes.isEmpty) {
      await workspace.keepInboxItemAsNote(item.id);
      return;
    }

    final chosen = await AppBottomSheet.show<TextNote>(
      context: context,
      builder: (sheetCtx) {
        final tokens = sheetCtx.tokens;
        return Padding(
          padding: AppSpacing.modalSheetPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Append capture to note',
                style: AppTypography.title(color: tokens.textPrimary),
              ),
              const SizedBox(height: AppSpacing.s3),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notes.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: tokens.borderSubtle),
                  itemBuilder: (_, i) {
                    final n = notes[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: TackIcon(
                        TackIcons.notes,
                        size: 18,
                        color: tokens.textSecondary,
                      ),
                      title: Text(
                        n.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          color: tokens.textPrimary,
                          weight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        n.getSummary(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          color: tokens.textTertiary,
                        ),
                      ),
                      onTap: () => Navigator.of(sheetCtx).pop(n),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (chosen != null && context.mounted) {
      await workspace.appendInboxItemToNote(item.id, chosen.id);
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('Appended to "${chosen.title}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final workspace = context.read<WorkspaceProvider>();
    final palette = AppColors.getPaletteById(item.paletteId);
    final accentColor = palette.resolveAccentColor(tokens.isDark);
    final softTint = palette.resolveSoftBackground(tokens.isDark);
    final summary = item.getSummary();

    return Column(
      children: [
        // Stacked deck header peek (matching Screenshot 2 left stacked overview card)
        if (remainingCount > 1)
          Container(
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: tokens.canvasSunken,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: BoxDecoration(
            color: softTint,
            borderRadius: AppSpacing.roundedMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: onOpen,
                borderRadius: AppSpacing.roundedSm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s2),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSm(
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '$remainingCount in stack',
                          style: AppTypography.mono(
                            fontSize: 11,
                            color: accentColor,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (summary.isNotEmpty &&
                        summary.toLowerCase() != item.title.toLowerCase()) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              Wrap(
                spacing: AppSpacing.s2,
                runSpacing: AppSpacing.s2,
                children: [
                  _TriageButton(
                    icon: TackIcons.check,
                    label: 'Keep as note',
                    isPrimary: true,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      workspace.keepInboxItemAsNote(item.id);
                    },
                  ),
                  _TriageButton(
                    icon: TackIcons.plus,
                    label: 'Add to note',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _pickNoteToAppend(context);
                    },
                  ),
                  _TriageButton(
                    icon: TackIcons.task,
                    label: 'Make task',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      workspace.convertInboxItemToTodayTask(item.id);
                    },
                  ),
                  _TriageButton(
                    icon: TackIcons.trash,
                    label: 'Trash',
                    isDestructive: true,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      workspace.moveToTrash(item.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TriageButton extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDestructive;

  const _TriageButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bg = isPrimary ? tokens.actionPrimary : tokens.surfacePrimary;
    final fg = isPrimary
        ? tokens.actionPrimaryFg
        : (isDestructive ? tokens.danger : tokens.textPrimary);

    return Material(
      color: bg,
      borderRadius: AppSpacing.roundedPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TackIcon(icon, size: 14, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.caption(
                  color: fg,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square-rounded Task Row matching Screenshot 2 (*DailyLoop*).
class _TaskRow extends StatelessWidget {
  final DerivedTaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onOpenSource;

  const _TaskRow({
    required this.task,
    required this.onToggle,
    required this.onOpenSource,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(task.paletteId);
    final dotColor = palette.resolveAccentColor(tokens.isDark);

    return InkWell(
      onTap: onToggle,
      borderRadius: AppSpacing.roundedSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Square outlined checkbox (radius 5dp per 11-reference-ui-style.md §4)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: task.isDone ? tokens.actionPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: task.isDone
                      ? tokens.actionPrimary
                      : tokens.borderStrong,
                  width: 1.5,
                ),
              ),
              child: task.isDone
                  ? Center(
                      child: TackIcon(
                        TackIcons.check,
                        size: 13,
                        color: tokens.actionPrimaryFg,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(
                  color: task.isDone
                      ? tokens.textTertiary
                      : tokens.textPrimary,
                ).copyWith(
                  decoration:
                      task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorthRevisitingCard extends StatelessWidget {
  final TextNote note;
  final VoidCallback onTap;

  const _WorthRevisitingCard({
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(note.paletteId);
    final softTint = palette.resolveSoftBackground(tokens.isDark);
    final accentColor = palette.resolveAccentColor(tokens.isDark);

    return Container(
      decoration: ShapeDecoration(
        color: tokens.surfacePrimary,
        shadows: AppSpacing.elev1(tokens.isDark),
        shape: const SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          smoothness: 0.60,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'WORTH REVISITING',
                      style: AppTypography.mono(
                        fontSize: 11,
                        weight: FontWeight.w600,
                        color: tokens.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormatter.formatTimestamp(note.updatedAt)
                          .toUpperCase(),
                      style: AppTypography.mono(
                        fontSize: 11,
                        color: tokens.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s2),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s3),
                  decoration: BoxDecoration(
                    color: softTint,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: AppSpacing.roundedPill,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleSm(
                                color: tokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              note.getSummary(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm(
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuietEmptyBox extends StatelessWidget {
  final String message;

  const _QuietEmptyBox({required this.message});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: tokens.canvasSunken.withValues(alpha: 0.65),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Text(
        message,
        style: AppTypography.bodySm(color: tokens.textSecondary),
      ),
    );
  }
}

/// Helper to navigate to the right screen for any [BaseWorkspaceItem].
void openWorkspaceItemScreen(
  BuildContext context,
  BaseWorkspaceItem item, {
  bool startInEditMode = false,
}) {
  if (item is WhiteboardCanvasItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhiteboardCanvasScreen(item: item),
      ),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          item: item,
          startInEditMode: startInEditMode,
        ),
      ),
    );
  }
}

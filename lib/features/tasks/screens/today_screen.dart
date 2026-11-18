import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/tack_routes.dart';
import '../../../core/services/pinned_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/base_item.dart';
import '../../notes/models/text_note.dart';
import '../../whiteboard/models/whiteboard_item.dart';
import '../services/open_tasks_service.dart';
import '../widgets/task_reminder_sheet.dart';
import '../../../shared/providers/workspace_provider.dart';
import '../../whiteboard/widgets/board_grid_card.dart';
import '../../../shared/widgets/neo_note_card.dart';
import '../../../shared/widgets/responsive_card_grid.dart';
import '../../../shared/widgets/card_peek_sheet.dart';
import '../../../shared/widgets/sliding_pill_track.dart';
import '../../../shared/widgets/tack_card_open_container.dart';
import '../../../shared/widgets/tack_toast.dart';
import '../../../shared/widgets/z_order_column.dart';
import '../../notes/screens/note_editor_screen.dart';
import '../../whiteboard/screens/whiteboard_canvas_screen.dart';

enum _TodayTaskTab { todo, completed }

/// The **Today** screen redesigned in Soft Monochrome (`docs/design/11-reference-ui-style.md`):
/// 1. **Today's Daily Note Card** (Joi date header + soft tinted inner block)
/// 2. **Segmented Tasks Card** with Black-Pill Segmented Control (`To do` · `Completed`),
///    collapsible note group headers, and square checkboxes
/// 3. **Pinned** items grid (Notes & Boards)
/// 4. **Worth Revisiting** resurfacing note card
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
  bool _showAllTasks = false;

  Future<void> _openDailyNote(
    WorkspaceProvider workspace,
    TextNote? existingDaily,
  ) async {
    try {
      HapticFeedback.lightImpact();
      final isNew = existingDaily == null;
      final note = await workspace.openOrCreateTodaysNote();
      if (mounted) {
        widget.onOpenItem(note, startInEditMode: isNew);
      }
    } catch (_) {
      if (mounted) {
        TackToast.show(
          context,
          message: "Could not open Today's Daily Note",
          icon: TackIcons.close,
          iconColor: context.tokens.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final workspace = context.watch<WorkspaceProvider>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gutter = AppSpacing.screenGutter(screenWidth);
    final cols = AppSpacing.gridColumnsForWidth(screenWidth);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final expectedDailyTitle = 'Daily Note • $dateStr';
    final existingDaily = workspace.allActiveItems
        .whereType<TextNote>()
        .where((n) => !n.isTrash && n.title == expectedDailyTitle)
        .firstOrNull;

    final allTasks = OpenTasksService.extractTasks(
      workspace.allActiveItems,
      includeCompleted: true,
    );
    final openTasks = allTasks.where((t) => !t.isDone).toList();
    final completedTasks = allTasks.where((t) => t.isDone).toList();
    final pinned = workspace.pinnedItems;
    final revisitNote = workspace.worthRevisitingNote;

    return SafeArea(
      top: false,
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.readMaxWidth),
          child: CustomScrollView(
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
                      // 1. Today's Daily Note Hero Card
                      _TodaysDailyNoteCard(
                        now: now,
                        existingDaily: existingDaily,
                        carryForwardEnabled:
                            workspace.carryForwardTasksEnabled,
                        dateLabel: DateFormatter.formatOrdinalDate(now),
                        onTap: () => _openDailyNote(workspace, existingDaily),
                      ),

                      const SizedBox(height: AppSpacing.s5),

                      // 2. Segmented Tasks Card (To do · Completed)
                      _SegmentedTasksCard(
                        activeTab: _activeTab,
                        onSelectTab: (tab) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _activeTab = tab;
                            _showAllTasks = false;
                          });
                        },
                        openTasks: openTasks,
                        completedTasks: completedTasks,
                        showAllTasks: _showAllTasks,
                        onToggleShowAll: () => setState(
                          () => _showAllTasks = !_showAllTasks,
                        ),
                        collapsedGroups: _collapsedGroups,
                        onToggleGroup: (groupId) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (_collapsedGroups.contains(groupId)) {
                              _collapsedGroups.remove(groupId);
                            } else {
                              _collapsedGroups.add(groupId);
                            }
                          });
                        },
                        onToggleTask: (task) async {
                          HapticFeedback.selectionClick();
                          try {
                            final result = await workspace.toggleTask(task);
                            if (result != null &&
                                result.advancedRecurrence &&
                                result.nextDueAt != null &&
                                context.mounted) {
                              final nextPreview = DerivedTaskItem(
                                noteId: task.noteId,
                                noteTitle: task.noteTitle,
                                paletteId: task.paletteId,
                                lineIndex: task.lineIndex,
                                text: result.cleanText,
                                isDone: false,
                                noteUpdatedAt: DateTime.now(),
                                dueAt: result.nextDueAt,
                                hasExplicitTime: result.hasExplicitTime,
                                recurrence: result.recurrence,
                              );
                              final dueStr =
                                  nextPreview.formatDueLabel() ?? 'next date';
                              TackToast.show(
                                context,
                                message: 'Completed · Next due $dueStr',
                                icon: TackIcons.check,
                                iconColor: tokens.success,
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              TackToast.show(
                                context,
                                message: 'Could not update task',
                                icon: TackIcons.close,
                                iconColor: tokens.danger,
                              );
                            }
                          }
                        },
                        onEditReminder: (task) async {
                          final selection = await TaskReminderSheet.show(
                            context: context,
                            taskTitle: task.text,
                            initialDueAt: task.dueAt,
                            initialHasExplicitTime: task.hasExplicitTime,
                            initialRecurrence: task.recurrence,
                          );
                          if (selection == null) return;
                          try {
                            await workspace.setTaskReminder(
                              task,
                              dueAt: selection.dueAt,
                              hasExplicitTime: selection.hasExplicitTime,
                              recurrence: selection.recurrence,
                            );
                            if (selection.dueAt != null && context.mounted) {
                              final status =
                                  await PinnedNotificationService
                                      .getPermissionStatus();
                              if (!status.canScheduleExactAlarms &&
                                  context.mounted) {
                                TackToast.show(
                                  context,
                                  message:
                                      'Reminder saved (allow exact alarms for on-time alerts)',
                                  icon: TackIcons.notification,
                                  iconColor: tokens.accentPin,
                                  actionLabel: 'Settings',
                                  onAction: PinnedNotificationService
                                      .openExactAlarmSettings,
                                );
                              }
                            }
                          } catch (_) {
                            if (context.mounted) {
                              TackToast.show(
                                context,
                                message: 'Could not update reminder',
                                icon: TackIcons.close,
                                iconColor: tokens.danger,
                              );
                            }
                          }
                        },
                        onOpenSourceNote: (noteId) {
                          final note = workspace.getItemByIdSync(noteId);
                          if (note != null) widget.onOpenItem(note);
                        },
                        onOpenDailyNote: () =>
                            _openDailyNote(workspace, existingDaily),
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
                              style: AppTypography.titleSm(
                                color: tokens.textPrimary,
                              ),
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
                          openBuilder: (_) => buildWorkspaceItemDetailScreen(item),
                          onPeek: (openDetail) => CardPeekSheet.show(
                            context: context,
                            item: item,
                            onOpen: openDetail,
                          ),
                        );
                      }
                      return NeoNoteCard(
                        key: ValueKey('today_pin_${item.id}'),
                        item: item,
                        openBuilder: (_) => buildWorkspaceItemDetailScreen(item),
                        onPeek: (openDetail) => CardPeekSheet.show(
                          context: context,
                          item: item,
                          onOpen: openDetail,
                        ),
                      );
                    },
                  ),
                ),

              // 5. Worth Revisiting Section
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  revisitNote != null ? AppSpacing.s6 : AppSpacing.s2,
                  gutter,
                  AppSpacing.s9 + bottomInset,
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
                            _WorthRevisitingCard(note: revisitNote),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Regent & Joi-style Today's Daily Note Card (Screenshots 1 & 3).
class _TodaysDailyNoteCard extends StatelessWidget {
  final DateTime now;
  final TextNote? existingDaily;
  final bool carryForwardEnabled;
  final String dateLabel;
  final VoidCallback onTap;

  const _TodaysDailyNoteCard({
    required this.now,
    required this.existingDaily,
    required this.carryForwardEnabled,
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

    Widget buildDailyBody(VoidCallback handleTap) => Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('today_daily_note_card'),
            onTap: handleTap,
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
                        style: AppTypography.caption(
                          fontSize: 12,
                          weight: FontWeight.w600,
                          color: tokens.textTertiary,
                        ).copyWith(letterSpacing: 0.4),
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
                                    : (carryForwardEnabled
                                        ? 'Tap to start today’s note — open tasks carry forward automatically.'
                                        : 'Tap to start today’s note.'),
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
        );

    const cardShape = SmoothRectangleBorder(
      borderRadius: AppSpacing.roundedLg,
      smoothness: 0.60,
    );

    if (existingDaily != null) {
      return TackCardOpenContainer(
        closedShape: cardShape,
        openBuilder: (_) => NoteEditorScreen(item: existingDaily!),
        closedBuilder: (_, openContainer) => buildDailyBody(() {
          HapticFeedback.lightImpact();
          openContainer();
        }),
      );
    }

    return Container(
      decoration: ShapeDecoration(
        color: tokens.surfacePrimary,
        shadows: AppSpacing.elev1(tokens.isDark),
        shape: cardShape,
      ),
      clipBehavior: Clip.antiAlias,
      child: buildDailyBody(onTap),
    );
  }
}

/// Segmented Tasks Card (`To do` · `Completed`).
class _SegmentedTasksCard extends StatelessWidget {
  final _TodayTaskTab activeTab;
  final ValueChanged<_TodayTaskTab> onSelectTab;
  final List<DerivedTaskItem> openTasks;
  final List<DerivedTaskItem> completedTasks;
  final bool showAllTasks;
  final VoidCallback onToggleShowAll;
  final Set<String> collapsedGroups;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<DerivedTaskItem> onToggleTask;
  final ValueChanged<DerivedTaskItem> onEditReminder;
  final ValueChanged<String> onOpenSourceNote;
  final VoidCallback onOpenDailyNote;

  const _SegmentedTasksCard({
    required this.activeTab,
    required this.onSelectTab,
    required this.openTasks,
    required this.completedTasks,
    required this.showAllTasks,
    required this.onToggleShowAll,
    required this.collapsedGroups,
    required this.onToggleGroup,
    required this.onToggleTask,
    required this.onEditReminder,
    required this.onOpenSourceNote,
    required this.onOpenDailyNote,
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
          // 1. Gliding Black-Pill Segmented Control Bar (`To do` · `Completed`)
          SlidingPillTrack(
            itemCount: 2,
            selectedIndex: activeTab.index,
            trackColor: tokens.canvasSunken,
            indicatorColor: tokens.actionPrimary,
            children: [
              _buildSegmentPill(
                tokens: tokens,
                tab: _TodayTaskTab.todo,
                icon: TackIcons.taskOpen,
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
            ],
          ),

          const SizedBox(height: AppSpacing.s4),

          // 2. Top-Anchored Directional Switcher + Smooth Size Interpolation
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            reverseDuration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              reverseDuration: const Duration(milliseconds: 160),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren,
                  ?currentChild,
                ],
              ),
              transitionBuilder: (child, animation) {
                final isTodo = child.key == const ValueKey(_TodayTaskTab.todo);
                final slide = Tween<Offset>(
                  begin: Offset(isTodo ? -0.06 : 0.06, 0),
                  end: Offset.zero,
                ).animate(animation);
                return RepaintBoundary(
                  child: FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slide,
                      child: child,
                    ),
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(activeTab),
                child: activeTab == _TodayTaskTab.todo
                    ? _buildGroupedTaskList(
                        context,
                        tokens,
                        openTasks,
                        emptyMessage:
                            "No open tasks yet. Start Today's Daily Note or add checklist items inside any note.",
                        emptyActionLabel: "Open Today's Note",
                        onEmptyAction: onOpenDailyNote,
                      )
                    : _buildGroupedTaskList(
                        context,
                        tokens,
                        completedTasks,
                        emptyMessage: 'No completed tasks yet today.',
                      ),
              ),
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
  }) {
    final isSelected = activeTab == tab;
    final fg = isSelected ? tokens.actionPrimaryFg : tokens.textSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label, $count items',
      child: GestureDetector(
        onTap: () => onSelectTab(tab),
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.s2,
              horizontal: AppSpacing.s1,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TackIcon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    count > 0 ? '$label ($count)' : label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(
                      color: fg,
                      weight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

  Widget _buildGroupedTaskList(
    BuildContext context,
    TackTokens tokens,
    List<DerivedTaskItem> tasks, {
    required String emptyMessage,
    String? emptyActionLabel,
    VoidCallback? onEmptyAction,
  }) {
    if (tasks.isEmpty) {
      return _QuietEmptyBox(
        message: emptyMessage,
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
      );
    }

    const previewLimit = 12;
    final now = DateTime.now();
    final overdueCount = activeTab == _TodayTaskTab.todo
        ? tasks.where((t) => !t.isDone && t.isOverdue(now)).length
        : 0;
    final visibleTasks =
        (showAllTasks || tasks.length <= previewLimit)
            ? tasks
            : tasks.take(previewLimit).toList();

    // Group tasks by source noteId so identically-titled notes remain separate.
    final grouped = <String, List<DerivedTaskItem>>{};
    for (final t in visibleTasks) {
      grouped.putIfAbsent(t.noteId, () => []).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (overdueCount > 0) ...[
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.s3),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s2,
            ),
            decoration: BoxDecoration(
              color: tokens.danger.withValues(alpha: 0.10),
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Row(
              children: [
                TackIcon(TackIcons.warning, size: 15, color: tokens.danger),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Text(
                    '$overdueCount overdue ${overdueCount == 1 ? 'task' : 'tasks'}',
                    style: AppTypography.caption(
                      color: tokens.danger,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        for (final entry in grouped.entries) ...[
          InkWell(
            onTap: () => onToggleGroup(entry.key),
            borderRadius: AppSpacing.roundedSm,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.s1,
                  horizontal: 2,
                ),
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
                        entry.value.first.noteTitle.trim().isEmpty
                            ? 'Untitled'
                            : entry.value.first.noteTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSm(
                          color: tokens.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          AppSpacing.minTouchTarget,
                          AppSpacing.minTouchTarget,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s2,
                        ),
                      ),
                      onPressed: () =>
                          onOpenSourceNote(entry.value.first.noteId),
                      child: Text(
                        'Open note',
                        style: AppTypography.caption(
                          color: tokens.textSecondary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!collapsedGroups.contains(entry.key))
            for (final task in entry.value)
              _TaskRow(
                task: task,
                onToggle: () => onToggleTask(task),
                onEditReminder:
                    !task.isDone ? () => onEditReminder(task) : null,
                onOpenSource: () => onOpenSourceNote(task.noteId),
              ),
          const SizedBox(height: AppSpacing.s2),
        ],
        if (tasks.length > previewLimit)
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
            ),
            onPressed: onToggleShowAll,
            child: Text(
              showAllTasks
                  ? 'Show fewer'
                  : 'Show all ${tasks.length} tasks',
            ),
          ),
      ],
    );
  }
}

/// Square-rounded Task Row matching Screenshot 2 (*DailyLoop*).
class _TaskRow extends StatelessWidget {
  final DerivedTaskItem task;
  final VoidCallback onToggle;
  final VoidCallback? onEditReminder;
  final VoidCallback onOpenSource;

  const _TaskRow({
    required this.task,
    required this.onToggle,
    this.onEditReminder,
    required this.onOpenSource,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(task.paletteId);
    final dotColor = palette.resolveAccentColor(tokens.isDark);
    final now = DateTime.now();
    final isOverdue = task.isOverdue(now);
    final isToday = task.isDueToday(now);
    final dueLabel = task.formatDueLabel(now);
    final repeatLabel = task.recurrence?.label;

    final Color dueFg;
    final Color dueBg;
    if (isOverdue) {
      dueFg = tokens.danger;
      dueBg = tokens.danger.withValues(alpha: 0.12);
    } else if (isToday) {
      dueFg = tokens.accentPin;
      dueBg = tokens.accentPin.withValues(alpha: 0.12);
    } else {
      dueFg = tokens.textSecondary;
      dueBg = tokens.canvasSunken;
    }

    return Semantics(
      toggled: task.isDone,
      label: task.text,
      child: InkWell(
        onTap: onToggle,
        onLongPress: onEditReminder,
        borderRadius: AppSpacing.roundedSm,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.s2,
              horizontal: AppSpacing.s1,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Square outlined checkbox (radius 5dp per 11-reference-ui-style.md §4)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color:
                        task.isDone ? tokens.actionPrimary : Colors.transparent,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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
                      if (!task.isDone &&
                          (dueLabel != null || repeatLabel != null)) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (dueLabel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: dueBg,
                                  borderRadius: AppSpacing.roundedPill,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TackIcon(
                                      TackIcons.notification,
                                      size: 11,
                                      color: dueFg,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      dueLabel,
                                      style: AppTypography.caption(
                                        color: dueFg,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (repeatLabel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.canvasSunken,
                                  borderRadius: AppSpacing.roundedPill,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TackIcon(
                                      TackIcons.refresh,
                                      size: 11,
                                      color: tokens.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      repeatLabel,
                                      style: AppTypography.caption(
                                        color: tokens.textSecondary,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (onEditReminder != null)
                  IconButton(
                    onPressed: onEditReminder,
                    tooltip: 'Set reminder',
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    padding: EdgeInsets.zero,
                    icon: TackIcon(
                      TackIcons.notification,
                      size: 16,
                      color: dueLabel != null ? dueFg : tokens.textTertiary,
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

class _WorthRevisitingCard extends StatelessWidget {
  final TextNote note;

  const _WorthRevisitingCard({
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(note.paletteId);
    final softTint = palette.resolveSoftBackground(tokens.isDark);
    final accentColor = palette.resolveAccentColor(tokens.isDark);

    return TackCardOpenContainer(
      closedShape: const SmoothRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        smoothness: 0.60,
      ),
      openBuilder: (_) => NoteEditorScreen(item: note),
      closedBuilder: (_, openContainer) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            openContainer();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'WORTH REVISITING',
                      style: AppTypography.caption(
                        fontSize: 12,
                        weight: FontWeight.w600,
                        color: tokens.textTertiary,
                      ).copyWith(letterSpacing: 0.4),
                    ),
                    const Spacer(),
                    Text(
                      DateFormatter.formatTimestamp(note.updatedAt)
                          .toUpperCase(),
                      style: AppTypography.caption(
                        fontSize: 12,
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
  final String? actionLabel;
  final VoidCallback? onAction;

  const _QuietEmptyBox({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: tokens.canvasSunken.withValues(alpha: 0.65),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: AppTypography.bodySm(color: tokens.textSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.s2),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.minTouchTarget),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
              ),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Builds the detail screen widget for any [BaseWorkspaceItem].
Widget buildWorkspaceItemDetailScreen(
  BaseWorkspaceItem item, {
  bool startInEditMode = false,
}) {
  if (item is WhiteboardCanvasItem) {
    return WhiteboardCanvasScreen(item: item);
  }
  return NoteEditorScreen(
    item: item,
    startInEditMode: startInEditMode,
  );
}

/// Helper to navigate to the right screen for any [BaseWorkspaceItem] without fade-out lag.
void openWorkspaceItemScreen(
  BuildContext context,
  BaseWorkspaceItem item, {
  bool startInEditMode = false,
}) {
  final detailScreen = buildWorkspaceItemDetailScreen(
    item,
    startInEditMode: startInEditMode,
  );
  Navigator.of(context).push(
    startInEditMode
        ? TackRoutes.slideUp(detailScreen)
        : TackRoutes.sharedAxisHorizontal(detailScreen),
  );
}

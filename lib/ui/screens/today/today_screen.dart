import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/text_note.dart';
import '../../../domain/models/whiteboard_item.dart';
import '../../../domain/services/open_tasks_service.dart';
import '../../../state/workspace_provider.dart';
import '../../components/cards/board_grid_card.dart';
import '../../components/cards/neo_note_card.dart';
import '../../components/cards/responsive_card_grid.dart';
import '../../components/dialogs_sheets/app_bottom_sheet.dart';
import '../../components/dialogs_sheets/card_peek_sheet.dart';
import '../editor/note_editor_screen.dart';
import '../whiteboard/whiteboard_canvas_screen.dart';

/// The **Today** screen (`04-feature-strategy.md` F1/F2/F3/F13, `05-information-architecture.md` §2.1, `10-design.md` §5.2).
///
/// Serves as the calm daily desk on launch:
/// 1. **Today's Daily Note** card (1-tap to open or create with carried-forward tasks)
/// 2. **Inbox Triage** card stack (`N to sort` with `Keep as note` · `Add to note` · `Make task` · `Trash`)
/// 3. **Open Tasks** list (derived `- [ ]` lines across all notes, toggleable in-place)
/// 4. **Pinned** items grid (Notes & Boards)
/// 5. **Worth Revisiting** single resurfacing note card
class TodayScreen extends StatelessWidget {
  final void Function(BaseWorkspaceItem item, {bool startInEditMode}) onOpenItem;

  const TodayScreen({
    super.key,
    required this.onOpenItem,
  });

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
    final openTasks = workspace.openTasks;
    final pinned = workspace.pinnedItems;
    final revisitNote = workspace.worthRevisitingNote;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, AppSpacing.s2, gutter, AppSpacing.s4),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 1. Today's Daily Note Hero Card
              _TodaysDailyNoteCard(
                existingDaily: existingDaily,
                dateLabel: DateFormatter.formatOrdinalDate(now),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final isNew = existingDaily == null;
                  final note = await workspace.openOrCreateTodaysNote();
                  onOpenItem(note, startInEditMode: isNew);
                },
              ),

              // 2. Inbox Triage Card (when unsorted captures exist)
              if (inbox.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s6),
                _SectionHeader(
                  title: 'Inbox',
                  badgeText: '${inbox.length} to sort',
                  badgeIsPinAccent: true,
                ),
                const SizedBox(height: AppSpacing.s3),
                _InboxTriageCard(
                  item: inbox.first,
                  remainingCount: inbox.length,
                  onOpen: () => onOpenItem(inbox.first),
                ),
              ],

              // 3. Open Tasks across all notes
              const SizedBox(height: AppSpacing.s6),
              _SectionHeader(
                title: 'Open Tasks',
                badgeText: '${openTasks.length}',
              ),
              const SizedBox(height: AppSpacing.s3),
              if (openTasks.isEmpty)
                _QuietEmptyBox(
                  message:
                      'No open tasks across your notes. Add `- [ ]` to any note to track tasks here.',
                )
              else
                _OpenTasksListCard(
                  tasks: openTasks.take(8).toList(),
                  totalCount: openTasks.length,
                  onToggleTask: (task) {
                    HapticFeedback.selectionClick();
                    workspace.toggleTask(task);
                  },
                  onOpenSourceNote: (noteId) {
                    final note = workspace.getItemByIdSync(noteId);
                    if (note != null) onOpenItem(note);
                  },
                ),

              // 4. Pinned Section Header
              if (pinned.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s6),
                Row(
                  children: [
                    TackPinBadge(color: tokens.accentPin, size: 9),
                    const SizedBox(width: AppSpacing.s2),
                    Text(
                      'Pinned',
                      style: AppTypography.titleSm(color: tokens.textPrimary),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    Text(
                      '${pinned.length}',
                      style: AppTypography.caption(color: tokens.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),
              ],
            ]),
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
                    onTap: () => onOpenItem(item),
                    onLongPress: () => CardPeekSheet.show(
                      context: context,
                      item: item,
                      onOpen: () => onOpenItem(item),
                    ),
                  );
                }
                return NeoNoteCard(
                  key: ValueKey('today_pin_${item.id}'),
                  item: item,
                  onTap: () => onOpenItem(item),
                  onLongPress: () => CardPeekSheet.show(
                    context: context,
                    item: item,
                    onOpen: () => onOpenItem(item),
                  ),
                );
              },
            ),
          ),

        // 5. Worth Revisiting Card (`04` F13)
        if (revisitNote != null)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.s6,
              gutter,
              AppSpacing.s9,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    title: 'Worth Revisiting',
                    badgeText: 'From your archive',
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  NeoNoteCard(
                    item: revisitNote,
                    onTap: () => onOpenItem(revisitNote),
                    onLongPress: () => CardPeekSheet.show(
                      context: context,
                      item: revisitNote,
                      onOpen: () => onOpenItem(revisitNote),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.s9),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badgeText;
  final bool badgeIsPinAccent;

  const _SectionHeader({
    required this.title,
    this.badgeText,
    this.badgeIsPinAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.titleSm(color: tokens.textPrimary),
        ),
        if (badgeText != null) ...[
          const SizedBox(width: AppSpacing.s2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: badgeIsPinAccent
                  ? tokens.accentPin.withValues(alpha: 0.12)
                  : tokens.canvasSunken,
              borderRadius: AppSpacing.roundedPill,
              border: Border.all(
                color: badgeIsPinAccent
                    ? tokens.accentPin.withValues(alpha: 0.35)
                    : tokens.borderSubtle,
                width: 1,
              ),
            ),
            child: Text(
              badgeText!,
              style: AppTypography.caption(
                color: badgeIsPinAccent
                    ? tokens.accentPinText
                    : tokens.textSecondary,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TodaysDailyNoteCard extends StatelessWidget {
  final TextNote? existingDaily;
  final String dateLabel;
  final VoidCallback onTap;

  const _TodaysDailyNoteCard({
    required this.existingDaily,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final amberBand = AppColors.getPaletteById('amber').resolveCardColor(tokens.isDark);
    final summary = existingDaily?.getSummary() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfacePrimary,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: tokens.borderSubtle, width: 1),
        boxShadow: AppSpacing.elev1(tokens.isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('today_daily_note_card'),
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: AppSpacing.cardColorBandWidth,
                  color: amberBand,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TackIcon(
                              TackIcons.sun,
                              size: 18,
                              color: tokens.textPrimary,
                            ),
                            const SizedBox(width: AppSpacing.s2),
                            Expanded(
                              child: Text(
                                "Today's Note · $dateLabel",
                                style: AppTypography.titleSm(
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s3,
                                vertical: AppSpacing.s1,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.actionPrimary,
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: Text(
                                existingDaily == null ? 'Start' : 'Open',
                                style: AppTypography.caption(
                                  color: tokens.actionPrimaryFg,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          existingDaily == null
                              ? 'Tap to open today’s daily note and carry forward unfinished tasks.'
                              : (summary.isEmpty
                                  ? 'Tap to continue writing in today’s note.'
                                  : summary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
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
}

class _InboxTriageCard extends StatelessWidget {
  final BaseWorkspaceItem item;
  final int remainingCount;
  final VoidCallback onOpen;

  const _InboxTriageCard({
    required this.item,
    required this.remainingCount,
    required this.onOpen,
  });

  void _showAppendTargetPicker(BuildContext context) {
    final workspace = context.read<WorkspaceProvider>();
    final notes = workspace.libraryNotes.whereType<TextNote>().toList();

    AppBottomSheet.show<void>(
      context: context,
      builder: (ctx) {
        final tokens = ctx.tokens;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s2,
            AppSpacing.s5,
            AppSpacing.s5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Append capture to note',
                style: AppTypography.titleSm(color: tokens.textPrimary),
              ),
              const SizedBox(height: AppSpacing.s3),
              if (notes.isEmpty)
                Text(
                  'No existing notes yet.',
                  style: AppTypography.bodySm(color: tokens.textSecondary),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notes.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: tokens.borderSubtle),
                    itemBuilder: (context, idx) {
                      final target = notes[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          target.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            color: tokens.textPrimary,
                            weight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          DateFormatter.formatTimestamp(target.updatedAt),
                          style: AppTypography.caption(
                            color: tokens.textTertiary,
                          ),
                        ),
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          await workspace.appendInboxItemToNote(
                            item.id,
                            target.id,
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final workspace = context.read<WorkspaceProvider>();
    final palette = AppColors.getPaletteById(item.paletteId);
    final bandColor = palette.resolveCardColor(tokens.isDark);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfacePrimary,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: tokens.borderSubtle, width: 1),
        boxShadow: AppSpacing.elev1(tokens.isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: AppSpacing.cardColorBandWidth,
              color: bandColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onOpen,
                      borderRadius: AppSpacing.roundedXs,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
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
                                DateFormatter.formatTimestamp(item.updatedAt),
                                style: AppTypography.caption(
                                  color: tokens.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s1),
                          Text(
                            item.getSummary(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    Divider(height: 1, color: tokens.borderSubtle),
                    const SizedBox(height: AppSpacing.s2),
                    Wrap(
                      spacing: AppSpacing.s2,
                      runSpacing: AppSpacing.s2,
                      children: [
                        _TriageButton(
                          key: const ValueKey('inbox_keep_as_note_btn'),
                          icon: TackIcons.check,
                          label: 'Keep as note',
                          isPrimary: true,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            workspace.keepInboxItemAsNote(item.id);
                          },
                        ),
                        _TriageButton(
                          key: const ValueKey('inbox_make_task_btn'),
                          icon: TackIcons.task,
                          label: 'Make task',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            workspace.convertInboxItemToTodayTask(item.id);
                          },
                        ),
                        _TriageButton(
                          key: const ValueKey('inbox_append_btn'),
                          icon: TackIcons.notes,
                          label: 'Add to note…',
                          onTap: () => _showAppendTargetPicker(context),
                        ),
                        _TriageButton(
                          key: const ValueKey('inbox_trash_btn'),
                          icon: TackIcons.trash,
                          label: 'Trash',
                          isDanger: true,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            workspace.moveToTrash(item.id);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TriageButton extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDanger;

  const _TriageButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bg = isPrimary ? tokens.actionPrimary : tokens.canvasPrimary;
    final fg = isPrimary
        ? tokens.actionPrimaryFg
        : (isDanger ? tokens.danger : tokens.textPrimary);

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedSm,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 38),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s3,
            vertical: AppSpacing.s2,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppSpacing.roundedSm,
            border: Border.all(
              color: isPrimary ? tokens.actionPrimary : tokens.borderSubtle,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TackIcon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
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

class _OpenTasksListCard extends StatelessWidget {
  final List<DerivedTaskItem> tasks;
  final int totalCount;
  final ValueChanged<DerivedTaskItem> onToggleTask;
  final ValueChanged<String> onOpenSourceNote;

  const _OpenTasksListCard({
    required this.tasks,
    required this.totalCount,
    required this.onToggleTask,
    required this.onOpenSourceNote,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfacePrimary,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: tokens.borderSubtle, width: 1),
        boxShadow: AppSpacing.elev1(tokens.isDark),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tasks.length; i++) ...[
            if (i > 0) Divider(height: 1, color: tokens.borderSubtle),
            _OpenTaskRow(
              task: tasks[i],
              onToggle: () => onToggleTask(tasks[i]),
              onOpenNote: () => onOpenSourceNote(tasks[i].noteId),
            ),
          ],
          if (totalCount > tasks.length) ...[
            Divider(height: 1, color: tokens.borderSubtle),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s3),
              child: Text(
                '+${totalCount - tasks.length} more open tasks in your notes',
                style: AppTypography.caption(color: tokens.textTertiary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OpenTaskRow extends StatelessWidget {
  final DerivedTaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onOpenNote;

  const _OpenTaskRow({
    required this.task,
    required this.onToggle,
    required this.onOpenNote,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(task.paletteId);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s1,
        ),
        child: Row(
          children: [
            // 48dp checkbox touch target
            Semantics(
              button: true,
              label: 'Complete task ${task.text}',
              child: InkWell(
                key: ValueKey('task_checkbox_${task.id}'),
                onTap: onToggle,
                borderRadius: AppSpacing.roundedSm,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: tokens.borderStrong,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: InkWell(
                onTap: onOpenNote,
                child: Text(
                  task.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm(color: tokens.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            InkWell(
              onTap: onOpenNote,
              borderRadius: AppSpacing.roundedPill,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 120),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s2,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: tokens.canvasSunken,
                  borderRadius: AppSpacing.roundedPill,
                  border: Border.all(color: tokens.borderSubtle, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: palette.resolveCardColor(tokens.isDark),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        task.noteTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        color: tokens.canvasSunken.withValues(alpha: 0.6),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: tokens.borderSubtle, width: 1),
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

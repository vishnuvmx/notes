import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/tack_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/models/base_item.dart';
import '../../../shared/providers/workspace_provider.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/tack_toast.dart';
import '../../folders/screens/folder_view_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../whiteboard/models/whiteboard_item.dart';

/// Calm, decluttered **Search & Actions** screen for Tack.
///
/// Shows concise one-line quick actions and recent items while idle, then
/// expands cleanly into focused `Actions · Tasks · Notes · Boards` results
/// as you type — without taglines or noisy metadata clutter.
class SearchCommandScreen extends StatefulWidget {
  final void Function(BaseWorkspaceItem item, {bool startInEditMode}) onOpenItem;

  const SearchCommandScreen({
    super.key,
    required this.onOpenItem,
  });

  @override
  State<SearchCommandScreen> createState() => _SearchCommandScreenState();
}

class _SearchCommandScreenState extends State<SearchCommandScreen> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  List<_CommandEntry> _buildCommands() {
    final workspace = context.read<WorkspaceProvider>();
    final themeProv = context.read<ThemeProvider>();

    return [
      _CommandEntry(
        icon: TackIcons.sun,
        title: "Today's Daily Note",
        keywords: 'today daily note journal focus',
        onExecute: () async {
          try {
            final daily = await workspace.openOrCreateTodaysNote();
            if (mounted) widget.onOpenItem(daily);
          } catch (_) {
            if (mounted) {
              TackToast.show(
                context,
                message: "Could not open Today's Note",
                icon: TackIcons.close,
                iconColor: context.tokens.danger,
              );
            }
          }
        },
      ),
      _CommandEntry(
        icon: TackIcons.boards,
        title: 'New Board',
        keywords: 'new board canvas whiteboard flowchart diagram',
        onExecute: () async {
          try {
            final board = await workspace.createQuickItem(
              title: 'Untitled Board',
              type: ItemType.whiteboard,
              paletteId: 'cyan',
            );
            if (mounted) widget.onOpenItem(board);
          } catch (_) {
            if (mounted) {
              TackToast.show(
                context,
                message: 'Could not create board',
                icon: TackIcons.close,
                iconColor: context.tokens.danger,
              );
            }
          }
        },
      ),
      _CommandEntry(
        icon: TackIcons.moon,
        title: 'Switch Theme',
        keywords: 'theme dark mode light appearance',
        onExecute: () => themeProv.toggleTheme(context),
      ),
      _CommandEntry(
        icon: TackIcons.trash,
        title: 'Trash',
        keywords: 'trash deleted restore empty',
        onExecute: () {
          Navigator.of(context).push(
            TackRoutes.sharedAxisHorizontal(
              const FolderViewScreen(
                folderType: FolderType.trash,
              ),
            ),
          );
        },
      ),
      _CommandEntry(
        icon: TackIcons.settings,
        title: 'Settings',
        keywords: 'settings backup export import restore json',
        onExecute: () {
          Navigator.of(context).push(
            TackRoutes.slideUp(const SettingsScreen()),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final workspace = context.watch<WorkspaceProvider>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gutter = AppSpacing.screenGutter(screenWidth);
    final q = _query.trim();
    final lowerQ = q.toLowerCase();

    final allCommands = _buildCommands();
    final matchingCommands = q.isEmpty
        ? allCommands.take(4).toList()
        : allCommands
            .where((c) =>
                c.title.toLowerCase().contains(lowerQ) ||
                c.keywords.toLowerCase().contains(lowerQ))
            .toList();

    final recentItems = q.isEmpty
        ? (List<BaseWorkspaceItem>.from(
              workspace.allActiveItems.where((i) => !i.isTrash && !i.isInbox),
            )..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)))
            .take(4)
            .toList()
        : const <BaseWorkspaceItem>[];

    final matchingNotes = q.isEmpty
        ? const <BaseWorkspaceItem>[]
        : workspace.allActiveItems
            .where((i) =>
                i.type != ItemType.whiteboard &&
                !i.isTrash &&
                i.matchesQuery(q))
            .toList();

    final matchingBoards = q.isEmpty
        ? const <WhiteboardCanvasItem>[]
        : workspace.boardItems.where((b) => b.matchesQuery(q)).toList();

    final matchingTasks = q.isEmpty
        ? const []
        : workspace.openTasks
            .where((t) =>
                t.text.toLowerCase().contains(lowerQ) ||
                t.noteTitle.toLowerCase().contains(lowerQ))
            .toList();

    final hasNoResults = q.isNotEmpty &&
        matchingCommands.isEmpty &&
        matchingNotes.isEmpty &&
        matchingBoards.isEmpty &&
        matchingTasks.isEmpty;

    return SafeArea(
      top: false,
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.readMaxWidth),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.s2,
                  gutter,
                  AppSpacing.s3,
                ),
                child: AppSearchField(
                  controller: _queryController,
                  hintText: 'Search notes, boards, or tasks…',
                  onChanged: (val) => setState(() => _query = val),
                  onClear: () => setState(() => _query = ''),
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.s2,
                    gutter,
                    AppSpacing.s9 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    if (hasNoResults)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.s8,
                        ),
                        child: Column(
                          children: [
                            TackIcon(
                              TackIcons.search,
                              size: 28,
                              color: tokens.textTertiary,
                            ),
                            const SizedBox(height: AppSpacing.s3),
                            Text(
                              'No results for "$q"',
                              textAlign: TextAlign.center,
                              style: AppTypography.titleSm(
                                color: tokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(
                                  0,
                                  AppSpacing.minTouchTarget,
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  final note =
                                      await workspace.createQuickItem(
                                    title: q,
                                    type: ItemType.note,
                                    paletteId: 'amber',
                                  );
                                  if (context.mounted) {
                                    widget.onOpenItem(
                                      note,
                                      startInEditMode: true,
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    TackToast.show(
                                      context,
                                      message: 'Could not create note',
                                      icon: TackIcons.close,
                                      iconColor: tokens.danger,
                                    );
                                  }
                                }
                              },
                              child: Text('Create note "$q"'),
                            ),
                            const SizedBox(height: AppSpacing.s2),
                            TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(
                                  0,
                                  AppSpacing.minTouchTarget,
                                ),
                              ),
                              onPressed: () {
                                _queryController.clear();
                                setState(() => _query = '');
                              },
                              child: const Text('Clear search'),
                            ),
                          ],
                        ),
                      ),

                    // 1. Actions Group (compact single-line commands)
                    if (matchingCommands.isNotEmpty) ...[
                      _GroupHeader(
                        title: q.isEmpty ? 'Quick Actions' : 'Actions',
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      _SearchGroupCard(
                        children: [
                          for (int i = 0; i < matchingCommands.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                indent: 52,
                                color: tokens.borderSubtle,
                              ),
                            _CommandRow(entry: matchingCommands[i]),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s6),
                    ],

                    // 2. Idle Recent Items (merged concise list, max 4 items)
                    if (recentItems.isNotEmpty) ...[
                      const _GroupHeader(title: 'Recent'),
                      const SizedBox(height: AppSpacing.s2),
                      _SearchGroupCard(
                        children: [
                          for (int i = 0; i < recentItems.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                indent: 36,
                                color: tokens.borderSubtle,
                              ),
                            _SearchResultItemRow(
                              item: recentItems[i],
                              query: '',
                              onTap: () => widget.onOpenItem(recentItems[i]),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // 3. Active Search: Matching Tasks
                    if (matchingTasks.isNotEmpty) ...[
                      const _GroupHeader(title: 'Tasks'),
                      const SizedBox(height: AppSpacing.s2),
                      _SearchGroupCard(
                        children: [
                          for (int i = 0; i < matchingTasks.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                indent: 48,
                                color: tokens.borderSubtle,
                              ),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s2,
                                vertical: AppSpacing.s1,
                              ),
                              leading: Semantics(
                                button: true,
                                label: 'Complete ${matchingTasks[i].text}',
                                child: IconButton(
                                  tooltip: 'Complete task',
                                  constraints: const BoxConstraints(
                                    minWidth: AppSpacing.minTouchTarget,
                                    minHeight: AppSpacing.minTouchTarget,
                                  ),
                                  icon: TackIcon(
                                    TackIcons.taskOpen,
                                    size: 19,
                                    color: tokens.textSecondary,
                                  ),
                                  onPressed: () async {
                                    HapticFeedback.selectionClick();
                                    final task = matchingTasks[i];
                                    final previousItem =
                                        workspace.getItemByIdSync(task.noteId);
                                    try {
                                      await workspace.toggleTask(task);
                                      if (!context.mounted) return;
                                      TackToast.show(
                                        context,
                                        message: 'Completed "${task.text}"',
                                        icon: TackIcons.check,
                                        iconColor: tokens.success,
                                        duration: const Duration(seconds: 4),
                                        actionLabel: previousItem != null
                                            ? 'Undo'
                                            : null,
                                        onAction: previousItem != null
                                            ? () => workspace.saveItem(
                                                  previousItem,
                                                )
                                            : null,
                                      );
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
                                ),
                              ),
                              title: Text(
                                matchingTasks[i].text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySm(
                                  color: tokens.textPrimary,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                matchingTasks[i].noteTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption(
                                  color: tokens.textTertiary,
                                ),
                              ),
                              onTap: () {
                                final note = workspace.getItemByIdSync(
                                  matchingTasks[i].noteId,
                                );
                                if (note != null) widget.onOpenItem(note);
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s6),
                    ],

                    // 4. Active Search: Matching Notes
                    if (matchingNotes.isNotEmpty) ...[
                      const _GroupHeader(title: 'Notes'),
                      const SizedBox(height: AppSpacing.s2),
                      _SearchGroupCard(
                        children: [
                          for (int i = 0; i < matchingNotes.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                indent: 36,
                                color: tokens.borderSubtle,
                              ),
                            _SearchResultItemRow(
                              item: matchingNotes[i],
                              query: q,
                              onTap: () => widget.onOpenItem(matchingNotes[i]),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s6),
                    ],

                    // 5. Active Search: Matching Boards
                    if (matchingBoards.isNotEmpty) ...[
                      const _GroupHeader(title: 'Boards'),
                      const SizedBox(height: AppSpacing.s2),
                      _SearchGroupCard(
                        children: [
                          for (int i = 0; i < matchingBoards.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                indent: 36,
                                color: tokens.borderSubtle,
                              ),
                            _SearchResultItemRow(
                              item: matchingBoards[i],
                              query: q,
                              onTap: () =>
                                  widget.onOpenItem(matchingBoards[i]),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchGroupCard extends StatelessWidget {
  final List<Widget> children;

  const _SearchGroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: tokens.surfacePrimary,
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          smoothness: AppSpacing.defaultSmoothing,
          side: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(children: children),
      ),
    );
  }
}

class _CommandEntry {
  final dynamic icon;
  final String title;
  final String keywords;
  final VoidCallback onExecute;

  const _CommandEntry({
    required this.icon,
    required this.title,
    required this.keywords,
    required this.onExecute,
  });
}

class _GroupHeader extends StatelessWidget {
  final String title;

  const _GroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.s1),
      child: Text(
        title,
        style: AppTypography.label(
          color: tokens.textSecondary,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  final _CommandEntry entry;

  const _CommandRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        entry.onExecute();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tokens.canvasSunken,
                  borderRadius: AppSpacing.roundedXs,
                ),
                child: Center(
                  child: TackIcon(
                    entry.icon,
                    size: 16,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm(
                    color: tokens.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              TackIcon(
                TackIcons.chevronRight,
                size: 16,
                color: tokens.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultItemRow extends StatelessWidget {
  final BaseWorkspaceItem item;
  final String query;
  final VoidCallback onTap;

  const _SearchResultItemRow({
    required this.item,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(item.paletteId);
    final bandColor = palette.resolveCardColor(tokens.isDark);
    final isIdle = query.isEmpty;
    final snippet = isIdle ? '' : item.extractMatchSnippet(query).trim();

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: bandColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title.trim().isEmpty ? 'Untitled' : item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm(
                              color: tokens.textPrimary,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (item.isFavorite) ...[
                          const SizedBox(width: AppSpacing.s2),
                          TackPinBadge(color: tokens.accentPin, size: 10),
                        ],
                      ],
                    ),
                    if (snippet.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        snippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isIdle) ...[
                const SizedBox(width: AppSpacing.s2),
                Text(
                  item is WhiteboardCanvasItem ? 'Board' : 'Note',
                  style: AppTypography.caption(color: tokens.textTertiary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

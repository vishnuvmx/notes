import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/base_item.dart';
import '../../whiteboard/models/whiteboard_item.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/providers/workspace_provider.dart';
import '../../../shared/widgets/create_item_sheet.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/z_order_column.dart';
import '../../folders/screens/folder_view_screen.dart';
import '../../settings/screens/settings_screen.dart';

/// Unified **Search & "Do anything"** screen (`05-information-architecture.md` §3, `10-design.md` §5.2).
///
/// Searches full note body text, tags, board node labels, open tasks, and
/// workspace commands in a single calm surface, grouped by:
/// `Actions · Notes · Boards · Tasks`.
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

  List<_CommandEntry> _buildCommands(BuildContext context) {
    final workspace = context.read<WorkspaceProvider>();
    final themeProv = context.read<ThemeProvider>();

    return [
      _CommandEntry(
        icon: TackIcons.sun,
        title: "Open Today's Daily Note",
        subtitle: 'Jump to today’s note with carried-forward tasks',
        keywords: 'today daily note journal focus',
        onExecute: () async {
          final daily = await workspace.openOrCreateTodaysNote();
          if (mounted) widget.onOpenItem(daily);
        },
      ),
      _CommandEntry(
        icon: TackIcons.plus,
        title: 'Capture to Inbox',
        subtitle: 'Open fast capture sheet',
        keywords: 'new capture inbox note template',
        onExecute: () async {
          final created = await CreateItemSheet.show(context);
          if (created != null && mounted) {
            widget.onOpenItem(created, startInEditMode: true);
          }
        },
      ),
      _CommandEntry(
        icon: TackIcons.boards,
        title: 'Create New Board',
        subtitle: 'Start a visual flowchart & spec board',
        keywords: 'new board canvas whiteboard flowchart diagram',
        onExecute: () async {
          final board = await workspace.createQuickItem(
            title: 'Untitled Board',
            type: ItemType.whiteboard,
            paletteId: 'cyan',
          );
          if (mounted) widget.onOpenItem(board);
        },
      ),
      _CommandEntry(
        icon: TackIcons.moon,
        title: 'Switch Theme (System / Light / Dark)',
        subtitle: 'Toggle Soft Monochrome light or dark appearance',
        keywords: 'theme dark mode light mode appearance',
        onExecute: () => themeProv.toggleTheme(context),
      ),
      _CommandEntry(
        icon: TackIcons.trash,
        title: 'Open Trash',
        subtitle: 'Restore or permanently delete trashed items',
        keywords: 'trash deleted restore empty',
        onExecute: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const FolderViewScreen(
                folderType: FolderType.trash,
              ),
            ),
          );
        },
      ),
      _CommandEntry(
        icon: TackIcons.settings,
        title: 'Settings & Backup',
        subtitle: 'Export or import workspace JSON backup',
        keywords: 'settings backup export import restore json',
        onExecute: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            ),
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

    final allCommands = _buildCommands(context);
    final matchingCommands = q.isEmpty
        ? allCommands.take(4).toList()
        : allCommands
            .where((c) =>
                c.title.toLowerCase().contains(lowerQ) ||
                c.keywords.toLowerCase().contains(lowerQ))
            .toList();

    final matchingNotes = q.isEmpty
        ? workspace.libraryNotes.take(6).toList()
        : workspace.allActiveItems
            .where((i) =>
                i.type != ItemType.whiteboard &&
                !i.isTrash &&
                i.matchesQuery(q))
            .toList();

    final matchingBoards = q.isEmpty
        ? workspace.boardItems.take(3).toList()
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

    return Column(
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
            hintText: 'Search notes, boards, tasks, or actions…',
            onChanged: (val) => setState(() => _query = val),
            onClear: () => setState(() => _query = ''),
          ),
        ),
        Expanded(
          child: ListView(
            clipBehavior: Clip.none,
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.s2,
              gutter,
              AppSpacing.s9,
            ),
            children: [
              ZOrderColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasNoResults)
                    Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                  child: Column(
                    children: [
                      TackIcon(
                        TackIcons.search,
                        size: 32,
                        color: tokens.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      Text(
                        'No results for "$q"',
                        style: AppTypography.titleSm(color: tokens.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        'Create a new note with this title directly below.',
                        style: AppTypography.bodySm(color: tokens.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      ElevatedButton(
                        onPressed: () async {
                          final note = await workspace.createQuickItem(
                            title: q,
                            type: ItemType.note,
                            paletteId: 'amber',
                          );
                          if (context.mounted) {
                            widget.onOpenItem(note, startInEditMode: true);
                          }
                        },
                        child: Text('Create note "$q"'),
                      ),
                    ],
                  ),
                ),

              // 1. Actions Group
              if (matchingCommands.isNotEmpty) ...[
                _GroupHeader(
                  title: q.isEmpty ? 'Quick Actions' : 'Actions',
                ),
                const SizedBox(height: AppSpacing.s2),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: tokens.surfacePrimary,
                    shape: SmoothRectangleBorder(
                      borderRadius: AppSpacing.roundedMd,
                      smoothness: AppSpacing.defaultSmoothing,
                    ),
                    shadows: AppSpacing.elev1(tokens.isDark),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        for (int i = 0; i < matchingCommands.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, color: tokens.borderSubtle),
                          _CommandRow(entry: matchingCommands[i]),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
              ],

              // 2. Matching Tasks Group
              if (matchingTasks.isNotEmpty) ...[
                _GroupHeader(title: 'Tasks (${matchingTasks.length})'),
                const SizedBox(height: AppSpacing.s2),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: tokens.surfacePrimary,
                    shape: SmoothRectangleBorder(
                      borderRadius: AppSpacing.roundedMd,
                      smoothness: AppSpacing.defaultSmoothing,
                    ),
                    shadows: AppSpacing.elev1(tokens.isDark),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        for (int i = 0; i < matchingTasks.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, color: tokens.borderSubtle),
                          ListTile(
                          leading: IconButton(
                            icon: TackIcon(
                              TackIcons.taskOpen,
                              size: 20,
                              color: tokens.textSecondary,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              workspace.toggleTask(matchingTasks[i]);
                            },
                          ),
                          title: Text(
                            matchingTasks[i].text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm(
                              color: tokens.textPrimary,
                              weight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'In ${matchingTasks[i].noteTitle}',
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
                ),
              ),
                const SizedBox(height: AppSpacing.s5),
              ],

              // 3. Matching Notes Group
              if (matchingNotes.isNotEmpty) ...[
                _GroupHeader(
                  title: q.isEmpty
                      ? 'Recent Notes'
                      : 'Notes (${matchingNotes.length})',
                ),
                const SizedBox(height: AppSpacing.s2),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: tokens.surfacePrimary,
                    shape: SmoothRectangleBorder(
                      borderRadius: AppSpacing.roundedMd,
                      smoothness: AppSpacing.defaultSmoothing,
                    ),
                    shadows: AppSpacing.elev1(tokens.isDark),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        for (int i = 0; i < matchingNotes.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, color: tokens.borderSubtle),
                          _SearchResultItemRow(
                            item: matchingNotes[i],
                            query: q,
                            onTap: () => widget.onOpenItem(matchingNotes[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
              ],

              // 4. Matching Boards Group
              if (matchingBoards.isNotEmpty) ...[
                _GroupHeader(
                  title: q.isEmpty
                      ? 'Boards'
                      : 'Boards (${matchingBoards.length})',
                ),
                const SizedBox(height: AppSpacing.s2),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: tokens.surfacePrimary,
                    shape: SmoothRectangleBorder(
                      borderRadius: AppSpacing.roundedMd,
                      smoothness: AppSpacing.defaultSmoothing,
                    ),
                    shadows: AppSpacing.elev1(tokens.isDark),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        for (int i = 0; i < matchingBoards.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, color: tokens.borderSubtle),
                          _SearchResultItemRow(
                            item: matchingBoards[i],
                            query: q,
                            onTap: () => widget.onOpenItem(matchingBoards[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  ],
);
  }
}

class _CommandEntry {
  final dynamic icon;
  final String title;
  final String subtitle;
  final String keywords;
  final VoidCallback onExecute;

  const _CommandEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
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
    return Text(
      title,
      style: AppTypography.label(
        color: tokens.textSecondary,
        weight: FontWeight.w600,
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
            vertical: AppSpacing.s2,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm(
                        color: tokens.textPrimary,
                        weight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      entry.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(color: tokens.textTertiary),
                    ),
                  ],
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
    final snippet = item.extractMatchSnippet(query);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 36,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: bandColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title.trim().isEmpty ? 'Untitled' : item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSm(
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                        if (item.isFavorite) ...[
                          const SizedBox(width: AppSpacing.s2),
                          TackPinBadge(color: tokens.accentPin, size: 8),
                        ],
                      ],
                    ),
                    if (snippet.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      '${item is WhiteboardCanvasItem ? "Board" : (item.isInbox ? "Inbox" : "Note")} · ${DateFormatter.formatTimestamp(item.updatedAt)}',
                      style: AppTypography.caption(color: tokens.textTertiary),
                    ),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/models/base_item.dart';
import '../../../state/workspace_provider.dart';
import '../../components/app_bars/app_header_bar.dart';
import '../../components/cards/board_grid_card.dart';
import '../../components/cards/neo_note_card.dart';
import '../../components/cards/responsive_card_grid.dart';
import '../../components/dialogs_sheets/app_bottom_sheet.dart';
import '../../components/dialogs_sheets/card_peek_sheet.dart';
import '../../components/dialogs_sheets/create_item_sheet.dart';
import '../../components/feedback/empty_state_widget.dart';
import '../../components/navigation/smart_bottom_nav_bar.dart';
import '../search/search_command_screen.dart';
import '../settings/profile_settings_screen.dart';
import '../today/today_screen.dart';

/// Main 5-Slot Application Shell for Tack (`05-information-architecture.md` §2.1, `10-design.md` §4).
///
/// Bottom Navigation Bar slots:
/// - `0`: **Today** (`TodayScreen`)
/// - `1`: **Library** (`_LibraryView` — GRID ONLY, no rotation, Paper & Pin cards)
/// - `2`: **(+) Capture** (`CreateItemSheet`)
/// - `3`: **Boards** (`_BoardsView` — `BoardGridCard`s with live mini-thumbnails)
/// - `4`: **Search** (`SearchCommandScreen` — full-text + "Do anything")
class HomeScreen extends StatefulWidget {
  final void Function(BaseWorkspaceItem item, {bool startInEditMode})? onOpenItem;
  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenTrash;
  final VoidCallback? onOpenArchive;

  const HomeScreen({
    super.key,
    this.onOpenItem,
    this.onOpenFavorites,
    this.onOpenSettings,
    this.onOpenTrash,
    this.onOpenArchive,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _openItem(BaseWorkspaceItem item, {bool startInEditMode = false}) {
    if (widget.onOpenItem != null) {
      widget.onOpenItem!(item, startInEditMode: startInEditMode);
    } else {
      openWorkspaceItemScreen(
        context,
        item,
        startInEditMode: startInEditMode,
      );
    }
  }

  Future<void> _openCaptureSheet({ItemType? defaultType}) async {
    final created = await CreateItemSheet.show(
      context,
      defaultType: defaultType,
    );
    if (created != null && mounted) {
      _openItem(
        created,
        startInEditMode: created.type != ItemType.whiteboard,
      );
    }
  }

  void _handleBottomNavTap(int index) {
    final workspace = context.read<WorkspaceProvider>();
    if (index == 2) {
      _openCaptureSheet(
        defaultType: workspace.bottomNavIndex == 3
            ? ItemType.whiteboard
            : ItemType.note,
      );
      return;
    }
    workspace.setBottomNavIndex(index);
  }

  String _titleForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Today';
      case 1:
        return 'Library';
      case 3:
        return 'Boards';
      case 4:
        return 'Search';
      default:
        return 'Today';
    }
  }

  String? _subtitleForTab(int tabIndex, WorkspaceProvider workspace) {
    switch (tabIndex) {
      case 1:
        final count = workspace.libraryNotes.length;
        return '$count';
      case 3:
        final count = workspace.boardItems.length;
        return '$count';
      default:
        return null;
    }
  }

  void _showSortSheet(BuildContext context, WorkspaceProvider workspace) {
    AppBottomSheet.show<void>(
      context: context,
      builder: (ctx) {
        final tokens = ctx.tokens;
        final current = workspace.sortMode;
        final options = [
          (mode: HomeSortMode.newestFirst, label: 'Recently updated (Pinned first)'),
          (mode: HomeSortMode.oldestFirst, label: 'Oldest created first'),
          (mode: HomeSortMode.alphabetical, label: 'Title (A – Z)'),
        ];
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
                'Sort items',
                style: AppTypography.titleSm(color: tokens.textPrimary),
              ),
              const SizedBox(height: AppSpacing.s2),
              for (final opt in options)
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    workspace.setSortMode(opt.mode);
                    Navigator.of(ctx).pop();
                  },
                  borderRadius: AppSpacing.roundedSm,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s2,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt.label,
                              style: AppTypography.body(
                                color: tokens.textPrimary,
                                weight: current == opt.mode
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (current == opt.mode)
                            TackIcon(
                              TackIcons.check,
                              size: 18,
                              color: tokens.accentPin,
                            ),
                        ],
                      ),
                    ),
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
    final workspace = context.watch<WorkspaceProvider>();
    final activeTab = workspace.bottomNavIndex;
    final canPopApp = activeTab == 0;

    return PopScope(
      canPop: canPopApp,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (activeTab != 0) {
          workspace.setBottomNavIndex(0);
        }
      },
      child: Scaffold(
        backgroundColor: tokens.canvasPrimary,
        appBar: AppHeaderBar(
          title: _titleForTab(activeTab),
          subtitle: _subtitleForTab(activeTab, workspace),
          tagline: activeTab == 0 ? "Let's make progress today!" : null,
          trailingAction: (activeTab == 1 || activeTab == 3)
              ? IconButton(
                  key: const ValueKey('header_sort_button'),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _showSortSheet(context, workspace);
                  },
                  tooltip: 'Sort',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(
                      AppSpacing.minTouchTarget,
                      AppSpacing.minTouchTarget,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  icon: Container(
                    width: 38,
                    height: 38,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: tokens.surfacePrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppSpacing.elev1(tokens.isDark),
                    ),
                    child: Center(
                      child: TackIcon(
                        TackIcons.sort,
                        size: 18,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                )
              : null,
          onOpenProfileSettings: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileSettingsScreen(),
              ),
            );
          },
        ),
        body: workspace.isLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _stackIndexForTab(activeTab),
                children: [
                  // 0: Today
                  TodayScreen(onOpenItem: _openItem),

                  // 1: Library
                  _LibraryView(
                    onOpenItem: _openItem,
                    onCreateNote: () => _openCaptureSheet(
                      defaultType: ItemType.note,
                    ),
                  ),

                  // 2: Boards (tab index 3)
                  _BoardsView(
                    onOpenItem: _openItem,
                    onCreateBoard: () async {
                      final board = await workspace.createQuickItem(
                        title: 'Untitled Board',
                        type: ItemType.whiteboard,
                        paletteId: 'cyan',
                      );
                      if (mounted) _openItem(board);
                    },
                  ),

                  // 3: Search (tab index 4)
                  SearchCommandScreen(onOpenItem: _openItem),
                ],
              ),
        bottomNavigationBar: SmartBottomNavBar(
          currentIndex: activeTab,
          inboxCount: workspace.inboxItems.length,
          onTap: _handleBottomNavTap,
          onFabTap: () => _openCaptureSheet(
            defaultType: activeTab == 3 ? ItemType.whiteboard : ItemType.note,
          ),
        ),
      ),
    );
  }

  int _stackIndexForTab(int tab) {
    switch (tab) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      default:
        return 0;
    }
  }
}

class _LibraryView extends StatelessWidget {
  final void Function(BaseWorkspaceItem item, {bool startInEditMode}) onOpenItem;
  final VoidCallback onCreateNote;

  const _LibraryView({
    required this.onOpenItem,
    required this.onCreateNote,
  });

  void _showFolderSheet(BuildContext context, WorkspaceProvider workspace) {
    final newFolderCtrl = TextEditingController();
    AppBottomSheet.show<void>(
      context: context,
      builder: (ctx) {
        final tokens = ctx.tokens;
        final folders = workspace.folders;
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
                'Folders',
                style: AppTypography.titleSm(color: tokens.textPrimary),
              ),
              const SizedBox(height: AppSpacing.s3),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: folders.length,
                  itemBuilder: (_, idx) {
                    final f = folders[idx];
                    final selected = workspace.selectedFolder == f;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: TackIcon(
                        TackIcons.folder,
                        size: 18,
                        color: selected
                            ? tokens.accentPin
                            : tokens.textSecondary,
                      ),
                      title: Text(
                        f,
                        style: AppTypography.body(
                          color: tokens.textPrimary,
                          weight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: selected
                          ? TackIcon(
                              TackIcons.check,
                              size: 18,
                              color: tokens.accentPin,
                            )
                          : null,
                      onTap: () {
                        workspace.setSelectedFolder(f);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: newFolderCtrl,
                      decoration: const InputDecoration(
                        hintText: 'New folder name…',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  ElevatedButton(
                    onPressed: () async {
                      final name = newFolderCtrl.text.trim();
                      if (name.isEmpty) return;
                      await workspace.addFolder(name);
                      workspace.setSelectedFolder(name);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: const Text('Add'),
                  ),
                ],
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
    final workspace = context.watch<WorkspaceProvider>();
    final notes = workspace.libraryNotes;
    final tags = workspace.availableTags;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gutter = AppSpacing.screenGutter(screenWidth);
    final cols = AppSpacing.gridColumnsForWidth(screenWidth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Single-row Filter Bar: Folder pill · Pinned chip · Real #tag chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            children: [
              // Folder selector chip
              _LibraryFilterChip(
                icon: TackIcons.folder,
                label: workspace.selectedFolder,
                isSelected: workspace.selectedFolder != 'All Notes',
                showChevron: true,
                onTap: () => _showFolderSheet(context, workspace),
              ),
              const SizedBox(width: AppSpacing.s2),

              // Pinned filter chip
              _LibraryFilterChip(
                leadingWidget: TackPinBadge(
                  color: workspace.pinnedFilterOnly
                      ? tokens.actionPrimaryFg
                      : tokens.accentPin,
                  size: 8,
                ),
                label: 'Pinned',
                isSelected: workspace.pinnedFilterOnly,
                onTap: () => workspace.setPinnedFilterOnly(
                  !workspace.pinnedFilterOnly,
                ),
              ),

              // Dynamic user tags (only real tags present in user notes)
              for (final tag in tags) ...[
                const SizedBox(width: AppSpacing.s2),
                _LibraryFilterChip(
                  label: '#$tag',
                  isSelected: workspace.selectedTag?.toLowerCase() ==
                      tag.toLowerCase(),
                  onTap: () => workspace.setTagFilter(tag),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s2),

        // Grid feed
        Expanded(
          child: notes.isEmpty
              ? EmptyStateWidget(
                  icon: TackIcons.notes,
                  title: workspace.pinnedFilterOnly
                      ? 'No pinned notes yet'
                      : (workspace.selectedTag != null
                          ? 'No #${workspace.selectedTag} notes'
                          : 'Your Library is empty'),
                  subtitle: workspace.pinnedFilterOnly
                      ? 'Long-press any note to pin it to the top.'
                      : 'Tap (+) below to write a note or save a thought.',
                  actionLabel: workspace.pinnedFilterOnly ||
                          workspace.selectedTag != null ||
                          workspace.selectedFolder != 'All Notes'
                      ? 'Reset filters'
                      : 'New note',
                  onAction: () {
                    if (workspace.pinnedFilterOnly ||
                        workspace.selectedTag != null ||
                        workspace.selectedFolder != 'All Notes') {
                      workspace.setPinnedFilterOnly(false);
                      workspace.setTagFilter(null);
                      workspace.setSelectedFolder('All Notes');
                    } else {
                      onCreateNote();
                    }
                  },
                )
              : ResponsiveCardGrid(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.s2,
                    gutter,
                    AppSpacing.s9,
                  ),
                  crossAxisCount: cols,
                  mainAxisSpacing: AppSpacing.cardGridGap,
                  crossAxisSpacing: AppSpacing.cardGridGap,
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return NeoNoteCard(
                      key: ValueKey('lib_note_${note.id}'),
                      item: note,
                      onTap: () => onOpenItem(note),
                      onLongPress: () => CardPeekSheet.show(
                        context: context,
                        item: note,
                        onOpen: () => onOpenItem(note),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BoardsView extends StatelessWidget {
  final void Function(BaseWorkspaceItem item, {bool startInEditMode}) onOpenItem;
  final VoidCallback onCreateBoard;

  const _BoardsView({
    required this.onOpenItem,
    required this.onCreateBoard,
  });

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<WorkspaceProvider>();
    final boards = workspace.boardItems;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gutter = AppSpacing.screenGutter(screenWidth);
    final cols = AppSpacing.gridColumnsForWidth(screenWidth);

    if (boards.isEmpty) {
      return EmptyStateWidget(
        icon: TackIcons.boards,
        title: 'No Boards yet',
        subtitle:
            'Map flowcharts, system diagrams, and pin Markdown Spec Cards on an infinite board.',
        actionLabel: 'Create Board',
        onAction: onCreateBoard,
      );
    }

    return ResponsiveCardGrid(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.s2,
        gutter,
        AppSpacing.s9,
      ),
      crossAxisCount: cols,
      mainAxisSpacing: AppSpacing.cardGridGap,
      crossAxisSpacing: AppSpacing.cardGridGap,
      itemCount: boards.length,
      itemBuilder: (context, index) {
        final board = boards[index];
        return BoardGridCard(
          key: ValueKey('board_card_${board.id}'),
          board: board,
          onTap: () => onOpenItem(board),
          onLongPress: () => CardPeekSheet.show(
            context: context,
            item: board,
            onOpen: () => onOpenItem(board),
          ),
        );
      },
    );
  }
}

class _LibraryFilterChip extends StatelessWidget {
  final dynamic icon;
  final Widget? leadingWidget;
  final String label;
  final bool isSelected;
  final bool showChevron;
  final VoidCallback onTap;

  const _LibraryFilterChip({
    this.icon,
    this.leadingWidget,
    required this.label,
    required this.isSelected,
    this.showChevron = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bg = isSelected ? tokens.actionPrimary : tokens.surfacePrimary;
    final fg = isSelected ? tokens.actionPrimaryFg : tokens.textPrimary;

    return Center(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: AppSpacing.roundedPill,
        child: AnimatedContainer(
          duration: AppSpacing.durationFast,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppSpacing.roundedPill,
            boxShadow: AppSpacing.elev1(tokens.isDark),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingWidget != null) ...[
                leadingWidget!,
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                TackIcon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTypography.label(
                  color: fg,
                  weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 4),
                TackIcon(TackIcons.chevronDown, size: 13, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

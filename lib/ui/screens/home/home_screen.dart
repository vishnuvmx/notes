import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/sticky_note.dart';
import '../../../domain/models/clipboard_item.dart';
import '../../../state/workspace_provider.dart';
import '../../components/app_bars/app_header_bar.dart';
import '../../components/inputs/category_filter_pills.dart';
import '../../components/inputs/tack_dropdown.dart';
import '../../components/cards/neo_note_card.dart';
import '../../components/cards/smart_note_list_card.dart';
import '../../components/cards/sticky_note_card.dart';
import '../../components/cards/clipboard_card.dart';
import '../../components/dialogs_sheets/create_item_sheet.dart';
import '../../components/navigation/smart_bottom_nav_bar.dart';
import '../../components/navigation/app_nav_drawer.dart';
import '../../components/feedback/empty_state_widget.dart';
import '../../components/feedback/tack_toast.dart';
import '../../components/dialogs_sheets/note_action_sheet.dart';
import '../graph/knowledge_graph_screen.dart';

/// Main Home Dashboard Screen for Tack.
/// Features the Playful Neo-Pop / Soft Neo-Brutalist design matching the Dribbble reference.
class HomeScreen extends StatefulWidget {
  final Function(BaseWorkspaceItem item)? onOpenItem;
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearching = false;
  late final ScrollController _scrollController;
  bool _isBarsVisible = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isSearching) {
      if (!_isBarsVisible) setState(() => _isBarsVisible = true);
      return;
    }
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;

    if (offset <= 12) {
      if (!_isBarsVisible) {
        setState(() => _isBarsVisible = true);
      }
    } else if (delta > 3 && _isBarsVisible) {
      // User is scrolling down: hide navbar and top bar along the motion
      setState(() => _isBarsVisible = false);
    } else if (delta < -3 && !_isBarsVisible) {
      // User is scrolling up: restore navbar and top bar immediately
      setState(() => _isBarsVisible = true);
    }
    _lastScrollOffset = offset;
  }

  String _getHeadlineTitle(ItemType? category) {
    switch (category) {
      case null:
        return 'Your Files';
      case ItemType.note:
        return 'Your Notes';
      case ItemType.whiteboard:
        return 'Your Boards';
      case ItemType.clipboard:
        return 'Clipboard';
      case ItemType.sticky:
        return 'Your Stickies';
    }
  }

  void _openCreateSheet({ItemType? defaultType}) async {
    final newItem = await CreateItemSheet.show(context, defaultType: defaultType);
    if (newItem != null && widget.onOpenItem != null) {
      widget.onOpenItem!(newItem);
    }
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.mediumImpact();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (!mounted) return;

    if (text == null || text.isEmpty) {
      TackToast.show(
        context,
        message: 'Clipboard is empty',
        icon: TackIcons.clipboard,
        iconColor: AppColors.accentAmber,
        bottomMargin: 88,
      );
      return;
    }

    final workspace = context.read<WorkspaceProvider>();

    // Rule 1: Do not add individual numbers (e.g. standalone numbers)
    if (WorkspaceProvider.isIndividualNumber(text)) {
      TackToast.show(
        context,
        message: 'Numbers are skipped',
        icon: TackIcons.close,
        iconColor: AppColors.error,
        bottomMargin: 88,
      );
      return;
    }

    // Rule 2: Do not add duplicates (if added once, don't add again)
    if (workspace.isClipboardDuplicate(text)) {
      TackToast.show(
        context,
        message: 'Already in clipboard',
        icon: TackIcons.checkCircle,
        iconColor: AppColors.accentAmber,
        bottomMargin: 88,
      );
      return;
    }

    final item = await workspace.saveClipboardSnippet(text);
    if (mounted && item != null) {
      TackToast.show(
        context,
        message: 'Saved to clips',
        icon: TackIcons.checkCircle,
        iconColor: AppColors.success,
        actionLabel: 'Open',
        onAction: () => widget.onOpenItem?.call(item),
        bottomMargin: 88,
      );
    }
  }

  void _handleBottomNavTap(int index) {
    if (!_isBarsVisible) {
      setState(() => _isBarsVisible = true);
    }
    final workspace = context.read<WorkspaceProvider>();

    switch (index) {
      case 0:
        workspace.setCategory(null);
        break;
      case 1:
        workspace.setCategory(ItemType.note);
        break;
      case 2:
        _openCreateSheet();
        break;
      case 3:
        workspace.setCategory(ItemType.whiteboard);
        break;
      case 4:
        workspace.setCategory(ItemType.clipboard);
        break;
    }
  }

  int _calculateNavIndex(ItemType? category) {
    if (category == null) return 0;
    switch (category) {
      case ItemType.note:
        return 1;
      case ItemType.whiteboard:
        return 3;
      case ItemType.clipboard:
        return 4;
      case ItemType.sticky:
        return 0; // Sticky is shown on home dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.watch<WorkspaceProvider>();
    final items = workspace.items;
    final currentNavIndex = _calculateNavIndex(workspace.selectedCategory);

    final headlineColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF191A23);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFF191A23);
    final canPopHome = !(_scaffoldKey.currentState?.isDrawerOpen ?? false) &&
        !_isSearching &&
        workspace.selectedCategory == null;

    return PopScope(
      canPop: canPopHome,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            workspace.setSearchQuery('');
          });
          return;
        }
        if (workspace.selectedCategory != null) {
          workspace.setCategory(null);
          return;
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawerEnableOpenDragGesture: false,
        extendBody: true,
        drawer: AppNavDrawer(
          onOpenFavorites: widget.onOpenFavorites ?? () => workspace.setSelectedFolder('Favorites'),
          onOpenArchive: widget.onOpenArchive,
          onOpenTrash: widget.onOpenTrash,
          onOpenSettings: widget.onOpenSettings,
          onOpenItem: widget.onOpenItem,
        ),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Collapsible Top Session: AppHeaderBar + "Your Notes" headline + filter pills
                ClipRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.bottomCenter,
                    heightFactor: (_isBarsVisible || _isSearching) ? 1.0 : 0.0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: (_isBarsVisible || _isSearching) ? 1.0 : 0.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: MediaQuery.paddingOf(context).top),
                          AppHeaderBar(
                            primary: false,
                            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                            onToggleSearch: () {
                              setState(() {
                                _isSearching = !_isSearching;
                                if (!_isSearching) {
                                  workspace.setSearchQuery('');
                                }
                              });
                            },
                            isSearching: _isSearching,
                            onQuickCreate: () => _openCreateSheet(),
                          ),
                          // 1. Headline + Rounded Rect [+] Quick Add Button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, AppSpacing.lg, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    _getHeadlineTitle(workspace.selectedCategory),
                                    style: AppTypography.sectionHeadline(
                                      color: headlineColor,
                                      fontSize: 34,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Sort Selector Menu
                                    _SortButton(
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      activeSort: workspace.sortOrder,
                                      onSelected: (order) {
                                        HapticFeedback.lightImpact();
                                        workspace.setSortOrder(order);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    // Tactile [+] Button with dark border matching reference
                                    _QuickAddButton(
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      onTap: () => _openCreateSheet(defaultType: workspace.selectedCategory),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 2. Folder Dropdown + Tag Filter Pills + Quick Habit Bar (Notes / All)
                          if (workspace.selectedCategory != ItemType.whiteboard &&
                              workspace.selectedCategory != ItemType.clipboard) ...[
                            if (!_isSearching)
                              _buildQuickWorkspaceActionsBar(workspace, isDark, borderColor),
                            const CategoryFilterPills(),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Main Notes Feed: Neo-Pop Grid, Clean Notebook List, or Clipboard List
                Expanded(
                  child: ClipRect(
                  child: NotificationListener<UserScrollNotification>(
                    onNotification: (notification) {
                      if (_isSearching) return false;
                      if (notification.direction == ScrollDirection.reverse) {
                        if (_isBarsVisible && _scrollController.hasClients && _scrollController.offset > 8) {
                          setState(() => _isBarsVisible = false);
                        }
                      } else if (notification.direction == ScrollDirection.forward) {
                        if (!_isBarsVisible) {
                          setState(() => _isBarsVisible = true);
                        }
                      }
                      return false;
                    },
                    child: workspace.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : items.isEmpty
                            ? _buildEmptyState(workspace)
                            : (workspace.selectedCategory == ItemType.clipboard
                                ? _buildClipboardListView(items.whereType<ClipboardItem>().toList(), isDark)
                                : (workspace.viewMode == HomeViewMode.notebook &&
                                        workspace.selectedCategory != ItemType.whiteboard
                                    ? _buildNotebookListView(items)
                                    : _buildNeoGridFeedView(items))),
                  ),
                  ),
                ),
              ],
            ),

            // Floating Bottom Popup Dock for Clipboard Category
            if (workspace.selectedCategory == ItemType.clipboard)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: (_isBarsVisible && !_isSearching) ? (76 + MediaQuery.paddingOf(context).bottom) : -120,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: (_isBarsVisible && !_isSearching) ? 1.0 : 0.0,
                  child: _buildClipboardBottomDock(isDark),
                ),
              ),
          ],
        ),
        bottomNavigationBar: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: (_isBarsVisible && !_isSearching) ? Offset.zero : const Offset(0, 1.25),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: (_isBarsVisible && !_isSearching) ? 1.0 : 0.0,
            child: SmartBottomNavBar(
              currentIndex: currentNavIndex,
              onTap: _handleBottomNavTap,
              onFabTap: () => _openCreateSheet(defaultType: workspace.selectedCategory),
            ),
          ),
        ),
      ),
    );
  }

  /// Floating bottom dock for quick paste when viewing Clipboard category
  Widget _buildClipboardBottomDock(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF191A23).withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pasteFromClipboard,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.accentAmber.withValues(alpha: isDark ? 0.2 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentAmber.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: TackIcon(
                      TackIcons.clipboard,
                      size: 20,
                      color: AppColors.accentAmber,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Save from Clipboard',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Tap to import copied snippet',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentAmber,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentAmber.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TackIcon(
                        TackIcons.pasteSvg,
                        size: 14,
                        color: Color(0xFF191A23),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Paste',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF191A23),
                          letterSpacing: -0.2,
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

  Widget _buildClipboardListView(List<ClipboardItem> clips, bool isDark) {
    final sortedClips = List<ClipboardItem>.from(clips);
    sortedClips.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(
        0,
        AppSpacing.xs,
        0,
        140 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: sortedClips.length,
      itemBuilder: (context, index) {
        final item = sortedClips[index];
        return ClipboardCard(
          key: ValueKey(item.id),
          item: item,
          onTap: () => widget.onOpenItem?.call(item),
          onLongPress: () => NoteActionSheet.show(context, item: item),
        );
      },
    );
  }


  Widget _buildQuickWorkspaceActionsBar(
    WorkspaceProvider workspace,
    bool isDark,
    Color borderColor,
  ) {
    Widget chip({
      required String label,
      String? emoji,
      IconData? icon,
      required Color accent,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isDark ? accent.withValues(alpha: 0.45) : borderColor,
              width: 1.35,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF191A23).withValues(alpha: 0.06),
                      blurRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji, style: const TextStyle(fontSize: 13.5)),
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(icon, size: 14, color: accent),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                  color: isDark ? Colors.white : const Color(0xFF191A23),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            chip(
              emoji: '☀️',
              label: "Today's Note",
              accent: AppColors.accentAmber,
              onTap: () async {
                HapticFeedback.mediumImpact();
                final daily = await workspace.openOrCreateTodaysNote();
                widget.onOpenItem?.call(daily);
              },
            ),
            const SizedBox(width: 8),
            chip(
              emoji: '⚡',
              label: 'Quick Note',
              accent: AppColors.pastelLimeLight,
              onTap: () async {
                HapticFeedback.mediumImpact();
                final created = await workspace.createQuickItem(
                  title: 'Untitled Note',
                  type: ItemType.note,
                  paletteId: 'peach',
                );
                widget.onOpenItem?.call(created);
              },
            ),
            const SizedBox(width: 8),
            chip(
              icon: LucideIcons.network,
              label: 'Graph',
              accent: AppColors.accentCyan,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const KnowledgeGraphScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotebookListView(List<BaseWorkspaceItem> items) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(
        0,
        AppSpacing.xs,
        0,
        96 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return SmartNoteListCard(
          key: ValueKey(item.id),
          item: item,
          index: index,
          onTap: () => widget.onOpenItem?.call(item),
          onLongPress: () => NoteActionSheet.show(context, item: item),
        );
      },
    );
  }

  Widget _buildCard(BaseWorkspaceItem item) {
    if (item is StickyNote) {
      return StickyNoteCard(
        item: item,
        onTap: () => widget.onOpenItem?.call(item),
        onLongPress: () => NoteActionSheet.show(context, item: item),
      );
    }
    return NeoNoteCard(
      item: item,
      isGrid: true,
      onTap: () => widget.onOpenItem?.call(item),
      onLongPress: () => NoteActionSheet.show(context, item: item),
    );
  }

  Widget _buildNeoGridFeedView(List<BaseWorkspaceItem> items) {
    final leftItems = <BaseWorkspaceItem>[];
    final rightItems = <BaseWorkspaceItem>[];

    for (int i = 0; i < items.length; i++) {
      if (i.isEven) {
        leftItems.add(items[i]);
      } else {
        rightItems.add(items[i]);
      }
    }

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        88,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column 1 (Starts at top)
          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < leftItems.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Transform.rotate(
                      angle: i.isEven ? -0.035 : -0.022,
                      child: SizedBox(
                        height: 218,
                        child: _buildCard(leftItems[i]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Column 2 (Staggered offset downwards like reference image)
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 38), // Stagger offset matching mockup!
                for (int i = 0; i < rightItems.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Transform.rotate(
                      angle: i.isEven ? 0.028 : 0.032,
                      child: SizedBox(
                        height: 218,
                        child: _buildCard(rightItems[i]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState(WorkspaceProvider workspace) {
    final cat = workspace.selectedCategory;
    final tag = workspace.selectedTag;

    String title;
    String subtitle;
    String actionLabel;
    IconData icon;

    if (workspace.searchQuery.isNotEmpty) {
      title = 'Nothing found';
      subtitle = 'No matches for "${workspace.searchQuery}". Try a different term.';
      actionLabel = 'Clear Search';
      icon = TackIcons.search;
    } else if (cat == ItemType.whiteboard) {
      title = 'No Whiteboards Yet';
      subtitle = 'Create diagrams, mindmaps, and visual workflows.';
      actionLabel = 'New Whiteboard';
      icon = TackIcons.whiteboard;
    } else if (cat == ItemType.clipboard) {
      title = 'No Clips Yet';
      subtitle = 'Save code snippets, text excerpts, and copied links.';
      actionLabel = 'Paste from Clipboard';
      icon = TackIcons.clipboard;
    } else if (tag != null && tag != '#All' && tag != 'All') {
      title = 'No $tag notes yet';
      subtitle = 'Create a note with this tag or tap (+) to add one.';
      actionLabel = 'Create Note';
      icon = TackIcons.notes;
    } else {
      title = 'No Notes Yet';
      subtitle = 'Tap (+) below to create your first note or board.';
      actionLabel = 'Create Note';
      icon = TackIcons.notes;
    }

    return EmptyStateWidget(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: workspace.searchQuery.isNotEmpty
          ? () {
              setState(() => _isSearching = false);
              workspace.setSearchQuery('');
            }
          : (cat == ItemType.clipboard
              ? () => _pasteFromClipboard()
              : () => _openCreateSheet(defaultType: workspace.selectedCategory)),
    );
  }
}

class _QuickAddButton extends StatefulWidget {
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<_QuickAddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.borderColor, width: 1.6),
            boxShadow: widget.isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF191A23).withValues(alpha: _pressed ? 0.02 : 0.08),
                      blurRadius: 0,
                      offset: Offset(0, _pressed ? 1 : 2),
                    ),
                  ],
          ),
          child: Center(
            child: TackIcon(
              TackIcons.plusSvg,
              size: 24,
              color: widget.isDark ? AppColors.darkTextPrimary : const Color(0xFF191A23),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final bool isDark;
  final Color borderColor;
  final NoteSortOrder activeSort;
  final ValueChanged<NoteSortOrder> onSelected;

  const _SortButton({
    required this.isDark,
    required this.borderColor,
    required this.activeSort,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TackDropdown<NoteSortOrder>(
      value: activeSort,
      customLabel: '',
      onSelected: onSelected,
      tooltip: 'Sort Notes',
      leadingIcon: TackIcons.listView,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      borderColor: borderColor,
      items: const [
        TackDropdownItem(
          value: NoteSortOrder.recentlyModified,
          label: 'Recently Modified',
          icon: TackIcons.clock,
        ),
        TackDropdownItem(
          value: NoteSortOrder.dateCreated,
          label: 'Date Created',
          icon: TackIcons.notes,
        ),
        TackDropdownItem(
          value: NoteSortOrder.titleAZ,
          label: 'Title (A–Z)',
          icon: TackIcons.tag,
        ),
      ],
    );
  }
}


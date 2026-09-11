import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/clipboard_item.dart';
import '../../../state/workspace_provider.dart';
import '../../components/app_bars/app_header_bar.dart';
import '../../components/inputs/category_filter_pills.dart';
import '../../components/cards/neo_note_card.dart';
import '../../components/cards/clipboard_card.dart';
import '../../components/dialogs_sheets/create_item_sheet.dart';
import '../../components/navigation/smart_bottom_nav_bar.dart';
import '../../components/navigation/app_nav_drawer.dart';
import '../../components/feedback/empty_state_widget.dart';

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
    if (_scrollController.hasClients && _scrollController.offset <= 12) {
      if (!_isBarsVisible) {
        setState(() => _isBarsVisible = true);
      }
    }
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
        return 'Your Saves';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (text != null && text.isNotEmpty) {
      final workspace = context.read<WorkspaceProvider>();
      final item = await workspace.saveClipboardSnippet(text);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 10,
            backgroundColor: isDark ? const Color(0xFF14151B) : const Color(0xFF191A23),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : const Color(0xFF2C2E3B),
                width: 1.2,
              ),
            ),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: TackIcon(TackIcons.check, size: 18, color: AppColors.success),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saved to Notes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    widget.onOpenItem?.call(item);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Open',
                      style: TextStyle(
                        color: Color(0xFF191A23),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 10,
          backgroundColor: isDark ? const Color(0xFF14151B) : const Color(0xFF191A23),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : const Color(0xFF2C2E3B),
              width: 1.2,
            ),
          ),
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: TackIcon(TackIcons.clipboard, size: 18, color: AppColors.accentAmber),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Clipboard is Empty',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Copy text from any app to save it here',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: AppNavDrawer(
        onOpenFavorites: widget.onOpenFavorites ?? () => workspace.setCategory(null),
        onOpenArchive: widget.onOpenArchive,
        onOpenTrash: widget.onOpenTrash,
        onOpenSettings: widget.onOpenSettings,
      ),
      appBar: AppHeaderBar(
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
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Collapsible Top Section ("Your Files" / "Your Notes" + Folder Dropdown + Filter Pills)
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.bottomCenter,
                  heightFactor: _isBarsVisible ? 1.0 : 0.0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _isBarsVisible ? 1.0 : 0.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
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

                              // Tactile [+] Button with dark border matching reference
                              _QuickAddButton(
                                isDark: isDark,
                                borderColor: borderColor,
                                onTap: () => _openCreateSheet(defaultType: workspace.selectedCategory),
                              ),
                            ],
                          ),
                        ),

                        // 2. Folder Dropdown + Tag Filter Pills (Only shown for Notes / All)
                        if (workspace.selectedCategory != ItemType.whiteboard &&
                            workspace.selectedCategory != ItemType.clipboard) ...[
                          const CategoryFilterPills(),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Main Notes Feed: Neo-Pop Grid Feed with scroll listener
              Expanded(
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    if (notification.direction == ScrollDirection.reverse) {
                      if (_isBarsVisible && _scrollController.hasClients && _scrollController.offset > 24) {
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
                          : _buildNeoGridFeedView(items),
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
              bottom: _isBarsVisible ? (76 + MediaQuery.paddingOf(context).bottom) : -120,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _isBarsVisible ? 1.0 : 0.0,
                child: _buildClipboardBottomDock(isDark),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offset: _isBarsVisible ? Offset.zero : const Offset(0, 1.25),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _isBarsVisible ? 1.0 : 0.0,
          child: SmartBottomNavBar(
            currentIndex: currentNavIndex,
            onTap: _handleBottomNavTap,
            onFabTap: () => _openCreateSheet(defaultType: workspace.selectedCategory),
          ),
        ),
      ),
    );
  }

  /// Floating bottom dock for quick paste when viewing Clipboard category
  Widget _buildClipboardBottomDock(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13141B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFF191A23),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.6)
                : const Color(0xFF191A23).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pasteFromClipboard,
          borderRadius: BorderRadius.circular(18),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF191A23),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Tap to import copied snippet',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TackIcon(
                        TackIcons.copy,
                        size: 14,
                        color: Color(0xFF191A23),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Paste',
                        style: TextStyle(
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

  /// Staggered Neo-Pop Feed matching Reference Mockup (Offset columns instead of rigid matrix)
  Widget _buildNeoGridFeedView(List<BaseWorkspaceItem> items) {
    final isClipboard = context.watch<WorkspaceProvider>().selectedCategory == ItemType.clipboard;
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
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        isClipboard ? 110 : 88,
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
                        child: NeoNoteCard(
                          item: leftItems[i],
                          isGrid: true,
                          onTap: () => widget.onOpenItem?.call(leftItems[i]),
                        ),
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
                        child: NeoNoteCard(
                          item: rightItems[i],
                          isGrid: true,
                          onTap: () => widget.onOpenItem?.call(rightItems[i]),
                        ),
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
    HeroIcons icon;

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
              TackIcons.plus,
              size: 22,
              color: widget.isDark ? AppColors.darkTextPrimary : const Color(0xFF191A23),
            ),
          ),
        ),
      ),
    );
  }
}


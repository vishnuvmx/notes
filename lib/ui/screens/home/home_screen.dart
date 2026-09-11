import 'package:flutter/material.dart';
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
import '../../components/inputs/smart_search_bar.dart';
import '../../components/inputs/category_filter_pills.dart';
import '../../components/cards/neo_note_card.dart';
import '../../components/cards/smart_note_list_card.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const TackIcon(TackIcons.check, size: 18, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saved "${item.title}" from clipboard',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            backgroundColor: isDark ? const Color(0xFF1E2026) : const Color(0xFF191A23),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Open',
              textColor: AppColors.accentAmber,
              onPressed: () => widget.onOpenItem?.call(item),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              TackIcon(TackIcons.clipboard, size: 18, color: Colors.white),
              SizedBox(width: 10),
              Text('System clipboard is currently empty', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          backgroundColor: isDark ? const Color(0xFF1E2026) : const Color(0xFF191A23),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleBottomNavTap(int index) {
    final workspace = context.read<WorkspaceProvider>();

    if (index == 0) {
      workspace.setCategory(null);
    } else if (index == 1) {
      workspace.setCategory(ItemType.note);
    } else if (index == 3) {
      workspace.setCategory(ItemType.whiteboard);
    } else if (index == 4) {
      workspace.setCategory(ItemType.clipboard);
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
    final borderColor = isDark ? const Color(0xFF323642) : const Color(0xFF191A23);

    return Scaffold(
      key: _scaffoldKey,
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated Search Bar
          if (_isSearching) ...[
            SmartSearchBar(
              onClose: () {
                setState(() => _isSearching = false);
                workspace.setSearchQuery('');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // 1. "Your Notes" Headline + Rounded Rect [+] Quick Add Button
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, AppSpacing.lg, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Your Notes',
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

          // 2. Folder Dropdown + View Switcher + Tag Filter Pills
          const CategoryFilterPills(),
          if (workspace.selectedCategory == ItemType.clipboard) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: InkWell(
                onTap: _pasteFromClipboard,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    boxShadow: AppSpacing.floatingControlShadow,
                  ),
                  child: Row(
                    children: [
                      const TackIcon(TackIcons.clipboard, size: 18, color: AppColors.accentAmber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Save from System Clipboard',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: headlineColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.pastelAmberLight.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TackIcon(TackIcons.clipboard, size: 14, color: AppColors.accentAmber),
                            SizedBox(width: 4),
                            Text(
                              'Paste',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentAmber,
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
          ],
          const SizedBox(height: AppSpacing.md),

          // 3. Main Notes Feed: Neo-Pop Grid Feed
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.03),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.97, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                    ),
                    child: child,
                  ),
                );
              },
              child: workspace.isLoading
                  ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
                  : items.isEmpty
                      ? KeyedSubtree(
                          key: ValueKey('empty_${workspace.selectedCategory}_${workspace.selectedTag}'),
                          child: _buildEmptyState(workspace),
                        )
                      : KeyedSubtree(
                          key: const ValueKey('grid_view'),
                          child: _buildNeoGridFeedView(items),
                        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SmartBottomNavBar(
        currentIndex: currentNavIndex,
        onTap: _handleBottomNavTap,
        onFabTap: () => _openCreateSheet(defaultType: workspace.selectedCategory),
      ),
    );
  }

  /// Staggered Neo-Pop Feed matching Reference Mockup (Offset columns instead of rigid matrix)
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
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
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

  /// Tactile List View
  Widget _buildTactileListView(List<BaseWorkspaceItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (item is ClipboardItem) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ClipboardCard(
              item: item,
              onTap: () => widget.onOpenItem?.call(item),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: SmartNoteListCard(
            item: item,
            index: index,
            onTap: () => widget.onOpenItem?.call(item),
          ),
        );
      },
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
            color: widget.isDark ? const Color(0xFF252833) : Colors.white,
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
              color: widget.isDark ? Colors.white : const Color(0xFF191A23),
            ),
          ),
        ),
      ),
    );
  }
}


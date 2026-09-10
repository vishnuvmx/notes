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
                Text(
                  'Your Notes',
                  style: AppTypography.sectionHeadline(
                    color: headlineColor,
                    fontSize: 34,
                  ),
                ),

                // Tactile [+] Button with dark border matching reference
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _openCreateSheet(defaultType: workspace.selectedCategory);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252833) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.6),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF191A23).withValues(alpha: 0.08),
                                  blurRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Center(
                        child: TackIcon(
                          TackIcons.plus,
                          size: 22,
                          color: isDark ? Colors.white : const Color(0xFF191A23),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Folder Dropdown + View Switcher + Tag Filter Pills
          const CategoryFilterPills(),
          const SizedBox(height: AppSpacing.md),

          // 3. Main Notes Feed: 2-Column Neo-Pop Grid vs List View
          Expanded(
            child: workspace.isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? _buildEmptyState(workspace)
                    : workspace.viewMode == HomeViewMode.notebook
                        ? _buildTactileListView(items)
                        : _buildNeoGridFeedView(items),
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

  /// 2-Column Neo-Pop Pastel Grid View matching Reference Mockup
  Widget _buildNeoGridFeedView(List<BaseWorkspaceItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 13,
        crossAxisSpacing: 13,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return NeoNoteCard(
          item: item,
          isGrid: true,
          onTap: () => widget.onOpenItem?.call(item),
        );
      },
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
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: SizedBox(
            height: 155,
            child: NeoNoteCard(
              item: item,
              isGrid: false,
              onTap: () => widget.onOpenItem?.call(item),
            ),
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
      subtitle = 'No matches for "${workspace.searchQuery}". Try a different word! 🔍';
      actionLabel = 'Clear Search';
      icon = TackIcons.search;
    } else if (cat == ItemType.whiteboard) {
      title = 'Blank Canvas';
      subtitle = 'Sketch flowcharts, mindmaps & quick visual notes! 🎨';
      actionLabel = 'New Whiteboard';
      icon = TackIcons.whiteboard;
    } else if (cat == ItemType.clipboard) {
      title = 'Clipboard is Cozy';
      subtitle = 'Save code snippets, quotes, or copied thoughts here 📋';
      actionLabel = 'New Clip';
      icon = TackIcons.clipboard;
    } else if (tag != null && tag != '#All' && tag != 'All') {
      title = 'No $tag notes yet';
      subtitle = 'Create a note with this tag or tap (+) to get started ✨';
      actionLabel = 'Create Note';
      icon = TackIcons.notes;
    } else {
      title = 'Your Space is Clean & Cozy';
      subtitle = 'Tap (+) below to scribble your first note or doodle ✨';
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
          : () => _openCreateSheet(defaultType: workspace.selectedCategory),
    );
  }
}


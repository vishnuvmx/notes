import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/clipboard_item.dart';
import '../../../state/workspace_provider.dart';
import '../../components/app_bars/app_header_bar.dart';
import '../../components/inputs/smart_search_bar.dart';
import '../../components/inputs/category_filter_pills.dart';
import '../../components/cards/smart_note_list_card.dart';
import '../../components/cards/bento_workspace_card.dart';
import '../../components/cards/clipboard_card.dart';
import '../../components/dialogs_sheets/create_item_sheet.dart';
import '../../components/navigation/smart_bottom_nav_bar.dart';
import '../../components/navigation/app_nav_drawer.dart';
import '../../components/feedback/empty_state_widget.dart';

/// Main Home Dashboard Screen for Tack.
/// Offers both Pinterest / Givingli-style Bento Feed and Tactile Push-Pin List View.
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
    final workspace = context.watch<WorkspaceProvider>();
    final items = workspace.items;
    final currentNavIndex = _calculateNavIndex(workspace.selectedCategory);

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

          // Pill Filter Tabs (Wallpaper / Avatar / Upload style)
          const CategoryFilterPills(),
          const SizedBox(height: AppSpacing.md),

          // Main Feed: Pinterest Bento-Box vs Tactile Note List
          Expanded(
            child: workspace.isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? _buildEmptyState(workspace)
                    : workspace.viewMode == HomeViewMode.notebook
                        ? _buildTactileListView(items)
                        : _buildBentoFeedView(items),
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

  /// Tactile Push-Pin Note List View (Screenshot 2)
  Widget _buildTactileListView(List<BaseWorkspaceItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (item is ClipboardItem) {
          return ClipboardCard(
            item: item,
            onTap: () => widget.onOpenItem?.call(item),
          );
        }

        return SmartNoteListCard(
          item: item,
          index: index,
          onTap: () => widget.onOpenItem?.call(item),
        );
      },
    );
  }

  /// Givingli / Pinterest Bento-Box Feed View (Screenshot 3 & 4)
  Widget _buildBentoFeedView(List<BaseWorkspaceItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      itemCount: _calculateBentoRowCount(items.length),
      itemBuilder: (context, rowIndex) {
        // First item or every 4th row is a Hero full-width Bento Card
        final startIndex = _getBentoStartIndex(rowIndex);
        final isHeroRow = (rowIndex % 3 == 0) && (startIndex < items.length);

        if (isHeroRow || startIndex + 1 >= items.length) {
          final item = items[startIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: BentoWorkspaceCard(
              item: item,
              isHero: true,
              onTap: () => widget.onOpenItem?.call(item),
            ),
          );
        }

        // 2-Column paired bento cards
        final item1 = items[startIndex];
        final item2 = items[startIndex + 1];

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: BentoWorkspaceCard(
                    item: item1,
                    onTap: () => widget.onOpenItem?.call(item1),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: BentoWorkspaceCard(
                    item: item2,
                    onTap: () => widget.onOpenItem?.call(item2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _calculateBentoRowCount(int totalItems) {
    if (totalItems == 0) return 0;
    int count = 0;
    int itemsPlaced = 0;
    while (itemsPlaced < totalItems) {
      if (count % 3 == 0) {
        itemsPlaced += 1;
      } else {
        itemsPlaced += 2;
      }
      count++;
    }
    return count;
  }

  int _getBentoStartIndex(int targetRow) {
    int index = 0;
    for (int r = 0; r < targetRow; r++) {
      if (r % 3 == 0) {
        index += 1;
      } else {
        index += 2;
      }
    }
    return index;
  }

  Widget _buildEmptyState(WorkspaceProvider workspace) {
    final catName = workspace.selectedCategory?.label ?? 'items';
    return EmptyStateWidget(
      icon: TackIcons.notes,
      title: 'No $catName found',
      subtitle: workspace.searchQuery.isNotEmpty
          ? 'No matching items for "${workspace.searchQuery}"'
          : 'Tap (+) below to create your first $catName.',
      actionLabel: 'Create New $catName',
      onAction: () => _openCreateSheet(defaultType: workspace.selectedCategory),
    );
  }
}

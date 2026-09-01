import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/clipboard_item.dart';
import '../../../state/workspace_provider.dart';
import '../../components/app_bars/app_header_bar.dart';
import '../../components/inputs/smart_search_bar.dart';
import '../../components/inputs/category_filter_pills.dart';
import '../../components/cards/smart_note_list_card.dart';
import '../../components/cards/sticky_note_card.dart';
import '../../components/cards/clipboard_card.dart';
import '../../components/dialogs_sheets/create_item_sheet.dart';
import '../../components/navigation/smart_bottom_nav_bar.dart';
import '../../components/navigation/app_nav_drawer.dart';
import '../../components/feedback/empty_state_widget.dart';

/// Main Home Dashboard Screen for Tack.
/// Supports both tactile Notebook View (Screenshot 5) and Sticky Pastel Grid (Screenshots 1 & 3).
class HomeScreen extends StatefulWidget {
  final Function(BaseWorkspaceItem item)? onOpenItem;
  final VoidCallback? onOpenWhiteboardTab;
  final VoidCallback? onOpenClipboardTab;
  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenTrash;
  final VoidCallback? onOpenArchive;

  const HomeScreen({
    super.key,
    this.onOpenItem,
    this.onOpenWhiteboardTab,
    this.onOpenClipboardTab,
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
  int _currentNavIndex = 0;

  void _openCreateSheet({ItemType? defaultType}) async {
    final newItem = await CreateItemSheet.show(context, defaultType: defaultType);
    if (newItem != null && widget.onOpenItem != null) {
      widget.onOpenItem!(newItem);
    }
  }

  void _handleBottomNavTap(int index) {
    setState(() => _currentNavIndex = index);
    final workspace = context.read<WorkspaceProvider>();

    if (index == 0) {
      workspace.setCategory(null);
    } else if (index == 1) {
      workspace.setCategory(ItemType.note);
    } else if (index == 3) {
      if (widget.onOpenWhiteboardTab != null) {
        widget.onOpenWhiteboardTab!();
      } else {
        workspace.setCategory(ItemType.whiteboard);
      }
    } else if (index == 4) {
      if (widget.onOpenClipboardTab != null) {
        widget.onOpenClipboardTab!();
      } else {
        workspace.setCategory(ItemType.clipboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<WorkspaceProvider>();
    final items = workspace.items;

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
          // Animated Search Bar if opened
          if (_isSearching) ...[
            SmartSearchBar(
              onClose: () {
                setState(() => _isSearching = false);
                workspace.setSearchQuery('');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Category Filter Pills
          const CategoryFilterPills(),
          const SizedBox(height: AppSpacing.md),

          // Main Feed (Notebook List vs Sticky Grid)
          Expanded(
            child: workspace.isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? _buildEmptyState(workspace)
                    : workspace.viewMode == HomeViewMode.notebook
                        ? _buildNotebookListView(items)
                        : _buildStickyGridView(items),
          ),
        ],
      ),
      bottomNavigationBar: SmartBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _handleBottomNavTap,
        onFabTap: () => _openCreateSheet(defaultType: workspace.selectedCategory),
      ),
    );
  }

  /// Tactile Spiral Notebook List View (Screenshot 5)
  Widget _buildNotebookListView(List<BaseWorkspaceItem> items) {
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

  /// Colorful Sticky Note 2-Column Grid (Screenshots 1 & 3)
  Widget _buildStickyGridView(List<BaseWorkspaceItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return StickyNoteCard(
          item: item,
          onTap: () => widget.onOpenItem?.call(item),
        );
      },
    );
  }

  Widget _buildEmptyState(WorkspaceProvider workspace) {
    final catName = workspace.selectedCategory?.label ?? 'items';
    return EmptyStateWidget(
      icon: Icons.note_add_outlined,
      title: 'No $catName found',
      subtitle: workspace.searchQuery.isNotEmpty
          ? 'No matching items for "${workspace.searchQuery}"'
          : 'Tap (+) below to create your first $catName.',
      actionLabel: 'Create New $catName',
      onAction: () => _openCreateSheet(defaultType: workspace.selectedCategory),
    );
  }
}

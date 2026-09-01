import '../models/base_item.dart';

/// Repository interface contract demonstrating Abstraction and Polymorphism.
abstract class IWorkspaceRepository {
  /// Synchronous cached getters for instantaneous frame-1 UI rendering
  List<BaseWorkspaceItem> get cachedActiveItems => [];
  List<BaseWorkspaceItem> get cachedTrashItems => [];
  List<BaseWorkspaceItem> get cachedArchivedItems => [];
  List<BaseWorkspaceItem> get cachedFavoriteItems => [];

  /// Fetch all active workspace items.
  Future<List<BaseWorkspaceItem>> getAllActiveItems();

  /// Fetch items by filter type.
  Future<List<BaseWorkspaceItem>> getItemsByType(ItemType? type);

  /// Fetch favorite items.
  Future<List<BaseWorkspaceItem>> getFavoriteItems();

  /// Fetch archived items.
  Future<List<BaseWorkspaceItem>> getArchivedItems();

  /// Fetch items in the trash.
  Future<List<BaseWorkspaceItem>> getTrashItems();

  /// Search across all items polymorphically.
  Future<List<BaseWorkspaceItem>> searchItems(String query, {ItemType? type});

  /// Get single item by ID.
  Future<BaseWorkspaceItem?> getItemById(String id);

  /// Save or update an item.
  Future<void> saveItem(BaseWorkspaceItem item);

  /// Soft delete (move to trash).
  Future<void> moveToTrash(String id);

  /// Restore from trash.
  Future<void> restoreItem(String id);

  /// Archive or unarchive.
  Future<void> toggleArchive(String id);

  /// Toggle favorite status.
  Future<void> toggleFavorite(String id);

  /// Permanent deletion.
  Future<void> deletePermanently(String id);

  /// Empty entire trash bin.
  Future<void> emptyTrash();
}

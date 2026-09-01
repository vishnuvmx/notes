import '../../domain/interfaces/i_workspace_repo.dart';
import '../../domain/models/base_item.dart';
import '../mock/mock_initial_data.dart';

/// In-memory repository implementing IWorkspaceRepository demonstrating Polymorphism & Encapsulation.
class InMemoryWorkspaceRepository implements IWorkspaceRepository {
  final List<BaseWorkspaceItem> _items = [];

  InMemoryWorkspaceRepository({List<BaseWorkspaceItem>? initialItems}) {
    _items.addAll(initialItems ?? MockInitialData.getInitialItems());
  }

  @override
  Future<List<BaseWorkspaceItem>> getAllActiveItems() async {
    return _items
        .where((item) => !item.isTrash && !item.isArchived)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<BaseWorkspaceItem>> getItemsByType(ItemType? type) async {
    if (type == null) {
      return getAllActiveItems();
    }
    return _items
        .where((item) => !item.isTrash && !item.isArchived && item.type == type)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<BaseWorkspaceItem>> getFavoriteItems() async {
    return _items
        .where((item) => !item.isTrash && item.isFavorite)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<BaseWorkspaceItem>> getArchivedItems() async {
    return _items
        .where((item) => !item.isTrash && item.isArchived)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<BaseWorkspaceItem>> getTrashItems() async {
    return _items
        .where((item) => item.isTrash)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<BaseWorkspaceItem>> searchItems(String query, {ItemType? type}) async {
    return _items.where((item) {
      if (item.isTrash || item.isArchived) return false;
      if (type != null && item.type != type) return false;
      return item.matchesQuery(query);
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<BaseWorkspaceItem?> getItemById(String id) async {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveItem(BaseWorkspaceItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.insert(0, item);
    }
  }

  @override
  Future<void> moveToTrash(String id) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(isTrash: true);
    }
  }

  @override
  Future<void> restoreItem(String id) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(isTrash: false, isArchived: false);
    }
  }

  @override
  Future<void> toggleArchive(String id) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final current = _items[index];
      _items[index] = current.copyWith(isArchived: !current.isArchived);
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final current = _items[index];
      _items[index] = current.copyWith(isFavorite: !current.isFavorite);
    }
  }

  @override
  Future<void> deletePermanently(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> emptyTrash() async {
    _items.removeWhere((item) => item.isTrash);
  }
}

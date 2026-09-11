import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../domain/interfaces/i_workspace_repo.dart';
import '../domain/models/base_item.dart';
import '../domain/models/text_note.dart';
import '../domain/models/sticky_note.dart';
import '../domain/models/whiteboard_item.dart';
import '../domain/models/clipboard_item.dart';
import '../domain/models/item_serializer.dart';

/// Supported Home view styles
enum HomeViewMode {
  notebook, // Tactile spiral notebook list with numbered indices (01, 02...)
  stickyGrid, // 2-column pastel sticky note card grid
}

/// Central state notifier for workspace items, search, filtering, and view mode.
class WorkspaceProvider extends ChangeNotifier {
  final IWorkspaceRepository _repository;

  WorkspaceProvider(this._repository) {
    _items = _repository.cachedActiveItems;
    _trashItems = _repository.cachedTrashItems;
    _archivedItems = _repository.cachedArchivedItems;
    _favoriteItems = _repository.cachedFavoriteItems;
    loadItems();
  }

  List<BaseWorkspaceItem> _items = [];
  List<BaseWorkspaceItem> _trashItems = [];
  List<BaseWorkspaceItem> _archivedItems = [];
  List<BaseWorkspaceItem> _favoriteItems = [];

  ItemType? _selectedCategory; // null = 'All'
  String _searchQuery = '';
  HomeViewMode _viewMode = HomeViewMode.stickyGrid; // Default to 2x2 neo-pop grid
  String? _selectedTag = '#All'; // Default to show all notes
  String _selectedFolder = 'All Notes';
  bool _isLoading = false;

  // Getters
  List<BaseWorkspaceItem> get rawItems => _items;

  List<BaseWorkspaceItem> get items {
    if (_selectedTag == null ||
        _selectedTag == 'All' ||
        _selectedTag == '#All') {
      return _items;
    }
    final cleanTag = _selectedTag!.replaceAll('#', '').toLowerCase();
    final filtered = _items.where((item) {
      if (item is TextNote) {
        return item.tags.any((t) => t.toLowerCase() == cleanTag);
      }
      return false;
    }).toList();

    return filtered;
  }

  List<BaseWorkspaceItem> get trashItems => _trashItems;
  List<BaseWorkspaceItem> get archivedItems => _archivedItems;
  List<BaseWorkspaceItem> get favoriteItems => _favoriteItems;
  ItemType? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  HomeViewMode get viewMode => _viewMode;
  String? get selectedTag => _selectedTag;
  String get selectedFolder => _selectedFolder;
  bool get isLoading => _isLoading;

  /// Available tags dynamically gathered plus standard tags
  List<String> get availableTags {
    final tagsSet = <String>{'#All', '#work', '#Personal', '#Fitness'};
    for (final item in _items) {
      if (item is TextNote) {
        for (final t in item.tags) {
          tagsSet.add('#$t');
        }
      }
    }
    return tagsSet.toList();
  }

  /// Load items based on active search and filter
  Future<void> loadItems() async {
    if (_items.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    if (_searchQuery.trim().isNotEmpty) {
      _items = await _repository.searchItems(_searchQuery.trim(), type: _selectedCategory);
    } else {
      _items = await _repository.getItemsByType(_selectedCategory);
    }

    _trashItems = await _repository.getTrashItems();
    _archivedItems = await _repository.getArchivedItems();
    _favoriteItems = await _repository.getFavoriteItems();

    _isLoading = false;
    notifyListeners();
  }

  /// Change category filter ("All", "Notes", "Sticky", "Whiteboard", "Clipboard")
  void setCategory(ItemType? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _selectedTag = '#All';
    _selectedFolder = 'All Notes';
    loadItems();
  }

  /// Select tag filter (e.g. "#Personal", "#work", "#Fitness", "#All")
  void setSelectedTag(String? tag) {
    if (_selectedTag == tag) return;
    _selectedTag = tag;
    notifyListeners();
  }

  /// Select folder (e.g. "Personal", "Work", "Ideas")
  void setSelectedFolder(String folder) {
    if (_selectedFolder == folder) return;
    _selectedFolder = folder;
    notifyListeners();
  }

  /// Update search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    loadItems();
  }

  /// Toggle between Notebook list and Sticky grid view modes
  void setViewMode(HomeViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    notifyListeners();
  }

  /// Save or update an item
  Future<void> saveItem(BaseWorkspaceItem item) async {
    await _repository.saveItem(item);
    await loadItems();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id) async {
    await _repository.toggleFavorite(id);
    await loadItems();
  }

  /// Soft delete item to trash
  Future<void> moveToTrash(String id) async {
    await _repository.moveToTrash(id);
    await loadItems();
  }

  /// Restore item from trash
  Future<void> restoreItem(String id) async {
    await _repository.restoreItem(id);
    await loadItems();
  }

  /// Toggle archive
  Future<void> toggleArchive(String id) async {
    await _repository.toggleArchive(id);
    await loadItems();
  }

  /// Permanent deletion
  Future<void> deletePermanently(String id) async {
    await _repository.deletePermanently(id);
    await loadItems();
  }

  /// Empty trash bin
  Future<void> emptyTrash() async {
    await _repository.emptyTrash();
    await loadItems();
  }

  /// Helper factory to quickly create and save a new note
  Future<BaseWorkspaceItem> createQuickItem({
    required String title,
    required ItemType type,
    required String paletteId,
    String? content,
  }) async {
    final now = DateTime.now();
    final id = 'item_${now.millisecondsSinceEpoch}';
    BaseWorkspaceItem newItem;

    switch (type) {
      case ItemType.note:
        newItem = TextNote(
          id: id,
          title: title.isEmpty ? 'Untitled Note' : title,
          content: content ?? '',
          createdAt: now,
          updatedAt: now,
          paletteId: paletteId,
        );
        break;
      case ItemType.sticky:
        newItem = StickyNote(
          id: id,
          title: title.isEmpty ? 'New Sticky' : title,
          content: content ?? '',
          createdAt: now,
          updatedAt: now,
          paletteId: paletteId,
          rotationAngle: (now.millisecond % 5 - 2) * 0.008,
        );
        break;
      case ItemType.whiteboard:
        newItem = WhiteboardCanvasItem(
          id: id,
          title: title.isEmpty ? 'New Whiteboard' : title,
          createdAt: now,
          updatedAt: now,
          paletteId: paletteId,
          nodes: [
            CanvasNode(
              id: 'node_${now.millisecondsSinceEpoch}',
              text: 'Start',
              shapeType: CanvasNodeType.startEnd,
              x: 120,
              y: 50,
              paletteId: paletteId,
            ),
          ],
        );
        break;
      case ItemType.clipboard:
        newItem = ClipboardItem(
          id: id,
          title: title.isEmpty ? 'Saved Clip' : title,
          clipText: content ?? '',
          createdAt: now,
          updatedAt: now,
          paletteId: paletteId,
        );
        break;
    }

    await saveItem(newItem);
    return newItem;
  }

  /// Save a snippet directly from the system clipboard
  Future<ClipboardItem> saveClipboardSnippet(String text, {String? source}) async {
    final now = DateTime.now();
    final clean = text.trim();
    final firstLine = clean.split('\n').first.trim();
    final title = firstLine.length > 32
        ? '${firstLine.substring(0, 32)}...'
        : (firstLine.isEmpty ? 'Clipboard Snippet' : firstLine);

    final newItem = ClipboardItem(
      id: 'clip_${now.millisecondsSinceEpoch}',
      title: title,
      clipText: clean,
      createdAt: now,
      updatedAt: now,
      paletteId: 'amber',
      sourceApp: source ?? 'System Clipboard',
    );

    await saveItem(newItem);
    return newItem;
  }

  // Workspace Statistics
  int get totalActiveNotesCount => _items.where((i) => i.type == ItemType.note).length;
  int get totalStickiesCount => _items.where((i) => i.type == ItemType.sticky).length;
  int get totalWhiteboardsCount => _items.where((i) => i.type == ItemType.whiteboard).length;
  int get totalClipsCount => _items.where((i) => i.type == ItemType.clipboard).length;

  /// Export workspace state as formatted JSON backup string.
  String exportWorkspaceJson() {
    final Map<String, dynamic> exportData = {
      'app': 'Tack',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'itemCounts': {
        'total': _items.length,
        'notes': totalActiveNotesCount,
        'stickies': totalStickiesCount,
        'whiteboards': totalWhiteboardsCount,
        'clips': totalClipsCount,
      },
      'items': _items.map((item) => item.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Restore workspace items from a JSON backup string.
  /// Supports Tack export bundle format or raw list of item JSON objects.
  Future<int> importWorkspaceJson(String jsonStr) async {
    final dynamic decoded = jsonDecode(jsonStr);
    List<dynamic> itemsList;
    if (decoded is Map<String, dynamic> && decoded.containsKey('items')) {
      itemsList = decoded['items'] as List<dynamic>;
    } else if (decoded is List<dynamic>) {
      itemsList = decoded;
    } else {
      throw const FormatException('Invalid backup structure. Expected Tack backup bundle or item list.');
    }

    int importedCount = 0;
    for (final raw in itemsList) {
      if (raw is Map<String, dynamic>) {
        final item = ItemSerializer.fromJson(raw);
        if (item != null) {
          await _repository.saveItem(item);
          importedCount++;
        }
      }
    }

    if (importedCount > 0) {
      await loadItems();
    }
    return importedCount;
  }
}

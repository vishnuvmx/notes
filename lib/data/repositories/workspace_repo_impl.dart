import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/interfaces/i_workspace_repo.dart';
import '../../domain/models/base_item.dart';
import '../../domain/models/text_note.dart';
import '../../domain/models/sticky_note.dart';
import '../../domain/models/item_serializer.dart';
import '../mock/mock_initial_data.dart';

/// Workspace repository implementing IWorkspaceRepository with persistent SharedPreferences storage.
class LocalStorageWorkspaceRepository implements IWorkspaceRepository {
  static const String _storageKey = 'tack_workspace_items_v2';
  final List<BaseWorkspaceItem> _items = [];
  bool _isInitialized = false;

  LocalStorageWorkspaceRepository({List<BaseWorkspaceItem>? initialItems}) {
    if (initialItems != null) {
      _items.addAll(initialItems);
      _isInitialized = true;
    }
  }

  @override
  List<BaseWorkspaceItem> get cachedActiveItems =>
      _items.where((i) => !i.isTrash && !i.isArchived).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  List<BaseWorkspaceItem> get cachedTrashItems =>
      _items.where((i) => i.isTrash).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  List<BaseWorkspaceItem> get cachedArchivedItems =>
      _items.where((i) => !i.isTrash && i.isArchived).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  List<BaseWorkspaceItem> get cachedFavoriteItems =>
      _items.where((i) => !i.isTrash && i.isFavorite).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  /// Initialize and load items from local persistent storage.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawData = prefs.getString(_storageKey);

      if (rawData != null && rawData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawData) as List<dynamic>;
        _items.clear();
        for (final entry in decoded) {
          if (entry is Map<String, dynamic>) {
            final item = ItemSerializer.fromJson(entry);
            if (item != null) {
              _items.add(item);
            }
          }
        }
        // Clean out any legacy placeholder mockups or old emoji-laden seed items from prior builds
        _items.removeWhere((item) =>
            item.id.startsWith('mockup_') ||
            item.title.contains('mockup') ||
            item.title.contains('dumb dumb') ||
            item.title.contains('🌱') ||
            item.title.contains('📌') ||
            item.title.contains('🎨'));

        // One-time sanitization and migration of existing notes with legacy HTML tags or empty markdown markers
        _sanitizeAndMigrateNotes();
      }
      
      // If storage was empty or legacy items cleaned out, initialize with curated initial data
      if (_items.isEmpty) {
        _items.clear();
        _items.addAll(MockInitialData.getInitialItems());
        _sanitizeAndMigrateNotes();
        await _persistToStorage();
      }
    } catch (_) {
      if (_items.isEmpty) {
        _items.addAll(MockInitialData.getInitialItems());
      }
    } finally {
      _isInitialized = true;
    }
  }

  void _sanitizeAndMigrateNotes() {
    bool hasChanges = false;
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item is TextNote) {
        final sanitized = _cleanCorruptedMarkdown(item.content);
        if (sanitized != item.content) {
          _items[i] = item.copyWith(content: sanitized);
          hasChanges = true;
        }
      } else if (item is StickyNote) {
        final sanitized = _cleanCorruptedMarkdown(item.content);
        if (sanitized != item.content) {
          _items[i] = item.copyWith(content: sanitized);
          hasChanges = true;
        }
      }
    }
    if (hasChanges) {
      _persistToStorage();
    }
  }

  String _cleanCorruptedMarkdown(String text) {
    if (text.isEmpty) return text;
    // Migrate legacy <u>...</u> into standard markdown __...__
    var result = text.replaceAllMapped(
      RegExp(r'<u>(.*?)</u>', caseSensitive: false, dotAll: false),
      (match) => '__${match.group(1)}__',
    );
    // Remove dangling empty formatting artifacts
    result = result
        .replaceAll('****', '')
        .replaceAll('____', '')
        .replaceAll('~~~~', '')
        .replaceAll('====', '')
        .replaceAll('<u></u>', '');
    return result;
  }

  Future<void> _persistToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _items.map((item) => item.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e, st) {
      // Log storage failures so they are visible in debug output.
      // In production, consider surfacing this to the user via a callback.
      debugPrint('[WorkspaceRepo] Failed to persist workspace: $e\n$st');
    }
  }

  Future<void> _ensureReady() async {
    if (!_isInitialized) {
      await init();
    }
  }

  @override
  Future<List<BaseWorkspaceItem>> getAllActiveItems() async {
    await _ensureReady();
    return _items
        .where((item) => !item.isTrash && !item.isArchived)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<BaseWorkspaceItem>> getItemsByType(ItemType? type) async {
    await _ensureReady();
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
    await _ensureReady();
    return _items
        .where((item) => !item.isTrash && item.isFavorite)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<BaseWorkspaceItem>> getArchivedItems() async {
    await _ensureReady();
    return _items
        .where((item) => !item.isTrash && item.isArchived)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<BaseWorkspaceItem>> getTrashItems() async {
    await _ensureReady();
    return _items
        .where((item) => item.isTrash)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<BaseWorkspaceItem>> searchItems(String query, {ItemType? type}) async {
    await _ensureReady();
    return _items.where((item) {
      if (item.isTrash || item.isArchived) return false;
      if (type != null && item.type != type) return false;
      return item.matchesQuery(query);
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<BaseWorkspaceItem?> getItemById(String id) async {
    await _ensureReady();
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveItem(BaseWorkspaceItem item) async {
    await _ensureReady();
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.insert(0, item);
    }
    await _persistToStorage();
  }

  @override
  Future<void> moveToTrash(String id) async {
    await _ensureReady();
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(isTrash: true);
      await _persistToStorage();
    }
  }

  @override
  Future<void> restoreItem(String id) async {
    await _ensureReady();
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(isTrash: false, isArchived: false);
      await _persistToStorage();
    }
  }

  @override
  Future<void> toggleArchive(String id) async {
    await _ensureReady();
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final current = _items[index];
      _items[index] = current.copyWith(isArchived: !current.isArchived);
      await _persistToStorage();
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    await _ensureReady();
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final current = _items[index];
      _items[index] = current.copyWith(isFavorite: !current.isFavorite);
      await _persistToStorage();
    }
  }

  @override
  Future<void> deletePermanently(String id) async {
    await _ensureReady();
    _items.removeWhere((item) => item.id == id);
    await _persistToStorage();
    _sweepOrphanedMedia();
  }

  @override
  Future<void> emptyTrash() async {
    await _ensureReady();
    _items.removeWhere((item) => item.isTrash);
    await _persistToStorage();
    _sweepOrphanedMedia();
  }

  /// Background garbage collection: scans for unreferenced media files in shared_media cache and deletes them.
  Future<void> _sweepOrphanedMedia() async {
    try {
      final referencedPaths = <String>{};
      final imgRegex = RegExp(r'!\[.*?\]\((.*?)\)');
      for (final item in _items) {
        String? text;
        if (item is TextNote) {
          text = item.content;
        } else if (item is StickyNote) {
          text = item.content;
        }
        if (text != null && text.isNotEmpty) {
          for (final match in imgRegex.allMatches(text)) {
            final path = match.group(1)?.trim();
            if (path != null && path.isNotEmpty) {
              referencedPaths.add(path);
            }
          }
        }
      }

      final tempDir = await getTemporaryDirectory();
      final sharedMediaDir = Directory('${tempDir.path}/shared_media');
      if (await sharedMediaDir.exists()) {
        await for (final file in sharedMediaDir.list()) {
          if (file is File) {
            if (!referencedPaths.contains(file.path)) {
              try {
                await file.delete();
                debugPrint('[WorkspaceRepo] Deleted orphaned media: ${file.path}');
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[WorkspaceRepo] sweepOrphanedMedia error: $e');
    }
  }
}

/// Backwards-compatible alias for in-memory or default repo.
typedef InMemoryWorkspaceRepository = LocalStorageWorkspaceRepository;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import 'i_workspace_repo.dart';
import '../models/base_item.dart';
import '../models/item_serializer.dart';
import 'mock_initial_data.dart';

/// Concrete implementation of IWorkspaceRepository backed by SharedPreferences JSON persistence.
/// Includes corrupt-store backup & last-good fallback (`03` §7 P2, `08` §5) and
/// automatic migration of legacy palette IDs and archived state (`05` §7.2).
class LocalStorageWorkspaceRepository implements IWorkspaceRepository {
  static const String _storageKey = 'tack_workspace_items_v2';
  static const String _lastGoodStorageKey = 'tack_workspace_items_v2_last_good';
  static const String _corruptBackupStorageKey = 'tack_workspace_items_v2_corrupt_backup';

  List<BaseWorkspaceItem> _items = [];
  bool _initialized = false;

  @override
  List<BaseWorkspaceItem> get cachedActiveItems =>
      _items.where((i) => !i.isTrash && !i.isArchived).toList();

  @override
  List<BaseWorkspaceItem> get cachedTrashItems =>
      _items.where((i) => i.isTrash).toList();

  @override
  List<BaseWorkspaceItem> get cachedArchivedItems =>
      _items.where((i) => i.isArchived && !i.isTrash).toList();

  @override
  List<BaseWorkspaceItem> get cachedFavoriteItems =>
      _items.where((i) => i.isFavorite && !i.isTrash && !i.isArchived).toList();

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      final parsed = _tryDecodeItems(jsonString);
      if (parsed != null) {
        _items = parsed.map(_migrateLegacyItem).toList();
      } else {
        // Preserve corrupt payload so user data is never silently lost (`03` §7 P2)
        await prefs.setString(_corruptBackupStorageKey, jsonString);
        final lastGood = prefs.getString(_lastGoodStorageKey);
        final recovered = lastGood != null ? _tryDecodeItems(lastGood) : null;
        if (recovered != null && recovered.isNotEmpty) {
          _items = recovered.map(_migrateLegacyItem).toList();
          await _persistToDisk();
        } else {
          _items = MockInitialData.getInitialItems();
          await _persistToDisk();
        }
      }
    } else {
      // First launch: seed with clean starter items and persist
      _items = MockInitialData.getInitialItems();
      await _persistToDisk();
    }
    _initialized = true;
  }

  List<BaseWorkspaceItem>? _tryDecodeItems(String rawJson) {
    try {
      final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .map((e) => ItemSerializer.fromJson(Map<String, dynamic>.from(e as Map)))
          .whereType<BaseWorkspaceItem>()
          .toList();
    } catch (e) {
      debugPrint('Failed to decode workspace items: $e');
      return null;
    }
  }

  /// Normalizes legacy palette IDs (`terracotta -> peach`, `yellow -> amber`)
  /// and migrates legacy `isArchived: true` items to `isFavorite: true, isArchived: false`
  /// so nothing is hidden after retiring Archive (`05` §7.2).
  BaseWorkspaceItem _migrateLegacyItem(BaseWorkspaceItem item) {
    final normalizedPalette = AppColors.normalizePaletteId(item.paletteId);
    final shouldMigrateArchive = item.isArchived && !item.isTrash;
    if (normalizedPalette != item.paletteId || shouldMigrateArchive) {
      return item.copyWith(
        paletteId: normalizedPalette,
        isArchived: shouldMigrateArchive ? false : item.isArchived,
        isFavorite: shouldMigrateArchive ? true : item.isFavorite,
      );
    }
    return item;
  }

  Future<void> _persistToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _items.map((item) => item.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      await prefs.setString(_storageKey, encoded);
      await prefs.setString(_lastGoodStorageKey, encoded);
    } catch (e) {
      debugPrint('Error saving workspace items: $e');
    }
  }

  @override
  Future<List<BaseWorkspaceItem>> getAllActiveItems() async {
    await _ensureInitialized();
    final active = _items.where((i) => !i.isTrash && !i.isArchived).toList();
    active.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return active;
  }

  @override
  Future<List<BaseWorkspaceItem>> getItemsByType(ItemType? type) async {
    final active = await getAllActiveItems();
    if (type == null) return active;
    return active.where((i) => i.type == type).toList();
  }

  @override
  Future<List<BaseWorkspaceItem>> getFavoriteItems() async {
    final active = await getAllActiveItems();
    return active.where((i) => i.isFavorite).toList();
  }

  @override
  Future<List<BaseWorkspaceItem>> getArchivedItems() async {
    await _ensureInitialized();
    final archived = _items.where((i) => i.isArchived && !i.isTrash).toList();
    archived.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return archived;
  }

  @override
  Future<List<BaseWorkspaceItem>> getTrashItems() async {
    await _ensureInitialized();
    final trashed = _items.where((i) => i.isTrash).toList();
    trashed.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return trashed;
  }

  @override
  Future<List<BaseWorkspaceItem>> searchItems(String query, {ItemType? type}) async {
    final active = await getAllActiveItems();
    return active.where((item) {
      final matchesType = type == null || item.type == type;
      final matchesQuery = item.matchesQuery(query);
      return matchesType && matchesQuery;
    }).toList();
  }

  @override
  Future<BaseWorkspaceItem?> getItemById(String id) async {
    await _ensureInitialized();
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveItem(BaseWorkspaceItem item) async {
    await _ensureInitialized();
    final normalized = _migrateLegacyItem(item);
    final index = _items.indexWhere((i) => i.id == normalized.id);
    if (index >= 0) {
      _items[index] = normalized;
    } else {
      _items.insert(0, normalized);
    }
    await _persistToDisk();
  }

  @override
  Future<void> moveToTrash(String id) async {
    await _ensureInitialized();
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        isTrash: true,
        updatedAt: DateTime.now(),
      );
      await _persistToDisk();
    }
  }

  @override
  Future<void> restoreItem(String id) async {
    await _ensureInitialized();
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        isTrash: false,
        isArchived: false,
        updatedAt: DateTime.now(),
      );
      await _persistToDisk();
    }
  }

  @override
  Future<void> toggleArchive(String id) async {
    await _ensureInitialized();
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final current = _items[index];
      _items[index] = current.copyWith(
        isArchived: !current.isArchived,
        updatedAt: DateTime.now(),
      );
      await _persistToDisk();
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    await _ensureInitialized();
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final current = _items[index];
      _items[index] = current.copyWith(
        isFavorite: !current.isFavorite,
        updatedAt: DateTime.now(),
      );
      await _persistToDisk();
    }
  }

  @override
  Future<void> deletePermanently(String id) async {
    await _ensureInitialized();
    _items.removeWhere((i) => i.id == id);
    await _persistToDisk();
  }

  @override
  Future<void> emptyTrash() async {
    await _ensureInitialized();
    _items.removeWhere((i) => i.isTrash);
    await _persistToDisk();
  }
}

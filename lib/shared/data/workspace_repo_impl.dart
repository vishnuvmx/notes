import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/native/tack_core_bridge.dart';
import '../../core/theme/app_colors.dart';
import '../../features/notes/models/text_note.dart';
import '../../features/whiteboard/models/whiteboard_item.dart';
import '../models/base_item.dart';
import '../models/clipboard_item.dart';
import '../models/item_serializer.dart';
import '../models/sticky_note.dart';
import 'i_workspace_repo.dart';
import 'mock_initial_data.dart';

/// Concrete implementation of [IWorkspaceRepository].
///
/// Primary persistence engine: **Rust SQLite WAL + FTS5** via [TackCoreBridge],
/// giving O(1) incremental per-item writes and sub-millisecond BM25 full-text
/// search without serializing the entire workspace into XML SharedPreferences.
///
/// Includes automatic one-time migration from legacy SharedPreferences JSON
/// storage and a seamless SharedPreferences fallback when native FFI or
/// `path_provider` is unavailable (e.g., Web or unit-test harnesses).
class LocalStorageWorkspaceRepository implements IWorkspaceRepository {
  static const String _storageKey = 'tack_workspace_items_v2';
  static const String _lastGoodStorageKey = 'tack_workspace_items_v2_last_good';
  static const String _corruptBackupStorageKey =
      'tack_workspace_items_v2_corrupt_backup';
  static const String _starterShowcaseSeededKey =
      'tack_starter_showcase_v2_seeded';
  static const String _sqliteMigratedKey = 'tack_sqlite_v2_migrated';

  final String? _explicitDbPath;
  List<BaseWorkspaceItem> _items = [];
  bool _initialized = false;
  int _dbHandle = 0;

  LocalStorageWorkspaceRepository({String? dbPath}) : _explicitDbPath = dbPath;

  bool get isUsingNativeSqlite => _dbHandle > 0;

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

  void dispose() {
    if (_dbHandle > 0) {
      TackCoreBridge.instance.closeDatabase(_dbHandle);
      _dbHandle = 0;
    }
  }

  Future<String?> _resolveDatabasePath() async {
    if (_explicitDbPath != null) return _explicitDbPath;
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}${Platform.pathSeparator}tack_workspace_v2.db';
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    // 1. Attempt to open native Rust SQLite WAL + FTS5 database
    if (TackCoreBridge.instance.isAvailable) {
      final dbPath = await _resolveDatabasePath();
      if (dbPath != null) {
        _dbHandle = TackCoreBridge.instance.openDatabase(dbPath);
      }
    }

    if (_dbHandle > 0) {
      await _initFromSqlite();
    } else {
      await _initFromSharedPreferences();
    }

    _initialized = true;
  }

  Future<void> _initFromSqlite() async {
    final existingJson = TackCoreBridge.instance.loadAllItemsJson(_dbHandle);
    final existingItems = existingJson != null
        ? _tryDecodeItems(existingJson)
        : null;

    if (existingItems != null && existingItems.isNotEmpty) {
      _items = existingItems.map(_migrateLegacyItem).toList();
      return;
    }

    // Empty SQLite DB: check if legacy SharedPreferences data exists to migrate
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }

    final legacyJson = prefs?.getString(_storageKey);
    if (legacyJson != null && legacyJson.isNotEmpty) {
      final parsed = _tryDecodeItems(legacyJson);
      if (parsed != null && parsed.isNotEmpty) {
        _items = parsed.map(_migrateLegacyItem).toList();
      } else {
        await prefs?.setString(_corruptBackupStorageKey, legacyJson);
        final lastGood = prefs?.getString(_lastGoodStorageKey);
        final recovered = lastGood != null ? _tryDecodeItems(lastGood) : null;
        _items = (recovered != null && recovered.isNotEmpty)
            ? recovered.map(_migrateLegacyItem).toList()
            : MockInitialData.getInitialItems();
      }
    } else {
      _items = MockInitialData.getInitialItems();
    }

    _batchUpsertSqlite(_items);
    try {
      await prefs?.setBool(_sqliteMigratedKey, true);
      await prefs?.setBool(_starterShowcaseSeededKey, true);
    } catch (_) {}
  }

  Future<void> _initFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      final parsed = _tryDecodeItems(jsonString);
      if (parsed != null) {
        _items = parsed.map(_migrateLegacyItem).toList();
      } else {
        await prefs.setString(_corruptBackupStorageKey, jsonString);
        final lastGood = prefs.getString(_lastGoodStorageKey);
        final recovered = lastGood != null ? _tryDecodeItems(lastGood) : null;
        if (recovered != null && recovered.isNotEmpty) {
          _items = recovered.map(_migrateLegacyItem).toList();
          await _persistLegacySharedPreferences();
        } else {
          _items = MockInitialData.getInitialItems();
          await _persistLegacySharedPreferences();
        }
      }
      if (!(prefs.getBool(_starterShowcaseSeededKey) ?? false)) {
        final now = DateTime.now();
        bool upgraded = false;
        for (int i = 0; i < _items.length; i++) {
          final replacement = MockInitialData.tryUpgradeLegacyStarter(
            _items[i],
            now,
          );
          if (replacement != null) {
            _items[i] = replacement;
            upgraded = true;
          }
        }
        if (upgraded) {
          await _persistLegacySharedPreferences();
        }
        await prefs.setBool(_starterShowcaseSeededKey, true);
      }
    } else {
      _items = MockInitialData.getInitialItems();
      await _persistLegacySharedPreferences();
      await prefs.setBool(_starterShowcaseSeededKey, true);
    }
  }

  List<BaseWorkspaceItem>? _tryDecodeItems(String rawJson) {
    try {
      final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .map(
            (e) => ItemSerializer.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .whereType<BaseWorkspaceItem>()
          .toList();
    } catch (e) {
      debugPrint('Failed to decode workspace items: $e');
      return null;
    }
  }

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

  static String _extractSearchBody(BaseWorkspaceItem item) {
    if (item is TextNote) return item.content;
    if (item is StickyNote) return item.content;
    if (item is ClipboardItem) return '${item.clipText} ${item.sourceApp}';
    if (item is WhiteboardCanvasItem) {
      return item.nodes.map((n) => n.text).join(' ');
    }
    return '';
  }

  static String _extractSearchTags(BaseWorkspaceItem item) {
    if (item is TextNote) return item.tags.join(' ');
    return '';
  }

  void _upsertSingleSqlite(BaseWorkspaceItem item) {
    if (_dbHandle <= 0) return;
    TackCoreBridge.instance.upsertItem(
      handle: _dbHandle,
      id: item.id,
      itemType: item.type.name,
      title: item.title,
      bodyText: _extractSearchBody(item),
      tagsText: _extractSearchTags(item),
      isTrash: item.isTrash,
      isArchived: item.isArchived,
      isFavorite: item.isFavorite,
      updatedAtMs: item.updatedAt.millisecondsSinceEpoch,
      jsonPayload: jsonEncode(item.toJson()),
    );
  }

  void _batchUpsertSqlite(List<BaseWorkspaceItem> items) {
    if (_dbHandle <= 0 || items.isEmpty) return;
    final batch = [
      for (final item in items)
        {
          'id': item.id,
          'itemType': item.type.name,
          'title': item.title,
          'bodyText': _extractSearchBody(item),
          'tagsText': _extractSearchTags(item),
          'isTrash': item.isTrash,
          'isArchived': item.isArchived,
          'isFavorite': item.isFavorite,
          'updatedAtMs': item.updatedAt.millisecondsSinceEpoch,
          'jsonPayload': jsonEncode(item.toJson()),
        },
    ];
    TackCoreBridge.instance.upsertBatchJson(_dbHandle, jsonEncode(batch));
  }

  Future<void> _persistLegacySharedPreferences() async {
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
  Future<List<BaseWorkspaceItem>> searchItems(
    String query, {
    ItemType? type,
  }) async {
    await _ensureInitialized();
    if (query.trim().isEmpty) {
      return getItemsByType(type);
    }
    if (_dbHandle > 0) {
      final ids = TackCoreBridge.instance.searchItemIds(
        _dbHandle,
        query,
        itemType: type?.name,
      );
      if (ids != null) {
        final byId = {for (final item in _items) item.id: item};
        return [
          for (final id in ids)
            if (byId[id] != null) byId[id]!,
        ];
      }
    }
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
    if (_dbHandle > 0) {
      _upsertSingleSqlite(normalized);
    } else {
      await _persistLegacySharedPreferences();
    }
  }

  @override
  Future<void> moveToTrash(String id) async {
    await _ensureInitialized();
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final updated = _items[index].copyWith(
        isTrash: true,
        updatedAt: DateTime.now(),
      );
      _items[index] = updated;
      if (_dbHandle > 0) {
        _upsertSingleSqlite(updated);
      } else {
        await _persistLegacySharedPreferences();
      }
    }
  }

  @override
  Future<void> restoreItem(String id) async {
    await _ensureInitialized();
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final updated = _items[index].copyWith(
        isTrash: false,
        isArchived: false,
        updatedAt: DateTime.now(),
      );
      _items[index] = updated;
      if (_dbHandle > 0) {
        _upsertSingleSqlite(updated);
      } else {
        await _persistLegacySharedPreferences();
      }
    }
  }

  @override
  Future<void> toggleArchive(String id) async {
    await _ensureInitialized();
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final current = _items[index];
      final updated = current.copyWith(
        isArchived: !current.isArchived,
        updatedAt: DateTime.now(),
      );
      _items[index] = updated;
      if (_dbHandle > 0) {
        _upsertSingleSqlite(updated);
      } else {
        await _persistLegacySharedPreferences();
      }
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    await _ensureInitialized();
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final current = _items[index];
      final updated = current.copyWith(
        isFavorite: !current.isFavorite,
        updatedAt: DateTime.now(),
      );
      _items[index] = updated;
      if (_dbHandle > 0) {
        _upsertSingleSqlite(updated);
      } else {
        await _persistLegacySharedPreferences();
      }
    }
  }

  @override
  Future<void> deletePermanently(String id) async {
    await _ensureInitialized();
    _items.removeWhere((i) => i.id == id);
    if (_dbHandle > 0) {
      TackCoreBridge.instance.deleteItem(_dbHandle, id);
    } else {
      await _persistLegacySharedPreferences();
    }
  }

  @override
  Future<void> emptyTrash() async {
    await _ensureInitialized();
    _items.removeWhere((i) => i.isTrash);
    if (_dbHandle > 0) {
      TackCoreBridge.instance.emptyTrash(_dbHandle);
    } else {
      await _persistLegacySharedPreferences();
    }
  }
}

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Native C ABI typedefs for `tack_core`
// ---------------------------------------------------------------------------
typedef _VersionNative = Int32 Function();
typedef _VersionDart = int Function();

typedef _AllocNative = Pointer<Uint8> Function(IntPtr len);
typedef _AllocDart = Pointer<Uint8> Function(int len);

typedef _FreeNative = Void Function(Pointer<Uint8> ptr, IntPtr len);
typedef _FreeDart = void Function(Pointer<Uint8> ptr, int len);

typedef _FreeCstrNative = Void Function(Pointer<Uint8> ptr);
typedef _FreeCstrDart = void Function(Pointer<Uint8> ptr);

typedef _FreeI32BufNative = Void Function(Pointer<Int32> ptr, IntPtr len);
typedef _FreeI32BufDart = void Function(Pointer<Int32> ptr, int len);

typedef _LayoutGraphNative = Void Function(
  Pointer<Float> positions,
  Int32 nodeCount,
  Pointer<Int32> edges,
  Int32 edgeCount,
  Int32 pinnedIndex,
  Float centerX,
  Float centerY,
  Float canvasSize,
  Int32 iterations,
);
typedef _LayoutGraphDart = void Function(
  Pointer<Float> positions,
  int nodeCount,
  Pointer<Int32> edges,
  int edgeCount,
  int pinnedIndex,
  double centerX,
  double centerY,
  double canvasSize,
  int iterations,
);

typedef _DbOpenNative = Int64 Function(Pointer<Uint8> pathPtr, IntPtr pathLen);
typedef _DbOpenDart = int Function(Pointer<Uint8> pathPtr, int pathLen);

typedef _DbCloseNative = Void Function(Int64 handle);
typedef _DbCloseDart = void Function(int handle);

typedef _DbUpsertItemNative = Int32 Function(
  Int64 handle,
  Pointer<Uint8> idPtr,
  IntPtr idLen,
  Pointer<Uint8> typePtr,
  IntPtr typeLen,
  Pointer<Uint8> titlePtr,
  IntPtr titleLen,
  Pointer<Uint8> bodyPtr,
  IntPtr bodyLen,
  Pointer<Uint8> tagsPtr,
  IntPtr tagsLen,
  Int32 isTrash,
  Int32 isArchived,
  Int32 isFavorite,
  Int64 updatedAtMs,
  Pointer<Uint8> jsonPtr,
  IntPtr jsonLen,
);
typedef _DbUpsertItemDart = int Function(
  int handle,
  Pointer<Uint8> idPtr,
  int idLen,
  Pointer<Uint8> typePtr,
  int typeLen,
  Pointer<Uint8> titlePtr,
  int titleLen,
  Pointer<Uint8> bodyPtr,
  int bodyLen,
  Pointer<Uint8> tagsPtr,
  int tagsLen,
  int isTrash,
  int isArchived,
  int isFavorite,
  int updatedAtMs,
  Pointer<Uint8> jsonPtr,
  int jsonLen,
);

typedef _DbUpsertBatchNative = Int32 Function(
  Int64 handle,
  Pointer<Uint8> batchPtr,
  IntPtr batchLen,
);
typedef _DbUpsertBatchDart = int Function(
  int handle,
  Pointer<Uint8> batchPtr,
  int batchLen,
);

typedef _DbDeleteItemNative = Int32 Function(
  Int64 handle,
  Pointer<Uint8> idPtr,
  IntPtr idLen,
);
typedef _DbDeleteItemDart = int Function(
  int handle,
  Pointer<Uint8> idPtr,
  int idLen,
);

typedef _DbEmptyTrashNative = Int32 Function(Int64 handle);
typedef _DbEmptyTrashDart = int Function(int handle);

typedef _DbLoadAllNative = Pointer<Uint8> Function(Int64 handle);
typedef _DbLoadAllDart = Pointer<Uint8> Function(int handle);

typedef _DbSearchIdsNative = Pointer<Uint8> Function(
  Int64 handle,
  Pointer<Uint8> queryPtr,
  IntPtr queryLen,
  Pointer<Uint8> typeFilterPtr,
  IntPtr typeFilterLen,
  Int32 limit,
);
typedef _DbSearchIdsDart = Pointer<Uint8> Function(
  int handle,
  Pointer<Uint8> queryPtr,
  int queryLen,
  Pointer<Uint8> typeFilterPtr,
  int typeFilterLen,
  int limit,
);

typedef _ExtractWikiLinksNative = Pointer<Uint8> Function(
  Pointer<Uint8> contentPtr,
  IntPtr contentLen,
);
typedef _ExtractWikiLinksDart = Pointer<Uint8> Function(
  Pointer<Uint8> contentPtr,
  int contentLen,
);

typedef _ComputeBacklinksNative = Pointer<Uint8> Function(
  Pointer<Uint8> reqPtr,
  IntPtr reqLen,
);
typedef _ComputeBacklinksDart = Pointer<Uint8> Function(
  Pointer<Uint8> reqPtr,
  int reqLen,
);

typedef _TokenizeCodeNative = Pointer<Int32> Function(
  Pointer<Uint8> codePtr,
  IntPtr codeLen,
  Pointer<Uint8> langPtr,
  IntPtr langLen,
  Pointer<IntPtr> outLen,
);
typedef _TokenizeCodeDart = Pointer<Int32> Function(
  Pointer<Uint8> codePtr,
  int codeLen,
  Pointer<Uint8> langPtr,
  int langLen,
  Pointer<IntPtr> outLen,
);

/// Zero-dependency `dart:ffi` bridge to the native Rust `tack_core` library.
///
/// Automatically loads:
/// - `libtack_core.so` on Android / Linux
/// - `tack_core.dll` on Windows (including `rust/tack_core/target/release/` for `flutter test`)
/// - `libtack_core.dylib` on macOS
///
/// If the native binary is unavailable (e.g. Web or unbuilt platform), [isAvailable]
/// is `false` and all callers seamlessly fall back to pure Dart.
class TackCoreBridge {
  TackCoreBridge._();

  static final TackCoreBridge instance = TackCoreBridge._();

  bool _initialized = false;
  bool _available = false;

  late final _AllocDart _alloc;
  late final _FreeDart _free;
  late final _FreeCstrDart _freeCstr;
  late final _FreeI32BufDart _freeI32Buf;
  late final _LayoutGraphDart _layoutGraph;
  late final _DbOpenDart _dbOpen;
  late final _DbCloseDart _dbClose;
  late final _DbUpsertItemDart _dbUpsertItem;
  late final _DbUpsertBatchDart _dbUpsertBatch;
  late final _DbDeleteItemDart _dbDeleteItem;
  late final _DbEmptyTrashDart _dbEmptyTrash;
  late final _DbLoadAllDart _dbLoadAll;
  late final _DbSearchIdsDart _dbSearchIds;
  late final _ExtractWikiLinksDart _extractWikiLinks;
  late final _ComputeBacklinksDart _computeBacklinks;
  late final _TokenizeCodeDart _tokenizeCode;

  bool get isAvailable {
    if (!_initialized) {
      _tryInit();
    }
    return _available;
  }

  DynamicLibrary? _openLibrary() {
    if (kIsWeb) return null;
    try {
      if (Platform.isAndroid) {
        return DynamicLibrary.open('libtack_core.so');
      }
      if (Platform.isWindows) {
        final candidates = [
          'tack_core.dll',
          '${Directory.current.path}\\rust\\tack_core\\target\\release\\tack_core.dll',
          '${Directory.current.path}\\rust\\tack_core\\target\\debug\\tack_core.dll',
        ];
        for (final path in candidates) {
          if (path == 'tack_core.dll' || File(path).existsSync()) {
            try {
              return DynamicLibrary.open(path);
            } catch (_) {}
          }
        }
        return null;
      }
      if (Platform.isLinux) {
        final candidates = [
          'libtack_core.so',
          '${Directory.current.path}/rust/tack_core/target/release/libtack_core.so',
        ];
        for (final path in candidates) {
          try {
            return DynamicLibrary.open(path);
          } catch (_) {}
        }
        return null;
      }
      if (Platform.isMacOS) {
        final candidates = [
          'libtack_core.dylib',
          '${Directory.current.path}/rust/tack_core/target/release/libtack_core.dylib',
        ];
        for (final path in candidates) {
          try {
            return DynamicLibrary.open(path);
          } catch (_) {}
        }
        return null;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  void _tryInit() {
    _initialized = true;
    final lib = _openLibrary();
    if (lib == null) {
      _available = false;
      return;
    }
    try {
      final version = lib.lookupFunction<_VersionNative, _VersionDart>(
        'tack_core_version',
      )();
      if (version != 1) {
        _available = false;
        return;
      }
      _alloc = lib.lookupFunction<_AllocNative, _AllocDart>('tack_alloc');
      _free = lib.lookupFunction<_FreeNative, _FreeDart>('tack_free');
      _freeCstr = lib.lookupFunction<_FreeCstrNative, _FreeCstrDart>(
        'tack_free_cstr',
      );
      _freeI32Buf = lib.lookupFunction<_FreeI32BufNative, _FreeI32BufDart>(
        'tack_free_i32_buf',
      );
      _layoutGraph = lib.lookupFunction<_LayoutGraphNative, _LayoutGraphDart>(
        'tack_layout_graph',
      );
      _dbOpen = lib.lookupFunction<_DbOpenNative, _DbOpenDart>('tack_db_open');
      _dbClose = lib.lookupFunction<_DbCloseNative, _DbCloseDart>(
        'tack_db_close',
      );
      _dbUpsertItem = lib
          .lookupFunction<_DbUpsertItemNative, _DbUpsertItemDart>(
            'tack_db_upsert_item',
          );
      _dbUpsertBatch = lib
          .lookupFunction<_DbUpsertBatchNative, _DbUpsertBatchDart>(
            'tack_db_upsert_batch_json',
          );
      _dbDeleteItem = lib
          .lookupFunction<_DbDeleteItemNative, _DbDeleteItemDart>(
            'tack_db_delete_item',
          );
      _dbEmptyTrash = lib
          .lookupFunction<_DbEmptyTrashNative, _DbEmptyTrashDart>(
            'tack_db_empty_trash',
          );
      _dbLoadAll = lib.lookupFunction<_DbLoadAllNative, _DbLoadAllDart>(
        'tack_db_load_all_json',
      );
      _dbSearchIds = lib.lookupFunction<_DbSearchIdsNative, _DbSearchIdsDart>(
        'tack_db_search_ids',
      );
      _extractWikiLinks = lib
          .lookupFunction<_ExtractWikiLinksNative, _ExtractWikiLinksDart>(
            'tack_extract_wikilinks',
          );
      _computeBacklinks = lib
          .lookupFunction<_ComputeBacklinksNative, _ComputeBacklinksDart>(
            'tack_compute_backlinks',
          );
      _tokenizeCode = lib
          .lookupFunction<_TokenizeCodeNative, _TokenizeCodeDart>(
            'tack_tokenize_code',
          );
      _available = true;
    } catch (e) {
      debugPrint('TackCoreBridge init failed, falling back to Dart: $e');
      _available = false;
    }
  }

  // -------------------------------------------------------------------------
  // Low-level UTF-8 & buffer marshalling helpers
  // -------------------------------------------------------------------------
  (Pointer<Uint8>, int) _toNativeUtf8(String value) {
    final bytes = utf8.encode(value);
    if (bytes.isEmpty) {
      return (nullptr, 0);
    }
    final ptr = _alloc(bytes.length);
    ptr.asTypedList(bytes.length).setAll(0, bytes);
    return (ptr, bytes.length);
  }

  void _freeUtf8((Pointer<Uint8>, int) buf) {
    if (buf.$1 != nullptr && buf.$2 > 0) {
      _free(buf.$1, buf.$2);
    }
  }

  String _consumeCstr(Pointer<Uint8> ptr) {
    if (ptr == nullptr) return '';
    try {
      int len = 0;
      while (ptr[len] != 0) {
        len++;
      }
      if (len == 0) return '';
      return utf8.decode(ptr.asTypedList(len), allowMalformed: true);
    } finally {
      _freeCstr(ptr);
    }
  }

  // -------------------------------------------------------------------------
  // 1. Knowledge Graph Force-Directed Layout
  // -------------------------------------------------------------------------
  bool layoutGraph({
    required List<Offset> positions,
    required List<int> flatEdges,
    required int pinnedIndex,
    required Offset center,
    required double canvasSize,
    int iterations = 70,
  }) {
    if (!isAvailable || positions.isEmpty) return false;
    final n = positions.length;
    final posByteLen = n * 2 * 4;
    final posBytes = _alloc(posByteLen);
    final posFloats = posBytes.cast<Float>();
    final posView = posFloats.asTypedList(n * 2);
    for (int i = 0; i < n; i++) {
      posView[i * 2] = positions[i].dx;
      posView[i * 2 + 1] = positions[i].dy;
    }

    final edgeCount = flatEdges.length ~/ 3;
    final edgeByteLen = flatEdges.length * 4;
    final edgeBytes = edgeByteLen > 0 ? _alloc(edgeByteLen) : nullptr;
    final edgeInts = edgeBytes.cast<Int32>();
    if (edgeByteLen > 0) {
      edgeInts.asTypedList(flatEdges.length).setAll(0, flatEdges);
    }

    try {
      _layoutGraph(
        posFloats,
        n,
        edgeInts,
        edgeCount,
        pinnedIndex,
        center.dx,
        center.dy,
        canvasSize,
        iterations,
      );
      for (int i = 0; i < n; i++) {
        positions[i] = Offset(posView[i * 2], posView[i * 2 + 1]);
      }
      return true;
    } finally {
      _free(posBytes, posByteLen);
      if (edgeBytes != nullptr && edgeByteLen > 0) {
        _free(edgeBytes, edgeByteLen);
      }
    }
  }

  // -------------------------------------------------------------------------
  // 2. SQLite + FTS5 Incremental Storage & Search
  // -------------------------------------------------------------------------
  int openDatabase(String path) {
    if (!isAvailable) return 0;
    final buf = _toNativeUtf8(path);
    try {
      return _dbOpen(buf.$1, buf.$2);
    } finally {
      _freeUtf8(buf);
    }
  }

  void closeDatabase(int handle) {
    if (!isAvailable || handle <= 0) return;
    _dbClose(handle);
  }

  bool upsertItem({
    required int handle,
    required String id,
    required String itemType,
    required String title,
    required String bodyText,
    required String tagsText,
    required bool isTrash,
    required bool isArchived,
    required bool isFavorite,
    required int updatedAtMs,
    required String jsonPayload,
  }) {
    if (!isAvailable || handle <= 0) return false;
    final bId = _toNativeUtf8(id);
    final bType = _toNativeUtf8(itemType);
    final bTitle = _toNativeUtf8(title);
    final bBody = _toNativeUtf8(bodyText);
    final bTags = _toNativeUtf8(tagsText);
    final bJson = _toNativeUtf8(jsonPayload);
    try {
      return _dbUpsertItem(
            handle,
            bId.$1,
            bId.$2,
            bType.$1,
            bType.$2,
            bTitle.$1,
            bTitle.$2,
            bBody.$1,
            bBody.$2,
            bTags.$1,
            bTags.$2,
            isTrash ? 1 : 0,
            isArchived ? 1 : 0,
            isFavorite ? 1 : 0,
            updatedAtMs,
            bJson.$1,
            bJson.$2,
          ) ==
          1;
    } finally {
      _freeUtf8(bId);
      _freeUtf8(bType);
      _freeUtf8(bTitle);
      _freeUtf8(bBody);
      _freeUtf8(bTags);
      _freeUtf8(bJson);
    }
  }

  bool upsertBatchJson(int handle, String batchJson) {
    if (!isAvailable || handle <= 0) return false;
    final b = _toNativeUtf8(batchJson);
    try {
      return _dbUpsertBatch(handle, b.$1, b.$2) == 1;
    } finally {
      _freeUtf8(b);
    }
  }

  bool deleteItem(int handle, String id) {
    if (!isAvailable || handle <= 0) return false;
    final b = _toNativeUtf8(id);
    try {
      return _dbDeleteItem(handle, b.$1, b.$2) == 1;
    } finally {
      _freeUtf8(b);
    }
  }

  bool emptyTrash(int handle) {
    if (!isAvailable || handle <= 0) return false;
    return _dbEmptyTrash(handle) == 1;
  }

  String? loadAllItemsJson(int handle) {
    if (!isAvailable || handle <= 0) return null;
    final ptr = _dbLoadAll(handle);
    if (ptr == nullptr) return null;
    return _consumeCstr(ptr);
  }

  List<String>? searchItemIds(
    int handle,
    String query, {
    String? itemType,
    int limit = 200,
  }) {
    if (!isAvailable || handle <= 0) return null;
    final bQ = _toNativeUtf8(query);
    final bT = _toNativeUtf8(itemType ?? '');
    try {
      final raw = _consumeCstr(
        _dbSearchIds(handle, bQ.$1, bQ.$2, bT.$1, bT.$2, limit),
      );
      if (raw.isEmpty) return const [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<String>();
    } catch (_) {
      return null;
    } finally {
      _freeUtf8(bQ);
      _freeUtf8(bT);
    }
  }

  // -------------------------------------------------------------------------
  // 3. Wiki-Link & Backlinks Scanner
  // -------------------------------------------------------------------------
  List<Map<String, dynamic>>? extractWikiLinks(String content) {
    if (!isAvailable) return null;
    if (content.isEmpty) return const [];
    final b = _toNativeUtf8(content);
    try {
      final raw = _consumeCstr(_extractWikiLinks(b.$1, b.$2));
      if (raw.isEmpty) return const [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    } catch (_) {
      return null;
    } finally {
      _freeUtf8(b);
    }
  }

  Map<String, dynamic>? computeBacklinks(Map<String, dynamic> request) {
    if (!isAvailable) return null;
    final b = _toNativeUtf8(jsonEncode(request));
    try {
      final raw = _consumeCstr(_computeBacklinks(b.$1, b.$2));
      if (raw.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    } finally {
      _freeUtf8(b);
    }
  }

  // -------------------------------------------------------------------------
  // 4. Zero-Copy Multi-Language Code Syntax Lexer
  // -------------------------------------------------------------------------
  /// Returns flat `[utf16_start, utf16_end, token_kind_id, ...]` or `null` if unavailable.
  Int32List? tokenizeCode(String code, String language) {
    if (!isAvailable) return null;
    if (code.isEmpty) return Int32List(0);
    final bCode = _toNativeUtf8(code);
    final bLang = _toNativeUtf8(language);
    final outLenBytes = _alloc(8);
    final outLenPtr = outLenBytes.cast<IntPtr>();
    outLenPtr.value = 0;

    try {
      final tokPtr = _tokenizeCode(
        bCode.$1,
        bCode.$2,
        bLang.$1,
        bLang.$2,
        outLenPtr,
      );
      final count = outLenPtr.value;
      if (tokPtr == nullptr || count <= 0) {
        return Int32List(0);
      }
      try {
        return Int32List.fromList(tokPtr.asTypedList(count));
      } finally {
        _freeI32Buf(tokPtr, count);
      }
    } finally {
      _freeUtf8(bCode);
      _freeUtf8(bLang);
      _free(outLenBytes, 8);
    }
  }
}

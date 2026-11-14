import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/task_reminder_service.dart';
import '../data/i_workspace_repo.dart';
import '../models/base_item.dart';
import '../models/item_serializer.dart';
import '../../features/notes/models/text_note.dart';
import '../models/sticky_note.dart';
import '../../features/whiteboard/models/whiteboard_item.dart';
import '../models/clipboard_item.dart';
import '../../features/notes/services/frontmatter_service.dart';
import '../../features/tasks/services/open_tasks_service.dart';
import '../../features/notes/services/wiki_link_service.dart';

enum HomeSortMode {
  newestFirst,
  oldestFirst,
  alphabetical,
}

/// Centralized state manager for Tack workspace items.
/// Maintains an unfiltered master list (`_allActiveItems`) separate from filtered
/// UI projections so backups, Daily Note lookups, and link resolution never
/// operate on a partial subset (`03` §7 P0, `08` §2.1).
class WorkspaceProvider extends ChangeNotifier {
  static const String _foldersPrefsKey = 'tack_custom_folders_v1';
  static const String _carryForwardPrefsKey = 'tack_carry_forward_tasks_v1';
  static const List<String> _defaultFolders = [
    'All Notes',
    'Work',
    'Ideas',
    'Personal',
    'Specs',
  ];

  final IWorkspaceRepository _repository;
  static int _idSeq = 0;

  static String _nextId(String prefix) {
    _idSeq++;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_idSeq';
  }

  /// Unfiltered master list of all active (non-trash, non-archived) items.
  List<BaseWorkspaceItem> _allActiveItems = [];
  List<BaseWorkspaceItem> _trashItems = [];
  List<BaseWorkspaceItem> _archivedItems = [];
  List<String> _folders = List<String>.from(_defaultFolders);

  String _searchQuery = '';
  ItemType? _selectedCategory;
  String? _selectedTag;
  String _selectedFolder = 'All Notes';
  bool _pinnedFilterOnly = false;
  HomeSortMode _sortMode = HomeSortMode.newestFirst;
  int _bottomNavIndex = 0;
  bool _isLoading = false;
  bool _carryForwardTasksEnabled = true;

  WorkspaceProvider(this._repository) {
    _allActiveItems = List<BaseWorkspaceItem>.from(_repository.cachedActiveItems);
    _loadPrefsAndItems();
  }

  Future<void> _loadPrefsAndItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFolders = prefs.getStringList(_foldersPrefsKey);
      if (savedFolders != null && savedFolders.isNotEmpty) {
        final merged = <String>['All Notes'];
        for (final f in savedFolders) {
          if (f.trim().isNotEmpty && !merged.contains(f.trim())) {
            merged.add(f.trim());
          }
        }
        _folders = merged;
      }
      _carryForwardTasksEnabled = prefs.getBool(_carryForwardPrefsKey) ?? true;
    } catch (_) {
      // Fallback to defaults
    }
    await loadItems();
  }

  // ---------------------------------------------------------------------------
  // Core Getters
  // ---------------------------------------------------------------------------

  /// Unfiltered active items across the entire workspace.
  List<BaseWorkspaceItem> get allActiveItems => List.unmodifiable(_allActiveItems);

  /// Alias for `allActiveItems` used by graph, backlinks, and wiki-link resolution.
  List<BaseWorkspaceItem> get rawItems => allActiveItems;

  BaseWorkspaceItem? getItemById(String id) => getItemByIdSync(id);

  Future<void> restoreItem(String id) => restoreFromTrash(id);

  /// Filtered & sorted items matching current Library/Home filters.
  List<BaseWorkspaceItem> get items {
    var filtered = _allActiveItems.where((item) {
      if (_selectedCategory != null && item.type != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty && !item.matchesQuery(_searchQuery)) {
        return false;
      }
      return true;
    }).toList();

    if (_selectedFolder != 'All Notes') {
      filtered = filtered.where((item) {
        final effectiveFolder = resolveEffectiveFolder(item);
        return effectiveFolder?.toLowerCase() == _selectedFolder.toLowerCase();
      }).toList();
    }

    if (_selectedTag != null && _selectedTag!.isNotEmpty) {
      filtered = filtered.where((item) {
        if (item is TextNote) {
          return item.tags.any(
            (t) => t.toLowerCase() == _selectedTag!.toLowerCase(),
          );
        }
        return false;
      }).toList();
    }

    if (_pinnedFilterOnly) {
      filtered = filtered.where((i) => i.isFavorite).toList();
    }

    _sortItemsList(filtered);
    return List.unmodifiable(filtered);
  }

  /// Non-inbox notes & legacy stickies/clips for the Library grid (`05` §2.1).
  List<BaseWorkspaceItem> get libraryNotes {
    var filtered = _allActiveItems.where((item) {
      if (item.isInbox) return false;
      if (item.type == ItemType.whiteboard) return false;
      if (_searchQuery.isNotEmpty && !item.matchesQuery(_searchQuery)) {
        return false;
      }
      return true;
    }).toList();

    if (_selectedFolder != 'All Notes') {
      filtered = filtered.where((item) {
        final effectiveFolder = resolveEffectiveFolder(item);
        return effectiveFolder?.toLowerCase() == _selectedFolder.toLowerCase();
      }).toList();
    }

    if (_selectedTag != null && _selectedTag!.isNotEmpty) {
      filtered = filtered.where((item) {
        if (item is TextNote) {
          return item.tags.any(
            (t) => t.toLowerCase() == _selectedTag!.toLowerCase(),
          );
        }
        return false;
      }).toList();
    }

    if (_pinnedFilterOnly) {
      filtered = filtered.where((i) => i.isFavorite).toList();
    }

    _sortItemsList(filtered);
    return List.unmodifiable(filtered);
  }

  /// Unsorted captures waiting in the Inbox (`04` F1, `05` §4).
  List<BaseWorkspaceItem> get inboxItems {
    final list = _allActiveItems.where((i) => i.isInbox && !i.isTrash).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(list);
  }

  /// Visual Boards (`WhiteboardCanvasItem`s) for the Boards tab (`05` §2.1).
  List<WhiteboardCanvasItem> get boardItems {
    final list = _allActiveItems
        .whereType<WhiteboardCanvasItem>()
        .where((b) => !b.isTrash)
        .toList();
    _sortItemsList(list);
    return List.unmodifiable(list);
  }

  /// Pinned notes & boards (`isFavorite == true && !isInbox`).
  List<BaseWorkspaceItem> get pinnedItems {
    final list = _allActiveItems
        .where((i) => i.isFavorite && !i.isInbox && !i.isTrash)
        .toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(list);
  }

  /// Open `- [ ]` tasks derived across all active notes (`04` F3).
  List<DerivedTaskItem> get openTasks =>
      OpenTasksService.extractTasks(_allActiveItems, includeCompleted: false);

  /// Single "Worth revisiting" note card (`04` F13): an older note (>7 days or
  /// least recently updated non-daily note) to resurface on Today.
  TextNote? get worthRevisitingNote {
    final now = DateTime.now();
    final candidates = _allActiveItems
        .whereType<TextNote>()
        .where((n) =>
            !n.isInbox &&
            !n.isTrash &&
            !n.title.startsWith('Daily Note • ') &&
            n.content.trim().isNotEmpty)
        .toList();
    if (candidates.isEmpty) return null;

    final olderThanWeek = candidates
        .where((n) => now.difference(n.updatedAt).inDays >= 7)
        .toList();
    if (olderThanWeek.isNotEmpty) {
      final daySeed = now.year * 1000 + now.month * 31 + now.day;
      return olderThanWeek[daySeed % olderThanWeek.length];
    }
    return null;
  }

  List<BaseWorkspaceItem> get trashItems => List.unmodifiable(_trashItems);
  List<BaseWorkspaceItem> get archivedItems => List.unmodifiable(_archivedItems);
  List<BaseWorkspaceItem> get favoriteItems =>
      _allActiveItems.where((i) => i.isFavorite).toList();

  List<String> get folders => List.unmodifiable(_folders);
  List<String> get userFolders =>
      _folders.where((f) => f != 'All Notes').toList();

  String get searchQuery => _searchQuery;
  ItemType? get selectedCategory => _selectedCategory;
  String? get selectedTag => _selectedTag;
  String get selectedFolder => _selectedFolder;
  bool get pinnedFilterOnly => _pinnedFilterOnly;
  HomeSortMode get sortMode => _sortMode;
  int get bottomNavIndex => _bottomNavIndex;
  bool get isLoading => _isLoading;
  bool get carryForwardTasksEnabled => _carryForwardTasksEnabled;

  /// Dynamically extracts all unique tags across all active TextNotes.
  /// No longer seeds fake `#Fitness` tags when unused (`03` §7 P2).
  List<String> get availableTags {
    final Set<String> tagSet = {};
    for (final item in _allActiveItems) {
      if (item is TextNote && !item.isInbox) {
        for (final t in item.tags) {
          if (t.trim().isNotEmpty) {
            tagSet.add(t.trim());
          }
        }
      }
    }
    final sorted = tagSet.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  void _sortItemsList(List<BaseWorkspaceItem> list) {
    list.sort((a, b) {
      // Pinned items float to top in newestFirst mode
      if (_sortMode == HomeSortMode.newestFirst && a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      switch (_sortMode) {
        case HomeSortMode.newestFirst:
          return b.updatedAt.compareTo(a.updatedAt);
        case HomeSortMode.oldestFirst:
          return a.createdAt.compareTo(b.createdAt);
        case HomeSortMode.alphabetical:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });
  }

  /// Resolves folder name for an item, walking up `parentId` if needed.
  String? resolveEffectiveFolder(BaseWorkspaceItem item) {
    if (item.folderName != null && item.folderName!.trim().isNotEmpty) {
      return item.folderName;
    }
    String? currentParentId = item.parentId;
    int depth = 0;
    while (currentParentId != null && depth < 8) {
      final parent = getItemByIdSync(currentParentId);
      if (parent == null) break;
      if (parent.folderName != null && parent.folderName!.trim().isNotEmpty) {
        return parent.folderName;
      }
      currentParentId = parent.parentId;
      depth++;
    }
    return null;
  }

  /// Returns direct sub-notes (`parentId == parentItemId`) for an item.
  List<BaseWorkspaceItem> getChildItems(String parentItemId) {
    final children = _allActiveItems
        .where((i) => !i.isTrash && !i.isArchived && i.parentId == parentItemId)
        .toList();
    children.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return children;
  }

  /// Returns the ancestor chain `[root, ..., immediateParent]` for breadcrumb navigation.
  List<BaseWorkspaceItem> getBreadcrumbChain(BaseWorkspaceItem item) {
    final chain = <BaseWorkspaceItem>[];
    String? currentParentId = item.parentId;
    int depth = 0;
    while (currentParentId != null && depth < 8) {
      final parent = getItemByIdSync(currentParentId);
      if (parent == null) break;
      chain.insert(0, parent);
      currentParentId = parent.parentId;
      depth++;
    }
    return chain;
  }

  BaseWorkspaceItem? getItemByIdSync(String id) {
    for (final item in _allActiveItems) {
      if (item.id == id) return item;
    }
    for (final item in _archivedItems) {
      if (item.id == id) return item;
    }
    for (final item in _trashItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Load & Filter Setters
  // ---------------------------------------------------------------------------

  Future<void> loadItems() async {
    final shouldShowSpinner = _allActiveItems.isEmpty;
    if (shouldShowSpinner) {
      _isLoading = true;
      notifyListeners();
    }

    _allActiveItems = await _repository.getAllActiveItems();
    _trashItems = await _repository.getTrashItems();
    _archivedItems = await _repository.getArchivedItems();

    // Ensure any folder referenced by existing items is present in `_folders`
    bool foldersUpdated = false;
    for (final item in _allActiveItems) {
      final f = item.folderName?.trim();
      if (f != null && f.isNotEmpty && !_folders.contains(f)) {
        _folders.add(f);
        foldersUpdated = true;
      }
    }
    if (foldersUpdated) {
      await _persistFolders();
    }

    _isLoading = false;
    unawaited(TaskReminderService.syncWorkspaceReminders(_allActiveItems));
    notifyListeners();
  }

  void setBottomNavIndex(int index) {
    _bottomNavIndex = index;
    notifyListeners();
  }

  void setCategoryFilter(ItemType? type) {
    _selectedCategory = type;
    notifyListeners();
  }

  void setCategory(ItemType? type) => setCategoryFilter(type);

  void setTagFilter(String? tag) {
    if (_selectedTag == tag) {
      _selectedTag = null;
    } else {
      _selectedTag = tag;
    }
    notifyListeners();
  }

  void setSelectedTag(String? tag) => setTagFilter(tag);

  Future<void> moveItemToFolder(String id, String? folderName) async {
    final existing = getItemByIdSync(id);
    if (existing == null) return;
    final cleanFolder = folderName?.trim();
    if (cleanFolder != null && cleanFolder.isNotEmpty) {
      await addFolder(cleanFolder);
      await saveItem(
        existing.copyWith(
          folderName: cleanFolder,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await saveItem(
        existing.copyWith(
          clearFolder: true,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  void setPinnedFilterOnly(bool value) {
    _pinnedFilterOnly = value;
    notifyListeners();
  }

  void setSelectedFolder(String folder) {
    if (_selectedFolder == folder) return;
    _selectedFolder = folder;
    notifyListeners();
  }

  Future<void> setCarryForwardTasksEnabled(bool enabled) async {
    _carryForwardTasksEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_carryForwardPrefsKey, enabled);
    } catch (_) {}
  }

  Future<void> addFolder(String folderName) async {
    final cleaned = folderName.trim();
    if (cleaned.isEmpty || _folders.any((f) => f.toLowerCase() == cleaned.toLowerCase())) {
      return;
    }
    _folders.add(cleaned);
    await _persistFolders();
    notifyListeners();
  }

  Future<void> deleteFolder(String folderName) async {
    if (folderName == 'All Notes') return;
    _folders.removeWhere((f) => f.toLowerCase() == folderName.toLowerCase());
    if (_selectedFolder.toLowerCase() == folderName.toLowerCase()) {
      _selectedFolder = 'All Notes';
    }
    for (final item in _allActiveItems) {
      if (item.folderName?.toLowerCase() == folderName.toLowerCase()) {
        await _repository.saveItem(item.copyWith(clearFolder: true));
      }
    }
    await _persistFolders();
    await loadItems();
  }

  Future<void> _persistFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_foldersPrefsKey, _folders);
    } catch (_) {}
  }

  void setSortMode(HomeSortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CRUD, Link Rename Propagation & Triage Actions
  // ---------------------------------------------------------------------------

  /// Saves [item] and propagates any title rename across inbound `[[WikiLinks]]`
  /// so links never break on rename (`04` M2/F5, `08` §5).
  Future<void> saveItem(BaseWorkspaceItem item) async {
    final existing = getItemByIdSync(item.id);
    final oldTitle = existing?.title.trim() ?? '';
    final newTitle = item.title.trim();

    await _repository.saveItem(item);

    if (existing != null &&
        oldTitle.isNotEmpty &&
        newTitle.isNotEmpty &&
        oldTitle.toLowerCase() != newTitle.toLowerCase() &&
        oldTitle.toLowerCase() != 'untitled') {
      await _propagateTitleRename(oldTitle: oldTitle, newTitle: newTitle);
    }

    await loadItems();
  }

  Future<void> _propagateTitleRename({
    required String oldTitle,
    required String newTitle,
  }) async {
    for (final other in List<BaseWorkspaceItem>.from(_allActiveItems)) {
      if (other is TextNote) {
        final rewritten = OpenTasksService.rewriteWikiLinks(
          other.content,
          oldTitle: oldTitle,
          newTitle: newTitle,
        );
        if (rewritten != other.content) {
          final updatedLinks = WikiLinkService.extractAllLinks(rewritten)
              .map((l) => l.target)
              .toSet()
              .toList();
          await _repository.saveItem(
            other.copyWith(
              content: rewritten,
              links: updatedLinks,
            ),
          );
        }
      }
    }
  }

  /// Toggles a derived Markdown task (`- [ ]` ↔ `- [x]`) or advances a recurring
  /// task (`@repeat(...)`) to its next due date directly in its source note.
  Future<TaskToggleResult?> toggleTask(
    DerivedTaskItem task, {
    DateTime? now,
  }) async {
    return completeTaskLineByIndex(
      task.noteId,
      task.lineIndex,
      now: now,
    );
  }

  /// Toggles/advances checklist line [lineIndex] inside [noteId].
  Future<TaskToggleResult?> completeTaskLineByIndex(
    String noteId,
    int lineIndex, {
    DateTime? now,
  }) async {
    final item = getItemByIdSync(noteId);
    if (item is TextNote) {
      final result = OpenTasksService.completeOrToggleTaskAtLine(
        item.content,
        lineIndex,
        now: now,
      );
      if (result != null) {
        await saveItem(
          item.copyWith(
            content: result.updatedContent,
            updatedAt: DateTime.now(),
          ),
        );
      }
      return result;
    } else if (item is StickyNote) {
      final result = OpenTasksService.completeOrToggleTaskAtLine(
        item.content,
        lineIndex,
        now: now,
      );
      if (result != null) {
        await saveItem(
          item.copyWith(
            content: result.updatedContent,
            updatedAt: DateTime.now(),
          ),
        );
      }
      return result;
    }
    return null;
  }

  /// Updates or clears `@due(...)` and `@repeat(...)` metadata directly on a task's
  /// Markdown checklist line inside its source note.
  Future<void> setTaskReminder(
    DerivedTaskItem task, {
    DateTime? dueAt,
    bool hasExplicitTime = false,
    TaskRecurrence? recurrence,
  }) async {
    final item = getItemByIdSync(task.noteId);
    if (item is TextNote) {
      final updatedBody = OpenTasksService.setTaskReminderAtLine(
        item.content,
        task.lineIndex,
        dueAt: dueAt,
        hasExplicitTime: hasExplicitTime,
        recurrence: recurrence,
      );
      if (updatedBody != null) {
        await saveItem(
          item.copyWith(
            content: updatedBody,
            updatedAt: DateTime.now(),
          ),
        );
      }
    } else if (item is StickyNote) {
      final updatedBody = OpenTasksService.setTaskReminderAtLine(
        item.content,
        task.lineIndex,
        dueAt: dueAt,
        hasExplicitTime: hasExplicitTime,
        recurrence: recurrence,
      );
      if (updatedBody != null) {
        await saveItem(
          item.copyWith(
            content: updatedBody,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  /// Captures a quick thought or shared text into the Inbox (`isInbox: true`).
  Future<TextNote> captureToInbox(
    String text, {
    String? title,
    String paletteId = 'amber',
    String? sourceApp,
  }) async {
    final now = DateTime.now();
    final cleaned = text.trim();
    final firstLine = cleaned.split('\n').first.replaceAll(RegExp(r'^#+\s*'), '').trim();
    final resolvedTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : (firstLine.isNotEmpty
            ? (firstLine.length > 48 ? '${firstLine.substring(0, 48)}…' : firstLine)
            : 'Quick Capture');

    final tagMatches = RegExp(r'#(\w+)').allMatches(cleaned);
    final tags = tagMatches.map((m) => m.group(1)!).toSet().toList();
    final links = WikiLinkService.extractAllLinks(cleaned)
        .map((l) => l.target)
        .toSet()
        .toList();

    final note = TextNote(
      id: _nextId('inbox'),
      title: resolvedTitle,
      content: cleaned,
      createdAt: now,
      updatedAt: now,
      paletteId: paletteId,
      isInbox: true,
      tags: tags,
      links: links,
    );
    await saveItem(note);
    return note;
  }

  /// Triage action 1: Keeps an Inbox item as a full Library note (`isInbox: false`).
  Future<void> keepInboxItemAsNote(String inboxId, {String? folderName}) async {
    final item = getItemByIdSync(inboxId);
    if (item == null) return;
    if (item is ClipboardItem) {
      final now = DateTime.now();
      await deletePermanently(inboxId);
      await saveItem(
        TextNote(
          id: 'note_${now.microsecondsSinceEpoch}',
          title: item.title,
          content: item.clipText,
          createdAt: item.createdAt,
          updatedAt: now,
          paletteId: item.paletteId,
          isInbox: false,
          folderName: folderName,
        ),
      );
      return;
    }
    await saveItem(
      item.copyWith(
        isInbox: false,
        folderName: folderName ?? item.folderName,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Triage action 2: Appends an Inbox item's content to an existing target note
  /// and removes the Inbox capture.
  Future<void> appendInboxItemToNote(String inboxId, String targetNoteId) async {
    final inboxItem = getItemByIdSync(inboxId);
    final target = getItemByIdSync(targetNoteId);
    if (inboxItem == null || target is! TextNote) return;

    String textToAppend = '';
    if (inboxItem is TextNote) {
      textToAppend = inboxItem.content.trim().isNotEmpty
          ? inboxItem.content.trim()
          : inboxItem.title;
    } else if (inboxItem is ClipboardItem) {
      textToAppend = inboxItem.clipText.trim();
    } else {
      textToAppend = inboxItem.getSummary();
    }

    final separator = target.content.trim().isEmpty ? '' : '\n\n';
    final updatedContent = '${target.content.trimRight()}$separator$textToAppend';
    await saveItem(
      target.copyWith(
        content: updatedContent,
        updatedAt: DateTime.now(),
      ),
    );
    await deletePermanently(inboxId);
  }

  /// Triage action 3: Converts an Inbox capture into a `- [ ]` task on Today's Daily Note.
  Future<void> convertInboxItemToTodayTask(String inboxId) async {
    final inboxItem = getItemByIdSync(inboxId);
    if (inboxItem == null) return;

    String taskText = '';
    if (inboxItem is TextNote) {
      taskText = inboxItem.content.trim().isNotEmpty
          ? inboxItem.content.trim().replaceAll('\n', ' ')
          : inboxItem.title.trim();
    } else if (inboxItem is ClipboardItem) {
      taskText = inboxItem.clipText.trim().replaceAll('\n', ' ');
    } else {
      taskText = inboxItem.title.trim();
    }
    if (taskText.isEmpty) taskText = ' Captured task';
    taskText = taskText.replaceFirst(RegExp(r'^[-*]\s*\[[ xX]\]\s*'), '');

    final todaysNote = await openOrCreateTodaysNote();
    final updatedContent = '${todaysNote.content.trimRight()}\n- [ ] $taskText\n';
    await saveItem(
      todaysNote.copyWith(
        content: updatedContent,
        updatedAt: DateTime.now(),
      ),
    );
    await deletePermanently(inboxId);
  }

  /// Duplicates an item as a new copy.
  Future<BaseWorkspaceItem> duplicateItem(BaseWorkspaceItem item) async {
    final now = DateTime.now();
    final newId = _nextId(item.type.name);
    final copyTitle = '${item.title} (Copy)';

    BaseWorkspaceItem duplicated;
    if (item is TextNote) {
      duplicated = TextNote(
        id: newId,
        title: copyTitle,
        content: item.content,
        createdAt: now,
        updatedAt: now,
        paletteId: item.paletteId,
        folderName: item.folderName,
        parentId: item.parentId,
        iconEmoji: item.iconEmoji,
        tags: List<String>.from(item.tags),
        links: List<String>.from(item.links),
        estimatedMinutes: item.estimatedMinutes,
      );
    } else if (item is WhiteboardCanvasItem) {
      duplicated = WhiteboardCanvasItem(
        id: newId,
        title: copyTitle,
        createdAt: now,
        updatedAt: now,
        paletteId: item.paletteId,
        folderName: item.folderName,
        iconEmoji: item.iconEmoji,
        nodes: List<CanvasNode>.from(item.nodes),
        edges: List<CanvasEdge>.from(item.edges),
        zoomScale: item.zoomScale,
        panOffset: item.panOffset,
      );
    } else if (item is StickyNote) {
      duplicated = StickyNote(
        id: newId,
        title: copyTitle,
        content: item.content,
        createdAt: now,
        updatedAt: now,
        paletteId: item.paletteId,
        folderName: item.folderName,
      );
    } else {
      duplicated = item;
    }

    await saveItem(duplicated);
    return duplicated;
  }

  Future<void> toggleFavorite(String id) async {
    await _repository.toggleFavorite(id);
    await loadItems();
  }

  Future<void> toggleArchive(String id) async {
    await _repository.toggleArchive(id);
    await loadItems();
  }

  Future<void> moveToTrash(String id) async {
    await _repository.moveToTrash(id);
    await loadItems();
  }

  Future<void> restoreFromTrash(String id) async {
    await _repository.restoreItem(id);
    await loadItems();
  }

  Future<void> deletePermanently(String id) async {
    await _repository.deletePermanently(id);
    await loadItems();
  }

  Future<void> emptyTrash() async {
    await _repository.emptyTrash();
    await loadItems();
  }

  // ---------------------------------------------------------------------------
  // Backup & Restore (All Items: Active + Trash + Archived)
  // ---------------------------------------------------------------------------

  /// Exports ALL workspace items (active + trash + archived) as a pretty-printed
  /// JSON string so backups are never affected by active UI filters (`03` §7 P0).
  String exportWorkspaceJson() {
    final all = <BaseWorkspaceItem>[
      ..._allActiveItems,
      ..._trashItems,
      ..._archivedItems,
    ];
    final payload = {
      'app': 'Tack',
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'folders': _folders,
      'items': all.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Imports workspace items from a JSON backup string, merging by ID.
  Future<int> importWorkspaceJson(String jsonString) async {
    final dynamic decoded = jsonDecode(jsonString);
    List<dynamic> rawItems;

    if (decoded is Map<String, dynamic> && decoded['items'] is List) {
      rawItems = decoded['items'] as List<dynamic>;
      if (decoded['folders'] is List) {
        for (final f in (decoded['folders'] as List)) {
          final name = f.toString().trim();
          if (name.isNotEmpty && !_folders.contains(name)) {
            _folders.add(name);
          }
        }
        await _persistFolders();
      }
    } else if (decoded is List) {
      rawItems = decoded;
    } else {
      throw const FormatException('Invalid Tack backup format');
    }

    int count = 0;
    for (final raw in rawItems) {
      if (raw is Map) {
        final item = ItemSerializer.fromJson(Map<String, dynamic>.from(raw));
        if (item != null) {
          await _repository.saveItem(item);
          count++;
        }
      }
    }
    await loadItems();
    return count;
  }

  // ---------------------------------------------------------------------------
  // Quick Item Creation & Daily Note
  // ---------------------------------------------------------------------------

  /// Helper to create a new quick item of any polymorphic type.
  Future<BaseWorkspaceItem> createQuickItem({
    required String title,
    required ItemType type,
    required String paletteId,
    String extraContent = '',
    String? content,
    String? folderName,
    String? parentId,
    String? iconEmoji,
    List<String>? tags,
    bool isInbox = false,
  }) async {
    final bodyContent = (content != null && content.isNotEmpty) ? content : extraContent;
    final now = DateTime.now();
    final id = _nextId(type.name);
    final resolvedFolder = folderName ??
        (parentId != null
            ? resolveEffectiveFolder(
                getItemByIdSync(parentId) ??
                    TextNote(
                      id: '',
                      title: '',
                      content: '',
                      createdAt: now,
                      updatedAt: now,
                      paletteId: paletteId,
                    ),
              )
            : (_selectedFolder != 'All Notes' ? _selectedFolder : null));

    BaseWorkspaceItem newItem;
    switch (type) {
      case ItemType.note:
        final tagMatches = RegExp(r'#(\w+)').allMatches(bodyContent);
        final mergedTags = <String>{
          ...?tags,
          ...tagMatches.map((m) => m.group(1)!),
        }.toList();
        final links = WikiLinkService.extractAllLinks(bodyContent)
            .map((l) => l.target)
            .toSet()
            .toList();
        newItem = TextNote(
          id: id,
          title: title.isEmpty ? 'Untitled Note' : title,
          content: bodyContent,
          createdAt: now,
          updatedAt: now,
          paletteId: paletteId,
          isInbox: isInbox,
          folderName: resolvedFolder,
          parentId: parentId,
          iconEmoji: iconEmoji,
          tags: mergedTags,
          links: links,
        );
        break;
      case ItemType.sticky:
        newItem = StickyNote(
          id: id,
          title: title.isEmpty ? 'Quick Sticky' : title,
          content: bodyContent.isEmpty ? title : bodyContent,
          createdAt: now,
          updatedAt: now,
          paletteId: paletteId,
          isInbox: isInbox,
          folderName: resolvedFolder,
          parentId: parentId,
          iconEmoji: iconEmoji,
          rotationAngle: 0.0,
        );
        break;
      case ItemType.whiteboard:
        newItem = WhiteboardCanvasItem(
          id: id,
          title: title.isEmpty ? 'Untitled Board' : title,
          createdAt: now,
          updatedAt: now,
          paletteId: paletteId,
          folderName: resolvedFolder,
          parentId: parentId,
          iconEmoji: iconEmoji,
          nodes: [
            CanvasNode(
              id: 'node_start_${now.millisecondsSinceEpoch}',
              text: 'Start',
              shapeType: CanvasNodeType.startEnd,
              x: 2930,
              y: 2960,
              width: 140,
              height: 54,
              paletteId: 'coral',
            ),
          ],
          edges: [],
        );
        break;
      case ItemType.clipboard:
        newItem = ClipboardItem(
          id: id,
          title: title.isEmpty ? 'Saved Snippet' : title,
          clipText: extraContent.isEmpty ? title : extraContent,
          createdAt: now,
          updatedAt: now,
          paletteId: paletteId,
          isInbox: isInbox,
          folderName: resolvedFolder,
          parentId: parentId,
          iconEmoji: iconEmoji,
        );
        break;
    }

    await saveItem(newItem);
    return newItem;
  }

  /// Opens or creates Today's Daily Note (`Daily Note • YYYY-MM-DD`).
  /// Searches `_allActiveItems` so active filters never hide Today's Note (`03` §7 P0).
  Future<TextNote> openOrCreateTodaysNote({DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final expectedTitle = 'Daily Note • $dateStr';

    for (final item in _allActiveItems) {
      if (item is TextNote && !item.isTrash && item.title == expectedTitle) {
        return item;
      }
    }

    // Find the most recent previous Daily Note for task carry-forward (`04` M4)
    TextNote? previousDaily;
    for (final item in _allActiveItems) {
      if (item is TextNote &&
          !item.isTrash &&
          item.title.startsWith('Daily Note • ') &&
          item.title != expectedTitle) {
        if (previousDaily == null ||
            item.createdAt.isAfter(previousDaily.createdAt)) {
          previousDaily = item;
        }
      }
    }

    final carriedForwardTasks = _carryForwardTasksEnabled && previousDaily != null
        ? _extractUnfinishedTasks(previousDaily.content)
        : <String>[];

    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('status: Active');
    buffer.writeln('date: $dateStr');
    buffer.writeln('---');
    buffer.writeln('# ☀️ $expectedTitle');
    buffer.writeln();
    if (carriedForwardTasks.isNotEmpty && previousDaily != null) {
      buffer.writeln('## Carried Forward (from [[${previousDaily.title}]])');
      for (final task in carriedForwardTasks) {
        buffer.writeln(task);
      }
      buffer.writeln();
    }
    buffer.writeln('## Top 3 Focus');
    buffer.writeln('- [ ] ');
    buffer.writeln('- [ ] ');
    buffer.writeln('- [ ] ');
    buffer.writeln();
    buffer.writeln('## Quick Log & Captures');
    buffer.writeln('- ');
    buffer.writeln();
    buffer.writeln('#daily');

    final content = buffer.toString();
    final links = WikiLinkService.extractAllLinks(content)
        .map((l) => l.target)
        .toSet()
        .toList();

    final created = TextNote(
      id: 'daily_$dateStr',
      title: expectedTitle,
      content: content,
      createdAt: now,
      updatedAt: now,
      paletteId: 'amber',
      folderName: _folders.contains('Personal') ? 'Personal' : null,
      iconEmoji: '☀️',
      tags: const ['daily'],
      links: links,
      estimatedMinutes: 1,
    );

    await saveItem(created);
    return created;
  }

  List<String> _extractUnfinishedTasks(String content) {
    final parsed = FrontmatterService.parse(content);
    final lines = parsed.bodyWithoutFrontmatter.split('\n');
    final results = <String>[];
    bool inCodeBlock = false;
    final taskRegex = RegExp(r'^\s*(?:[-*]\s+)?\[\s\]\s+(.+)$');

    for (final line in lines) {
      if (line.trimLeft().startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        continue;
      }
      if (inCodeBlock) continue;
      final match = taskRegex.firstMatch(line);
      if (match != null) {
        final taskText = match.group(1)!.trim();
        if (taskText.isNotEmpty) {
          results.add('- [ ] $taskText');
        }
      }
    }
    return results;
  }
}

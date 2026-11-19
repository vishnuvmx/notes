import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notes/core/theme/app_theme.dart';
import 'package:notes/features/notes/models/text_note.dart';
import 'package:notes/features/notes/widgets/markdown_text_editing_controller.dart';
import 'package:notes/shared/data/i_workspace_repo.dart';
import 'package:notes/shared/models/base_item.dart';
import 'package:notes/shared/providers/workspace_provider.dart';
import 'package:notes/shared/widgets/responsive_card_grid.dart';

class _InMemoryRepo extends IWorkspaceRepository {
  final List<BaseWorkspaceItem> _active;
  _InMemoryRepo(this._active);

  @override
  List<BaseWorkspaceItem> get cachedActiveItems => List.unmodifiable(_active);

  @override
  Future<List<BaseWorkspaceItem>> getAllActiveItems() async =>
      List.unmodifiable(_active);

  @override
  Future<List<BaseWorkspaceItem>> getItemsByType(ItemType? type) async =>
      type == null
      ? List.unmodifiable(_active)
      : _active.where((i) => i.type == type).toList();

  @override
  Future<List<BaseWorkspaceItem>> getFavoriteItems() async =>
      _active.where((i) => i.isFavorite).toList();

  @override
  Future<List<BaseWorkspaceItem>> getTrashItems() async => const [];

  @override
  Future<List<BaseWorkspaceItem>> getArchivedItems() async => const [];

  @override
  Future<List<BaseWorkspaceItem>> searchItems(
    String query, {
    ItemType? type,
  }) async => _active.where((i) => i.matchesQuery(query)).toList();

  @override
  Future<BaseWorkspaceItem?> getItemById(String id) async {
    for (final item in _active) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> saveItem(BaseWorkspaceItem item) async {
    final idx = _active.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      _active[idx] = item;
    } else {
      _active.add(item);
    }
  }

  @override
  Future<void> moveToTrash(String id) async {
    _active.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> restoreItem(String id) async {}

  @override
  Future<void> toggleArchive(String id) async {}

  @override
  Future<void> toggleFavorite(String id) async {}

  @override
  Future<void> deletePermanently(String id) async {
    _active.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> emptyTrash() async {}
}

void main() {
  group('120fps Performance Optimizations', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('WorkspaceProvider memoizes derived projections until state changes', () async {
      final now = DateTime(2026, 11, 19);
      final repo = _InMemoryRepo([
        TextNote(
          id: 'n1',
          title: 'First Note',
          content: '- [ ] Ship 120fps build',
          tags: const ['perf', 'flutter'],
          isFavorite: true,
          paletteId: 'cyan',
          createdAt: now,
          updatedAt: now,
        ),
        TextNote(
          id: 'n2',
          title: 'Second Note',
          content: 'Regular body text',
          tags: const ['notes'],
          paletteId: 'peach',
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      final provider = WorkspaceProvider(repo);
      await provider.loadItems();

      final rev0 = provider.revision;
      final activeA = provider.allActiveItems;
      final activeB = provider.allActiveItems;
      expect(identical(activeA, activeB), isTrue);

      final notesA = provider.libraryNotes;
      final notesB = provider.libraryNotes;
      expect(identical(notesA, notesB), isTrue);

      final itemsA = provider.items;
      final itemsB = provider.items;
      expect(identical(itemsA, itemsB), isTrue);

      final pinnedA = provider.pinnedItems;
      final pinnedB = provider.pinnedItems;
      expect(identical(pinnedA, pinnedB), isTrue);

      final tagsA = provider.availableTags;
      final tagsB = provider.availableTags;
      expect(identical(tagsA, tagsB), isTrue);

      final tasksA = provider.openTasks;
      final tasksB = provider.openTasks;
      expect(identical(tasksA, tasksB), isTrue);

      // Mutating filter increments revision and invalidates cached projections.
      provider.setSearchQuery('First');
      expect(provider.revision, greaterThan(rev0));
      final notesAfterSearch = provider.libraryNotes;
      expect(identical(notesA, notesAfterSearch), isFalse);
      expect(notesAfterSearch.length, 1);
    });

    testWidgets(
      'MarkdownTextEditingController caches TextSpan across unchanged rebuilds',
      (tester) async {
        final controller = MarkdownTextEditingController(
          text: '# Title\n\nSome **bold** and `code` with #tag.',
          paletteId: 'cyan',
        );
        addTearDown(controller.dispose);

        TextSpan? span1;
        TextSpan? span2;
        TextSpan? spanAfterEdit;
        TextSpan? spanAfterPalette;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) {
                const baseStyle = TextStyle(fontSize: 16);
                span1 = controller.buildTextSpan(
                  context: context,
                  style: baseStyle,
                  withComposing: false,
                );
                span2 = controller.buildTextSpan(
                  context: context,
                  style: baseStyle,
                  withComposing: false,
                );
                controller.text = '# Updated Title';
                spanAfterEdit = controller.buildTextSpan(
                  context: context,
                  style: baseStyle,
                  withComposing: false,
                );
                controller.paletteId = 'peach';
                spanAfterPalette = controller.buildTextSpan(
                  context: context,
                  style: baseStyle,
                  withComposing: false,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(identical(span1, span2), isTrue);
        expect(identical(span1, spanAfterEdit), isFalse);
        expect(identical(spanAfterEdit, spanAfterPalette), isFalse);
      },
    );

    testWidgets(
      'SliverResponsiveCardGrid lazily builds only visible viewport rows',
      (tester) async {
        final builtIndices = <int>{};

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: CustomScrollView(
                  slivers: [
                    SliverResponsiveCardGrid(
                      crossAxisCount: 2,
                      itemCount: 200,
                      itemBuilder: (context, index) {
                        builtIndices.add(index);
                        return SizedBox(
                          height: 160,
                          child: Text('Item $index'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // With 200 items of height 160 in a 600px viewport, only visible + cache
        // rows should be built (far fewer than 200).
        expect(builtIndices.isNotEmpty, isTrue);
        expect(builtIndices.length, lessThan(40));
      },
    );
  });
}

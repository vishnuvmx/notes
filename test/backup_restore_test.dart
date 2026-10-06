import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/data/repositories/workspace_repo_impl.dart';
import 'package:notes/domain/models/clipboard_item.dart';
import 'package:notes/domain/models/sticky_note.dart';
import 'package:notes/domain/models/text_note.dart';
import 'package:notes/domain/models/whiteboard_item.dart';
import 'package:notes/state/workspace_provider.dart';

void main() {
  group('Export and Restore Backup Tests', () {
    test('Exports and restores all 4 item types correctly', () async {
      final now = DateTime.now();
      final initialItems = [
        TextNote(
          id: 'note_1',
          title: 'Meeting Notes',
          content: 'Discussing architecture',
          createdAt: now,
          updatedAt: now,
          paletteId: 'peach',
          tags: ['work', 'arch'],
        ),
        StickyNote(
          id: 'sticky_1',
          title: 'Grocery List',
          content: 'Milk, eggs, coffee',
          createdAt: now,
          updatedAt: now,
          paletteId: 'amber',
          rotationAngle: 0.05,
          priority: 2,
        ),
        WhiteboardCanvasItem(
          id: 'board_1',
          title: 'System Diagram',
          createdAt: now,
          updatedAt: now,
          paletteId: 'cyan',
          nodes: [
            const CanvasNode(
              id: 'n1',
              text: 'Server',
              shapeType: CanvasNodeType.process,
              x: 100,
              y: 200,
            ),
          ],
          edges: [],
        ),
        ClipboardItem(
          id: 'clip_1',
          title: 'Git Command',
          clipText: 'git status -s',
          createdAt: now,
          updatedAt: now,
          paletteId: 'lime',
          sourceApp: 'Terminal',
          isPinned: true,
        ),
      ];

      final repo = LocalStorageWorkspaceRepository(initialItems: initialItems);
      final provider = WorkspaceProvider(repo);
      await provider.loadItems();

      expect(provider.rawItems.length, 4);

      // 1. Export to JSON
      final jsonStr = provider.exportWorkspaceJson();
      expect(jsonStr, isNotEmpty);

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['app'], 'Tack');
      expect(decoded['version'], 1);
      expect(decoded['items'], isA<List>());
      expect((decoded['items'] as List).length, 4);

      // 2. Create fresh repository and import
      final freshRepo = LocalStorageWorkspaceRepository(initialItems: []);
      final freshProvider = WorkspaceProvider(freshRepo);
      await freshProvider.loadItems();
      expect(freshProvider.rawItems.length, 0);

      final restoredCount = await freshProvider.importWorkspaceJson(jsonStr);
      expect(restoredCount, 4);
      expect(freshProvider.rawItems.length, 4);

      // Verify specific types and fields
      final restoredNote = freshProvider.rawItems.whereType<TextNote>().first;
      expect(restoredNote.title, 'Meeting Notes');
      expect(restoredNote.content, 'Discussing architecture');
      expect(restoredNote.tags, contains('work'));

      final restoredClip = freshProvider.rawItems.whereType<ClipboardItem>().first;
      expect(restoredClip.clipText, 'git status -s');
      expect(restoredClip.sourceApp, 'Terminal');
      expect(restoredClip.isPinned, isTrue);

      final restoredBoard = freshProvider.rawItems.whereType<WhiteboardCanvasItem>().first;
      expect(restoredBoard.nodes.length, 1);
      expect(restoredBoard.nodes.first.text, 'Server');

      final restoredSticky = freshProvider.rawItems.whereType<StickyNote>().first;
      expect(restoredSticky.content, 'Milk, eggs, coffee');
      expect(restoredSticky.priority, 2);
    });

    test('Throws on corrupted or invalid backup JSON structure', () async {
      final repo = LocalStorageWorkspaceRepository(initialItems: []);
      final provider = WorkspaceProvider(repo);

      expect(
        () async => await provider.importWorkspaceJson('{"corrupted": true}'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

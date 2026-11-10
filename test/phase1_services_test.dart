import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notes/domain/interfaces/i_workspace_repo.dart';
import 'package:notes/domain/models/base_item.dart';
import 'package:notes/domain/models/item_serializer.dart';
import 'package:notes/domain/models/text_note.dart';
import 'package:notes/domain/models/whiteboard_item.dart';
import 'package:notes/domain/services/block_transform_service.dart';
import 'package:notes/domain/services/frontmatter_service.dart';
import 'package:notes/domain/services/markdown_table_service.dart';
import 'package:notes/domain/services/note_export_service.dart';
import 'package:notes/domain/services/note_template_service.dart';
import 'package:notes/domain/services/open_tasks_service.dart';
import 'package:notes/domain/services/wiki_link_service.dart';
import 'package:notes/state/workspace_provider.dart';

class _InMemoryWorkspaceRepo extends IWorkspaceRepository {
  final List<BaseWorkspaceItem> _store = [];

  @override
  List<BaseWorkspaceItem> get cachedActiveItems =>
      _store.where((i) => !i.isTrash && !i.isArchived).toList();

  @override
  Future<List<BaseWorkspaceItem>> getAllActiveItems() async => cachedActiveItems;

  @override
  Future<List<BaseWorkspaceItem>> getItemsByType(ItemType? type) async {
    if (type == null) return cachedActiveItems;
    return cachedActiveItems.where((i) => i.type == type).toList();
  }

  @override
  Future<List<BaseWorkspaceItem>> getFavoriteItems() async =>
      cachedActiveItems.where((i) => i.isFavorite).toList();

  @override
  Future<List<BaseWorkspaceItem>> getArchivedItems() async =>
      _store.where((i) => i.isArchived && !i.isTrash).toList();

  @override
  Future<List<BaseWorkspaceItem>> getTrashItems() async =>
      _store.where((i) => i.isTrash).toList();

  @override
  Future<List<BaseWorkspaceItem>> searchItems(String query, {ItemType? type}) async =>
      cachedActiveItems
          .where((i) =>
              (type == null || i.type == type) && i.matchesQuery(query))
          .toList();

  @override
  Future<BaseWorkspaceItem?> getItemById(String id) async =>
      _store.where((i) => i.id == id).firstOrNull;

  @override
  Future<void> saveItem(BaseWorkspaceItem item) async {
    final idx = _store.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      _store[idx] = item;
    } else {
      _store.add(item);
    }
  }

  @override
  Future<void> moveToTrash(String id) async {}

  @override
  Future<void> restoreItem(String id) async {}

  @override
  Future<void> toggleArchive(String id) async {}

  @override
  Future<void> toggleFavorite(String id) async {}

  @override
  Future<void> deletePermanently(String id) async {
    _store.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> emptyTrash() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 1 — WikiLinkService, SpecCard & BlockTransformService', () {
    test('extractAllLinks parses standard, anchored, aliased, and embedded wiki-links', () {
      const content = '''
# Product Architecture
See [[Auth Flow]] and [[Auth Flow#Token Refresh|refresh spec]].
Embedded board:
![[Checkout Board#node_42]]
```dart
// Inside fenced code block: [[Ignored Link]]
```
''';
      final links = WikiLinkService.extractAllLinks(content);
      expect(links.length, 3);

      expect(links[0].target, 'Auth Flow');
      expect(links[0].anchor, isNull);
      expect(links[0].alias, isNull);
      expect(links[0].isEmbed, isFalse);

      expect(links[1].target, 'Auth Flow');
      expect(links[1].anchor, 'Token Refresh');
      expect(links[1].alias, 'refresh spec');
      expect(links[1].displayLabel, 'refresh spec');

      expect(links[2].target, 'Checkout Board');
      expect(links[2].anchor, 'node_42');
      expect(links[2].isEmbed, isTrue);
    });

    test('detectActiveWikiTrigger & detectActiveSlashTrigger handle live editor cursor', () {
      const text1 = 'Link to [[Design Sys';
      final trigger1 = WikiLinkService.detectActiveWikiTrigger(text1, text1.length);
      expect(trigger1, isNotNull);
      expect(trigger1!.targetQuery, 'Design Sys');
      expect(trigger1.anchorQuery, isNull);
      expect(trigger1.isEmbed, isFalse);

      const text2 = 'Embed ![[Design System#Typo';
      final trigger2 = WikiLinkService.detectActiveWikiTrigger(text2, text2.length);
      expect(trigger2, isNotNull);
      expect(trigger2!.targetQuery, 'Design System');
      expect(trigger2.anchorQuery, 'Typo');
      expect(trigger2.isEmbed, isTrue);

      const closed = 'Completed [[Design System]] ';
      expect(WikiLinkService.detectActiveWikiTrigger(closed, closed.length), isNull);

      const slashText = 'First paragraph\n/toggle';
      final slash = WikiLinkService.detectActiveSlashTrigger(slashText, slashText.length);
      expect(slash, isNotNull);
      expect(slash!.query, 'toggle');

      const midLineUrl = 'https://example.com/toggle';
      expect(WikiLinkService.detectActiveSlashTrigger(midLineUrl, midLineUrl.length), isNull);
    });

    test('computeBacklinks resolves wiki-links, YAML aliases, unlinked mentions, and Spec Cards', () {
      final now = DateTime(2026, 11, 2);
      final specNote = TextNote(
        id: 'note_spec',
        title: 'Offline Sync Spec',
        content: '''---
aliases: [Sync PRD, Offline Spec]
status: Approved
---
## Conflict Resolution
Use LWW timestamps.
## Queue
Retry on reconnect.''',
        createdAt: now,
        updatedAt: now,
        paletteId: 'cyan',
      );
      final meetingNote = TextNote(
        id: 'note_meeting',
        title: 'Sprint Planning',
        content: 'Reviewed [[Sync PRD#Conflict Resolution]] today.',
        createdAt: now,
        updatedAt: now,
        paletteId: 'amber',
      );
      final unlinkedNote = TextNote(
        id: 'note_unlinked',
        title: 'QA Checklist',
        content: 'Need to verify Offline Sync Spec before release.',
        createdAt: now,
        updatedAt: now,
        paletteId: 'lime',
      );
      final board = WhiteboardCanvasItem(
        id: 'wb_1',
        title: 'System Flow',
        createdAt: now,
        updatedAt: now,
        paletteId: 'lavender',
        nodes: const [
          CanvasNode(
            id: 'node_spec_1',
            text: 'Offline Sync Spec',
            shapeType: CanvasNodeType.specCard,
            x: 3000,
            y: 3000,
            linkedNoteId: 'note_spec',
          ),
        ],
      );

      final all = [specNote, meetingNote, unlinkedNote, board];
      expect(WikiLinkService.resolveTarget('Sync PRD', all)?.id, 'note_spec');

      final backlinks = WikiLinkService.computeBacklinks(
        currentItem: specNote,
        allItems: all,
      );
      expect(backlinks.linked.length, 2);
      expect(backlinks.linked.any((b) => b.sourceItem.id == 'note_meeting'), isTrue);
      expect(backlinks.linked.any((b) => b.sourceItem.id == 'wb_1'), isTrue);

      expect(backlinks.unlinked.length, 1);
      expect(backlinks.unlinked.first.sourceItem.id, 'note_unlinked');

      final section = WikiLinkService.extractSectionMarkdown(
        specNote.content,
        anchor: 'Conflict Resolution',
      );
      expect(section, contains('Use LWW timestamps.'));
      expect(section, isNot(contains('Retry on reconnect.')));
    });

    test('BlockTransformService turnInto, moveBlockUp/Down, and duplicateBlock', () {
      const initial = '- [ ] Ship Phase 1';
      final asH2 = BlockTransformService.turnInto(
        const TextEditingValue(
          text: initial,
          selection: TextSelection.collapsed(offset: 6),
        ),
        BlockKind.h2,
      );
      expect(asH2.text, '## Ship Phase 1');

      final asCallout = BlockTransformService.turnInto(asH2, BlockKind.calloutNote);
      expect(asCallout.text, '> [!NOTE]\n> Ship Phase 1');

      const doc = 'Line A\nLine B\nLine C';
      const val = TextEditingValue(
        text: doc,
        selection: TextSelection.collapsed(offset: 9),
      );
      final movedUp = BlockTransformService.moveBlockUp(val);
      expect(movedUp.text, 'Line B\nLine A\nLine C');

      final movedBackDown = BlockTransformService.moveBlockDown(movedUp);
      expect(movedBackDown.text, 'Line A\nLine B\nLine C');

      final duplicated = BlockTransformService.duplicateBlock(movedBackDown);
      expect(duplicated.text, 'Line A\nLine B\nLine B\nLine C');
    });

    test('CanvasNode SpecCard serializes and deserializes linkedNoteId', () {
      const node = CanvasNode(
        id: 'n_1',
        text: 'Checkout Spec',
        shapeType: CanvasNodeType.specCard,
        x: 2800,
        y: 2900,
        width: 220,
        height: 148,
        paletteId: 'cyan',
        linkedNoteId: 'note_123',
      );
      final restored = CanvasNode.fromJson(node.toJson());
      expect(restored.shapeType, CanvasNodeType.specCard);
      expect(restored.linkedNoteId, 'note_123');
    });
  });

  group('Phase 2 — FrontmatterService & MarkdownTableService', () {
    test('FrontmatterService parses, updates, and preserves exact body line offsets', () {
      const raw = '''---
status: Draft
priority: High
aliases: [Spec V1, Checkout]
---
# Heading One
Body line.''';

      final parsed = FrontmatterService.parse(raw);
      expect(parsed.hasProperties, isTrue);
      expect(parsed.status, 'Draft');
      expect(parsed.priority, 'High');
      expect(parsed.aliases, ['Spec V1', 'Checkout']);
      expect(parsed.contentStartLineIndex, 5);
      expect(parsed.bodyWithoutFrontmatter, '# Heading One\nBody line.');

      final updated = FrontmatterService.upsertProperty(raw, 'status', 'Approved');
      final reparsed = FrontmatterService.parse(updated);
      expect(reparsed.status, 'Approved');
      expect(reparsed.bodyWithoutFrontmatter, '# Heading One\nBody line.');
    });

    test('MarkdownTableService parses GFM alignments, escapes pipes, and replaces in-place', () {
      const doc = '''Intro line
| Feature | Owner | Score |
| :--- | :---: | ---: |
| Toggles | UX | 95 |
Outro line''';

      final docLines = doc.split('\n');
      final table = MarkdownTableService.parseTableLines(docLines.sublist(1, 4));
      expect(table, isNotNull);
      expect(table!.headers, ['Feature', 'Owner', 'Score']);
      expect(table.alignments, [
        TableColumnAlign.left,
        TableColumnAlign.center,
        TableColumnAlign.right,
      ]);
      expect(table.rows.first, ['Toggles', 'UX', '95']);

      final modified = EditableMarkdownTable(
        headers: table.headers,
        alignments: table.alignments,
        rows: [
          ['Toggles | Folding', 'Core UX', '100'],
        ],
      );
      final replaced = MarkdownTableService.replaceTableInDocument(
        rawDocument: doc,
        startLine: 1,
        endLineExclusive: 4,
        updatedTable: modified,
      );
      expect(replaced, contains(r'Toggles \| Folding'));
      expect(replaced, startsWith('Intro line\n'));
      expect(replaced, endsWith('\nOutro line'));
    });
  });

  group('Phase 3 — Templates, Daily Carry-Forward, Folders & Sub-Note Hierarchy', () {
    test('NoteTemplateService expands tokens and persists custom templates offline', () async {
      final dt = DateTime(2026, 11, 2, 9, 5);
      final expanded = NoteTemplateService.expandTokens(
        'Spec ({{date}} @ {{time}}): {{title}}',
        customTitle: 'Graph View',
        now: dt,
      );
      expect(expanded, 'Spec (2026-11-02 @ 09:05): Graph View');

      await NoteTemplateService.saveCustomTemplate(
        name: 'Retro Template',
        bodyTemplate: '## Went Well\n- ',
        paletteId: 'lime',
        iconEmoji: '🚀',
      );
      final all = await NoteTemplateService.loadAllTemplates();
      expect(all.any((t) => t.name == 'Retro Template' && t.isCustom), isTrue);
    });

    test('WorkspaceProvider handles folders, sub-note breadcrumbs, and Daily Note task carry-forward', () async {
      final repo = _InMemoryWorkspaceRepo();
      final provider = WorkspaceProvider(repo);

      // 1. Folder filtering & item persistence
      await provider.addFolder('Architecture');
      expect(provider.userFolders, contains('Architecture'));

      final root = await provider.createQuickItem(
        title: 'Platform Blueprint',
        type: ItemType.note,
        paletteId: 'cyan',
        folderName: 'Architecture',
        iconEmoji: '📐',
      );
      final child = await provider.createQuickItem(
        title: 'Storage Engine',
        type: ItemType.note,
        paletteId: 'cyan',
        parentId: root.id,
        iconEmoji: '💾',
      );
      final grandChild = await provider.createQuickItem(
        title: 'Markdown Serializer',
        type: ItemType.note,
        paletteId: 'cyan',
        parentId: child.id,
      );

      // Verify JSON round-trip preserves folderName, parentId, and iconEmoji
      final roundTrip = ItemSerializer.fromJson(child.toJson())!;
      expect(roundTrip.folderName, 'Architecture');
      expect(roundTrip.parentId, root.id);
      expect(roundTrip.iconEmoji, '💾');

      // Breadcrumb chain: [root, child]
      final chain = provider.getBreadcrumbChain(grandChild);
      expect(chain.map((e) => e.id).toList(), [root.id, child.id]);
      expect(provider.getChildItems(root.id).map((e) => e.id), contains(child.id));

      // Folder filter
      provider.setSelectedFolder('Architecture');
      expect(provider.items.length, 3);
      provider.setSelectedFolder('Work');
      expect(provider.items, isEmpty);
      provider.setSelectedFolder('All Notes');

      // 2. Daily Note + automatic carry-forward of unfinished tasks
      final yesterday = DateTime(2026, 11, 1, 10, 0);
      await provider.saveItem(
        TextNote(
          id: 'daily_2026-11-01',
          title: 'Daily Note • 2026-11-01',
          content: '- [x] Completed yesterday\n- [ ] Carry me forward\n[ ] Also carry bare checkbox',
          createdAt: yesterday,
          updatedAt: yesterday,
          paletteId: 'amber',
          tags: const ['daily'],
        ),
      );

      final today = DateTime(2026, 11, 2, 8, 30);
      final todaysNote = await provider.openOrCreateTodaysNote(referenceDate: today);
      expect(todaysNote.title, 'Daily Note • 2026-11-02');
      expect(todaysNote.iconEmoji, '☀️');
      expect(todaysNote.content, contains('## Carried Forward (from [[Daily Note • 2026-11-01]])'));
      expect(todaysNote.content, contains('- [ ] Carry me forward'));
      expect(todaysNote.content, contains('- [ ] Also carry bare checkbox'));
      expect(todaysNote.content, isNot(contains('Completed yesterday')));

      // Calling a second time on the same day is idempotent
      final sameDayAgain = await provider.openOrCreateTodaysNote(referenceDate: today);
      expect(sameDayAgain.id, todaysNote.id);
    });
  });

  group('Paper & Pin Redesign — Inbox Triage, Open Tasks, Link Rename Propagation & Export', () {
    test('Inbox capture & triage actions (keep, append, convert to task)', () async {
      final repo = _InMemoryWorkspaceRepo();
      final provider = WorkspaceProvider(repo);

      // 1. Capture to Inbox -> keep as note
      final cap1 = await provider.captureToInbox(
        'Quick architectural thought\nMore details here',
        sourceApp: 'Share Sheet',
      );
      expect(cap1.isInbox, isTrue);
      expect(provider.inboxItems.map((e) => e.id), contains(cap1.id));
      expect(provider.libraryNotes.map((e) => e.id), isNot(contains(cap1.id)));

      await provider.keepInboxItemAsNote(cap1.id, folderName: 'Architecture');
      expect(provider.inboxItems.map((e) => e.id), isNot(contains(cap1.id)));
      expect(provider.libraryNotes.map((e) => e.id), contains(cap1.id));

      // 2. Capture to Inbox -> append to existing note
      final cap2 = await provider.captureToInbox('Appended paragraph from inbox');
      await provider.appendInboxItemToNote(cap2.id, cap1.id);
      expect(provider.inboxItems, isEmpty);
      final updatedNote = provider.getItemByIdSync(cap1.id) as TextNote;
      expect(updatedNote.content, contains('Appended paragraph from inbox'));

      // 3. Capture to Inbox -> convert to Today task
      final cap3 = await provider.captureToInbox('Review PR #42');
      await provider.convertInboxItemToTodayTask(cap3.id);
      expect(provider.inboxItems, isEmpty);
      expect(
        provider.openTasks.any((t) => t.text.contains('Review PR #42')),
        isTrue,
      );
    });

    test('OpenTasksService extracts open tasks and toggleTask updates note in-place', () async {
      final repo = _InMemoryWorkspaceRepo();
      final provider = WorkspaceProvider(repo);

      final note = await provider.createQuickItem(
        title: 'Release Checklist',
        content: '- [ ] Run flutter analyze\n- [x] Update tokens\n```\n- [ ] Ignored in code fence\n```',
        type: ItemType.note,
        paletteId: 'amber',
      );

      final open = provider.openTasks.where((t) => t.noteId == note.id).toList();
      expect(open.length, 1);
      expect(open.first.text, 'Run flutter analyze');

      await provider.toggleTask(open.first);
      final openAfter = provider.openTasks.where((t) => t.noteId == note.id).toList();
      expect(openAfter, isEmpty);

      final allTasks = OpenTasksService.extractTasks(
        provider.allActiveItems,
        includeCompleted: true,
      ).where((t) => t.noteId == note.id).toList();
      expect(allTasks.length, 2);
      expect(allTasks.every((t) => t.isDone), isTrue);
    });

    test('Renaming a note automatically rewrites inbound [[WikiLinks]] across notes', () async {
      final repo = _InMemoryWorkspaceRepo();
      final provider = WorkspaceProvider(repo);

      final target = await provider.createQuickItem(
        title: 'Auth Spec',
        content: '## Token Flow\nDetails.',
        type: ItemType.note,
        paletteId: 'cyan',
      ) as TextNote;

      final caller = await provider.createQuickItem(
        title: 'API Overview',
        content: 'Refer to [[Auth Spec]] and [[Auth Spec#Token Flow|token docs]].',
        type: ItemType.note,
        paletteId: 'amber',
      ) as TextNote;

      await provider.saveItem(target.copyWith(title: 'Identity Spec'));

      final updatedCaller = provider.getItemByIdSync(caller.id) as TextNote;
      expect(updatedCaller.content, contains('[[Identity Spec]]'));
      expect(updatedCaller.content, contains('[[Identity Spec#Token Flow|token docs]]'));
      expect(updatedCaller.content, isNot(contains('[[Auth Spec')));
    });

    test('exportWorkspaceJson exports all items regardless of active UI filters and formatMarkdown preserves YAML at line 0', () async {
      final repo = _InMemoryWorkspaceRepo();
      final provider = WorkspaceProvider(repo);

      await provider.addFolder('Work');
      await provider.createQuickItem(
        title: 'Work Note',
        content: 'Body A',
        type: ItemType.note,
        paletteId: 'amber',
        folderName: 'Work',
      );
      final personal = await provider.createQuickItem(
        title: 'Personal Note',
        content: '---\nstatus: Active\n---\nBody B',
        type: ItemType.note,
        paletteId: 'peach',
      ) as TextNote;

      // Activate a restrictive UI filter
      provider.setSelectedFolder('Work');
      provider.setSearchQuery('NonExistentQueryXYZ');
      expect(provider.libraryNotes, isEmpty);

      // Backup export must still contain both notes
      final backupJson = provider.exportWorkspaceJson();
      expect(backupJson, contains('Work Note'));
      expect(backupJson, contains('Personal Note'));

      // Markdown export must keep YAML frontmatter at line 0
      final exportedMd = NoteExportService.formatMarkdown(
        title: personal.title,
        content: personal.content,
        tags: personal.tags,
      );
      expect(exportedMd.startsWith('---\nstatus: Active\n---'), isTrue);
    });
  });
}

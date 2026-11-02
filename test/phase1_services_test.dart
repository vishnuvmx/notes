import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/domain/models/text_note.dart';
import 'package:notes/domain/models/whiteboard_item.dart';
import 'package:notes/domain/services/block_transform_service.dart';
import 'package:notes/domain/services/wiki_link_service.dart';

void main() {
  group('WikiLinkService', () {
    test('extractLinks parses standard, anchored, aliased, and embedded wiki-links', () {
      const content = '''
# Product Architecture
See [[Auth Flow]] and [[Auth Flow#Token Refresh|refresh spec]].
Embedded board:
![[Checkout Board#node_42]]
```dart
// Inside fenced code block: [[Ignored Link]]
```
''';
      final links = WikiLinkService.extractLinks(content);
      expect(links.length, 3);

      expect(links[0].targetTitle, 'Auth Flow');
      expect(links[0].anchor, isNull);
      expect(links[0].alias, isNull);
      expect(links[0].isEmbed, isFalse);

      expect(links[1].targetTitle, 'Auth Flow');
      expect(links[1].anchor, 'Token Refresh');
      expect(links[1].alias, 'refresh spec');
      expect(links[1].displayLabel, 'refresh spec');

      expect(links[2].targetTitle, 'Checkout Board');
      expect(links[2].anchor, 'node_42');
      expect(links[2].isEmbed, isTrue);
    });

    test('detectActiveWikiTrigger detects unclosed [[ and #anchor triggers', () {
      const text1 = 'Link to [[Design Sys';
      final trigger1 = WikiLinkService.detectActiveWikiTrigger(text1, text1.length);
      expect(trigger1, isNotNull);
      expect(trigger1!.targetQuery, 'Design Sys');
      expect(trigger1.isSearchingAnchor, isFalse);
      expect(trigger1.isEmbed, isFalse);

      const text2 = 'Embed ![[Design System#Typo';
      final trigger2 = WikiLinkService.detectActiveWikiTrigger(text2, text2.length);
      expect(trigger2, isNotNull);
      expect(trigger2!.targetQuery, 'Design System');
      expect(trigger2.anchorQuery, 'Typo');
      expect(trigger2.isSearchingAnchor, isTrue);
      expect(trigger2.isEmbed, isTrue);

      const closed = 'Completed [[Design System]] ';
      expect(WikiLinkService.detectActiveWikiTrigger(closed, closed.length), isNull);
    });

    test('detectActiveSlashTrigger triggers at start of line and ignores URLs or code fences', () {
      const text = 'First paragraph\n/call';
      final slash = WikiLinkService.detectActiveSlashTrigger(text, text.length);
      expect(slash, isNotNull);
      expect(slash!.query, 'call');

      const midLine = 'https://example.com/call';
      expect(WikiLinkService.detectActiveSlashTrigger(midLine, midLine.length), isNull);
    });

    test('findBacklinks and findUnlinkedMentions resolve note links and whiteboard spec pins', () {
      final now = DateTime(2026, 11, 2);
      final specNote = TextNote(
        id: 'note_spec',
        title: 'Offline Sync Spec',
        content: '## Conflict Resolution\nUse LWW timestamps.\n## Queue\nRetry on reconnect.',
        createdAt: now,
        updatedAt: now,
        paletteId: 'cyan',
      );
      final meetingNote = TextNote(
        id: 'note_meeting',
        title: 'Sprint Planning',
        content: 'Reviewed [[Offline Sync Spec#Conflict Resolution]] today.',
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
      final backlinks = WikiLinkService.findBacklinks(specNote, all);
      expect(backlinks.length, 2);
      expect(backlinks.any((b) => b.sourceItem.id == 'note_meeting'), isTrue);
      expect(backlinks.any((b) => b.sourceItem.id == 'wb_1'), isTrue);

      final unlinked = WikiLinkService.findUnlinkedMentions(specNote, all);
      expect(unlinked.length, 1);
      expect(unlinked.first.sourceItem.id, 'note_unlinked');

      final section = WikiLinkService.extractSectionPreview(
        specNote.content,
        anchor: 'Conflict Resolution',
      );
      expect(section, contains('Use LWW timestamps.'));
      expect(section, isNot(contains('Retry on reconnect.')));
    });
  });

  group('BlockTransformService', () {
    test('turnInto converts block prefix cleanly while preserving body text', () {
      const initial = '- [ ] Ship Phase 1';
      final asH2 = BlockTransformService.turnInto(
        TextEditingValue(
          text: initial,
          selection: const TextSelection.collapsed(offset: 6),
        ),
        BlockKind.h2,
      );
      expect(asH2.text, '## Ship Phase 1');

      final asCallout = BlockTransformService.turnInto(asH2, BlockKind.callout);
      expect(asCallout.text, '> [!NOTE] Ship Phase 1');

      final asParagraph = BlockTransformService.turnInto(asCallout, BlockKind.paragraph);
      expect(asParagraph.text, 'Ship Phase 1');
    });

    test('moveBlockUp, moveBlockDown, and duplicateBlock manipulate lines accurately', () {
      const doc = 'Line A\nLine B\nLine C';
      // Cursor inside "Line B" (offset 9)
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
  });

  group('CanvasNode SpecCard serialization', () {
    test('serializes and deserializes specCard shapeType and linkedNoteId', () {
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
      expect(restored.width, 220);
      expect(restored.height, 148);
    });
  });
}


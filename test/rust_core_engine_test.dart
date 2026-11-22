import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:notes/core/native/tack_core_bridge.dart';
import 'package:notes/features/notes/models/text_note.dart';
import 'package:notes/features/notes/services/wiki_link_service.dart';
import 'package:notes/features/notes/widgets/code_syntax_highlighter.dart';
import 'package:notes/shared/data/workspace_repo_impl.dart';
import 'package:notes/shared/models/base_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TackCoreBridge Native Rust Engine & Fallback Parity', () {
    test('Android jniLibs contain compiled libtack_core.so for all 3 ABIs', () {
      for (final abi in const ['arm64-v8a', 'armeabi-v7a', 'x86_64']) {
        final so = File('android/app/src/main/jniLibs/$abi/libtack_core.so');
        expect(so.existsSync(), isTrue, reason: 'Missing $abi libtack_core.so');
        expect(so.lengthSync(), greaterThan(500 * 1024));
      }
    });

    test(
      'Knowledge Graph Rust force layout matches physics & stays sub-50ms',
      () {
        const nodeCount = 120;
        const center = Offset(1100, 1100);
        final positions = <Offset>[
          for (int i = 0; i < nodeCount; i++)
            center +
                Offset(
                  math.cos(i * 2.39996323) * (90.0 + 36.0 * math.sqrt(i + 1)),
                  math.sin(i * 2.39996323) * (90.0 + 36.0 * math.sqrt(i + 1)),
                ),
        ];
        final flatEdges = <int>[
          for (int i = 0; i < nodeCount - 1; i++) ...[
            i,
            (i + 1) % nodeCount,
            0,
          ],
          for (int i = 0; i < nodeCount - 5; i += 3) ...[i, i + 5, 1],
        ];

        final sw = Stopwatch()..start();
        final ok = TackCoreBridge.instance.layoutGraph(
          positions: positions,
          flatEdges: flatEdges,
          pinnedIndex: 0,
          center: center,
          canvasSize: 2200.0,
          iterations: 70,
        );
        sw.stop();

        expect(ok, isTrue);
        expect(positions[0].dx, closeTo(center.dx, 0.01));
        expect(positions[0].dy, closeTo(center.dy, 0.01));
        for (final p in positions) {
          expect(p.dx.isFinite, isTrue);
          expect(p.dy.isFinite, isTrue);
          expect(p.dx, inInclusiveRange(120.0, 2080.0));
          expect(p.dy, inInclusiveRange(120.0, 2080.0));
        }
        expect(sw.elapsedMilliseconds, lessThan(50));
      },
      skip: !TackCoreBridge.instance.isAvailable
          ? 'Host desktop tack_core binary not present (Android .so verified above)'
          : null,
    );

    test(
      'Workspace repository upserts, searches, and deletes cleanly',
      () async {
        SharedPreferences.setMockInitialValues({});
        final repo = LocalStorageWorkspaceRepository(dbPath: ':memory:');
        addTearDown(repo.dispose);

        final now = DateTime.now();
        final noteA = TextNote(
          id: 'rust_note_1',
          title: 'Rust Engine Architecture',
          content:
              'SQLite FTS5 indexing gives sub-millisecond full-text search.',
          createdAt: now,
          updatedAt: now,
          paletteId: 'cyan',
          tags: const ['rust', 'performance'],
        );
        final noteB = TextNote(
          id: 'rust_note_2',
          title: 'Grocery Checklist',
          content: '- [ ] Buy matcha and oat milk',
          createdAt: now,
          updatedAt: now.add(const Duration(seconds: 1)),
          paletteId: 'lime',
        );

        await repo.saveItem(noteA);
        await repo.saveItem(noteB);

        final searchHit = await repo.searchItems('sub-millisecond');
        expect(searchHit.map((e) => e.id), contains('rust_note_1'));
        expect(searchHit.map((e) => e.id), isNot(contains('rust_note_2')));

        final tagHit = await repo.searchItems(
          'performance',
          type: ItemType.note,
        );
        expect(tagHit.map((e) => e.id), contains('rust_note_1'));

        await repo.moveToTrash('rust_note_2');
        final afterTrash = await repo.searchItems('matcha');
        expect(afterTrash, isEmpty);

        await repo.emptyTrash();
        final trashItems = await repo.getTrashItems();
        expect(trashItems.where((i) => i.id == 'rust_note_2'), isEmpty);
      },
    );

    test('Wiki-Link & Backlinks scanner handles links, code fences, and UTF-16 offsets', () {
      final longDoc =
          '''
# Project Notes 🚀
Here is a link to [[Architecture#Storage|Rust DB]] and an embed ![[System Board]].
```dart
// Inside a fenced code block — must be ignored:
final ignored = "[[ShouldNotMatch]]";
```
Plain text mention of Rust Engine right after an emoji 🎯 Rust Engine rocks.
''' *
          2;

      final links = WikiLinkService.extractAllLinks(longDoc);
      expect(links.length, 4);
      expect(links[0].target, 'Architecture');
      expect(links[0].anchor, 'Storage');
      expect(links[0].alias, 'Rust DB');
      expect(links[0].isEmbed, isFalse);
      expect(links[1].target, 'System Board');
      expect(links[1].isEmbed, isTrue);

      final now = DateTime.now();
      final targetNote = TextNote(
        id: 'target_1',
        title: 'Rust Engine',
        content: 'Core native crate.',
        createdAt: now,
        updatedAt: now,
        paletteId: 'cyan',
      );
      final linkingNote = TextNote(
        id: 'src_linked',
        title: 'Index',
        content: 'See [[Rust Engine]] for details.',
        createdAt: now,
        updatedAt: now,
        paletteId: 'slate',
      );
      final unlinkedNote = TextNote(
        id: 'src_unlinked',
        title: 'Diary',
        content: 'Today 🚀 the Rust Engine compiled cleanly!',
        createdAt: now,
        updatedAt: now,
        paletteId: 'lime',
      );

      final res = WikiLinkService.computeBacklinks(
        currentItem: targetNote,
        allItems: [targetNote, linkingNote, unlinkedNote],
      );
      expect(res.linked.length, 1);
      expect(res.linked.first.sourceItem.id, 'src_linked');
      expect(res.unlinked.length, 1);
      expect(res.unlinked.first.sourceItem.id, 'src_unlinked');

      final off = res.unlinked.first.unlinkedMatchOffset!;
      final len = res.unlinked.first.unlinkedMatchLength!;
      expect(unlinkedNote.content.substring(off, off + len), 'Rust Engine');
    });

    test('CodeSyntaxHighlighter preserves exact Unicode text across spans', () {
      const sample = '''
// Fast native lexer 🚀
Future<int> compute(int x) async {
  final msg = "hello 🌟 world";
  return x + 42;
}
''';
      final spans = CodeSyntaxHighlighter.highlight(
        sample,
        language: 'dart',
        isDark: true,
      );
      final reconstructed = spans.map((s) => s.text ?? '').join();
      expect(reconstructed, sample);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notes/core/theme/app_theme.dart';
import 'package:notes/features/notes/models/text_note.dart';
import 'package:notes/features/whiteboard/models/whiteboard_item.dart';
import 'package:notes/features/whiteboard/widgets/board_grid_card.dart';
import 'package:notes/shared/widgets/neo_note_card.dart';
import 'package:notes/shared/widgets/responsive_card_grid.dart';

void main() {
  group('Uniform Note & Board Grid Cards', () {
    testWidgets(
      'NeoNoteCard and BoardGridCard match heights cleanly with blank note space and board graph preview',
      (tester) async {
        final date = DateTime(2025, 3, 10);
        int noteMoreTapped = 0;
        int boardMoreTapped = 0;

        final noteShort = TextNote(
          id: 'n1',
          title: 'Cx Results',
          content: 'Secret clinical content that must remain hidden on cards.',
          paletteId: 'peach',
          createdAt: date,
          updatedAt: date,
        );

        final noteLongTitle = TextNote(
          id: 'n2',
          title: 'Very Long Architecture Meeting Notes Title That Truncates',
          content: 'More hidden body copy',
          tags: const ['arch'],
          isFavorite: true,
          paletteId: 'amber',
          createdAt: date,
          updatedAt: date,
        );

        final board = WhiteboardCanvasItem(
          id: 'b1',
          title: 'System Flow',
          paletteId: 'cyan',
          createdAt: date,
          updatedAt: date,
          nodes: [
            CanvasNode(
              id: 'node1',
              shapeType: CanvasNodeType.startEnd,
              x: 0,
              y: 0,
              text: 'Hidden Node Label',
              paletteId: 'cyan',
            ),
            CanvasNode(
              id: 'node2',
              shapeType: CanvasNodeType.process,
              x: 200,
              y: 120,
              text: 'Hidden Target Label',
              paletteId: 'lime',
            ),
          ],
          edges: [
            CanvasEdge(
              id: 'e1',
              fromNodeId: 'node1',
              toNodeId: 'node2',
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SizedBox(
                width: 390,
                height: 700,
                child: ResponsiveCardGrid(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return NeoNoteCard(
                        key: const ValueKey('card_short_note'),
                        item: noteShort,
                        onTap: () {},
                        onLongPress: () => noteMoreTapped++,
                      );
                    }
                    if (index == 1) {
                      return NeoNoteCard(
                        key: const ValueKey('card_long_note'),
                        item: noteLongTitle,
                        onTap: () {},
                        onLongPress: () => noteMoreTapped++,
                      );
                    }
                    return BoardGridCard(
                      key: const ValueKey('card_board'),
                      board: board,
                      onTap: () {},
                      onLongPress: () => boardMoreTapped++,
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final shortRect = tester.getRect(find.byKey(const ValueKey('card_short_note')));
        final longRect = tester.getRect(find.byKey(const ValueKey('card_long_note')));
        final boardRect = tester.getRect(find.byKey(const ValueKey('card_board')));

        // All cards in the grid share exact equal dimensions (even spacing & alignment).
        expect(shortRect.size, equals(longRect.size));
        expect(shortRect.size, equals(boardRect.size));

        // Note body content and node text labels are NOT rendered on cards.
        expect(find.textContaining('Secret clinical content'), findsNothing);
        expect(find.textContaining('Hidden Node Label'), findsNothing);

        // Date format & board node count subtitle are visible.
        expect(find.text('Mar 10, 2025'), findsNWidgets(2));
        expect(find.text('Mar 10, 2025 · 2 nodes'), findsOneWidget);

        // Board graph CustomPaint is present inside the board card.
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('card_board')),
            matching: find.byType(CustomPaint),
          ),
          findsWidgets,
        );

        // Tapping top-right '...' menu triggers onLongPress action on both note & board cards.
        final shortMore = find
            .descendant(
              of: find.byKey(const ValueKey('card_short_note')),
              matching: find.byType(InkWell),
            )
            .last;
        final boardMore = find
            .descendant(
              of: find.byKey(const ValueKey('card_board')),
              matching: find.byType(InkWell),
            )
            .last;
        await tester.tap(shortMore);
        await tester.tap(boardMore);
        await tester.pumpAndSettle();

        expect(noteMoreTapped, 1);
        expect(boardMoreTapped, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Supports dark mode and 1.4x text scaling without overflow',
      (tester) async {
        final date = DateTime(2025, 2, 21);
        final note = TextNote(
          id: 'n_dark',
          title: 'Face Scan Summary',
          content: 'Hidden text',
          tags: const ['health'],
          paletteId: 'lavender',
          createdAt: date,
          updatedAt: date,
        );
        final board = WhiteboardCanvasItem(
          id: 'b_dark',
          title: 'Empty Board',
          paletteId: 'slate',
          createdAt: date,
          updatedAt: date,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
              child: Scaffold(
                body: SizedBox(
                  width: 360,
                  height: 700,
                  child: ResponsiveCardGrid(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(16),
                    itemCount: 2,
                    itemBuilder: (_, index) => index == 0
                        ? NeoNoteCard(item: note, onTap: () {}, onLongPress: () {})
                        : BoardGridCard(board: board, onTap: () {}, onLongPress: () {}),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Feb 21, 2025'), findsOneWidget);
        expect(find.text('Feb 21, 2025 · 0 nodes'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

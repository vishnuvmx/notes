import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/domain/models/text_note.dart';
import 'package:notes/domain/models/sticky_note.dart';
import 'package:notes/ui/components/inputs/rich_note_content_view.dart';
import 'package:notes/ui/screens/editor/note_editor_screen.dart';

void main() {
  group('RichNoteContentView rendering tests', () {
    testWidgets('renders bold, italic, and underline correctly without raw syntax leaking', (tester) async {
      const markdownContent =
          '# Heading with **bold**\n\n'
          '[ ] Checklist with **bold**, *italics*, and __underline__\n\n'
          '> Blockquote with *italic* and __underline__\n\n'
          'Regular paragraph with **bold**, __underline__, *italic*, and <u>legacy</u>.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RichNoteContentView(
                content: markdownContent,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that raw markdown tokens are NOT rendered as standalone text
      expect(find.textContaining('**bold**'), findsNothing);
      expect(find.textContaining('__underline__'), findsNothing);
      expect(find.textContaining('<u>legacy</u>'), findsNothing);

      // Verify that styled text words exist inside RichText spans
      bool hasWordInRichText(String word) {
        return tester.widgetList<RichText>(find.byType(RichText)).any(
              (r) => r.text.toPlainText().contains(word),
            );
      }

      expect(hasWordInRichText('bold'), isTrue);
      expect(hasWordInRichText('underline'), isTrue);
      expect(hasWordInRichText('italics'), isTrue);
      expect(hasWordInRichText('legacy'), isTrue);
    });
  });

  group('MarkdownTextEditingController tests', () {
    testWidgets('buildTextSpan produces spans matching text length with styles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = MarkdownTextEditingController(
                  text: 'Text with **bold** and __underline__ and *italic*',
                );
                final span = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(fontSize: 16),
                  withComposing: false,
                );

                // Total length of span tree text must equal original text length
                int calculateLength(InlineSpan s) {
                  int len = 0;
                  s.visitChildren((child) {
                    if (child is TextSpan && child.text != null) {
                      len += child.text!.length;
                    }
                    return true;
                  });
                  return len;
                }

                expect(calculateLength(span), equals(controller.text.length));
                return Container();
              },
            ),
          ),
        ),
      );
    });
  });

  group('Note summary cleaning tests', () {
    test('TextNote getSummary strips markdown tokens', () {
      final note = TextNote(
        id: '1',
        title: 'Test Note',
        content: '# Title\n[ ] Apply **bold**, *italics*, and __underline__\n> Quote',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paletteId: 'peach',
      );

      final summary = note.getSummary();
      expect(summary.contains('**'), isFalse);
      expect(summary.contains('__'), isFalse);
      expect(summary.contains('*'), isFalse);
      expect(summary.contains('#'), isFalse);
      expect(summary.contains('[ ]'), isFalse);
      expect(summary, contains('Title'));
      expect(summary, contains('bold'));
      expect(summary, contains('underline'));
    });

    test('StickyNote getSummary strips markdown tokens', () {
      final sticky = StickyNote(
        id: '2',
        title: 'Sticky Test',
        content: 'Check **urgent** and __important__ task!',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paletteId: 'amber',
      );

      final summary = sticky.getSummary();
      expect(summary.contains('**'), isFalse);
      expect(summary.contains('__'), isFalse);
      expect(summary, equals('Check urgent and important task!'));
    });
  });
}

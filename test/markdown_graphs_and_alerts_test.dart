import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/ui/components/inputs/mermaid/mermaid_diagram_parser.dart';
import 'package:notes/ui/components/inputs/mermaid/mermaid_diagram_card.dart';
import 'package:notes/ui/components/inputs/rich_note_content_view.dart';

void main() {
  group('MermaidDiagramParser Tests', () {
    test('Parses Top-Down Flowchart correctly', () {
      const code = '''
graph TD
    A[Start] --> B(Process)
    B --> C{Decision}
    C -->|Yes| D([Success])
    C -->|No| E((Retry))
''';

      final result = MermaidDiagramParser.parse(code);
      expect(result.isValid, isTrue);
      expect(result.type, equals(MermaidDiagramType.flowchart));
      expect(result.direction, equals('TD'));
      expect(result.nodes.length, equals(5));

      final nodeA = result.nodes.firstWhere((n) => n.id == 'A');
      expect(nodeA.label, equals('Start'));
      expect(nodeA.shape, equals(MermaidNodeShape.process));

      final nodeC = result.nodes.firstWhere((n) => n.id == 'C');
      expect(nodeC.label, equals('Decision'));
      expect(nodeC.shape, equals(MermaidNodeShape.decision));

      final nodeD = result.nodes.firstWhere((n) => n.id == 'D');
      expect(nodeD.label, equals('Success'));
      expect(nodeD.shape, equals(MermaidNodeShape.pill));

      expect(result.edges.length, equals(4));
      final yesEdge = result.edges.firstWhere((e) => e.label == 'Yes');
      expect(yesEdge.fromId, equals('C'));
      expect(yesEdge.toId, equals('D'));
    });

    test('Parses Pie Chart correctly', () {
      const code = '''
pie title Project Allocation
    "Frontend" : 40
    "Backend" : 35
    "DevOps" : 25
''';

      final result = MermaidDiagramParser.parse(code);
      expect(result.isValid, isTrue);
      expect(result.type, equals(MermaidDiagramType.pie));
      expect(result.title, equals('Project Allocation'));
      expect(result.pieSlices.length, equals(3));
      expect(result.pieSlices[0].label, equals('Frontend'));
      expect(result.pieSlices[0].value, equals(40.0));
      expect(result.pieSlices[1].label, equals('Backend'));
      expect(result.pieSlices[1].value, equals(35.0));
    });

    test('Parses Sequence Diagram correctly', () {
      const code = '''
sequenceDiagram
    Alice->>Bob: Hello Bob
    Bob-->>Alice: Hi Alice
''';

      final result = MermaidDiagramParser.parse(code);
      expect(result.isValid, isTrue);
      expect(result.type, equals(MermaidDiagramType.sequence));
      expect(result.participants, containsAll(['Alice', 'Bob']));
      expect(result.sequenceMessages.length, equals(2));
      expect(result.sequenceMessages[0].text, equals('Hello Bob'));
      expect(result.sequenceMessages[1].isDashed, isTrue);
    });
  });

  group('RichNoteContentView Graph & Alert Preview Tests', () {
    testWidgets('Renders MermaidDiagramCard when fenced code block has mermaid', (tester) async {
      const content = '''
# System Architecture

```mermaid
graph TD
    A[Client] --> B[Server]
```
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RichNoteContentView(
                content: content,
                paletteId: 'cyan',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MermaidDiagramCard), findsOneWidget);
      expect(find.text('FLOWCHART'), findsOneWidget);
      expect(find.text('Client'), findsOneWidget);
      expect(find.text('Server'), findsOneWidget);
    });

    testWidgets('Renders GitHub / Antigravity Callout Alert with styled header and body', (tester) async {
      const content = '''
# Important Notes

> [!NOTE]
> This is a crucial Antigravity note.
> It can have multiple lines.

> [!TIP]
> Keep your designs tactile and responsive.
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RichNoteContentView(
                content: content,
                paletteId: 'peach',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NOTE'), findsOneWidget);
      expect(find.text('TIP'), findsOneWidget);
      expect(find.textContaining('This is a crucial Antigravity note.', findRichText: true), findsOneWidget);
      expect(find.textContaining('Keep your designs tactile and responsive.', findRichText: true), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:notes/core/theme/app_theme.dart';
import 'package:notes/data/repositories/workspace_repo_impl.dart';
import 'package:notes/domain/models/text_note.dart';
import 'package:notes/state/workspace_provider.dart';
import 'package:notes/ui/components/inputs/mermaid/mermaid_completion_bar.dart';
import 'package:notes/ui/components/inputs/mermaid/mermaid_diagram_card.dart';
import 'package:notes/ui/screens/editor/note_editor_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MermaidCompletionBar Widget Tests', () {
    testWidgets('Renders completion chips and triggers onInsertSnippet callback', (tester) async {
      String? inserted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MermaidCompletionBar(
              onInsertSnippet: (snippet) {
                inserted = snippet;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MERMAID'), findsOneWidget);
      expect(find.text('-->'), findsOneWidget);
      expect(find.text('[Box]'), findsOneWidget);
      expect(find.text('{Decision}'), findsOneWidget);

      await tester.tap(find.text('-->'));
      await tester.pumpAndSettle();

      expect(inserted, equals(' --> '));
    });
  });

  group('MermaidDiagramCard Clean Rendering Tests', () {
    testWidgets('Renders clean diagram nodes with zero distracting headers or toggles', (tester) async {
      const rawCode = '''
graph TD
    A[Start] --> B[Finish]
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MermaidDiagramCard(
                rawCode: rawCode,
                paletteId: 'cyan',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MermaidDiagramCard), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);

      // Confirm no distracting buttons or headers
      expect(find.text('FLOWCHART'), findsNothing);
      expect(find.text('Visual'), findsNothing);
      expect(find.text('Code'), findsNothing);
    });
  });

  group('NoteEditorScreen Scroll Position Sync Tests', () {
    testWidgets('Maintains non-zero scroll position when switching between Edit and Read modes', (tester) async {
      final now = DateTime.now();
      // Create a long note with many lines
      final lines = List.generate(60, (i) => 'Line #$i: Detailed content for scroll testing paragraph.');
      final longContent = lines.join('\n');

      final note = TextNote(
        id: 'test-scroll-note',
        title: 'Long Scrollable Note',
        content: longContent,
        createdAt: now,
        updatedAt: now,
        paletteId: 'peach',
        tags: [],
      );

      final repository = LocalStorageWorkspaceRepository(initialItems: [note]);
      final workspace = WorkspaceProvider(repository);

      await tester.pumpWidget(
        ChangeNotifierProvider<WorkspaceProvider>.value(
          value: workspace,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: NoteEditorScreen(item: note),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify we start in Reader mode (since content is non-empty)
      expect(find.textContaining('Reader Mode'), findsOneWidget);

      // Scroll down substantially
      final scrollableFinder = find.byType(Scrollable).first;
      await tester.drag(scrollableFinder, const Offset(0, -600));
      await tester.pumpAndSettle();

      // Check scroll offset is > 0
      final scrollableState = tester.state<ScrollableState>(scrollableFinder);
      final offsetBeforeEdit = scrollableState.position.pixels;
      expect(offsetBeforeEdit, greaterThan(200));

      // Switch to Edit Mode using the mode switcher icon in AppBar
      final modeSwitcherFinder = find.byTooltip('Edit Mode');
      expect(modeSwitcherFinder, findsOneWidget);
      await tester.tap(modeSwitcherFinder);
      await tester.pumpAndSettle();

      // Verify we are now in Edit mode (TextField present)
      expect(find.byType(TextField), findsWidgets);

      // Check that scroll position did NOT reset to 0
      final offsetInEdit = scrollableState.position.pixels;
      expect(offsetInEdit, greaterThan(150));

      // Switch back to Reader Mode
      final readerSwitcherFinder = find.byTooltip('Reader Mode');
      expect(readerSwitcherFinder, findsOneWidget);
      await tester.tap(readerSwitcherFinder);
      await tester.pumpAndSettle();

      // Check that scroll position is preserved in Reader mode as well
      final offsetBackInReader = scrollableState.position.pixels;
      expect(offsetBackInReader, greaterThan(150));
    });
  });
}

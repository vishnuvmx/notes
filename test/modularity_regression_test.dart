import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notes/core/theme/app_theme.dart';
import 'package:notes/domain/models/text_note.dart';
import 'package:notes/domain/models/sticky_note.dart';
import 'package:notes/domain/services/note_export_service.dart';
import 'package:notes/data/repositories/workspace_repo_impl.dart';
import 'package:notes/state/workspace_provider.dart';
import 'package:notes/state/theme_provider.dart';
import 'package:notes/ui/components/cards/smart_note_list_card.dart';
import 'package:notes/ui/components/cards/sticky_note_card.dart';
import 'package:notes/ui/components/cards/neo_note_card.dart';
import 'package:notes/ui/components/dialogs_sheets/note_statistics_sheet.dart';
import 'package:notes/ui/screens/home/home_screen.dart';
import 'package:notes/ui/screens/editor/note_editor_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NoteExportService tests', () {
    test('formats markdown with title and tags cleanly', () {
      final md = NoteExportService.formatMarkdown(
        title: 'Meeting Notes',
        content: 'Discussing Q3 roadmap and budget.\n\n[ ] Send follow up email',
        tags: ['work', 'q3'],
      );

      expect(md, contains('# Meeting Notes'));
      expect(md, contains('#work #q3'));
      expect(md, contains('Discussing Q3 roadmap and budget.'));
    });

    test('strips markdown syntax and checklists for clean plain text', () {
      final plain = NoteExportService.formatPlainText(
        title: 'Groceries',
        content: '[ ] **Milk**\n[x] *Bread*\n[ ] ~~Apples~~',
      );

      expect(plain, contains('Groceries'));
      expect(plain, contains('• Milk'));
      expect(plain, contains('• Bread'));
      expect(plain, contains('• Apples'));
      expect(plain.contains('**'), isFalse);
      expect(plain.contains('*Bread*'), isFalse);
      expect(plain.contains('~~'), isFalse);
    });
  });

  group('WorkspaceProvider Optimistic State tests', () {
    test('saveItem, toggleFavorite, and moveToTrash update in-memory lists immediately', () async {
      final note1 = TextNote(
        id: 'note_1',
        title: 'Task Alpha',
        content: 'Content Alpha',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paletteId: 'peach',
      );

      final repo = LocalStorageWorkspaceRepository(initialItems: [note1]);
      final workspace = WorkspaceProvider(repo);

      // Verify initial state
      expect(workspace.items.length, 1);
      expect(workspace.items.first.title, 'Task Alpha');
      expect(workspace.favoriteItems.isEmpty, isTrue);

      // 1. Optimistic toggleFavorite
      await workspace.toggleFavorite('note_1');
      expect(workspace.favoriteItems.length, 1);
      expect(workspace.favoriteItems.first.id, 'note_1');

      // 2. Optimistic saveItem
      final updatedNote = note1.copyWith(title: 'Task Alpha Updated', isFavorite: true);
      await workspace.saveItem(updatedNote);
      expect(workspace.items.first.title, 'Task Alpha Updated');
      expect(workspace.favoriteItems.first.title, 'Task Alpha Updated');

      // 3. Optimistic moveToTrash
      await workspace.moveToTrash('note_1');
      expect(workspace.items.isEmpty, isTrue);
      expect(workspace.favoriteItems.isEmpty, isTrue);
      expect(workspace.trashItems.length, 1);
      expect(workspace.trashItems.first.id, 'note_1');

      // 4. Optimistic restoreItem
      await workspace.restoreItem('note_1');
      expect(workspace.trashItems.isEmpty, isTrue);
      expect(workspace.items.length, 1);
      expect(workspace.items.first.id, 'note_1');
    });
  });

  group('HomeScreen View Mode & Card Rendering tests', () {
    testWidgets('Toggles between Grid (tilted) and Notebook (spiral) view modes cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final note = TextNote(
        id: 'regular_note',
        title: 'Standard Note',
        content: 'This is a standard text note.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paletteId: 'peach',
      );

      final sticky = StickyNote(
        id: 'sticky_note',
        title: 'Sticky Task',
        content: 'Short sticky note reminder',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paletteId: 'amber',
      );

      final repo = LocalStorageWorkspaceRepository(initialItems: [note, sticky]);
      final workspace = WorkspaceProvider(repo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkspaceProvider>.value(value: workspace),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In default stickyGrid mode:
      // Regular note renders NeoNoteCard
      expect(find.byType(NeoNoteCard), findsOneWidget);
      // Sticky note renders StickyNoteCard
      expect(find.byType(StickyNoteCard), findsOneWidget);
      // Notebook card is not rendered in grid mode
      expect(find.byType(SmartNoteListCard), findsNothing);

      // Now switch viewMode to notebook
      workspace.setViewMode(HomeViewMode.notebook);
      await tester.pumpAndSettle();

      // In notebook mode:
      // SmartNoteListCard is rendered for items!
      expect(find.byType(SmartNoteListCard), findsNWidgets(2));
      expect(find.byType(NeoNoteCard), findsNothing);
      expect(find.byType(StickyNoteCard), findsNothing);
    });
  });

  group('NoteStatisticsSheet modal test', () {
    testWidgets('Renders word counts, reading time, and checklists', (tester) async {
      const sampleText = 'First paragraph with some words.\n\nSecond paragraph with checklists:\n[ ] Item 1\n[x] Item 2';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoteStatisticsSheet(content: sampleText),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Note Statistics'), findsOneWidget);
      expect(find.text('Words'), findsOneWidget);
      expect(find.text('Characters'), findsOneWidget);
      expect(find.text('Reading Time'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('1/2 done'), findsOneWidget);
    });
  });

  group('NoteEditorScreen with extracted components test', () {
    testWidgets('Opens note in reader mode, displays stats sheet on pill tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final note = TextNote(
        id: 'editor_test_note',
        title: 'Project Roadmap',
        content: 'Initial thoughts on modularity and clean code.\n\n[ ] Refactor cards\n[x] Audit spaghetti',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        paletteId: 'peach',
      );

      final repo = LocalStorageWorkspaceRepository(initialItems: [note]);
      final workspace = WorkspaceProvider(repo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkspaceProvider>.value(value: workspace),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: NoteEditorScreen(item: note),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title is rendered
      expect(find.text('Project Roadmap'), findsOneWidget);

      // Verify reader mode badge is present
      final readerModePill = find.textContaining('Reader Mode');
      expect(readerModePill, findsOneWidget);

      // Tap reader mode pill to trigger NoteStatisticsSheet modal
      await tester.tap(readerModePill);
      await tester.pumpAndSettle();

      // Verify NoteStatisticsSheet appears modally
      expect(find.text('Note Statistics'), findsOneWidget);
      expect(find.text('1/2 done'), findsOneWidget);
    });
  });
}

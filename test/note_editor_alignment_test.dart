import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notes/core/theme/app_spacing.dart';
import 'package:notes/domain/models/text_note.dart';
import 'package:notes/data/repositories/workspace_repo_impl.dart';
import 'package:notes/state/workspace_provider.dart';
import 'package:notes/state/theme_provider.dart';
import 'package:notes/ui/screens/editor/note_editor_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Short new note starts at left padding (AppSpacing.lg = 16.0) in reader mode and is not centered', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0; // Screen logical width is 360.0
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Short note similar to user screenshot "Untitled e" / "hello how"
    final note = TextNote(
      id: 'short_test_note',
      title: 'Untitled e',
      content: 'hello how',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      paletteId: 'peach',
      tags: [],
    );

    final repository = LocalStorageWorkspaceRepository(initialItems: [note]);
    final workspaceProvider = WorkspaceProvider(repository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WorkspaceProvider>.value(value: workspaceProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          home: NoteEditorScreen(item: note),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // In reader mode (initialContent is not empty so it defaults to reader mode if content is present, or let's check)
    // Find the title text "Untitled e"
    final titleFinder = find.text('Untitled e');
    expect(titleFinder, findsOneWidget);

    final titleTopLeft = tester.getTopLeft(titleFinder);
    // In logical pixels, AppSpacing.lg is 16.0.
    // If the Column was centered, it would be around (360 - contentWidth) / 2 > 80.0.
    // With left alignment, it MUST be at exactly AppSpacing.lg = 16.0!
    expect(titleTopLeft.dx, AppSpacing.lg);

    // Find the content text "hello how"
    final contentFinder = find.textContaining('hello how', findRichText: true);
    expect(contentFinder, findsOneWidget);

    final contentTopLeft = tester.getTopLeft(contentFinder);
    expect(contentTopLeft.dx, AppSpacing.lg);
  });
}

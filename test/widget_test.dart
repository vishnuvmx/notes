import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notes/main.dart';
import 'package:notes/ui/screens/home/home_screen.dart';
import 'package:notes/ui/components/cards/smart_note_list_card.dart';
import 'package:notes/domain/models/base_item.dart';
import 'package:notes/domain/models/text_note.dart';
import 'package:notes/data/repositories/workspace_repo_impl.dart';
import 'package:notes/data/mock/mock_initial_data.dart';
import 'package:notes/state/workspace_provider.dart';
import 'package:notes/state/theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('LocalStorageWorkspaceRepository initializes with mock data and retrieves items', () async {
    final repository = LocalStorageWorkspaceRepository(initialItems: MockInitialData.getInitialItems());
    final items = await repository.getAllActiveItems();
    expect(items.isNotEmpty, true);
    expect(items.first.title.isNotEmpty, true);

    final provider = WorkspaceProvider(repository);
    await provider.loadItems();
    expect(provider.items.isNotEmpty, true);
  });

  testWidgets('SmartNoteListCard renders title and summary', (WidgetTester tester) async {
    final note = MockInitialData.getInitialItems().firstWhere((i) => i is TextNote) as TextNote;
    final repository = LocalStorageWorkspaceRepository(initialItems: [note]);
    final workspaceProvider = WorkspaceProvider(repository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WorkspaceProvider>.value(value: workspaceProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SmartNoteListCard(
              item: note,
              index: 0,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text(note.title), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
  });

  testWidgets('HomeScreen renders Your Notes headline and neo-pop cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = LocalStorageWorkspaceRepository(initialItems: MockInitialData.getInitialItems());
    final workspaceProvider = WorkspaceProvider(repository);
    await workspaceProvider.loadItems();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WorkspaceProvider>.value(value: workspaceProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Your Files'), findsOneWidget);
    expect(find.text('Welcome to Tack'), findsOneWidget);
  });

  testWidgets('TackApp launches with HomeScreen and navigation destinations', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = LocalStorageWorkspaceRepository(initialItems: MockInitialData.getInitialItems());
    final workspaceProvider = WorkspaceProvider(repository);
    await workspaceProvider.loadItems();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WorkspaceProvider>.value(value: workspaceProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const TackApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify main screen is visible with neo-pop header
    expect(find.text('Your Files'), findsOneWidget);

    // Tap 'Clipboard' bottom nav destination
    await tester.tap(find.byKey(const ValueKey('nav_item_4')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(workspaceProvider.selectedCategory, ItemType.clipboard);

    // Tap 'Whiteboard' bottom nav destination
    await tester.tap(find.byKey(const ValueKey('nav_item_3')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(workspaceProvider.selectedCategory, ItemType.whiteboard);
  });
}

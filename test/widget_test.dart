import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:notes/main.dart';
import 'package:notes/ui/screens/home/home_screen.dart';
import 'package:notes/ui/components/cards/smart_note_list_card.dart';
import 'package:notes/ui/components/cards/clipboard_card.dart';
import 'package:notes/ui/components/inputs/category_filter_pills.dart';
import 'package:notes/ui/screens/splash/splash_screen.dart';
import 'package:notes/domain/models/base_item.dart';
import 'package:notes/data/repositories/workspace_repo_impl.dart';
import 'package:notes/data/mock/mock_initial_data.dart';
import 'package:notes/state/workspace_provider.dart';
import 'package:notes/state/theme_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('SplashScreen renders red background and centered app icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(nextScreen: Scaffold(body: Text('Home Content'))),
      ),
    );

    // Initial frame
    await tester.pump(const Duration(milliseconds: 100));

    // Verify splash screen elements
    expect(find.text('Tack'), findsOneWidget);
    expect(find.text('Everything worth remembering.'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Fast-forward animation to complete and slide up
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Verify next screen is displayed
    expect(find.text('Home Content'), findsOneWidget);
  });

  testWidgets('SmartNoteListCard renders title and summary', (WidgetTester tester) async {
    final note = MockInitialData.getInitialItems().first;
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
    expect(find.text('How to Build Trust on Your Website'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
  });

  testWidgets('HomeScreen renders feed, categories, and bottom navigation', (WidgetTester tester) async {
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

    await tester.pump(const Duration(milliseconds: 100));

    // Verify all parts of HomeScreen are rendered and visible!
    expect(find.text('Hey Tack'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('How to Build Trust on Your Website'), findsOneWidget);
    expect(find.text('Flutter Clean Architecture Snippet'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.byType(ClipboardCard), findsWidgets);
  });

  testWidgets('TackApp launches with SplashScreen and slides up to HomeScreen', (WidgetTester tester) async {
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

    // Verify Splash Screen first on launch
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Tack'), findsOneWidget);

    // Let splash finish and slide up to HomeScreen
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Verify main screen is visible
    expect(find.text('Hey Tack'), findsOneWidget);
    expect(find.text('How to Build Trust on Your Website'), findsOneWidget);

    // Tap 'Notes' category pill
    await tester.tap(find.descendant(of: find.byType(CategoryFilterPills), matching: find.text('Notes')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(workspaceProvider.selectedCategory, ItemType.note);

    // Tap 'Sticky' category pill
    await tester.tap(find.descendant(of: find.byType(CategoryFilterPills), matching: find.text('Sticky')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(workspaceProvider.selectedCategory, ItemType.sticky);

    // Tap 'Clipboard' bottom nav destination
    await tester.tap(find.byKey(const ValueKey('nav_item_4')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(workspaceProvider.selectedCategory, ItemType.clipboard);
  });
}

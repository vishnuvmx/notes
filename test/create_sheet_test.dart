import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notes/main.dart';
import 'package:notes/data/repositories/workspace_repo_impl.dart';
import 'package:notes/data/mock/mock_initial_data.dart';
import 'package:notes/state/workspace_provider.dart';
import 'package:notes/state/theme_provider.dart';
import 'package:notes/core/theme/tack_icons.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Tap QuickAdd plus button opens create sheet and creates note', (WidgetTester tester) async {
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

    // Find the plus icons (QuickAdd and Center FAB)
    final plusIcons = find.byWidgetPredicate(
      (widget) => widget is TackIcon && widget.icon == TackIcons.plus,
    );
    expect(plusIcons, findsNWidgets(2));

    // Tap QuickAdd button next to header
    await tester.tap(plusIcons.first);
    await tester.pumpAndSettle();

    // Verify Create Item Sheet is displayed
    expect(find.text('Create new item'), findsOneWidget);
    expect(find.text('Card Color'), findsOneWidget);

    // Enter title & content
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, 'Test New Note');
    await tester.pump();

    // Tap Create button
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Verify it navigated to Note Editor screen
    expect(find.text('Test New Note'), findsWidgets);
  });

  testWidgets('Tap Center FAB plus button opens create sheet and can switch to Sticky', (WidgetTester tester) async {
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

    final plusIcons = find.byWidgetPredicate(
      (widget) => widget is TackIcon && widget.icon == TackIcons.plus,
    );

    // Tap Center FAB
    await tester.tap(plusIcons.last);
    await tester.pumpAndSettle();

    expect(find.text('Create new item'), findsOneWidget);

    // Switch to Sticky
    await tester.tap(find.text('Sticky'));
    await tester.pumpAndSettle();

    // Enter title
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, 'My Cool Sticky');
    await tester.pump();

    // Tap Create
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Verify it navigated to editor
    expect(find.text('My Cool Sticky'), findsWidgets);
  });
}

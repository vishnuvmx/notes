import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notes/data/mock/mock_initial_data.dart';
import 'package:notes/data/repositories/workspace_repo_impl.dart';
import 'package:notes/domain/models/whiteboard_item.dart';
import 'package:notes/domain/models/base_item.dart';
import 'package:notes/state/workspace_provider.dart';
import 'package:notes/state/theme_provider.dart';
import 'package:notes/ui/screens/whiteboard/whiteboard_canvas_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('WhiteboardCanvasScreen opens and allows adding shapes/symbols', (WidgetTester tester) async {
    // Set a realistic mobile viewport
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = LocalStorageWorkspaceRepository(initialItems: MockInitialData.getInitialItems());
    final workspace = WorkspaceProvider(repository);
    await workspace.loadItems();

    final whiteboardItem = workspace.items.firstWhere((i) => i.type == ItemType.whiteboard) as WhiteboardCanvasItem;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WorkspaceProvider>.value(value: workspace),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          home: WhiteboardCanvasScreen(item: whiteboardItem),
        ),
      ),
    );

    // Initial pump and settle post frame animations
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify existing nodes are rendered without error
    expect(find.text('Project Proposal'), findsOneWidget);
    expect(find.text('Design & Review'), findsOneWidget);
    expect(find.text('Launch & Measure'), findsOneWidget);

    // Verify shape palette is visible and accessible
    expect(find.text('Start / End'), findsWidgets);
    expect(find.text('Process'), findsWidgets);
    expect(find.text('Decision'), findsWidgets);
    expect(find.text('Input / Output'), findsWidgets);
    expect(find.text('Connector'), findsWidgets);

    // Tap 'Process' shape in palette to add a new node
    final processButton = find.widgetWithText(InkWell, 'Process');
    expect(processButton, findsOneWidget);
    await tester.tap(processButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // A new Process node was added to canvas
    expect(find.text('Process'), findsWidgets);

    // Tap on a node to select it
    final nodeFinder = find.text('Project Proposal');
    await tester.tap(nodeFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify branch handles appear
    expect(find.byTooltip('Branch Right'), findsOneWidget);

    // Tap Export button to open Export bottom sheet
    final exportButton = find.widgetWithText(ElevatedButton, 'Export');
    expect(exportButton, findsOneWidget);
    await tester.tap(exportButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify all export format options are presented
    expect(find.text('Export Whiteboard'), findsOneWidget);
    expect(find.text('PNG Image (Lossless High-Res)'), findsOneWidget);
    expect(find.text('JPEG Image (Compressed)'), findsOneWidget);
    expect(find.text('PDF Document (Vector & Print)'), findsOneWidget);
  });
}

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

  Widget buildWhiteboardScreen({required WorkspaceProvider workspace, required WhiteboardCanvasItem item}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WorkspaceProvider>.value(value: workspace),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        home: WhiteboardCanvasScreen(item: item),
      ),
    );
  }

  testWidgets('Whiteboard UX: Branching coordinate does not clamp to 2400 on 6000px canvas', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Create a node located deep inside the canvas at x=2800, y=2800
    final customNode = CanvasNode(
      id: 'node-deep',
      shapeType: CanvasNodeType.process,
      text: 'Deep Node',
      x: 2800.0,
      y: 2800.0,
      width: 140.0,
      height: 70.0,
      paletteId: 'lime',
    );

    final whiteboardItem = WhiteboardCanvasItem(
      id: 'wb-test',
      title: 'Branching Test Canvas',
      nodes: [customNode],
      edges: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      paletteId: 'cyan',
    );

    final repository = LocalStorageWorkspaceRepository(initialItems: [whiteboardItem]);
    final workspace = WorkspaceProvider(repository);
    await workspace.loadItems();

    await tester.pumpWidget(buildWhiteboardScreen(workspace: workspace, item: whiteboardItem));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final state = tester.state(find.byType(WhiteboardCanvasScreen)) as dynamic;
    
    // Test branching in all 4 directions
    // 1. Right: 2800 + 140 + 75 = 3015.0
    state.branchFromNodeForTesting(customNode, 'right');
    // 2. Bottom: 2800 + 70 + 75 = 2945.0
    state.branchFromNodeForTesting(customNode, 'bottom');

    final nodes = state.nodes as List<CanvasNode>;
    expect(nodes.length, 3);

    final rightChild = nodes.firstWhere((n) => n.x > 3000);
    expect(rightChild.x, 3015.0);
    expect(rightChild.y, 2800.0);

    final bottomChild = nodes.firstWhere((n) => n.y > 2900);
    expect(bottomChild.x, 2800.0);
    expect(bottomChild.y, 2945.0);

    // Edges connected properly
    final edges = state.edges as List<CanvasEdge>;
    expect(edges.length, 2);
    expect(edges.any((e) => e.fromNodeId == 'node-deep' && e.toNodeId == rightChild.id), true);
    expect(edges.any((e) => e.fromNodeId == 'node-deep' && e.toNodeId == bottomChild.id), true);
  });

  testWidgets('Whiteboard UX: Edge context capsule allows editing and deleting connections', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final nodeA = CanvasNode(
      id: 'node-a',
      shapeType: CanvasNodeType.startEnd,
      text: 'Start Step',
      x: 3000.0,
      y: 3000.0,
      width: 140.0,
      height: 70.0,
      paletteId: 'coral',
    );
    final nodeB = CanvasNode(
      id: 'node-b',
      shapeType: CanvasNodeType.process,
      text: 'Next Step',
      x: 3200.0,
      y: 3000.0,
      width: 140.0,
      height: 70.0,
      paletteId: 'lime',
    );
    final edgeAB = CanvasEdge(
      id: 'edge-ab',
      fromNodeId: 'node-a',
      toNodeId: 'node-b',
      label: 'Initial Flow',
    );

    final whiteboardItem = WhiteboardCanvasItem(
      id: 'wb-edge-test',
      title: 'Edge Test Canvas',
      nodes: [nodeA, nodeB],
      edges: [edgeAB],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      paletteId: 'cyan',
    );

    final repository = LocalStorageWorkspaceRepository(initialItems: [whiteboardItem]);
    final workspace = WorkspaceProvider(repository);
    await workspace.loadItems();

    await tester.pumpWidget(buildWhiteboardScreen(workspace: workspace, item: whiteboardItem));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final state = tester.state(find.byType(WhiteboardCanvasScreen)) as dynamic;

    // Select edgeAB
    state.selectEdgeForTesting('edge-ab');
    await tester.pumpAndSettle();

    // Verify Edge Action Capsule widgets appear
    expect(find.byTooltip('Edit Connection Label'), findsOneWidget);
    expect(find.byTooltip('Reverse Direction'), findsOneWidget);
    expect(find.byTooltip('Delete Connection'), findsOneWidget);

    // Delete edge using helper
    state.deleteEdgeForTesting('edge-ab');
    await tester.pumpAndSettle();

    final edges = state.edges as List<CanvasEdge>;
    expect(edges.isEmpty, true);
    expect(find.byTooltip('Delete Connection'), findsNothing);
  });

  testWidgets('Whiteboard UX: Snap-to-Grid, Live Minimap, and Zen Mode toggles work reliably', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = LocalStorageWorkspaceRepository(initialItems: MockInitialData.getInitialItems());
    final workspace = WorkspaceProvider(repository);
    await workspace.loadItems();

    final whiteboardItem = workspace.items.firstWhere((i) => i.type == ItemType.whiteboard) as WhiteboardCanvasItem;

    await tester.pumpWidget(buildWhiteboardScreen(workspace: workspace, item: whiteboardItem));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final state = tester.state(find.byType(WhiteboardCanvasScreen)) as dynamic;

    // 1. Toggle Snap-to-Grid
    expect(state.snapToGrid, false);
    state.toggleSnapToGridForTesting();
    await tester.pumpAndSettle();
    expect(state.snapToGrid, true);

    // 2. Toggle Minimap
    expect(state.showMinimap, false);
    state.toggleMinimapForTesting();
    await tester.pumpAndSettle();
    expect(state.showMinimap, true);

    // 3. Toggle Zen Mode
    expect(state.isZenMode, false);
    state.toggleZenModeForTesting();
    await tester.pumpAndSettle();
    expect(state.isZenMode, true);

    // In Zen mode, "Show Tools" pill appears
    expect(find.text('Show Tools'), findsOneWidget);

    // Tap Show Tools to restore standard dock
    await tester.tap(find.text('Show Tools'));
    await tester.pumpAndSettle();
    expect(state.isZenMode, false);
  });
}

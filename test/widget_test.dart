import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:notes/main.dart';
import 'package:notes/data/repositories/workspace_repo_impl.dart';
import 'package:notes/state/workspace_provider.dart';
import 'package:notes/state/theme_provider.dart';

void main() {
  testWidgets('Tack app launches and displays title smoke test', (WidgetTester tester) async {
    final repository = InMemoryWorkspaceRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WorkspaceProvider(repository)),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const TackApp(),
      ),
    );

    // Pump initial frames
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Tack brand title
    expect(find.text('Tack'), findsWidgets);
  });
}

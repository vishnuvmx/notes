import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/workspace_repo_impl.dart';
import 'domain/models/base_item.dart';
import 'domain/models/text_note.dart';
import 'domain/models/sticky_note.dart';
import 'domain/models/whiteboard_item.dart';
import 'domain/models/clipboard_item.dart';
import 'state/workspace_provider.dart';
import 'state/theme_provider.dart';

import 'ui/screens/home/home_screen.dart';
import 'ui/screens/editor/note_editor_screen.dart';
import 'ui/screens/whiteboard/whiteboard_canvas_screen.dart';
import 'ui/screens/folders/folder_view_screen.dart';
import 'ui/screens/settings/settings_screen.dart';

import 'ui/screens/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Android edge-to-edge system navigation & status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  final repository = InMemoryWorkspaceRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkspaceProvider(repository)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const TackApp(),
    ),
  );
}

class TackApp extends StatelessWidget {
  const TackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Tack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProv.themeMode,
      home: const SplashScreen(nextScreen: TackRootNavigator()),
    );
  }
}


/// Root navigator managing seamless routing between Home, Editor, Whiteboard, and Folders.
class TackRootNavigator extends StatelessWidget {
  const TackRootNavigator({super.key});

  void _openItemDetail(BuildContext context, BaseWorkspaceItem item) {
    if (item is WhiteboardCanvasItem) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WhiteboardCanvasScreen(item: item),
        ),
      );
    } else if (item is TextNote || item is StickyNote) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NoteEditorScreen(item: item),
        ),
      );
    } else if (item is ClipboardItem) {
      // Open clipboard item in editor as well
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NoteEditorScreen(item: item),
        ),
      );
    }
  }

  void _openWhiteboardDirect(BuildContext context) {
    final workspace = context.read<WorkspaceProvider>();
    final whiteboard = workspace.items.cast<BaseWorkspaceItem?>().firstWhere(
          (i) => i is WhiteboardCanvasItem,
          orElse: () => null,
        );

    if (whiteboard != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WhiteboardCanvasScreen(item: whiteboard as WhiteboardCanvasItem),
        ),
      );
    } else {
      workspace.setCategory(ItemType.whiteboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      onOpenItem: (item) => _openItemDetail(context, item),
      onOpenWhiteboardTab: () => _openWhiteboardDirect(context),
      onOpenClipboardTab: () {
        context.read<WorkspaceProvider>().setCategory(ItemType.clipboard);
      },
      onOpenFavorites: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FolderViewScreen(
              folderType: FolderType.favorites,
              onOpenItem: (item) => _openItemDetail(context, item),
            ),
          ),
        );
      },
      onOpenArchive: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FolderViewScreen(
              folderType: FolderType.archive,
              onOpenItem: (item) => _openItemDetail(context, item),
            ),
          ),
        );
      },
      onOpenTrash: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FolderViewScreen(
              folderType: FolderType.trash,
              onOpenItem: (item) => _openItemDetail(context, item),
            ),
          ),
        );
      },
      onOpenSettings: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SettingsScreen(),
          ),
        );
      },
    );
  }
}

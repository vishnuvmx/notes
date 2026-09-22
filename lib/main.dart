import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide ProcessTextService;
import 'package:provider/provider.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/tack_icons.dart';
import 'data/repositories/workspace_repo_impl.dart';
import 'domain/models/base_item.dart';
import 'domain/models/text_note.dart';
import 'domain/models/sticky_note.dart';
import 'domain/models/whiteboard_item.dart';
import 'domain/models/clipboard_item.dart';
import 'domain/services/process_text_service.dart';
import 'domain/services/pinned_notification_service.dart';
import 'state/workspace_provider.dart';
import 'state/theme_provider.dart';

import 'ui/screens/home/home_screen.dart';
import 'ui/screens/editor/note_editor_screen.dart';
import 'ui/screens/whiteboard/whiteboard_canvas_screen.dart';
import 'ui/screens/folders/folder_view_screen.dart';
import 'ui/screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android edge-to-edge system navigation & status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Load saved theme preference & repository items from local storage
  final initialTheme = await ThemeProvider.loadSavedThemeMode();
  final repository = LocalStorageWorkspaceRepository();
  await repository.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkspaceProvider(repository)),
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialMode: initialTheme)),
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
      home: const TackRootNavigator(),
    );
  }
}


/// Root navigator managing seamless routing between Home, Editor, Whiteboard, and Folders.
class TackRootNavigator extends StatefulWidget {
  const TackRootNavigator({super.key});

  @override
  State<TackRootNavigator> createState() => _TackRootNavigatorState();
}

class _TackRootNavigatorState extends State<TackRootNavigator> {
  static Route<T> _buildTactileRoute<T>(Widget page) {
    return CupertinoPageRoute<T>(
      builder: (context) => page,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSystemIntegration();
    });
  }

  void _initSystemIntegration() async {
    // 1. Listen for incoming text / actions when app is running (foreground or background)
    ProcessTextService.initialize(
      onTextReceived: (data) {
        if (mounted) {
          _handleIncomingText(data);
        }
      },
    );

    // 2. Check if app was launched via "Save to Tack", SEND intent, or Quick Capture / Pinned Notification
    final initialData = await ProcessTextService.getInitialText();
    if (initialData != null && mounted) {
      _handleIncomingText(initialData);
    }

    // 3. Ensure persistent Quick Capture notification stays synced if enabled
    final quickCaptureEnabled = await PinnedNotificationService.isQuickCaptureEnabled();
    if (quickCaptureEnabled) {
      await PinnedNotificationService.setQuickCaptureEnabled(true);
    }
  }

  Future<void> _handleIncomingText(IncomingTextData data) async {
    // 1. Direct open of a status-bar pinned note
    if (data.action == 'OPEN_NOTE' && data.noteId != null) {
      final workspace = context.read<WorkspaceProvider>();
      final item = workspace.items.where((i) => i.id == data.noteId).firstOrNull;
      if (item != null && mounted) {
        HapticFeedback.selectionClick();
        _openItemDetail(context, item);
      }
      return;
    }

    // 2. Instant 1-tap quick capture from status bar or Quick Settings Tile
    if (data.action == 'QUICK_CAPTURE') {
      final workspace = context.read<WorkspaceProvider>();
      final note = await workspace.createQuickItem(
        title: '',
        type: ItemType.note,
        paletteId: 'peach',
        content: '',
      );
      if (mounted) {
        HapticFeedback.lightImpact();
        _openItemDetail(context, note);
      }
      return;
    }

    // 3. App Shortcut → New Note (long-press launcher icon)
    if (data.action == 'NEW_NOTE') {
      final workspace = context.read<WorkspaceProvider>();
      final note = await workspace.createQuickItem(
        title: '',
        type: ItemType.note,
        paletteId: 'peach',
        content: '',
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        _openItemDetail(context, note);
      }
      return;
    }

    // 4. App Shortcut → New Whiteboard (long-press launcher icon)
    if (data.action == 'NEW_WHITEBOARD') {
      final workspace = context.read<WorkspaceProvider>();
      final board = await workspace.createQuickItem(
        title: '',
        type: ItemType.whiteboard,
        paletteId: 'lavender',
        content: '',
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        _openItemDetail(context, board);
      }
      return;
    }

    final text = data.text.trim();
    if (text.isEmpty) {
      if (mounted) {
        _showFeedbackSnackBar(
          message: 'Empty file or no text selected',
          isError: true,
        );
      }
      return;
    }

    final workspace = context.read<WorkspaceProvider>();
    final newNote = await workspace.createNoteFromExternalText(
      data.text,
      title: data.title,
      sourceApp: data.sourceApp ?? data.fileName,
    );

    if (newNote != null && mounted) {
      HapticFeedback.mediumImpact();
      final String sourceLabel;
      if (data.fileName != null && data.fileName!.isNotEmpty) {
        sourceLabel = 'Opened ${data.fileName}';
      } else if (data.sourceApp != null && data.sourceApp!.isNotEmpty) {
        sourceLabel = 'Saved from ${data.sourceApp}';
      } else {
        sourceLabel = 'Saved from selected text';
      }

      _showFeedbackSnackBar(
        message: sourceLabel,
        isError: false,
      );

      // Open directly in Note Editor (which starts in Reader Mode for instant markdown preview)
      _openItemDetail(context, newNote);
    }
  }

  void _showFeedbackSnackBar({
    required String message,
    required bool isError,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 88),
        padding: EdgeInsets.zero,
        duration: const Duration(milliseconds: 2000),
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: AppSpacing.roundedPill,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : const Color(0xFF191A23).withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TackIcon(
                  isError ? TackIcons.close : TackIcons.checkCircle,
                  size: 16,
                  color: isError ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openItemDetail(BuildContext context, BaseWorkspaceItem item) {
    if (item is WhiteboardCanvasItem) {
      Navigator.of(context).push(
        _buildTactileRoute(WhiteboardCanvasScreen(item: item)),
      );
    } else if (item is TextNote || item is StickyNote) {
      Navigator.of(context).push(
        _buildTactileRoute(NoteEditorScreen(item: item)),
      );
    } else if (item is ClipboardItem) {
      // Open clipboard item in editor as well
      Navigator.of(context).push(
        _buildTactileRoute(NoteEditorScreen(item: item)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      onOpenItem: (item) => _openItemDetail(context, item),
      onOpenFavorites: () {
        Navigator.of(context).push(
          _buildTactileRoute(
            FolderViewScreen(
              folderType: FolderType.favorites,
              onOpenItem: (item) => _openItemDetail(context, item),
            ),
          ),
        );
      },
      onOpenArchive: () {
        Navigator.of(context).push(
          _buildTactileRoute(
            FolderViewScreen(
              folderType: FolderType.archive,
              onOpenItem: (item) => _openItemDetail(context, item),
            ),
          ),
        );
      },
      onOpenTrash: () {
        Navigator.of(context).push(
          _buildTactileRoute(
            FolderViewScreen(
              folderType: FolderType.trash,
              onOpenItem: (item) => _openItemDetail(context, item),
            ),
          ),
        );
      },
      onOpenSettings: () {
        Navigator.of(context).push(
          _buildTactileRoute(const SettingsScreen()),
        );
      },
    );
  }
}

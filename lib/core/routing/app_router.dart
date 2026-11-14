import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide ProcessTextService;
import 'package:provider/provider.dart';

import '../services/pinned_notification_service.dart';
import '../services/process_text_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/tack_icons.dart';
import '../../features/folders/screens/folder_view_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/notes/models/text_note.dart';
import '../../features/notes/screens/note_editor_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/whiteboard/models/whiteboard_item.dart';
import '../../features/whiteboard/screens/whiteboard_canvas_screen.dart';
import '../../shared/models/base_item.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/widgets/create_item_sheet.dart';

/// Root navigator managing routing between the 5-slot Shell, Note Editor,
/// Board Canvas, and System Intents (`05` §9).
class TackRootNavigator extends StatefulWidget {
  const TackRootNavigator({super.key});

  @override
  State<TackRootNavigator> createState() => _TackRootNavigatorState();
}

class _TackRootNavigatorState extends State<TackRootNavigator> {
  static Route<T> _buildRoute<T>(Widget page) {
    return MaterialPageRoute<T>(
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
    // 1. Listen for incoming text / actions via `com.notes.tacknotes/process_text`
    ProcessTextService.initialize(
      onTextReceived: (data) {
        if (mounted) {
          _handleIncomingText(data);
        }
      },
    );

    // 2. Check if app was launched via "Save to Tack", SEND intent, or Quick Capture
    final initialData = await ProcessTextService.getInitialText();
    if (initialData != null && mounted) {
      _handleIncomingText(initialData);
    }

    // 3. Keep persistent Quick Capture notification & pinned note notifications synced
    await PinnedNotificationService.initializeCallbacks(
      onQuickAdd: _handleNotificationQuickAdd,
      onCompleteNextTodo: _handleNotificationCompleteNextTodo,
      onUnpin: (_) async {},
    );

    final quickCaptureEnabled =
        await PinnedNotificationService.isQuickCaptureEnabled();
    if (quickCaptureEnabled) {
      await PinnedNotificationService.setQuickCaptureEnabled(true);
    }

    if (mounted) {
      final workspace = context.read<WorkspaceProvider>();
      final pinnedIds = await PinnedNotificationService.getPinnedNoteIds();
      for (final id in pinnedIds) {
        final item = workspace.getItemByIdSync(id);
        if (item == null || item.isTrash || item.isArchived) {
          await PinnedNotificationService.unpinNote(id);
        } else {
          await PinnedNotificationService.pinNote(item);
        }
      }
    }
  }

  Future<void> _handleNotificationQuickAdd(String noteId, String text) async {
    if (!mounted) return;
    final workspace = context.read<WorkspaceProvider>();

    if (noteId.isEmpty) {
      final lines = text.split('\n');
      final title = lines.first.trim();
      await workspace.createQuickItem(
        title: title.isEmpty ? 'Quick Note' : title,
        content: text,
        type: ItemType.note,
        paletteId: 'amber',
      );
      return;
    }

    final existing = workspace.getItemByIdSync(noteId);
    if (existing is TextNote) {
      final hasChecklist = RegExp(r'^\s*[-*]\s+\[[ xX]\]', multiLine: true)
          .hasMatch(existing.content);
      final addition = hasChecklist ? '- [ ] $text' : text;
      final base = existing.content.trimRight();
      final updated = existing.copyWith(
        content: base.isEmpty ? addition : '$base\n$addition',
        updatedAt: DateTime.now(),
      );
      await workspace.saveItem(updated);
      await PinnedNotificationService.syncPinnedNoteIfActive(updated);
    }
  }

  Future<void> _handleNotificationCompleteNextTodo(String noteId) async {
    if (!mounted) return;
    final workspace = context.read<WorkspaceProvider>();
    final existing = workspace.getItemByIdSync(noteId);
    if (existing is! TextNote) return;

    final todoPattern = RegExp(r'^(\s*[-*]\s+)\[\s\](\s+.*)$', multiLine: true);
    final match = todoPattern.firstMatch(existing.content);
    if (match == null) return;

    final updatedContent = existing.content.replaceFirstMapped(
      todoPattern,
      (m) => '${m.group(1)}[x]${m.group(2)}',
    );
    final updated = existing.copyWith(
      content: updatedContent,
      updatedAt: DateTime.now(),
    );
    await workspace.saveItem(updated);
    await PinnedNotificationService.syncPinnedNoteIfActive(updated);
  }

  Future<void> _handleIncomingText(IncomingTextData data) async {
    final workspace = context.read<WorkspaceProvider>();

    // 1. Direct open of a pinned note or dynamic app shortcut
    if (data.action == 'OPEN_NOTE' && data.noteId != null) {
      BaseWorkspaceItem? item = workspace.getItemByIdSync(data.noteId!);
      if (item == null && workspace.isLoading) {
        for (int retry = 0; retry < 20; retry++) {
          await Future.delayed(const Duration(milliseconds: 50));
          if (!mounted) return;
          item = workspace.getItemByIdSync(data.noteId!);
          if (item != null) break;
        }
      }
      if (item != null && mounted) {
        HapticFeedback.selectionClick();
        _openItemDetail(context, item);
      }
      return;
    }

    // 2. Quick Settings Tile / Notification → Open Capture Sheet (`05` §9)
    if (data.action == 'QUICK_CAPTURE') {
      if (!mounted) return;
      final created = await CreateItemSheet.show(context);
      if (created != null && mounted) {
        _openItemDetail(context, created, startInEditMode: true);
      }
      return;
    }

    // 3. App Shortcut → New Note
    if (data.action == 'NEW_NOTE') {
      final note = await workspace.createQuickItem(
        title: 'Untitled Note',
        type: ItemType.note,
        paletteId: 'amber',
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        _openItemDetail(context, note, startInEditMode: true);
      }
      return;
    }

    // 4. App Shortcut → New Board
    if (data.action == 'NEW_WHITEBOARD') {
      final board = await workspace.createQuickItem(
        title: 'Untitled Board',
        type: ItemType.whiteboard,
        paletteId: 'cyan',
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        _openItemDetail(context, board);
      }
      return;
    }

    // 5. Widget Action 1: "+ Worth remembering...." -> Capture to Inbox / Today
    if (data.action == 'WIDGET_WORTH_REMEMBERING') {
      if (!mounted) return;
      final created = await CreateItemSheet.show(context);
      if (created != null && mounted) {
        _openItemDetail(context, created, startInEditMode: true);
      }
      return;
    }

    // 6. Widget Action 2: "+ Done with your works?" -> Open Today's Daily Note
    if (data.action == 'WIDGET_DONE_WORKS' || data.action == 'WIDGET_PLAN_DAY') {
      final daily = await workspace.openOrCreateTodaysNote();
      if (mounted) {
        HapticFeedback.lightImpact();
        _openItemDetail(context, daily);
      }
      return;
    }

    final text = data.text.trim();
    final hasImage = data.imagePath != null && data.imagePath!.isNotEmpty;

    if (text.isEmpty && !hasImage) {
      if (mounted) {
        _showFeedbackSnackBar(
          message: 'Empty file or no content shared',
          isError: true,
        );
      }
      return;
    }

    final String noteContent;
    if (hasImage) {
      final imgTag = '![${data.title ?? 'Image'}](${data.imagePath})';
      noteContent = text.isNotEmpty ? '$imgTag\n\n$text' : imgTag;
    } else {
      noteContent = data.text;
    }

    // `VIEW` `.md`/`.txt` file opens directly in Read Mode; `SEND` / `PROCESS_TEXT` saves to Inbox (`05` §9)
    final isFileOpen = data.fileName != null && data.fileName!.isNotEmpty;
    if (isFileOpen) {
      final fileNote = await workspace.createQuickItem(
        title: data.title ?? data.fileName!,
        type: ItemType.note,
        paletteId: 'slate',
        extraContent: noteContent,
      );
      if (mounted) {
        _showFeedbackSnackBar(
          message: 'Imported ${data.fileName}',
          isError: false,
        );
        _openItemDetail(context, fileNote, startInEditMode: false);
      }
      return;
    }

    final captured = await workspace.captureToInbox(
      noteContent,
      title: data.title,
      sourceApp: data.sourceApp,
    );
    if (mounted) {
      HapticFeedback.mediumImpact();
      final label = (data.sourceApp != null && data.sourceApp!.isNotEmpty)
          ? 'Saved to Inbox from ${data.sourceApp}'
          : 'Saved to Inbox';
      _showFeedbackSnackBar(
        message: label,
        isError: false,
        onOpen: () => _openItemDetail(context, captured),
      );
    }
  }

  void _showFeedbackSnackBar({
    required String message,
    required bool isError,
    VoidCallback? onOpen,
  }) {
    final tokens = context.tokens;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 88),
        padding: EdgeInsets.zero,
        duration: const Duration(milliseconds: 2800),
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: AppSpacing.roundedPill,
              border: Border.all(color: tokens.borderSubtle, width: 1),
              boxShadow: AppSpacing.elev2(tokens.isDark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TackIcon(
                  isError ? TackIcons.close : TackIcons.checkCircle,
                  size: 16,
                  color: isError ? tokens.danger : tokens.success,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(
                      color: tokens.textPrimary,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onOpen != null) ...[
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      onOpen();
                    },
                    child: Text(
                      'Open',
                      style: AppTypography.label(
                        color: tokens.accentPinText,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openItemDetail(
    BuildContext context,
    BaseWorkspaceItem item, {
    bool startInEditMode = false,
  }) {
    if (item is WhiteboardCanvasItem) {
      Navigator.of(context).push(
        _buildRoute(WhiteboardCanvasScreen(item: item)),
      );
    } else {
      Navigator.of(context).push(
        _buildRoute(
          NoteEditorScreen(
            item: item,
            startInEditMode: startInEditMode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      onOpenItem: (item, {startInEditMode = false}) => _openItemDetail(
        context,
        item,
        startInEditMode: startInEditMode,
      ),
      onOpenFavorites: () {
        Navigator.of(context).push(
          _buildRoute(
            FolderViewScreen(
              folderType: FolderType.favorites,
              onOpenItem: (item) => _openItemDetail(context, item),
            ),
          ),
        );
      },
      onOpenArchive: () {
        Navigator.of(context).push(
          _buildRoute(
            FolderViewScreen(
              folderType: FolderType.archive,
              onOpenItem: (item) => _openItemDetail(context, item),
            ),
          ),
        );
      },
      onOpenTrash: () {
        Navigator.of(context).push(
          _buildRoute(
            FolderViewScreen(
              folderType: FolderType.trash,
              onOpenItem: (item) => _openItemDetail(context, item),
            ),
          ),
        );
      },
      onOpenSettings: () {
        Navigator.of(context).push(
          _buildRoute(const SettingsScreen()),
        );
      },
    );
  }
}

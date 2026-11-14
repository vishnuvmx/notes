import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/base_item.dart';
import '../models/text_note.dart';
import '../../../shared/models/sticky_note.dart';
import '../../../shared/models/clipboard_item.dart';
import '../../whiteboard/models/whiteboard_item.dart';
import '../services/block_transform_service.dart';
import '../../../core/services/pinned_notification_service.dart';
import '../services/wiki_link_service.dart';
import '../../../shared/providers/workspace_provider.dart';
import '../../../shared/widgets/color_swatch_picker.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_floating_dialog.dart';
import '../widgets/document_outline_sheet.dart';
import '../../../shared/widgets/ios_menu_button.dart';
import '../widgets/note_statistics_sheet.dart';
import '../widgets/slash_command_sheet.dart';
import '../widgets/frontmatter_properties_bar.dart';
import '../widgets/markdown_text_editing_controller.dart';
import '../widgets/rich_note_content_view.dart';
import '../widgets/smart_markdown_formatter.dart';
import '../widgets/wiki_link_components.dart';
import '../widgets/mermaid/mermaid_completion_bar.dart';
import '../widgets/mermaid_template_sheet.dart';
import '../widgets/editor_formatting_toolbar.dart';
import '../services/note_export_service.dart';
import '../services/note_template_service.dart';
import '../../graph/screens/knowledge_graph_screen.dart';
import '../../whiteboard/screens/whiteboard_canvas_screen.dart';

/// Full-featured Note Editor & Reader Screen (Phase 3 + Phase 1 Connected Specs).
/// Includes Reading/Editing mode switcher, bi-directional [[Wiki-Links]],
/// live ![[Whiteboard]] embeds, / Slash blocks, Turn-Into actions, and Backlinks.
class NoteEditorScreen extends StatefulWidget {
  final BaseWorkspaceItem item;
  final String? initialHeadingAnchor;
  final bool startInEditMode;

  const NoteEditorScreen({
    super.key,
    required this.item,
    this.initialHeadingAnchor,
    this.startInEditMode = false,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _titleController;
  late final MarkdownTextEditingController _contentController;
  final FocusNode _contentFocusNode = FocusNode();
  final TextEditingController _newTagController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _savedScrollRatio = 0.0;
  double _savedScrollOffset = 0.0;
  late String _paletteId;
  late List<String> _tags;
  String? _folderName;
  String? _parentId;
  String? _iconEmoji;

  bool _isEditingMode = true;
  bool _isAddingTag = false;
  final bool _autoSaveEnabled = true;
  bool _isSaving = false;
  bool _isNotificationPinned = false;
  Timer? _saveDebounce;

  int? _dismissedWikiTriggerOffset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PinnedNotificationService.isNotePinned(widget.item.id).then((pinned) {
      if (mounted) setState(() => _isNotificationPinned = pinned);
    });
    _titleController = TextEditingController(text: widget.item.title);
    final initialContent = widget.item is TextNote
        ? (widget.item as TextNote).content
        : (widget.item is StickyNote
            ? (widget.item as StickyNote).content
            : (widget.item is ClipboardItem ? (widget.item as ClipboardItem).clipText : ''));
    _paletteId = widget.item.paletteId;
    _contentController = MarkdownTextEditingController(
      text: initialContent,
      paletteId: _paletteId,
    );
    _isEditingMode = widget.startInEditMode ||
        (widget.initialHeadingAnchor == null && initialContent.trim().isEmpty);
    _tags = widget.item is TextNote ? List.from((widget.item as TextNote).tags) : [];
    _folderName = widget.item.folderName;
    _parentId = widget.item.parentId;
    _iconEmoji = widget.item.iconEmoji;

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        _savedScrollOffset = _scrollController.offset;
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          _savedScrollRatio = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
        }
      }
    });

    if (widget.initialHeadingAnchor != null && initialContent.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHeadingAnchor(widget.initialHeadingAnchor!);
      });
    }
  }

  void _scrollToHeadingAnchor(String anchor) {
    if (!_scrollController.hasClients) return;
    final text = _contentController.text;
    final lineIdx = WikiLinkService.findHeadingLineIndex(text, anchor);
    if (lineIdx == null) return;
    final totalLines = text.split('\n').length;
    if (totalLines <= 1) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final ratio = (lineIdx / totalLines).clamp(0.0, 1.0);
    _scrollController.animateTo(
      (maxScroll * ratio).clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  WorkspaceProvider? _workspace;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _workspace = context.read<WorkspaceProvider>();
  }

  BaseWorkspaceItem _buildUpdatedItem(WorkspaceProvider ws) {
    final latest = ws.getItemById(widget.item.id) ?? widget.item;
    final title = _titleController.text.trim();
    final content = _contentController.text;
    final paletteId = _paletteId;
    final tags = List<String>.from(_tags);

    if (latest is StickyNote) {
      return latest.copyWith(
        title: title.isEmpty ? 'Untitled Sticky' : title,
        content: content,
        paletteId: paletteId,
        folderName: _folderName,
        clearFolder: _folderName == null,
        parentId: _parentId,
        clearParent: _parentId == null,
        iconEmoji: _iconEmoji,
        clearIcon: _iconEmoji == null,
        updatedAt: DateTime.now(),
      );
    } else if (latest is ClipboardItem) {
      return latest.copyWith(
        title: title.isEmpty ? 'Untitled Clip' : title,
        clipText: content,
        paletteId: paletteId,
        folderName: _folderName,
        clearFolder: _folderName == null,
        parentId: _parentId,
        clearParent: _parentId == null,
        iconEmoji: _iconEmoji,
        clearIcon: _iconEmoji == null,
        updatedAt: DateTime.now(),
      );
    }
    final noteBase = latest is TextNote ? latest : (widget.item as TextNote);
    return noteBase.copyWith(
      title: title.isEmpty ? 'Untitled Note' : title,
      content: content,
      tags: tags,
      paletteId: paletteId,
      folderName: _folderName,
      clearFolder: _folderName == null,
      parentId: _parentId,
      clearParent: _parentId == null,
      iconEmoji: _iconEmoji,
      clearIcon: _iconEmoji == null,
      updatedAt: DateTime.now(),
      sourceApp: noteBase.sourceApp,
    );
  }

  bool get _isUntouchedEmptyDraft {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final isDefaultTitle = title.isEmpty ||
        title == 'Untitled Note' ||
        title == 'Untitled' ||
        title == 'Quick Sticky';
    return isDefaultTitle && content.isEmpty && _tags.isEmpty;
  }

  void _flushSave() {
    final ws = _workspace;
    if (ws == null) return;
    if (_isUntouchedEmptyDraft) return;
    final updated = _buildUpdatedItem(ws);
    ws.saveItem(updated);
    PinnedNotificationService.syncPinnedNoteIfActive(updated);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (_saveDebounce?.isActive ?? false) {
        _saveDebounce?.cancel();
        _flushSave();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_saveDebounce?.isActive ?? false) {
      _saveDebounce?.cancel();
      _flushSave();
    }
    _titleController.dispose();
    _contentController.dispose();
    _newTagController.dispose();
    _contentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleViewMode({int? targetLineIndex}) {
    if (_scrollController.hasClients) {
      _savedScrollOffset = _scrollController.offset;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        _savedScrollRatio = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
      }
    }

    final targetIsEditing = !_isEditingMode;

    if (targetIsEditing) {
      if (targetLineIndex != null) {
        final lines = _contentController.text.split('\n');
        int charOffset = 0;
        for (int i = 0; i < targetLineIndex && i < lines.length; i++) {
          charOffset += lines[i].length + 1;
        }
        _contentController.selection = TextSelection.collapsed(
          offset: charOffset.clamp(0, _contentController.text.length),
        );
      } else if (_savedScrollRatio > 0 && _contentController.text.isNotEmpty) {
        final approxOffset = (_savedScrollRatio * _contentController.text.length).floor();
        _contentController.selection = TextSelection.collapsed(
          offset: approxOffset.clamp(0, _contentController.text.length),
        );
      }

      setState(() => _isEditingMode = true);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          if (maxScroll > 0 && _savedScrollRatio > 0) {
            final targetOffset = (_savedScrollRatio * maxScroll).clamp(0.0, maxScroll);
            _scrollController.jumpTo(targetOffset);
          } else if (_savedScrollOffset <= maxScroll) {
            _scrollController.jumpTo(_savedScrollOffset);
          }
        }
        _contentFocusNode.requestFocus();
      });
    } else {
      setState(() => _isEditingMode = false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          if (maxScroll > 0 && _savedScrollRatio > 0) {
            final targetOffset = (_savedScrollRatio * maxScroll).clamp(0.0, maxScroll);
            _scrollController.jumpTo(targetOffset);
          } else if (_savedScrollOffset <= maxScroll) {
            _scrollController.jumpTo(_savedScrollOffset);
          }
        }
      });
    }
  }

  void _handleBackPress() {
    HapticFeedback.lightImpact();
    // Discard untouched empty draft on Back (`05-information-architecture.md` §2.2 D2)
    if (_isUntouchedEmptyDraft) {
      _saveDebounce?.cancel();
      FocusScope.of(context).unfocus();
      _workspace?.deletePermanently(widget.item.id);
      Navigator.of(context).pop();
      return;
    }
    if (_isEditingMode) {
      FocusScope.of(context).unfocus();
      _flushSave();
      setState(() => _isEditingMode = false);
      return;
    }
    FocusScope.of(context).unfocus();
    _flushSave();
    Navigator.of(context).pop();
  }

  void _jumpToLineIndex(int lineIndex) {
    final text = _contentController.text;
    final lines = text.split('\n');
    if (lines.isEmpty) return;
    final clampedLine = lineIndex.clamp(0, lines.length - 1);

    if (_isEditingMode) {
      int offset = 0;
      for (int i = 0; i < clampedLine; i++) {
        offset += lines[i].length + 1;
      }
      _contentController.selection = TextSelection.collapsed(
        offset: offset.clamp(0, text.length),
      );
      _contentFocusNode.requestFocus();
    }

    if (_scrollController.hasClients) {
      final ratio = lines.length <= 1 ? 0.0 : (clampedLine / lines.length).clamp(0.0, 1.0);
      final target = ratio * _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showDocumentOutlineSheet() {
    int? currentLine;
    if (_isEditingMode && _contentController.selection.isValid) {
      final before = _contentController.text.substring(
        0,
        _contentController.selection.baseOffset.clamp(0, _contentController.text.length),
      );
      currentLine = '\n'.allMatches(before).length;
    } else if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      final ratio =
          (_scrollController.offset / _scrollController.position.maxScrollExtent)
              .clamp(0.0, 1.0);
      final totalLines = _contentController.text.split('\n').length;
      currentLine = (ratio * totalLines).round();
    }

    DocumentOutlineSheet.show(
      context,
      noteTitle: _titleController.text.trim(),
      content: _contentController.text,
      paletteId: _paletteId,
      currentLineIndex: currentLine,
      onSelectHeading: (h) => _jumpToLineIndex(h.lineIndex),
    );
  }

  bool _isCursorInsideMermaidBlock() {
    final text = _contentController.text;
    final sel = _contentController.selection;
    if (!sel.isValid) return false;
    final cursor = sel.baseOffset.clamp(0, text.length);
    final textBefore = text.substring(0, cursor);
    final openMatches = RegExp(r'```(?:mermaid|graph|flowchart|pie|sequence|timeline)').allMatches(textBefore).length;
    final closeMatches = RegExp(r'```').allMatches(textBefore).length - openMatches;
    return openMatches > closeMatches;
  }

  void _insertMermaidSnippet(String snippet) {
    final text = _contentController.text;
    final sel = _contentController.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;

    final before = text.substring(0, start);
    final after = text.substring(end);

    final newText = '$before$snippet$after';
    final newCursor = before.length + snippet.length;

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _saveNote();
    _contentFocusNode.requestFocus();
  }

  void _submitNewTag() {
    final newTag = _newTagController.text.trim().replaceAll('#', '');
    if (newTag.isNotEmpty && !_tags.contains(newTag)) {
      HapticFeedback.lightImpact();
      setState(() {
        _tags.add(newTag);
        _newTagController.clear();
        _isAddingTag = false;
      });
      _saveNote();
    } else {
      setState(() {
        _newTagController.clear();
        _isAddingTag = false;
      });
    }
  }

  void _onTextChanged() {
    setState(() {});
    if (_autoSaveEnabled) {
      // Debounce: wait 600ms after last keystroke before writing to disk
      _saveDebounce?.cancel();
      _saveDebounce = Timer(const Duration(milliseconds: 600), _saveNote);
    }
  }

  void _saveNote() async {
    if (!mounted) return;
    _isSaving = true;
    final workspace = context.read<WorkspaceProvider>();
    final updated = _buildUpdatedItem(workspace);

    await workspace.saveItem(updated);
    await PinnedNotificationService.syncPinnedNoteIfActive(updated);
    if (!mounted) return;
    setState(() => _isSaving = false);
  }

  void _showEmojiPickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const emojis = [
      '📝', '📐', '🎨', '⚖️', '🚀', '💡', '🧠', '☀️',
      '🔥', '✅', '📌', '🗂️', '🧪', '🛠️', '🌟', '🔒',
    ];
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Note Icon',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (_iconEmoji != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _iconEmoji = null);
                        _saveNote();
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Remove'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: emojis.map((e) {
                  final selected = _iconEmoji == e;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _iconEmoji = e);
                      _saveNote();
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.pastelLimeLight
                            : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF191A23)
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: selected ? 1.6 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _showMoveToFolderSheet() async {
    final workspace = context.read<WorkspaceProvider>();
    final chosen = await AppBottomSheet.show<String?>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Move Note to Folder',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(LucideIcons.folderX, size: 19),
                title: const Text('No Folder (All Notes)'),
                trailing: _folderName == null
                    ? const TackIcon(TackIcons.check, size: 16)
                    : null,
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                onTap: () => Navigator.of(ctx).pop(''),
              ),
              ...workspace.userFolders.map(
                (f) => ListTile(
                  leading: const Icon(LucideIcons.folder, size: 19),
                  title: Text(f),
                  trailing: _folderName == f
                      ? const TackIcon(TackIcons.check, size: 16)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                  onTap: () => Navigator.of(ctx).pop(f),
                ),
              ),
            ],
          ),
        ),
      );
    if (chosen != null && mounted) {
      setState(() => _folderName = chosen.isEmpty ? null : chosen);
      _saveNote();
    }
  }

  Future<void> _handleCreateSubNote() async {
    HapticFeedback.mediumImpact();
    _flushSave();
    final workspace = context.read<WorkspaceProvider>();
    final child = await workspace.createQuickItem(
      title: 'Untitled Sub-note',
      type: ItemType.note,
      paletteId: _paletteId,
      parentId: widget.item.id,
      folderName: _folderName,
      iconEmoji: '📄',
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(item: child)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _handleSaveAsTemplate() async {
    final initial = _titleController.text.trim().isEmpty
        ? 'Custom Template'
        : _titleController.text.trim();
    final savedName = await AppFloatingDialog.prompt(
      context: context,
      title: 'Save as Template',
      hintText: 'e.g. Sprint Retro, Feature Spec…',
      initialValue: initial,
      confirmLabel: 'Save Template',
      icon: TackIcons.notes,
    );
    if (savedName != null && savedName.isNotEmpty) {
      await NoteTemplateService.saveCustomTemplate(
        name: savedName,
        bodyTemplate: _contentController.text,
        paletteId: _paletteId,
        iconEmoji: _iconEmoji ?? '✨',
        tags: _tags,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "$savedName" to Templates Gallery'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeTag(String tag) {
    HapticFeedback.selectionClick();
    setState(() => _tags.remove(tag));
    _saveNote();
  }

  void _applyFormatting(String action) {
    final text = _contentController.text;
    TextSelection selection = _contentController.selection;

    if (!selection.isValid || selection.start < 0) {
      selection = TextSelection.collapsed(offset: text.length);
    }

    final selectedText = selection.textInside(text);
    final before = selection.textBefore(text);
    final after = selection.textAfter(text);
    String newText = text;
    int newCursorStart = selection.start;
    int newCursorEnd = selection.end;

    switch (action) {
      case 'slash':
        _openSlashAndBlockSheet(startOnTurnIntoTab: false);
        return;
      case 'turn_into':
        _openSlashAndBlockSheet(startOnTurnIntoTab: true);
        return;
      case 'wikilink':
        if (selectedText.isNotEmpty) {
          newText = '$before[[$selectedText]]$after';
          newCursorStart = before.length + 2 + selectedText.length + 2;
          newCursorEnd = newCursorStart;
        } else {
          newText = '$before[[$after';
          newCursorStart = before.length + 2;
          newCursorEnd = newCursorStart;
          _dismissedWikiTriggerOffset = null;
        }
        break;
      case 'h1':
        final prefixH1 = (before.isEmpty || before.endsWith('\n')) ? '# ' : '\n# ';
        newText = '$before$prefixH1$selectedText$after';
        newCursorStart = before.length + prefixH1.length + selectedText.length;
        newCursorEnd = newCursorStart;
        break;
      case 'h2':
        final prefixH2 = (before.isEmpty || before.endsWith('\n')) ? '## ' : '\n## ';
        newText = '$before$prefixH2$selectedText$after';
        newCursorStart = before.length + prefixH2.length + selectedText.length;
        newCursorEnd = newCursorStart;
        break;
      case 'highlight':
        if (selectedText.isNotEmpty) {
          newText = '$before==$selectedText==$after';
          newCursorStart = before.length + 2;
          newCursorEnd = newCursorStart + selectedText.length;
        } else {
          newText = '$before====$after';
          newCursorStart = before.length + 2;
          newCursorEnd = newCursorStart;
        }
        break;
      case 'bold':
        if (selectedText.isNotEmpty) {
          newText = '$before**$selectedText**$after';
          newCursorStart = before.length + 2;
          newCursorEnd = newCursorStart + selectedText.length;
        } else {
          newText = '$before****$after';
          newCursorStart = before.length + 2;
          newCursorEnd = newCursorStart;
        }
        break;
      case 'italic':
        if (selectedText.isNotEmpty) {
          newText = '$before*$selectedText*$after';
          newCursorStart = before.length + 1;
          newCursorEnd = newCursorStart + selectedText.length;
        } else {
          newText = '$before**$after';
          newCursorStart = before.length + 1;
          newCursorEnd = newCursorStart;
        }
        break;
      case 'underline':
        if (selectedText.isNotEmpty) {
          newText = '${before}__${selectedText}__$after';
          newCursorStart = before.length + 2;
          newCursorEnd = newCursorStart + selectedText.length;
        } else {
          newText = '${before}____$after';
          newCursorStart = before.length + 2;
          newCursorEnd = newCursorStart;
        }
        break;
      case 'strikethrough':
        if (selectedText.isNotEmpty) {
          newText = '$before~~$selectedText~~$after';
          newCursorStart = before.length + 2;
          newCursorEnd = newCursorStart + selectedText.length;
        } else {
          newText = '$before~~~~$after';
          newCursorStart = before.length + 2;
          newCursorEnd = newCursorStart;
        }
        break;
      case 'bullet':
        // Use standard Markdown `- ` so exported notes render correctly in all Markdown renderers
        final prefix = (before.isEmpty || before.endsWith('\n')) ? '- ' : '\n- ';
        newText = '$before$prefix$selectedText$after';
        newCursorStart = before.length + prefix.length + selectedText.length;
        newCursorEnd = newCursorStart;
        break;
      case 'numbered':
        final prefix = (before.isEmpty || before.endsWith('\n')) ? '1. ' : '\n1. ';
        newText = '$before$prefix$selectedText$after';
        newCursorStart = before.length + prefix.length + selectedText.length;
        newCursorEnd = newCursorStart;
        break;
      case 'checkbox':
        final prefix = (before.isEmpty || before.endsWith('\n')) ? '[ ] ' : '\n[ ] ';
        newText = '$before$prefix$selectedText$after';
        newCursorStart = before.length + prefix.length + selectedText.length;
        newCursorEnd = newCursorStart;
        break;
      case 'quote':
        final prefix = (before.isEmpty || before.endsWith('\n')) ? '> ' : '\n> ';
        newText = '$before$prefix$selectedText$after';
        newCursorStart = before.length + prefix.length + selectedText.length;
        newCursorEnd = newCursorStart;
        break;
      case 'link':
        if (selectedText.isNotEmpty) {
          newText = '$before[$selectedText](https://)$after';
          newCursorStart = before.length + selectedText.length + 3;
          newCursorEnd = newCursorStart + 8;
        } else {
          newText = '$before[title](https://)$after';
          newCursorStart = before.length + 1;
          newCursorEnd = before.length + 6;
        }
        break;
      case 'image':
        _showImageSourcePicker();
        return;
      case 'table':
        final prefixTable = (before.isEmpty || before.endsWith('\n')) ? '' : '\n\n';
        const tableTemplate = '| Column 1 | Column 2 | Column 3 |\n| :--- | :---: | ---: |\n| Row 1 | Data | 100 |\n| Row 2 | Info | 250 |\n';
        newText = '$before$prefixTable$tableTemplate$after';
        newCursorStart = before.length + prefixTable.length + tableTemplate.length;
        newCursorEnd = newCursorStart;
        break;
      case 'diagram':
        _showDiagramTemplatePicker();
        return;
      case 'alert':
        _showAlertTemplatePicker();
        return;
      case 'timestamp':
        final now = DateTime.now();
        final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
        final minute = now.minute.toString().padLeft(2, '0');
        final period = now.hour >= 12 ? 'PM' : 'AM';
        final dateStr = DateFormatter.formatOrdinalDate(now);
        final stamp = '[$dateStr, $hour:$minute $period] ';
        newText = '$before$stamp$selectedText$after';
        newCursorStart = before.length + stamp.length + selectedText.length;
        newCursorEnd = newCursorStart;
        break;
    }

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: newCursorStart.clamp(0, newText.length),
        extentOffset: newCursorEnd.clamp(0, newText.length),
      ),
    );

    _contentFocusNode.requestFocus();
  }

  void _insertImageMarkdown(String pathOrUrl, {String alt = 'Image'}) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final before = text.substring(0, start);
    final after = text.substring(end);

    final prefix = (before.isEmpty || before.endsWith('\n')) ? '' : '\n';
    final suffix = (after.isEmpty || after.startsWith('\n')) ? '' : '\n';
    final imageMarkdown = '$prefix![$alt]($pathOrUrl)$suffix';

    final newText = '$before$imageMarkdown$after';
    final newCursor = before.length + imageMarkdown.length;

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _saveNote();
    _contentFocusNode.requestFocus();
  }

  Future<void> _handleInsertedContent(KeyboardInsertedContent insertedContent) async {
    try {
      final bytes = insertedContent.data;
      if (bytes != null && bytes.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${appDir.path}/note_images');
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }
        final ext = insertedContent.mimeType.contains('png') ? 'png' : 'jpg';
        final file = File('${imagesDir.path}/pasted_${DateTime.now().millisecondsSinceEpoch}.$ext');
        await file.writeAsBytes(bytes);
        _insertImageMarkdown(file.path, alt: 'Pasted Image');
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Error inserting clipboard content: $e');
    }
  }

  void _insertAtCursor(String insertion) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final before = text.substring(0, start);
    final after = text.substring(end);

    final prefix = (before.isEmpty || before.endsWith('\n')) ? '' : '\n\n';
    final suffix = (after.isEmpty || after.startsWith('\n')) ? '' : '\n';
    final fullText = '$prefix$insertion$suffix';

    final newText = '$before$fullText$after';
    final newCursor = before.length + fullText.length;

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _saveNote();
    _contentFocusNode.requestFocus();
  }

  void _showDiagramTemplatePicker() {
    MermaidTemplateSheet.show(context, onSelectTemplate: _insertAtCursor);
  }

  void _showAlertTemplatePicker() {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Insert Callout Alert',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(LucideIcons.info, size: 22, color: Color(0xFF0284C7)),
                title: const Text('Note Alert'),
                subtitle: const Text('> [!NOTE] Informational notice'),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _insertAtCursor('> [!NOTE]\n> Write your important context or informational notice here.\n');
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.lightbulb, size: 22, color: Color(0xFF059669)),
                title: const Text('Tip Alert'),
                subtitle: const Text('> [!TIP] Helpful recommendation'),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _insertAtCursor('> [!TIP]\n> Pro-tip: Organize your notes using tags or custom pastel palettes.\n');
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.star, size: 22, color: Color(0xFF7C3AED)),
                title: const Text('Important Alert'),
                subtitle: const Text('> [!IMPORTANT] Crucial requirement'),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _insertAtCursor('> [!IMPORTANT]\n> Essential requirement or critical step to keep in mind.\n');
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.alertTriangle, size: 22, color: Color(0xFFD97706)),
                title: const Text('Warning Alert'),
                subtitle: const Text('> [!WARNING] Potential pitfall or caution'),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _insertAtCursor('> [!WARNING]\n> Warning: Changes made here cannot be undone once deleted.\n');
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.shieldAlert, size: 22, color: Color(0xFFDC2626)),
                title: const Text('Caution Alert'),
                subtitle: const Text('> [!CAUTION] High-risk action notice'),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _insertAtCursor('> [!CAUTION]\n> High-risk action: Proceed with caution.\n');
                },
              ),
            ],
          ),
        ),
      );
  }

  void _showImageSourcePicker() {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Insert Image',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const TackIcon(TackIcons.photo, size: 22, color: AppColors.accentCyan),
                title: const Text('Choose from Gallery'),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final imagesDir = Directory('${appDir.path}/note_images');
                    if (!await imagesDir.exists()) {
                      await imagesDir.create(recursive: true);
                    }
                    final ext = picked.path.split('.').lastOrNull ?? 'jpg';
                    final savedFile = File('${imagesDir.path}/img_${DateTime.now().millisecondsSinceEpoch}.$ext');
                    await File(picked.path).copy(savedFile.path);
                    _insertImageMarkdown(savedFile.path, alt: 'Gallery Image');
                  }
                },
              ),
              ListTile(
                leading: const TackIcon(TackIcons.camera, size: 22, color: AppColors.accentOrange),
                title: const Text('Take Photo'),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final imagesDir = Directory('${appDir.path}/note_images');
                    if (!await imagesDir.exists()) {
                      await imagesDir.create(recursive: true);
                    }
                    final ext = picked.path.split('.').lastOrNull ?? 'jpg';
                    final savedFile = File('${imagesDir.path}/photo_${DateTime.now().millisecondsSinceEpoch}.$ext');
                    await File(picked.path).copy(savedFile.path);
                    _insertImageMarkdown(savedFile.path, alt: 'Camera Photo');
                  }
                },
              ),
              ListTile(
                leading: const TackIcon(TackIcons.link, size: 22, color: AppColors.accentAmber),
                title: const Text('Insert Image URL'),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showImageUrlDialog();
                },
              ),
            ],
          ),
        ),
      );
  }

  void _showImageUrlDialog() async {
    final url = await AppFloatingDialog.prompt(
      context: context,
      title: 'Image Web Link',
      hintText: 'https://example.com/image.png',
      confirmLabel: 'Insert',
      icon: LucideIcons.image,
    );
    if (url != null && url.isNotEmpty) {
      _insertImageMarkdown(url, alt: 'Web Image');
    }
  }

  void _showNoteStatisticsSheet() {
    NoteStatisticsSheet.show(context, content: _contentController.text);
  }

  void _showColorPicker() {
    AppBottomSheet.show(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Note Background Theme',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              ColorSwatchPicker(
                selectedPaletteId: _paletteId,
                onPaletteSelected: (id) {
                  setState(() {
                    _paletteId = id;
                    _contentController.paletteId = id;
                  });
                  _saveNote();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  void _showShareExportSheet() {
    final title = _titleController.text;
    final content = _contentController.text;

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export & Share Note',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const TackIcon(TackIcons.copy, size: 22),
              title: const Text('Copy Formatted Markdown'),
              onTap: () async {
                await NoteExportService.copyMarkdown(title: title, content: content, tags: _tags);
                if (!ctx.mounted || !mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Markdown copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const TackIcon(TackIcons.notes, size: 22),
              title: const Text('Copy Plain Text'),
              onTap: () async {
                await NoteExportService.copyPlainText(title: title, content: content);
                if (!ctx.mounted || !mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Plain text copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const TackIcon(TackIcons.photo, size: 22),
              title: Text(widget.item is StickyNote ? 'Export Sticky as Image (PNG)' : 'Export as Image (PNG)'),
              subtitle: const Text('High-resolution shareable card image'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final isDark = Theme.of(context).brightness == Brightness.dark;
                await NoteExportService.exportImage(
                  title: title,
                  content: content,
                  tags: _tags,
                  paletteId: _paletteId,
                  isSticky: widget.item is StickyNote,
                  isDark: isDark,
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const TackIcon(TackIcons.exportData, size: 22),
              title: const Text('Export as PDF Document'),
              subtitle: const Text('Formatted stationery PDF layout'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await NoteExportService.exportPdf(
                  title: title,
                  content: content,
                  tags: _tags,
                  paletteId: _paletteId,
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const TackIcon(TackIcons.tag, size: 22),
              title: const Text('Print / Save PDF'),
              subtitle: const Text('Native Android Print Preview'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await NoteExportService.printPdf(
                  title: title,
                  content: content,
                  tags: _tags,
                  paletteId: _paletteId,
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const TackIcon(TackIcons.share, size: 22),
              title: const Text('Share Note'),
              subtitle: const Text('System share sheet'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await NoteExportService.shareNote(
                  title: title,
                  content: content,
                  tags: _tags,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= Phase 1: Slash Commands, Turn Into, Wiki-Links & Backlinks =================

  void _openSlashAndBlockSheet({required bool startOnTurnIntoTab}) {
    final sel = _contentController.selection;
    final cursor = sel.isValid ? sel.baseOffset : _contentController.text.length;
    final currentKind = BlockTransformService.detectBlockKind(_contentController.text, cursor);

    SlashAndBlockActionsSheet.show(
      context,
      currentBlockKind: currentKind,
      startOnTurnIntoTab: startOnTurnIntoTab,
      onInsertCommand: (cmd) => _executeSlashCommand(cmd),
      onTurnInto: (kind) {
        _contentController.value = BlockTransformService.turnInto(_contentController.value, kind);
        _saveNote();
        _contentFocusNode.requestFocus();
      },
      onMoveUp: () {
        _contentController.value = BlockTransformService.moveBlockUp(_contentController.value);
        _saveNote();
      },
      onMoveDown: () {
        _contentController.value = BlockTransformService.moveBlockDown(_contentController.value);
        _saveNote();
      },
      onDuplicateBlock: () {
        _contentController.value = BlockTransformService.duplicateBlock(_contentController.value);
        _saveNote();
        _contentFocusNode.requestFocus();
      },
    );
  }

  void _executeSlashCommand(SlashCommandItem cmd, {ActiveSlashTrigger? slashTrigger}) {
    if (cmd.id == 'diagram') {
      if (slashTrigger != null) {
        _removeSlashToken(slashTrigger);
      }
      _showDiagramTemplatePicker();
      return;
    }

    if (cmd.id == 'board') {
      if (slashTrigger != null) {
        _removeSlashToken(slashTrigger);
      }
      _showWhiteboardEmbedPicker();
      return;
    }

    final snippet = cmd.markdownSnippet ?? '';
    if (snippet.isEmpty) return;

    final text = _contentController.text;
    int replaceStart;
    int replaceEnd;

    if (slashTrigger != null) {
      replaceStart = slashTrigger.slashOffset.clamp(0, text.length);
      replaceEnd = slashTrigger.cursorOffset.clamp(replaceStart, text.length);
    } else {
      final sel = _contentController.selection;
      replaceStart = sel.isValid ? sel.start.clamp(0, text.length) : text.length;
      replaceEnd = sel.isValid ? sel.end.clamp(replaceStart, text.length) : text.length;
    }

    final before = text.substring(0, replaceStart);
    final after = text.substring(replaceEnd);

    final needsLeadingNewline = slashTrigger == null &&
        cmd.id != 'link' &&
        before.isNotEmpty &&
        !before.endsWith('\n');
    final effectiveSnippet = needsLeadingNewline ? '\n$snippet' : snippet;

    final newText = '$before$effectiveSnippet$after';
    int newCursor = before.length + effectiveSnippet.length;
    if (cmd.id == 'code' && effectiveSnippet.endsWith('\n```')) {
      newCursor -= 4; // Place cursor inside fenced code block
    }
    if (cmd.id == 'link') {
      _dismissedWikiTriggerOffset = null;
    }

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor.clamp(0, newText.length)),
    );
    _saveNote();
    _contentFocusNode.requestFocus();
  }

  void _removeSlashToken(ActiveSlashTrigger trigger) {
    final text = _contentController.text;
    final start = trigger.slashOffset.clamp(0, text.length);
    final end = trigger.cursorOffset.clamp(start, text.length);
    final newText = text.replaceRange(start, end, '');
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start),
    );
  }

  void _showWhiteboardEmbedPicker() {
    final workspace = context.read<WorkspaceProvider>();
    final boards = workspace.rawItems.whereType<WhiteboardCanvasItem>().where((b) => !b.isTrash).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Embed Whiteboard Canvas',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
              const SizedBox(height: 4),
              Text(
                'Inserts a live interactive preview right inside this note.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: TackIcon(TackIcons.plus, size: 18, color: AppColors.accentCyan),
                  ),
                ),
                title: const Text(
                  'Create & Embed New Whiteboard',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final baseTitle = _titleController.text.trim();
                  final boardTitle = baseTitle.isEmpty ? 'Spec Flow' : '$baseTitle (Flow)';
                  final created = await workspace.createQuickItem(
                    title: boardTitle,
                    type: ItemType.whiteboard,
                    paletteId: 'cyan',
                  );
                  _insertAtCursor('![[${created.title}]]');
                },
              ),
              if (boards.isNotEmpty) const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: boards.length,
                  itemBuilder: (_, idx) {
                    final board = boards[idx];
                    return ListTile(
                      leading: TackIcon(
                        TackIcons.whiteboardSvg,
                        size: 20,
                        color: AppColors.getPaletteById(board.paletteId).resolveAccentColor(isDark),
                      ),
                      title: Text(
                        board.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(board.getSummary()),
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _insertAtCursor('![[${board.title}]]');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _completeWikiTrigger(ActiveWikiTrigger trigger, String completionToken) {
    final text = _contentController.text;
    final start = trigger.triggerStart.clamp(0, text.length);
    final end = trigger.cursorOffset.clamp(start, text.length);
    final newText = text.replaceRange(start, end, completionToken);
    final newCursor = (start + completionToken.length).clamp(0, newText.length);

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _dismissedWikiTriggerOffset = null;
    _saveNote();
    _contentFocusNode.requestFocus();
  }

  Future<void> _handleWikiLinkTap(ParsedWikiLink link) async {
    _flushSave();
    final workspace = context.read<WorkspaceProvider>();
    final resolved = WikiLinkService.resolveTarget(link.target, workspace.rawItems);

    if (resolved != null) {
      if (!mounted) return;
      if (resolved is WhiteboardCanvasItem) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WhiteboardCanvasScreen(
              item: resolved,
              initialFocusNodeId: link.anchor,
            ),
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NoteEditorScreen(
              item: resolved,
              initialHeadingAnchor: link.anchor,
            ),
          ),
        );
      }
      if (mounted) setState(() {});
      return;
    }

    // Create & open new linked note on 1 tap
    final created = await workspace.createQuickItem(
      title: link.target,
      type: ItemType.note,
      paletteId: _paletteId,
      content: '',
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(item: created)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _handleConvertUnlinkedMention(BacklinkEntry entry) async {
    final offset = entry.unlinkedMatchOffset;
    final length = entry.unlinkedMatchLength;
    if (offset == null || length == null) return;

    final workspace = context.read<WorkspaceProvider>();
    final source = workspace.getItemById(entry.sourceItem.id) ?? entry.sourceItem;
    final raw = WikiLinkService.contentOfItem(source);
    if (offset < 0 || offset + length > raw.length) return;

    final targetTitle = _titleController.text.trim();
    if (targetTitle.isEmpty) return;

    final updatedContent = raw.replaceRange(offset, offset + length, '[[$targetTitle]]');
    BaseWorkspaceItem? updatedItem;
    if (source is TextNote) {
      updatedItem = source.copyWith(content: updatedContent, updatedAt: DateTime.now());
    } else if (source is StickyNote) {
      updatedItem = source.copyWith(content: updatedContent, updatedAt: DateTime.now());
    }
    if (updatedItem != null) {
      await workspace.saveItem(updatedItem);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.watch<WorkspaceProvider>();
    final palette = AppColors.getPaletteById(_paletteId);

    final tokens = context.tokens;
    final backgroundColor = tokens.canvasPrimary;

    final content = _contentController.text;
    final letterCount = content.replaceAll(RegExp(r'\s'), '').length;
    final wordCount = content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;
    final readTime = ((wordCount / 180).ceil()).clamp(1, 60);

    final totalChecklists = RegExp(r'\[[ xX]\]').allMatches(content).length;
    final completedChecklists = RegExp(r'\[[xX]\]').allMatches(content).length;
    final allChecklistsCompleted = totalChecklists > 0 && completedChecklists == totalChecklists;

    final sel = _contentController.selection;
    final cursorOffset = sel.isValid ? sel.baseOffset : -1;
    final activeWikiTrigger = (_isEditingMode && cursorOffset >= 0)
        ? WikiLinkService.detectActiveWikiTrigger(content, cursorOffset)
        : null;
    if (activeWikiTrigger == null && _dismissedWikiTriggerOffset != null) {
      _dismissedWikiTriggerOffset = null;
    }
    final showWikiBar = activeWikiTrigger != null &&
        _dismissedWikiTriggerOffset != activeWikiTrigger.triggerStart;
    final activeSlashTrigger = (_isEditingMode && !showWikiBar && cursorOffset >= 0)
        ? WikiLinkService.detectActiveSlashTrigger(content, cursorOffset)
        : null;

    final currentSnapshot = (widget.item is TextNote)
        ? (widget.item as TextNote).copyWith(
            title: _titleController.text.trim().isEmpty
                ? widget.item.title
                : _titleController.text.trim(),
            content: content,
            folderName: _folderName,
            clearFolder: _folderName == null,
            parentId: _parentId,
            clearParent: _parentId == null,
            iconEmoji: _iconEmoji,
            clearIcon: _iconEmoji == null,
          )
        : widget.item.copyWith(
            title: _titleController.text.trim().isEmpty
                ? widget.item.title
                : _titleController.text.trim(),
            folderName: _folderName,
            clearFolder: _folderName == null,
            parentId: _parentId,
            clearParent: _parentId == null,
            iconEmoji: _iconEmoji,
            clearIcon: _iconEmoji == null,
          );
    final breadcrumbs = workspace.getBreadcrumbChain(currentSnapshot);
    final childItems = workspace.getChildItems(widget.item.id);
    final backlinks = WikiLinkService.computeBacklinks(
      currentItem: currentSnapshot,
      allItems: workspace.rawItems,
    );
    final hasHeadings = WikiLinkService.extractHeadings(content).isNotEmpty;

    return PopScope(
      canPop: !_isEditingMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _flushSave();
          return;
        }
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: false,
          titleSpacing: AppSpacing.md,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const TackIcon(TackIcons.back, size: 22),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: _handleBackPress,
                tooltip: 'Back',
              ),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white.withValues(alpha: 0.9),
                  borderRadius: AppSpacing.roundedPill,
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TackIcon(
                      _isSaving ? TackIcons.saving : TackIcons.checkCircle,
                      size: 14,
                      color: _isSaving ? AppColors.accentAmber : AppColors.success,
                      style: _isSaving ? HeroIconStyle.outline : HeroIconStyle.solid,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _isSaving ? 'Saving...' : 'Saved',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (hasHeadings)
            IconButton(
              icon: Icon(
                LucideIcons.listTree,
                size: 19,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              tooltip: 'Document Outline',
              onPressed: () {
                HapticFeedback.selectionClick();
                _showDocumentOutlineSheet();
              },
            ),

          // Edit / Read View Mode Switcher
          IconButton(
            icon: TackIcon(
              _isEditingMode ? TackIcons.eyeSvg : TackIcons.editSvg,
              size: 20,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            tooltip: _isEditingMode ? 'Reader Mode' : 'Edit Note',
            onPressed: () {
              HapticFeedback.selectionClick();
              _toggleViewMode();
            },
          ),

          // iOS-Style Overflow Menu (Palette, Favorite, Graph, Folder, Template, Share, Trash)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IosThreeDotMenu<String>(
              size: 36,
              icon: TackIcons.more,
              iconColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              onSelected: (val) async {
                if (val == 'palette') {
                  HapticFeedback.lightImpact();
                  _showColorPicker();
                } else if (val == 'favorite') {
                  workspace.toggleFavorite(widget.item.id);
                  setState(() {});
                } else if (val == 'local_graph') {
                  _flushSave();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => KnowledgeGraphScreen(focusItemId: widget.item.id),
                    ),
                  );
                } else if (val == 'move_folder') {
                  await _showMoveToFolderSheet();
                } else if (val == 'save_template') {
                  await _handleSaveAsTemplate();
                } else if (val == 'duplicate') {
                  HapticFeedback.lightImpact();
                  workspace.duplicateItem(widget.item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note duplicated!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (val == 'pin_notification') {
                  HapticFeedback.lightImpact();
                  _flushSave();
                  final messenger = ScaffoldMessenger.of(context);
                  final latest = workspace.getItemByIdSync(widget.item.id) ??
                      _buildUpdatedItem(workspace);
                  if (_isNotificationPinned) {
                    await PinnedNotificationService.unpinNote(latest.id);
                    if (mounted) {
                      setState(() => _isNotificationPinned = false);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Unpinned from notification bar'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    final ok = await PinnedNotificationService.pinNote(latest);
                    if (mounted) {
                      setState(() => _isNotificationPinned = ok);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Pinned to notification bar'
                                : 'Enable notifications to pin notes',
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                } else if (val == 'share') {
                  _showShareExportSheet();
                } else if (val == 'trash') {
                  workspace.moveToTrash(widget.item.id);
                  Navigator.of(context).pop();
                }
              },
              items: [
                const IosMenuItem(
                  value: 'palette',
                  title: 'Color Palette',
                  icon: TackIcons.palette,
                ),
                IosMenuItem(
                  value: 'favorite',
                  title: widget.item.isFavorite ? 'Unfavorite' : 'Favorite',
                  icon: TackIcons.star,
                  iconStyle: widget.item.isFavorite ? HeroIconStyle.solid : HeroIconStyle.outline,
                  iconColor: AppColors.accentAmber,
                ),
                const IosMenuItem(
                  value: 'local_graph',
                  title: 'Local Graph',
                  icon: LucideIcons.network,
                  iconColor: AppColors.accentCyan,
                ),
                const IosMenuItem(
                  value: 'move_folder',
                  title: 'Move to Folder',
                  icon: LucideIcons.folder,
                ),
                if (widget.item is TextNote)
                  const IosMenuItem(
                    value: 'save_template',
                    title: 'Save as Template',
                    icon: LucideIcons.sparkles,
                  ),
                const IosMenuItem(
                  value: 'duplicate',
                  title: 'Duplicate Note',
                  icon: TackIcons.copy,
                ),
                if (widget.item is TextNote)
                  IosMenuItem(
                    value: 'pin_notification',
                    title: _isNotificationPinned
                        ? 'Unpin Notification'
                        : 'Pin to Notification',
                    icon: TackIcons.notification,
                  ),
                const IosMenuItem(
                  value: 'share',
                  title: 'Export & Share',
                  icon: TackIcons.share,
                ),
                const IosMenuItem(
                  value: 'trash',
                  title: 'Delete Note',
                  icon: TackIcons.trash,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scrollable Note Document (constrained to 720dp reading measure on wide screens)
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.readMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Breadcrumbs, Folder & Hierarchy Bar
                    if (_folderName != null ||
                        breadcrumbs.isNotEmpty ||
                        _isEditingMode ||
                        _iconEmoji != null)
                      _buildBreadcrumbAndHierarchyBar(
                        breadcrumbs: breadcrumbs,
                        isDark: isDark,
                        palette: palette,
                      ),

                    // Date stamp above title (Screenshot 4 editorial style)
                    Text(
                      DateFormatter.formatOrdinalDate(widget.item.updatedAt),
                      style: AppTypography.cardDateStyle(
                        color: tokens.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Large Note Title (with optional Emoji Icon)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_iconEmoji != null && _iconEmoji!.isNotEmpty) ...[
                          GestureDetector(
                            onTap: _showEmojiPickerSheet,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
                                _iconEmoji!,
                                style: const TextStyle(fontSize: 30),
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: _isEditingMode
                              ? TextField(
                                  controller: _titleController,
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.7,
                                    height: 1.18,
                                  ),
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    hintText: 'Note title...',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                )
                              : Text(
                                  _titleController.text.isEmpty
                                      ? 'Untitled Note'
                                      : _titleController.text,
                                  style: AppTypography.display(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Screenshot 4 ("Design Ideas") Minimalist Metadata Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_folderName != null &&
                            _folderName!.isNotEmpty &&
                            _folderName != 'All Notes')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: palette.resolveSoftBackground(isDark),
                              borderRadius: AppSpacing.roundedPill,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TackIcon(
                                  TackIcons.folder,
                                  size: 11,
                                  color: palette.resolveAccentColor(isDark),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _folderName!,
                                  style: AppTypography.caption(
                                    color: palette.resolveAccentColor(isDark),
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showNoteStatisticsSheet();
                          },
                          child: Text(
                            '$wordCount ${wordCount == 1 ? 'word' : 'words'}  •  ${readTime}m read',
                            style: AppTypography.caption(
                              color: tokens.textSecondary,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (totalChecklists > 0)
                          Text(
                            allChecklistsCompleted
                                ? '•  ✓ All done'
                                : '•  $completedChecklists/$totalChecklists tasks',
                            style: AppTypography.caption(
                              color: allChecklistsCompleted
                                  ? tokens.success
                                  : tokens.textTertiary,
                              weight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    if (widget.item is TextNote && (widget.item as TextNote).sourceApp != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: palette.resolveAccentColor(isDark).withValues(alpha: isDark ? 0.16 : 0.12),
                              borderRadius: AppSpacing.roundedPill,
                              border: Border.all(
                                color: palette.resolveAccentColor(isDark).withValues(alpha: isDark ? 0.38 : 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TackIcon(
                                  TackIcons.share,
                                  size: 11,
                                  color: palette.resolveAccentColor(isDark),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Saved from ${(widget.item as TextNote).sourceApp}',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    color: palette.resolveAccentColor(isDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),

                    // Dynamic Tag Chips Bar
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ..._tags.map(
                          (tag) => Chip(
                            label: Text('#$tag'),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedPill),
                            backgroundColor: isDark ? AppColors.darkSurfaceAlt : Colors.white,
                            onDeleted: _isEditingMode ? () => _removeTag(tag) : null,
                            deleteIcon: _isEditingMode ? const TackIcon(TackIcons.close, size: 14) : null,
                          ),
                        ),
                        if (_isEditingMode)
                          if (_isAddingTag)
                            Container(
                              height: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceAlt : Colors.white,
                                borderRadius: AppSpacing.roundedPill,
                                border: Border.all(color: AppColors.accentAmber, width: 1.4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '#',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accentAmber,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 76,
                                    child: TextField(
                                      controller: _newTagController,
                                      autofocus: true,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        border: InputBorder.none,
                                        hintText: 'tag...',
                                      ),
                                      onSubmitted: (_) => _submitNewTag(),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _submitNewTag,
                                    child: const TackIcon(TackIcons.check, size: 14, color: AppColors.accentAmber),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => setState(() => _isAddingTag = false),
                                    child: const TackIcon(TackIcons.close, size: 13, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          else
                            ActionChip(
                              avatar: const TackIcon(TackIcons.plus, size: 14),
                              label: const Text('Add Tag'),
                              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              visualDensity: VisualDensity.compact,
                              shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedPill),
                               onPressed: () => setState(() => _isAddingTag = true),
                             ),
                       ],
                     ),

                     // Structured YAML Frontmatter Properties Bar
                     FrontmatterPropertiesBar(
                       rawContent: _contentController.text,
                       paletteId: _paletteId,
                       isEditingMode: _isEditingMode,
                       onContentChanged: (updatedContent) {
                         _contentController.text = updatedContent;
                         _saveNote();
                         setState(() {});
                       },
                     ),
                     const SizedBox(height: AppSpacing.lg),

                    // Body Content (Editing TextField vs Interactive Rich Preview)
                    if (_isEditingMode)
                      TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        inputFormatters: const [
                          SmartMarkdownContinuationFormatter(),
                        ],
                        contentInsertionConfiguration: ContentInsertionConfiguration(
                          allowedMimeTypes: const <String>[
                            'image/png',
                            'image/jpeg',
                            'image/gif',
                            'image/webp',
                          ],
                          onContentInserted: _handleInsertedContent,
                        ),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.55,
                          fontSize: 16,
                          fontFamily: AppTypography.fontFamily,
                        ),
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Start writing...\n\nTip: Type / for blocks, [[ to link notes or boards, or [ ] for tasks.',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    else ...[
                      SelectionArea(
                        child: GestureDetector(
                          behavior: HitTestBehavior.deferToChild,
                          onTap: () {
                            _toggleViewMode();
                          },
                          child: RichNoteContentView(
                            content: _contentController.text,
                            paletteId: _paletteId,
                            workspaceItems: workspace.rawItems,
                            onWikiLinkTap: _handleWikiLinkTap,
                            onHeadingJump: _jumpToLineIndex,
                            onLineTap: (lineIdx) {
                              _toggleViewMode(targetLineIndex: lineIdx);
                            },
                            onContentChanged: (newContent) {
                              _contentController.text = newContent;
                              _saveNote();
                            },
                          ),
                        ),
                      ),
                    ],

                    // Nested Sub-Notes Section (Feature 9)
                    if (childItems.isNotEmpty)
                      _buildSubNotesSection(
                        childItems: childItems,
                        isDark: isDark,
                        palette: palette,
                      ),

                    // Collapsible Bi-Directional Backlinks & Unlinked Mentions
                    NoteBacklinksSection(
                      linked: backlinks.linked,
                      unlinked: backlinks.unlinked,
                      onOpenEntry: (entry) async {
                        _flushSave();
                        final target = workspace.getItemById(entry.sourceItem.id) ?? entry.sourceItem;
                        if (target is WhiteboardCanvasItem) {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WhiteboardCanvasScreen(
                                item: target,
                                initialFocusNodeId: entry.canvasNodeId,
                              ),
                            ),
                          );
                        } else {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NoteEditorScreen(item: target),
                            ),
                          );
                        }
                        if (mounted) setState(() {});
                      },
                      onConvertUnlinkedToWikiLink: _handleConvertUnlinkedMention,
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),

            // Keyboard-Docked Formatting Toolbar (Only in Editing Mode)
            if (_isEditingMode) ...[
              if (showWikiBar)
                WikiLinkAutocompleteBar(
                  trigger: activeWikiTrigger,
                  workspaceItems: workspace.rawItems,
                  currentItemId: widget.item.id,
                  onSelectCompletion: (token) => _completeWikiTrigger(activeWikiTrigger, token),
                  onDismiss: () {
                    setState(() => _dismissedWikiTriggerOffset = activeWikiTrigger.triggerStart);
                  },
                )
              else if (activeSlashTrigger != null)
                SlashCommandInlineBar(
                  trigger: activeSlashTrigger,
                  onSelectCommand: (cmd) => _executeSlashCommand(cmd, slashTrigger: activeSlashTrigger),
                  onOpenFullSheet: () {
                    _removeSlashToken(activeSlashTrigger);
                    _openSlashAndBlockSheet(startOnTurnIntoTab: false);
                  },
                )
              else if (_isCursorInsideMermaidBlock())
                MermaidCompletionBar(
                  onInsertSnippet: _insertMermaidSnippet,
                  onOpenTemplates: () {
                    MermaidTemplateSheet.show(context, onSelectTemplate: _insertAtCursor);
                  },
                ),
              EditorFormattingToolbar(onFormatAction: _applyFormatting),
              const SizedBox(height: 4),
            ],

            // Always-at-bottom Status Footer (Last edited & Char count)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.lightBorder.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  'Last edited: ${DateFormatter.formatTimestamp(widget.item.updatedAt)}  •  $letterCount chars',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildBreadcrumbAndHierarchyBar({
    required List<BaseWorkspaceItem> breadcrumbs,
    required bool isDark,
    required TackColorPalette palette,
  }) {
    final pillBg = isDark ? AppColors.darkSurface : Colors.white.withValues(alpha: 0.85);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final muted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Folder pill
            if (_folderName != null || _isEditingMode)
              GestureDetector(
                onTap: _showMoveToFolderSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: AppSpacing.roundedPill,
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.folder, size: 12, color: muted),
                      const SizedBox(width: 4),
                      Text(
                        _folderName ?? 'Folder',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Ancestor breadcrumb chain
            for (final ancestor in breadcrumbs) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(LucideIcons.chevronRight, size: 13, color: muted),
              ),
              GestureDetector(
                onTap: () async {
                  _flushSave();
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NoteEditorScreen(item: ancestor),
                    ),
                  );
                  if (mounted) setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: AppSpacing.roundedPill,
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    ancestor.iconEmoji != null
                        ? '${ancestor.iconEmoji} ${ancestor.title}'
                        : ancestor.title,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF191A23),
                    ),
                  ),
                ),
              ),
            ],

            if (_isEditingMode) ...[
              if (_iconEmoji == null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _showEmojiPickerSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: AppSpacing.roundedPill,
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.smile, size: 12, color: muted),
                        const SizedBox(width: 4),
                        Text(
                          'Add Icon',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (widget.item is TextNote) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _handleCreateSubNote,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: AppSpacing.roundedPill,
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.filePlus2, size: 12, color: muted),
                        const SizedBox(width: 4),
                        Text(
                          '+ Sub-note',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubNotesSection({
    required List<BaseWorkspaceItem> childItems,
    required bool isDark,
    required TackColorPalette palette,
  }) {
    final accent = palette.resolveAccentColor(isDark);
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.folderTree, size: 15, color: accent),
                  const SizedBox(width: 7),
                  Text(
                    'Sub-notes (${childItems.length})',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.25,
                      color: isDark ? Colors.white : const Color(0xFF191A23),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _handleCreateSubNote,
                child: Text(
                  '+ New',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...childItems.map((child) {
            return InkWell(
              onTap: () async {
                _flushSave();
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NoteEditorScreen(item: child),
                  ),
                );
                if (mounted) setState(() {});
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Text(
                      child.iconEmoji ?? '📄',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF191A23),
                            ),
                          ),
                          if (child.getSummary().isNotEmpty)
                            Text(
                              child.getSummary(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11.5,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 15,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

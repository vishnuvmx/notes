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
import '../../../domain/models/base_item.dart';
import '../../../domain/models/text_note.dart';
import '../../../domain/models/sticky_note.dart';
import '../../../domain/models/clipboard_item.dart';
import '../../../state/workspace_provider.dart';
import '../../components/dialogs_sheets/color_swatch_picker.dart';
import '../../components/dialogs_sheets/ios_menu_button.dart';
import '../../components/dialogs_sheets/note_statistics_sheet.dart';
import '../../components/inputs/markdown_text_editing_controller.dart';
import '../../components/inputs/rich_note_content_view.dart';
import '../../components/inputs/smart_markdown_formatter.dart';
import '../../components/inputs/mermaid/mermaid_completion_bar.dart';
import '../../components/dialogs_sheets/mermaid_template_sheet.dart';
import '../../components/toolbars/editor_formatting_toolbar.dart';
import '../../../domain/services/note_export_service.dart';

/// Full-featured Note Editor & Reader Screen (Phase 3).
/// Includes Reading/Editing mode switcher, live interactive checklists,
/// tag manager, auto-save status pill, floating formatting toolbar, and note sharing.
class NoteEditorScreen extends StatefulWidget {
  final BaseWorkspaceItem item;

  const NoteEditorScreen({super.key, required this.item});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final MarkdownTextEditingController _contentController;
  final FocusNode _contentFocusNode = FocusNode();
  final TextEditingController _newTagController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _savedScrollRatio = 0.0;
  double _savedScrollOffset = 0.0;
  late String _paletteId;
  late List<String> _tags;

  bool _isEditingMode = true;
  bool _isAddingTag = false;
  final bool _autoSaveEnabled = true;
  bool _isSaving = false;
  Timer? _saveDebounce;

  // In-Note Find & Replace State
  bool _isSearching = false;
  bool _showReplace = false;
  final TextEditingController _searchQueryController = TextEditingController();
  final TextEditingController _replaceQueryController = TextEditingController();
  final List<int> _searchMatches = [];
  int _currentMatchIndex = 0;

  @override
  void initState() {
    super.initState();
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
    _isEditingMode = initialContent.trim().isEmpty;
    _tags = widget.item is TextNote ? List.from((widget.item as TextNote).tags) : [];

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
  }

  WorkspaceProvider? _workspace;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _workspace = context.read<WorkspaceProvider>();
  }

  void _flushSave() {
    final ws = _workspace;
    if (ws == null) return;
    final title = _titleController.text.trim();
    final content = _contentController.text;
    final paletteId = _paletteId;
    final tags = List<String>.from(_tags);

    BaseWorkspaceItem updated;
    if (widget.item is StickyNote) {
      updated = (widget.item as StickyNote).copyWith(
        title: title.isEmpty ? 'Untitled Sticky' : title,
        content: content,
        paletteId: paletteId,
        updatedAt: DateTime.now(),
      );
    } else if (widget.item is ClipboardItem) {
      updated = (widget.item as ClipboardItem).copyWith(
        title: title.isEmpty ? 'Untitled Clip' : title,
        clipText: content,
        paletteId: paletteId,
        updatedAt: DateTime.now(),
      );
    } else {
      updated = (widget.item as TextNote).copyWith(
        title: title.isEmpty ? 'Untitled Note' : title,
        content: content,
        tags: tags,
        paletteId: paletteId,
        updatedAt: DateTime.now(),
        sourceApp: (widget.item as TextNote).sourceApp,
      );
    }
    ws.saveItem(updated);
  }

  @override
  void dispose() {
    if (_saveDebounce?.isActive ?? false) {
      _saveDebounce?.cancel();
      _flushSave();
    }
    _titleController.dispose();
    _contentController.dispose();
    _newTagController.dispose();
    _contentFocusNode.dispose();
    _searchQueryController.dispose();
    _replaceQueryController.dispose();
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
    if (_isSearching) {
      _closeSearch();
      return;
    }
    if (_isEditingMode) {
      FocusScope.of(context).unfocus();
      _saveNote();
      _toggleViewMode();
      return;
    }
    Navigator.of(context).pop();
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
    // Capture all context-dependent values before the first await
    final workspace = context.read<WorkspaceProvider>();
    final title = _titleController.text.trim();
    final content = _contentController.text;
    final paletteId = _paletteId;
    final tags = List<String>.from(_tags);

    BaseWorkspaceItem updated;
    if (widget.item is StickyNote) {
      updated = (widget.item as StickyNote).copyWith(
        title: title.isEmpty ? 'Untitled Sticky' : title,
        content: content,
        paletteId: paletteId,
        updatedAt: DateTime.now(),
      );
    } else if (widget.item is ClipboardItem) {
      updated = (widget.item as ClipboardItem).copyWith(
        title: title.isEmpty ? 'Untitled Clip' : title,
        clipText: content,
        paletteId: paletteId,
        updatedAt: DateTime.now(),
      );
    } else {
      updated = (widget.item as TextNote).copyWith(
        title: title.isEmpty ? 'Untitled Note' : title,
        content: content,
        tags: tags,
        paletteId: paletteId,
        updatedAt: DateTime.now(),
        sourceApp: (widget.item as TextNote).sourceApp,
      );
    }

    await workspace.saveItem(updated);
    if (!mounted) return;
    setState(() => _isSaving = false);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
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
      ),
    );
  }

  void _showImageSourcePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
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
      ),
    );
  }

  void _showImageUrlDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Image Web Link'),
        content: TextField(
          controller: urlController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.png',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                _insertImageMarkdown(url, alt: 'Web Image');
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }

  void _showNoteStatisticsSheet() {
    NoteStatisticsSheet.show(context, content: _contentController.text);
  }

  void _showColorPicker() {
    showModalBottomSheet(
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

  void _onSearchQueryChanged(String query) {
    _searchMatches.clear();
    _currentMatchIndex = 0;
    if (query.trim().isNotEmpty) {
      final text = _contentController.text.toLowerCase();
      final q = query.toLowerCase();
      int startIndex = 0;
      while ((startIndex = text.indexOf(q, startIndex)) != -1) {
        _searchMatches.add(startIndex);
        startIndex += q.length;
      }
    }
    setState(() {});
    if (_searchMatches.isNotEmpty) {
      _jumpToMatch(0);
    }
  }

  void _jumpToMatch(int index) {
    if (_searchMatches.isEmpty) return;
    _currentMatchIndex = index.clamp(0, _searchMatches.length - 1);
    final matchStart = _searchMatches[_currentMatchIndex];
    final matchLength = _searchQueryController.text.length;
    _contentController.selection = TextSelection(
      baseOffset: matchStart,
      extentOffset: matchStart + matchLength,
    );
    setState(() {});
  }

  void _nextMatch() {
    if (_searchMatches.isEmpty) return;
    final next = (_currentMatchIndex + 1) % _searchMatches.length;
    _jumpToMatch(next);
  }

  void _prevMatch() {
    if (_searchMatches.isEmpty) return;
    final prev = (_currentMatchIndex - 1 + _searchMatches.length) % _searchMatches.length;
    _jumpToMatch(prev);
  }

  void _replaceCurrentMatch() {
    if (_searchMatches.isEmpty) return;
    final query = _searchQueryController.text;
    final replacement = _replaceQueryController.text;
    final matchStart = _searchMatches[_currentMatchIndex];
    final text = _contentController.text;

    final newText = text.replaceRange(matchStart, matchStart + query.length, replacement);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: matchStart + replacement.length),
    );
    _saveNote();
    _onSearchQueryChanged(query);
  }

  void _replaceAllMatches() {
    if (_searchMatches.isEmpty) return;
    final query = _searchQueryController.text;
    final replacement = _replaceQueryController.text;
    final text = _contentController.text;
    final newText = text.replaceAll(query, replacement);
    _contentController.text = newText;
    _saveNote();
    _onSearchQueryChanged(query);
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _showReplace = false;
      _searchMatches.clear();
      _searchQueryController.clear();
      _replaceQueryController.clear();
    });
  }

  void _showShareExportSheet() {
    final title = _titleController.text;
    final content = _contentController.text;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.read<WorkspaceProvider>();
    final palette = AppColors.getPaletteById(_paletteId);

    final backgroundColor = isDark
        ? AppColors.darkBackground
        : palette.softBackground;

    final content = _contentController.text;
    final letterCount = content.replaceAll(RegExp(r'\s'), '').length;
    final wordCount = content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;
    final readTime = ((wordCount / 180).ceil()).clamp(1, 60);

    final totalChecklists = RegExp(r'\[[ xX]\]').allMatches(content).length;
    final completedChecklists = RegExp(r'\[[xX]\]').allMatches(content).length;
    final allChecklistsCompleted = totalChecklists > 0 && completedChecklists == totalChecklists;

    return PopScope(
      canPop: !_isEditingMode && !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
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
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
                onPressed: _handleBackPress,
                tooltip: _isEditingMode ? 'Reader Mode' : 'Back',
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
                      _isSaving ? TackIcons.undo : TackIcons.checkCircle,
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

          // In-Note Find & Replace Trigger
          IconButton(
            icon: TackIcon(
              _isSearching ? TackIcons.close : TackIcons.searchSvg,
              size: 20,
              color: _isSearching
                  ? (isDark ? AppColors.accentAmber : AppColors.accentOrange)
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
            tooltip: _isSearching ? 'Close Search' : 'Find & Replace',
            onPressed: () {
              HapticFeedback.lightImpact();
              if (_isSearching) {
                _closeSearch();
              } else {
                setState(() => _isSearching = true);
              }
            },
          ),

          // Palette trigger
          IconButton(
            icon: const TackIcon(TackIcons.palette, size: 20),
            tooltip: 'Colors',
            onPressed: () {
              HapticFeedback.lightImpact();
              _showColorPicker();
            },
          ),

          // iOS-Style Overflow Menu (Favorite, Share, Trash)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IosThreeDotMenu<String>(
              size: 36,
              icon: TackIcons.more,
              iconColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              onSelected: (val) async {
                if (val == 'favorite') {
                  workspace.toggleFavorite(widget.item.id);
                  setState(() {});
                } else if (val == 'duplicate') {
                  HapticFeedback.lightImpact();
                  workspace.duplicateItem(widget.item.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note duplicated!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (val == 'share') {
                  _showShareExportSheet();
                } else if (val == 'trash') {
                  workspace.moveToTrash(widget.item.id);
                  Navigator.of(context).pop();
                }
              },
              items: [
                IosMenuItem(
                  value: 'favorite',
                  title: widget.item.isFavorite ? 'Unfavorite' : 'Favorite',
                  icon: TackIcons.star,
                  iconStyle: widget.item.isFavorite ? HeroIconStyle.solid : HeroIconStyle.outline,
                  iconColor: AppColors.accentAmber,
                ),
                const IosMenuItem(
                  value: 'duplicate',
                  title: 'Duplicate Note',
                  icon: TackIcons.copy,
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
            // Docked Find & Replace Bar
            if (_isSearching)
              _buildFindAndReplaceBar(isDark: isDark, palette: palette),

            // Scrollable Note Document
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Reader Mode Banner Indicator (Tap for detailed note stats)
                    if (!_isEditingMode)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showNoteStatisticsSheet();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceAlt : Colors.white.withValues(alpha: 0.8),
                            borderRadius: AppSpacing.roundedPill,
                          ),
                          child: Text(
                            'Reader Mode  •  $readTime min read',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                    // Large Note Title
                    if (_isEditingMode)
                      TextField(
                        controller: _titleController,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          height: 1.2,
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
                    else
                      Text(
                        _titleController.text.isEmpty ? 'Untitled Note' : _titleController.text,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          height: 1.2,
                        ),
                      ),
                    const SizedBox(height: 4),

                    // Ordinal Date Stamp & Checklist Progress
                    Row(
                      children: [
                        Text(
                          DateFormatter.formatOrdinalDate(widget.item.updatedAt),
                          style: AppTypography.cardDateStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (totalChecklists > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: allChecklistsCompleted
                                  ? (isDark ? AppColors.pastelLimeLight.withValues(alpha: 0.2) : AppColors.pastelLimeSoft)
                                  : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: allChecklistsCompleted
                                    ? AppColors.pastelLimeLight
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              allChecklistsCompleted
                                  ? '✓ All done!'
                                  : '✓ $completedChecklists/$totalChecklists done',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: allChecklistsCompleted
                                    ? (isDark ? AppColors.pastelLimeLight : const Color(0xFF386616))
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ),
                          ),
                        ],
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
                          hintText: 'Start writing your thoughts...\n\nTip: Use [ ] for interactive checklists, # for headings, and > for quotes.',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    else ...[
                      GestureDetector(
                        behavior: HitTestBehavior.deferToChild,
                        onTap: () {
                          _toggleViewMode();
                        },
                        child: RichNoteContentView(
                          content: _contentController.text,
                          paletteId: _paletteId,
                          onLineTap: (lineIdx) {
                            _toggleViewMode(targetLineIndex: lineIdx);
                          },
                          onContentChanged: (newContent) {
                            _contentController.text = newContent;
                            _saveNote();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

            // Keyboard-Docked Formatting Toolbar (Only in Editing Mode)
            if (_isEditingMode) ...[
              if (_isCursorInsideMermaidBlock())
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

  Widget _buildFindAndReplaceBar({required bool isDark, required TackColorPalette palette}) {
    final matchCount = _searchMatches.length;
    final matchText = _searchQueryController.text.isEmpty
        ? ''
        : (matchCount == 0 ? 'No matches' : '${_currentMatchIndex + 1} of $matchCount');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: 4),
              TackIcon(
                TackIcons.search,
                size: 16,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchQueryController,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: AppTypography.fontFamily,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Find in note...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontFamily: AppTypography.fontFamily,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                  ),
                  onChanged: _onSearchQueryChanged,
                ),
              ),
              if (matchText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    matchText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: matchCount > 0
                          ? (isDark ? AppColors.pastelAmberLight : AppColors.pastelAmberDark)
                          : AppColors.error,
                    ),
                  ),
                ),
              IconButton(
                icon: const TackIcon(TackIcons.chevronUp, size: 16),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Previous match',
                onPressed: matchCount > 0 ? _prevMatch : null,
              ),
              IconButton(
                icon: const TackIcon(TackIcons.chevronDown, size: 16),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Next match',
                onPressed: matchCount > 0 ? _nextMatch : null,
              ),
              IconButton(
                icon: TackIcon(
                  TackIcons.edit,
                  size: 16,
                  color: _showReplace
                      ? (isDark ? AppColors.accentAmber : AppColors.accentOrange)
                      : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Toggle Replace',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _showReplace = !_showReplace);
                },
              ),
              IconButton(
                icon: const TackIcon(TackIcons.close, size: 16),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Close',
                onPressed: _closeSearch,
              ),
            ],
          ),
          if (_showReplace) ...[
            const SizedBox(height: 6),
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 4),
                TackIcon(
                  TackIcons.redo,
                  size: 16,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _replaceQueryController,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: AppTypography.fontFamily,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Replace with...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        fontFamily: AppTypography.fontFamily,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: matchCount > 0 ? _replaceCurrentMatch : null,
                  child: const Text('Replace', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: matchCount > 0 ? _replaceAllMatches : null,
                  child: const Text('All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

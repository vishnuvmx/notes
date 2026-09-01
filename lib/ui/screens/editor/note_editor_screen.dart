import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/text_note.dart';
import '../../../domain/models/sticky_note.dart';
import '../../../state/workspace_provider.dart';
import '../../components/dialogs_sheets/color_swatch_picker.dart';
import '../../components/toolbars/editor_formatting_toolbar.dart';

/// Full-featured Note Editor Screen matching Screenshot 2.
/// Includes auto-save indicator, rich typography, floating formatting toolbar, and metadata footer.
class NoteEditorScreen extends StatefulWidget {
  final BaseWorkspaceItem item;

  const NoteEditorScreen({super.key, required this.item});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String _paletteId;
  bool _autoSaveEnabled = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    final initialContent = widget.item is TextNote
        ? (widget.item as TextNote).content
        : (widget.item is StickyNote ? (widget.item as StickyNote).content : '');
    _contentController = TextEditingController(text: initialContent);
    _paletteId = widget.item.paletteId;

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    if (_autoSaveEnabled) {
      _saveNote();
    }
  }

  void _saveNote() async {
    _isSaving = true;
    final workspace = context.read<WorkspaceProvider>();
    final title = _titleController.text.trim();
    final content = _contentController.text;

    BaseWorkspaceItem updated;
    if (widget.item is StickyNote) {
      updated = (widget.item as StickyNote).copyWith(
        title: title.isEmpty ? 'Untitled Sticky' : title,
        content: content,
        paletteId: _paletteId,
        updatedAt: DateTime.now(),
      );
    } else {
      updated = (widget.item as TextNote).copyWith(
        title: title.isEmpty ? 'Untitled Note' : title,
        content: content,
        paletteId: _paletteId,
        updatedAt: DateTime.now(),
      );
    }

    await workspace.saveItem(updated);
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  void _applyFormatting(String action) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (!selection.isValid) return;

    final selectedText = selection.textInside(text);
    final before = selection.textBefore(text);
    final after = selection.textAfter(text);
    String newText = text;
    int cursorOffset = selection.end;

    switch (action) {
      case 'bold':
        newText = '$before**$selectedText**$after';
        cursorOffset += 4;
        break;
      case 'italic':
        newText = '$before*$selectedText*$after';
        cursorOffset += 2;
        break;
      case 'underline':
        newText = '$before<u>$selectedText</u>$after';
        cursorOffset += 7;
        break;
      case 'strikethrough':
        newText = '$before~~$selectedText~~$after';
        cursorOffset += 4;
        break;
      case 'bullet':
        newText = '$before\n• $selectedText$after';
        cursorOffset += 3;
        break;
      case 'numbered':
        newText = '$before\n1. $selectedText$after';
        cursorOffset += 4;
        break;
      case 'checkbox':
        newText = '$before\n[ ] $selectedText$after';
        cursorOffset += 5;
        break;
      case 'quote':
        newText = '$before\n> $selectedText$after';
        cursorOffset += 3;
        break;
      case 'link':
        newText = '$before[$selectedText](url)$after';
        cursorOffset += 7;
        break;
      case 'image':
        newText = '$before\n![image](url)$after';
        cursorOffset += 14;
        break;
    }


    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorOffset.clamp(0, newText.length)),
    );
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
                  setState(() => _paletteId = id);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.read<WorkspaceProvider>();
    final palette = AppColors.getPaletteById(_paletteId);

    // Dynamic background color tint matching Screenshot 2
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : palette.softBackground;

    final content = _contentController.text;
    final letterCount = content.replaceAll(RegExp(r'\s'), '').length;
    final wordCount = content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;
    final lineCount = content.isEmpty ? 1 : content.split('\n').length;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white.withValues(alpha: 0.9),
            borderRadius: AppSpacing.roundedPill,
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isSaving ? Icons.sync_rounded : Icons.save_outlined,
                size: 16,
                color: _isSaving ? AppColors.accentAmber : AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                _isSaving ? 'Saving...' : 'Auto Save',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: _autoSaveEnabled,
                onChanged: (val) => setState(() => _autoSaveEnabled = val),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Change Color Theme',
            onPressed: _showColorPicker,
          ),
          IconButton(
            icon: Icon(
              widget.item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: widget.item.isFavorite ? AppColors.accentAmber : null,
            ),
            tooltip: 'Favorite',
            onPressed: () {
              workspace.toggleFavorite(widget.item.id);
              setState(() {});
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
            onSelected: (val) {
              if (val == 'trash') {
                workspace.moveToTrash(widget.item.id);
                Navigator.of(context).pop();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'trash',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete Note', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Note Document
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Large Note Title (Screenshot 2)
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
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Body Content
                    TextField(
                      controller: _contentController,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.55,
                        fontSize: 16,
                      ),
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Start writing your thoughts...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Keyboard-Docked Formatting Toolbar (Screenshot 2)
            EditorFormattingToolbar(onFormatAction: _applyFormatting),

            // Bottom Status Metadata Line (Screenshot 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceAlt : Colors.white.withValues(alpha: 0.8),
                border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last edited: ${DateFormatter.formatTimestamp(widget.item.updatedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                  Text(
                    'Letters: $letterCount   Words: $wordCount   Line: ${lineCount.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

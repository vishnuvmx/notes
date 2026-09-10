import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
import '../../components/inputs/rich_note_content_view.dart';
import '../../components/toolbars/editor_formatting_toolbar.dart';

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
  late final TextEditingController _contentController;
  late String _paletteId;
  late List<String> _tags;

  bool _isEditingMode = true;
  final bool _autoSaveEnabled = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    final initialContent = widget.item is TextNote
        ? (widget.item as TextNote).content
        : (widget.item is StickyNote
            ? (widget.item as StickyNote).content
            : (widget.item is ClipboardItem ? (widget.item as ClipboardItem).clipText : ''));
    _contentController = TextEditingController(text: initialContent);
    _paletteId = widget.item.paletteId;
    _tags = widget.item is TextNote ? List.from((widget.item as TextNote).tags) : [];

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
    } else if (widget.item is ClipboardItem) {
      updated = (widget.item as ClipboardItem).copyWith(
        title: title.isEmpty ? 'Untitled Clip' : title,
        clipText: content,
        paletteId: _paletteId,
        updatedAt: DateTime.now(),
      );
    } else {
      updated = (widget.item as TextNote).copyWith(
        title: title.isEmpty ? 'Untitled Note' : title,
        content: content,
        tags: _tags,
        paletteId: _paletteId,
        updatedAt: DateTime.now(),
      );
    }

    await workspace.saveItem(updated);
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  void _addTagDialog() {
    final tagCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: tagCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Design, Marketing, Strategy',
            prefixText: '# ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTag = tagCtrl.text.trim().replaceAll('#', '');
              if (newTag.isNotEmpty && !_tags.contains(newTag)) {
                HapticFeedback.lightImpact();
                setState(() => _tags.add(newTag));
                _saveNote();
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add Tag'),
          ),
        ],
      ),
    );
  }

  void _removeTag(String tag) {
    HapticFeedback.selectionClick();
    setState(() => _tags.remove(tag));
    _saveNote();
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

  void _showShareExportSheet() {
    final title = _titleController.text;
    final content = _contentController.text;
    final fullDoc = '# $title\n\n$content';

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
              onTap: () {
                Clipboard.setData(ClipboardData(text: fullDoc));
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
              onTap: () {
                final plain = '$title\n\n${content.replaceAll(RegExp(r'[*#_~>]'), '')}';
                Clipboard.setData(ClipboardData(text: plain));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Plain text copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                  ),
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
    final lineCount = content.isEmpty ? 1 : content.split('\n').length;
    final readTime = ((wordCount / 180).ceil()).clamp(1, 60);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const TackIcon(TackIcons.back, size: 22),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
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
              TackIcon(
                _isSaving ? TackIcons.undo : TackIcons.checkCircle,
                size: 14,
                color: _isSaving ? AppColors.accentAmber : AppColors.success,
                style: _isSaving ? HeroIconStyle.outline : HeroIconStyle.solid,
              ),
              const SizedBox(width: 5),
              Text(
                _isSaving ? 'Saving' : 'Saved',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Edit / Read View Mode Switcher
          IconButton(
            icon: TackIcon(
              _isEditingMode ? TackIcons.notes : TackIcons.whiteboard,
              size: 20,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            tooltip: _isEditingMode ? 'Reader Mode' : 'Edit Mode',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _isEditingMode = !_isEditingMode);
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

          // Overflow menu (Favorite, Share, Trash)
          PopupMenuButton<String>(
            icon: const TackIcon(TackIcons.more, size: 20),
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
            onSelected: (val) {
              if (val == 'favorite') {
                workspace.toggleFavorite(widget.item.id);
                setState(() {});
              } else if (val == 'share') {
                _showShareExportSheet();
              } else if (val == 'trash') {
                workspace.moveToTrash(widget.item.id);
                Navigator.of(context).pop();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'favorite',
                child: Row(
                  children: [
                    TackIcon(
                      TackIcons.star,
                      size: 18,
                      color: widget.item.isFavorite ? AppColors.accentAmber : null,
                      style: widget.item.isFavorite ? HeroIconStyle.solid : HeroIconStyle.outline,
                    ),
                    const SizedBox(width: 8),
                    Text(widget.item.isFavorite ? 'Unfavorite' : 'Favorite'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    TackIcon(TackIcons.share, size: 18),
                    SizedBox(width: 8),
                    Text('Export & Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'trash',
                child: Row(
                  children: [
                    TackIcon(TackIcons.trash, size: 18, color: AppColors.error),
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
                    // Reader Mode Banner Indicator
                    if (!_isEditingMode)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceAlt : Colors.white.withValues(alpha: 0.8),
                          borderRadius: AppSpacing.roundedPill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const TackIcon(TackIcons.notes, size: 14, color: AppColors.accentAmber),
                            const SizedBox(width: 6),
                            Text(
                              'Reader Mode  •  $readTime min read',
                              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
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

                    // Ordinal Date Stamp (Mockup detail screen: "4th Jan 2050")
                    Text(
                      DateFormatter.formatOrdinalDate(widget.item.updatedAt),
                      style: AppTypography.cardDateStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 13,
                      ),
                    ),
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
                          ActionChip(
                            avatar: const TackIcon(TackIcons.plus, size: 14),
                            label: const Text('Add Tag'),
                            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            visualDensity: VisualDensity.compact,
                            shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedPill),
                            onPressed: _addTagDialog,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Body Content (Editing TextField vs Interactive Rich Preview)
                    if (_isEditingMode)
                      TextField(
                        controller: _contentController,
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
                    else
                      RichNoteContentView(
                        content: _contentController.text,
                        onContentChanged: (newContent) {
                          _contentController.text = newContent;
                          _saveNote();
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Keyboard-Docked Formatting Toolbar (Only in Editing Mode)
            if (_isEditingMode)
              EditorFormattingToolbar(onFormatAction: _applyFormatting),

            // Bottom Status Metadata Line
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

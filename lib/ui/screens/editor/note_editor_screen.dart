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
  late final MarkdownTextEditingController _contentController;
  final FocusNode _contentFocusNode = FocusNode();
  final TextEditingController _newTagController = TextEditingController();
  late String _paletteId;
  late List<String> _tags;

  bool _isEditingMode = true;
  bool _isAddingTag = false;
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
    _contentController = MarkdownTextEditingController(text: initialContent);
    _isEditingMode = initialContent.trim().isEmpty;
    _paletteId = widget.item.paletteId;
    _tags = widget.item is TextNote ? List.from((widget.item as TextNote).tags) : [];

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _newTagController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
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
        final prefix = (before.isEmpty || before.endsWith('\n')) ? '• ' : '\n• ';
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
        newText = '$before\n![Image](https://)$after';
        newCursorStart = before.length + 11;
        newCursorEnd = newCursorStart + 8;
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
                _isSaving ? 'Saving' : 'Saved  •  $wordCount words',
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
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          setState(() => _isEditingMode = true);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _contentFocusNode.requestFocus();
                          });
                        },
                        child: RichNoteContentView(
                          content: _contentController.text,
                          onContentChanged: (newContent) {
                            _contentController.text = newContent;
                            _saveNote();
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: Text(
                          'Last edited: ${DateFormatter.formatTimestamp(widget.item.updatedAt)}  •  $letterCount chars',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Keyboard-Docked Formatting Toolbar (Only in Editing Mode)
            if (_isEditingMode) ...[
              EditorFormattingToolbar(onFormatAction: _applyFormatting),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}

/// Syntax-highlighted text controller that renders bold, italic, strikethrough, underline, and tags inside the editor TextField.
class MarkdownTextEditingController extends TextEditingController {
  MarkdownTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = this.text;
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final spans = <TextSpan>[];
    final pattern = RegExp(
      r'(==.*?==)|(\*\*.*?\*\*)|(__.*?__)|(\*.*?\*)|(_.*?_)|(~~.*?~~)|(<u>.*?</u>)|(#[a-zA-Z0-9_-]+)',
      dotAll: false,
    );

    final delimiterStyle = style?.copyWith(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.28),
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.normal,
      decoration: TextDecoration.none,
    );

    int lastMatchEnd = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: style,
        ));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('==') && matchedText.endsWith('==') && matchedText.length >= 4) {
        spans.add(TextSpan(text: '==', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: style?.copyWith(
            backgroundColor: isDark
                ? AppColors.pastelAmberLight.withValues(alpha: 0.35)
                : AppColors.pastelYellowLight.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ));
        spans.add(TextSpan(text: '==', style: delimiterStyle));
      } else if (matchedText.startsWith('**') && matchedText.endsWith('**') && matchedText.length >= 4) {
        spans.add(TextSpan(text: '**', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: style?.copyWith(fontWeight: FontWeight.bold),
        ));
        spans.add(TextSpan(text: '**', style: delimiterStyle));
      } else if (matchedText.startsWith('__') && matchedText.endsWith('__') && matchedText.length >= 4) {
        spans.add(TextSpan(text: '__', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: style?.copyWith(decoration: TextDecoration.underline),
        ));
        spans.add(TextSpan(text: '__', style: delimiterStyle));
      } else if (matchedText.startsWith('<u>') && matchedText.endsWith('</u>') && matchedText.length >= 7) {
        spans.add(TextSpan(text: '<u>', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(3, matchedText.length - 4),
          style: style?.copyWith(decoration: TextDecoration.underline),
        ));
        spans.add(TextSpan(text: '</u>', style: delimiterStyle));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*') && matchedText.length >= 2) {
        spans.add(TextSpan(text: '*', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: style?.copyWith(fontStyle: FontStyle.italic),
        ));
        spans.add(TextSpan(text: '*', style: delimiterStyle));
      } else if (matchedText.startsWith('_') && matchedText.endsWith('_') && matchedText.length >= 2) {
        spans.add(TextSpan(text: '_', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: style?.copyWith(fontStyle: FontStyle.italic),
        ));
        spans.add(TextSpan(text: '_', style: delimiterStyle));
      } else if (matchedText.startsWith('~~') && matchedText.endsWith('~~') && matchedText.length >= 4) {
        spans.add(TextSpan(text: '~~', style: delimiterStyle));
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: style?.copyWith(decoration: TextDecoration.lineThrough),
        ));
        spans.add(TextSpan(text: '~~', style: delimiterStyle));
      } else if (matchedText.startsWith('#')) {
        spans.add(TextSpan(
          text: matchedText,
          style: style?.copyWith(
            color: isDark ? AppColors.pastelLavenderLight : AppColors.pastelLavenderDark,
            fontWeight: FontWeight.w700,
          ),
        ));
      } else {
        spans.add(TextSpan(text: matchedText, style: style));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }

    return TextSpan(children: spans, style: style);
  }
}

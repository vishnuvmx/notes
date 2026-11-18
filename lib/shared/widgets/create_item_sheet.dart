import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tack_icons.dart';
import '../models/base_item.dart';
import '../../features/notes/services/note_template_service.dart';
import '../providers/workspace_provider.dart';
import 'app_bottom_sheet.dart';
import 'color_swatch_picker.dart';
import 'tactile_ink_target.dart';
import 'tack_toast.dart';

/// Fast Capture Sheet (`05-information-architecture.md` §4, `07-design-system.md` §7).
///
/// Designed for 1-tap capture without form friction:
/// 1. Auto-focused multiline text field (`body-lg`)
/// 2. Primary action: **Save to Inbox** (returns `null` after saving to Inbox and showing toast)
/// 3. Secondary action: **Open as note** (returns the created `TextNote` to open in Editor)
/// 4. Quiet bottom row: `Template…` · `New board` · `Paste clipboard`
class CreateItemSheet extends StatefulWidget {
  final ItemType? defaultType;

  const CreateItemSheet({super.key, this.defaultType});

  static Future<BaseWorkspaceItem?> show(
    BuildContext context, {
    ItemType? defaultType,
  }) {
    HapticFeedback.mediumImpact();
    return AppBottomSheet.show<BaseWorkspaceItem>(
      context: context,
      maxHeightFactor: 0.90,
      builder: (context) => CreateItemSheet(defaultType: defaultType),
    );
  }

  @override
  State<CreateItemSheet> createState() => _CreateItemSheetState();
}

class _CreateItemSheetState extends State<CreateItemSheet> {
  late final TextEditingController _captureController;
  late final FocusNode _captureFocusNode;

  String _selectedPaletteId = 'amber';
  String? _selectedFolder;
  bool _showTemplatesAndColor = false;
  bool _isSubmitting = false;
  List<NoteTemplate> _templates = NoteTemplateService.builtInTemplates;
  String _selectedTemplateId = 'blank';

  @override
  void initState() {
    super.initState();
    _captureController = TextEditingController();
    _captureFocusNode = FocusNode();

    if (widget.defaultType == ItemType.whiteboard) {
      _selectedPaletteId = 'cyan';
    }

    _loadTemplates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final activeFolder = context.read<WorkspaceProvider>().selectedFolder;
      if (activeFolder != 'All Notes') {
        setState(() => _selectedFolder = activeFolder);
      }
    });
  }

  Future<void> _loadTemplates() async {
    final loaded = await NoteTemplateService.loadAllTemplates();
    if (mounted) {
      setState(() => _templates = loaded);
    }
  }

  @override
  void dispose() {
    _captureController.dispose();
    _captureFocusNode.dispose();
    super.dispose();
  }

  NoteTemplate get _activeTemplate {
    return _templates.firstWhere(
      (t) => t.id == _selectedTemplateId,
      orElse: () => NoteTemplateService.builtInTemplates.first,
    );
  }

  Future<void> _handleSaveToInbox() async {
    if (_isSubmitting) return;
    HapticFeedback.mediumImpact();
    final raw = _captureController.text.trim();
    if (raw.isEmpty) {
      _captureFocusNode.requestFocus();
      return;
    }
    setState(() => _isSubmitting = true);
    final tokens = context.tokens;
    final workspace = context.read<WorkspaceProvider>();
    final hostContext = ScaffoldMessenger.maybeOf(context)?.context;
    try {
      await workspace.captureToInbox(
        raw,
        paletteId: _selectedPaletteId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(null);
      if (hostContext != null && hostContext.mounted) {
        TackToast.show(
          hostContext,
          message: 'Saved to Inbox',
          icon: TackIcons.check,
          iconColor: tokens.success,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      TackToast.show(
        context,
        message: 'Could not save to Inbox. Please try again.',
        icon: TackIcons.close,
        iconColor: tokens.danger,
      );
    }
  }

  Future<void> _handleOpenAsNote() async {
    if (_isSubmitting) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    final tokens = context.tokens;
    final raw = _captureController.text.trim();
    final workspace = context.read<WorkspaceProvider>();
    final tpl = _activeTemplate;
    final now = DateTime.now();

    String resolvedTitle;
    String resolvedBody;

    if (tpl.id != 'blank') {
      final firstLine = raw.isEmpty
          ? tpl.name
          : raw.split('\n').first.replaceAll(RegExp(r'^#+\s*'), '').trim();
      resolvedTitle = NoteTemplateService.expandTokens(
        tpl.titlePattern,
        customTitle: firstLine.isEmpty ? tpl.name : firstLine,
        now: now,
      );
      final expandedTpl = NoteTemplateService.expandTokens(
        tpl.bodyTemplate,
        customTitle: resolvedTitle,
        now: now,
      );
      resolvedBody = raw.isNotEmpty ? '$expandedTpl\n$raw\n' : expandedTpl;
    } else if (raw.isEmpty) {
      resolvedTitle = 'Untitled Note';
      resolvedBody = '';
    } else {
      final lines = raw.split('\n');
      final firstLine = lines.first.replaceAll(RegExp(r'^#+\s*'), '').trim();
      resolvedTitle = firstLine.isNotEmpty
          ? (firstLine.length > 56
              ? '${firstLine.substring(0, 56)}…'
              : firstLine)
          : 'Untitled Note';
      resolvedBody =
          lines.length > 1 ? lines.sublist(1).join('\n').trimLeft() : raw;
    }

    try {
      final item = await workspace.createQuickItem(
        title: resolvedTitle,
        type: ItemType.note,
        paletteId: _selectedPaletteId,
        extraContent: resolvedBody,
        folderName: _selectedFolder,
        iconEmoji: tpl.id == 'blank' ? null : tpl.iconEmoji,
        isInbox: false,
      );
      if (!mounted) return;
      Navigator.of(context).pop(item);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      TackToast.show(
        context,
        message: 'Could not create note. Please try again.',
        icon: TackIcons.close,
        iconColor: tokens.danger,
      );
    }
  }

  Future<void> _handleNewBoard() async {
    if (_isSubmitting) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    final tokens = context.tokens;
    final raw = _captureController.text.trim();
    final firstLine = raw.split('\n').first.trim();
    final title = firstLine.isEmpty ? 'Untitled Board' : firstLine;
    final workspace = context.read<WorkspaceProvider>();
    try {
      final board = await workspace.createQuickItem(
        title: title,
        type: ItemType.whiteboard,
        paletteId:
            _selectedPaletteId == 'amber' ? 'cyan' : _selectedPaletteId,
        folderName: _selectedFolder,
      );
      if (!mounted) return;
      Navigator.of(context).pop(board);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      TackToast.show(
        context,
        message: 'Could not create board. Please try again.',
        icon: TackIcons.close,
        iconColor: tokens.danger,
      );
    }
  }

  Future<void> _handlePasteClipboard() async {
    HapticFeedback.selectionClick();
    final tokens = context.tokens;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) {
        if (mounted) {
          TackToast.show(
            context,
            message: 'Clipboard is empty',
            icon: TackIcons.info,
            iconColor: tokens.textSecondary,
          );
        }
        return;
      }
      final current = _captureController.text;
      final next = current.isEmpty ? text : '$current\n$text';
      _captureController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        TackToast.show(
          context,
          message: 'Could not read clipboard',
          icon: TackIcons.close,
          iconColor: tokens.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(_selectedPaletteId);
    final bandColor = palette.resolveCardColor(tokens.isDark);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s5,
        AppSpacing.s6,
        AppSpacing.s6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 8,
                height: 18,
                decoration: BoxDecoration(
                  color: bandColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  _selectedTemplateId == 'blank'
                      ? 'Quick Capture'
                      : 'Template · ${_activeTemplate.name}',
                  style: AppTypography.titleSm(color: tokens.textPrimary),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  minimumSize: const Size(
                    AppSpacing.minTouchTarget,
                    AppSpacing.minTouchTarget,
                  ),
                ),
                icon: TackIcon(
                  TackIcons.close,
                  size: 18,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s2),

          if (_selectedFolder != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: 'Notes and boards file to $_selectedFolder. Tap to clear.',
                child: TactileInkTarget(
                  borderRadius: AppSpacing.roundedPill,
                  minWidth: 0,
                  triggerHaptics: true,
                  color: tokens.canvasSunken,
                  border: Border.all(color: tokens.borderSubtle),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3,
                    vertical: AppSpacing.s1,
                  ),
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() => _selectedFolder = null),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TackIcon(
                        TackIcons.folder,
                        size: 14,
                        color: tokens.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.s1),
                      Flexible(
                        child: Text(
                          'File in $_selectedFolder',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(
                            color: tokens.textSecondary,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s1),
                      TackIcon(
                        TackIcons.close,
                        size: 12,
                        color: tokens.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
          ],

          // Auto-focused capture input field (`body-lg`, single clean container)
          Container(
            constraints: const BoxConstraints(minHeight: 96, maxHeight: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s3,
            ),
            decoration: BoxDecoration(
              color: tokens.canvasSunken,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: TextField(
              key: const ValueKey('capture_sheet_input'),
              controller: _captureController,
              focusNode: _captureFocusNode,
              autofocus: true,
              maxLines: null,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              style: AppTypography.bodyLg(color: tokens.textPrimary),
              cursorColor: tokens.textPrimary,
              decoration: AppInputDecorations.bareWithHint(
                'Jot a thought, task, or #tag…',
                hintStyle: AppTypography.bodyLg(color: tokens.textTertiary),
              ),
            ),
          ),

          // Expandable Template & Color Band drawer
          if (_showTemplatesAndColor) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Color band',
              style: AppTypography.label(color: tokens.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s1),
            ColorSwatchPicker(
              selectedPaletteId: _selectedPaletteId,
              onPaletteSelected: (id) => setState(() => _selectedPaletteId = id),
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              'Templates',
              style: AppTypography.label(color: tokens.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s2),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _templates.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s2),
                itemBuilder: (ctx, idx) {
                  final tpl = _templates[idx];
                  final selected = tpl.id == _selectedTemplateId;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: '${tpl.name}. ${tpl.subtitle}',
                    child: InkWell(
                      onTap: _isSubmitting
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedTemplateId = tpl.id;
                                _selectedPaletteId =
                                    AppColors.normalizePaletteId(tpl.paletteId);
                              });
                            },
                      borderRadius: AppSpacing.roundedSm,
                      child: Container(
                        width: 152,
                        padding: const EdgeInsets.all(AppSpacing.s3),
                        decoration: BoxDecoration(
                          color: selected
                              ? tokens.canvasSunken
                              : tokens.surfacePrimary,
                          borderRadius: AppSpacing.roundedSm,
                          border: Border.all(
                            color: selected
                                ? tokens.borderFocus
                                : tokens.borderSubtle,
                            width: selected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  tpl.iconEmoji,
                                  style: AppTypography.bodySm(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s1),
                                Expanded(
                                  child: Text(
                                    tpl.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.label(
                                      color: tokens.textPrimary,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              tpl.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption(
                                color: tokens.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.s4),

          // Primary & Secondary Actions (`Save to Inbox` / `Open as note`)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('capture_open_as_note_btn'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      AppSpacing.minTouchTarget,
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _handleOpenAsNote,
                  child: const Text(
                    'Open as note',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: ElevatedButton(
                  key: const ValueKey('capture_save_to_inbox_btn'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      AppSpacing.minTouchTarget,
                    ),
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : (_captureController.text.trim().isEmpty
                          ? _handleOpenAsNote
                          : _handleSaveToInbox),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: tokens.actionPrimaryFg,
                          ),
                        )
                      : Text(
                          _captureController.text.trim().isEmpty
                              ? 'New blank note'
                              : 'Save to Inbox',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s2),

          // Quiet bottom action row (`Template…` · `New board` · `Paste clipboard`)
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: AppSpacing.s1,
            runSpacing: AppSpacing.s1,
            children: [
              _QuietCaptureOption(
                icon: TackIcons.sparkles,
                label: _showTemplatesAndColor ? 'Hide options' : 'Template…',
                isActive:
                    _showTemplatesAndColor || _selectedTemplateId != 'blank',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(
                    () => _showTemplatesAndColor = !_showTemplatesAndColor,
                  );
                },
              ),
              _QuietCaptureOption(
                icon: TackIcons.boards,
                label: 'New board',
                onTap: _isSubmitting ? () {} : _handleNewBoard,
              ),
              _QuietCaptureOption(
                icon: TackIcons.clipboard,
                label: 'Paste clipboard',
                onTap: _isSubmitting ? () {} : _handlePasteClipboard,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuietCaptureOption extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _QuietCaptureOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fg = isActive ? tokens.textPrimary : tokens.textSecondary;

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedSm,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
            minWidth: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TackIcon(icon, size: 16, color: fg),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(
                    color: fg,
                    weight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

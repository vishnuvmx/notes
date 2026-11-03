import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/services/note_template_service.dart';
import '../../../state/workspace_provider.dart';
import 'app_bottom_sheet.dart';
import 'color_swatch_picker.dart';

/// Modern Bottom Sheet for creating a new Note, Spec from Template, Sticky, or Whiteboard.
/// Includes 1-tap Instant Blank Note & Today's Note shortcuts to eliminate capture friction.
class CreateItemSheet extends StatefulWidget {
  final ItemType? defaultType;

  const CreateItemSheet({super.key, this.defaultType});

  static Future<BaseWorkspaceItem?> show(BuildContext context, {ItemType? defaultType}) {
    HapticFeedback.mediumImpact();
    return AppBottomSheet.show<BaseWorkspaceItem>(
      context: context,
      maxHeightFactor: 0.92,
      builder: (context) => CreateItemSheet(defaultType: defaultType),
    );
  }

  @override
  State<CreateItemSheet> createState() => _CreateItemSheetState();
}

class _CreateItemSheetState extends State<CreateItemSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late ItemType _selectedType;
  String _selectedPaletteId = 'peach';
  String? _selectedFolder;
  List<NoteTemplate> _templates = NoteTemplateService.builtInTemplates;
  String _selectedTemplateId = 'blank';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    final initial = widget.defaultType ?? ItemType.note;
    _selectedType = (initial == ItemType.clipboard) ? ItemType.note : initial;

    if (_selectedType == ItemType.sticky) {
      _selectedPaletteId = 'amber';
    } else if (_selectedType == ItemType.whiteboard) {
      _selectedPaletteId = 'cyan';
    }

    _loadTemplates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final activeFolder = context.read<WorkspaceProvider>().selectedFolder;
      if (activeFolder != 'All Notes' &&
          activeFolder != 'Favourites' &&
          activeFolder != 'Favorites') {
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
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  NoteTemplate get _activeTemplate {
    return _templates.firstWhere(
      (t) => t.id == _selectedTemplateId,
      orElse: () => NoteTemplateService.builtInTemplates.first,
    );
  }

  Future<void> _handleInstantBlankNote() async {
    HapticFeedback.mediumImpact();
    final workspace = context.read<WorkspaceProvider>();
    final item = await workspace.createQuickItem(
      title: 'Untitled Note',
      type: ItemType.note,
      paletteId: _selectedPaletteId,
      content: '',
      folderName: _selectedFolder,
    );
    if (mounted) {
      Navigator.of(context).pop(item);
    }
  }

  Future<void> _handleInstantTodaysNote() async {
    HapticFeedback.mediumImpact();
    final workspace = context.read<WorkspaceProvider>();
    final daily = await workspace.openOrCreateTodaysNote();
    if (mounted) {
      Navigator.of(context).pop(daily);
    }
  }

  void _handleCreate() async {
    HapticFeedback.mediumImpact();
    final rawTitle = _titleController.text.trim();
    final extraSnippet = _contentController.text.trim();
    final workspace = context.read<WorkspaceProvider>();

    if (_selectedType == ItemType.note) {
      final tpl = _activeTemplate;
      final now = DateTime.now();
      final resolvedTitle = tpl.id == 'blank'
          ? (rawTitle.isEmpty ? 'Untitled Note' : rawTitle)
          : NoteTemplateService.expandTokens(
              tpl.titlePattern,
              customTitle: rawTitle.isEmpty ? tpl.name : rawTitle,
              now: now,
            );
      final expandedBody = tpl.bodyTemplate.isEmpty
          ? extraSnippet
          : NoteTemplateService.expandTokens(
              tpl.bodyTemplate,
              customTitle: resolvedTitle,
              now: now,
            );
      final finalContent = (tpl.bodyTemplate.isNotEmpty && extraSnippet.isNotEmpty)
          ? '$expandedBody\n$extraSnippet\n'
          : expandedBody;

      final item = await workspace.createQuickItem(
        title: resolvedTitle,
        type: ItemType.note,
        paletteId: _selectedPaletteId,
        content: finalContent,
        folderName: _selectedFolder,
        iconEmoji: tpl.id == 'blank' ? null : tpl.iconEmoji,
        tags: tpl.tags,
      );
      if (mounted) Navigator.of(context).pop(item);
      return;
    }

    final defaultTitle = _selectedType == ItemType.sticky ? 'New Sticky' : 'New Whiteboard';
    final item = await workspace.createQuickItem(
      title: rawTitle.isEmpty ? defaultTitle : rawTitle,
      type: _selectedType,
      paletteId: _selectedPaletteId,
      content: extraSnippet,
      folderName: _selectedFolder,
    );

    if (mounted) {
      Navigator.of(context).pop(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.watch<WorkspaceProvider>();
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final size = MediaQuery.sizeOf(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet Title & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create new item',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    IconButton(
                      icon: const TackIcon(TackIcons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),

                // Zero-Friction 1-Tap Capture Shortcuts
                Row(
                  children: [
                    Expanded(
                      child: _buildInstantShortcutButton(
                        isDark: isDark,
                        emoji: '⚡',
                        label: 'Instant Blank Note',
                        accent: AppColors.pastelLimeLight,
                        onTap: _handleInstantBlankNote,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInstantShortcutButton(
                        isDark: isDark,
                        emoji: '☀️',
                        label: "Today's Note",
                        accent: AppColors.pastelAmberLight,
                        onTap: _handleInstantTodaysNote,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Item Type Selector Chips (Notes, Sticky, Whiteboard)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [ItemType.note, ItemType.sticky, ItemType.whiteboard].map((type) {
                      final isSelected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(type.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedType = type;
                                if (type == ItemType.sticky && _selectedPaletteId == 'peach') {
                                  _selectedPaletteId = 'amber';
                                } else if (type == ItemType.whiteboard && _selectedPaletteId == 'peach') {
                                  _selectedPaletteId = 'cyan';
                                }
                              });
                            }
                          },
                          selectedColor: isDark ? AppColors.lightSurface : AppColors.primaryDark,
                          labelStyle: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            color: isSelected
                                ? (isDark ? AppColors.darkBackground : AppColors.lightSurface)
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedPill),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Spec & Note Templates Gallery (when Note is selected)
                if (_selectedType == ItemType.note) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Templates & Spec Briefs',
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (_activeTemplate.isCustom)
                        Text(
                          'Long-press custom to delete',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 84 * MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.35),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _templates.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (ctx, idx) {
                        final tpl = _templates[idx];
                        final selected = tpl.id == _selectedTemplateId;
                        final palette = AppColors.getPaletteById(tpl.paletteId);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedTemplateId = tpl.id;
                              _selectedPaletteId = tpl.paletteId;
                            });
                          },
                          onLongPress: tpl.isCustom
                              ? () async {
                                  HapticFeedback.mediumImpact();
                                  await NoteTemplateService.deleteCustomTemplate(tpl.id);
                                  if (_selectedTemplateId == tpl.id) {
                                    _selectedTemplateId = 'blank';
                                  }
                                  await _loadTemplates();
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: 152,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? palette.resolveCardColor(isDark)
                                  : (isDark ? const Color(0xFF1E2026) : Colors.white),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? (isDark ? palette.lightColor : const Color(0xFF191A23))
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: selected ? 1.7 : 1.1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(tpl.iconEmoji, style: const TextStyle(fontSize: 15)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        tpl.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.25,
                                          color: isDark ? Colors.white : const Color(0xFF191A23),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  tpl.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 10.8,
                                    height: 1.25,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // Title Input
                TextField(
                  controller: _titleController,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Title (optional)',
                    labelStyle: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    hintText: _selectedType == ItemType.note
                        ? (_selectedTemplateId == 'blank'
                            ? 'e.g. Meeting Notes, Ideas...'
                            : 'e.g. Checkout Redesign...')
                        : (_selectedType == ItemType.sticky
                            ? 'e.g. Call dentist, Grocery list...'
                            : 'e.g. System Flowchart, Architecture...'),
                    hintStyle: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TackIcon(
                        _selectedType == ItemType.whiteboard
                            ? TackIcons.whiteboardSvg
                            : (_selectedType == ItemType.sticky ? TackIcons.star : TackIcons.notesSvg),
                        size: 18,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E2026) : const Color(0xFFF3F5F8),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF333742) : const Color(0xFFE2E6EC),
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF333742) : const Color(0xFFE2E6EC),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white : AppColors.primaryDark,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),

                // Optional Quick Content Input for Sticky or Blank Note
                if (_selectedType == ItemType.sticky ||
                    (_selectedType == ItemType.note && _selectedTemplateId == 'blank')) ...[
                  const SizedBox(height: AppSpacing.sm + 2),
                  TextField(
                    controller: _contentController,
                    maxLines: 2,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Quick Snippet (optional)',
                      labelStyle: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      hintText: 'Jot down a thought, or jump straight in...',
                      hintStyle: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        fontSize: 13.5,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E2026) : const Color(0xFFF3F5F8),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF333742) : const Color(0xFFE2E6EC),
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF333742) : const Color(0xFFE2E6EC),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkFocusBorder : AppColors.lightFocusBorder,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],

                // Optional Folder Selector
                if (workspace.userFolders.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Folder',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFolderChip(
                          label: 'None',
                          selected: _selectedFolder == null,
                          isDark: isDark,
                          onTap: () => setState(() => _selectedFolder = null),
                        ),
                        ...workspace.userFolders.map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _buildFolderChip(
                              label: f,
                              selected: _selectedFolder == f,
                              isDark: isDark,
                              onTap: () => setState(() => _selectedFolder = f),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // Color Swatch Picker Section
                Text(
                  'Card Color',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                ColorSwatchPicker(
                  selectedPaletteId: _selectedPaletteId,
                  onPaletteSelected: (id) => setState(() => _selectedPaletteId = id),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Action Buttons (Cancel / Create)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _handleCreate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.lightSurface : AppColors.primaryDark,
                          foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                        ),
                        child: Text(
                          _selectedType == ItemType.note && _selectedTemplateId != 'blank'
                              ? 'Create from Template'
                              : 'Create & Open',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildInstantShortcutButton({
    required bool isDark,
    required String emoji,
    required String label,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? const Color(0xFF1E2026) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? accent.withValues(alpha: 0.45) : const Color(0xFF191A23),
              width: 1.3,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.25,
                    color: isDark ? Colors.white : const Color(0xFF191A23),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderChip({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.pastelLimeLight
              : (isDark ? const Color(0xFF1E2026) : Colors.white),
          borderRadius: AppSpacing.roundedPill,
          border: Border.all(
            color: selected
                ? const Color(0xFF191A23)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != 'None') ...[
              Icon(
                LucideIcons.folder,
                size: 12.5,
                color: selected
                    ? const Color(0xFF191A23)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? const Color(0xFF191A23)
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

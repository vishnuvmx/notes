import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/models/base_item.dart';

import '../../../state/workspace_provider.dart';
import 'color_swatch_picker.dart';

/// Modern iOS-styled Bottom Sheet for creating a new Note, Sticky, Whiteboard, or Clipboard item.
/// Features ergonomic mobile bottom sheet layout with smooth haptics and microinteractions.
class CreateItemSheet extends StatefulWidget {
  final ItemType? defaultType;

  const CreateItemSheet({super.key, this.defaultType});

  static Future<BaseWorkspaceItem?> show(BuildContext context, {ItemType? defaultType}) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<BaseWorkspaceItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    final initial = widget.defaultType ?? ItemType.note;
    _selectedType = (initial == ItemType.clipboard) ? ItemType.note : initial;

    if (_selectedType == ItemType.sticky) {
      _selectedPaletteId = 'amber';
    } else if (_selectedType == ItemType.whiteboard) {
      _selectedPaletteId = 'cyan';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleCreate() async {
    HapticFeedback.mediumImpact();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final workspace = context.read<WorkspaceProvider>();

    final item = await workspace.createQuickItem(
      title: title.isEmpty ? 'Untitled ${_selectedType.label}' : title,
      type: _selectedType,
      paletteId: _selectedPaletteId,
      content: content,
    );

    if (mounted) {
      Navigator.of(context).pop(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    final size = MediaQuery.sizeOf(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.88,
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: AppSpacing.lg + keyboardBottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          boxShadow: AppSpacing.floatingControlShadow,
        ),
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create new item',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const TackIcon(TackIcons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
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
                          setState(() => _selectedType = type);
                        }
                      },
                      selectedColor: isDark ? AppColors.lightSurface : AppColors.primaryDark,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? (isDark ? AppColors.darkBackground : AppColors.lightSurface)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedPill),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title Input (Enhanced UI)
            TextField(
              controller: _titleController,
              autofocus: true,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                hintText: 'e.g. My Important Thought...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontSize: 14,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TackIcon(
                    TackIcons.whiteboard,
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
            const SizedBox(height: AppSpacing.md),

            // Optional Quick Content Input for Sticky / Note (Enhanced UI)
            if (_selectedType != ItemType.whiteboard) ...[
              TextField(
                controller: _contentController,
                maxLines: 3,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  labelText: 'Snippet / Content',
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  hintText: 'Write down quick notes or thoughts...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 32),
                    child: TackIcon(
                      TackIcons.notes,
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
              const SizedBox(height: AppSpacing.md),
            ],

            // Color Swatch Picker Section
            Text(
              'Card Color',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            ColorSwatchPicker(
              selectedPaletteId: _selectedPaletteId,
              onPaletteSelected: (id) => setState(() => _selectedPaletteId = id),
            ),
            const SizedBox(height: AppSpacing.xl),

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
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

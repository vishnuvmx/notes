import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../services/frontmatter_service.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/tack_toast.dart';
import '../../../shared/widgets/tactile_ink_target.dart';

/// Zero-clutter YAML Frontmatter Properties Bar.
///
/// - When the note has NO frontmatter properties:
///   - Hidden completely in Reader Mode (zero noise).
///   - Shows a subtle `+ Properties` pill in Edit Mode.
/// - When properties exist:
///   - Renders interactive pills (`Status`, `Priority`, `Target Date`, `Aliases`, custom fields)
///     that can be updated in 1 tap and stay 100% portable as `---` YAML frontmatter.
class FrontmatterPropertiesBar extends StatelessWidget {
  final String rawContent;
  final String paletteId;
  final bool isEditingMode;
  final ValueChanged<String> onContentChanged;

  const FrontmatterPropertiesBar({
    super.key,
    required this.rawContent,
    required this.paletteId,
    required this.isEditingMode,
    required this.onContentChanged,
  });

  void _cycleOrPickStatus(BuildContext context, String? currentStatus) {
    HapticFeedback.selectionClick();
    final presets = FrontmatterService.statusPresets;
    final idx = currentStatus == null
        ? -1
        : presets.indexWhere(
            (p) => p.toLowerCase() == currentStatus.toLowerCase(),
          );
    final next = presets[(idx + 1) % presets.length];
    onContentChanged(
      FrontmatterService.upsertProperty(rawContent, 'status', next),
    );
  }

  void _cyclePriority(String? currentPriority) {
    HapticFeedback.selectionClick();
    final presets = FrontmatterService.priorityPresets;
    final idx = currentPriority == null
        ? -1
        : presets.indexWhere(
            (p) => p.toLowerCase() == currentPriority.toLowerCase(),
          );
    final next = presets[(idx + 1) % presets.length];
    onContentChanged(
      FrontmatterService.upsertProperty(rawContent, 'priority', next),
    );
  }

  static DateTime _clampDate(DateTime dt, DateTime min, DateTime max) {
    if (dt.isBefore(min)) return min;
    if (dt.isAfter(max)) return max;
    return dt;
  }

  Future<void> _pickTargetDate(BuildContext context, String? current) async {
    HapticFeedback.lightImpact();
    final minDate = DateTime(2020);
    final maxDate = DateTime(2035);
    DateTime initial = DateTime.now();
    if (current != null) {
      final parsed = DateTime.tryParse(current.trim());
      if (parsed != null) initial = parsed;
    }
    initial = _clampDate(initial, minDate, maxDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate,
      lastDate: maxDate,
    );
    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      onContentChanged(
        FrontmatterService.upsertProperty(rawContent, 'target_date', formatted),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = tokens.isDark;
    final palette = AppColors.getPaletteById(paletteId);
    final accent = palette.resolveAccentColor(isDark);
    final chipFill = palette.resolveChipFill(isDark);
    final chipBorder = palette.resolveChipBorder(isDark);
    final parsed = FrontmatterService.parse(rawContent);

    if (!parsed.hasProperties) {
      if (!isEditingMode) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: TactileInkTarget(
          color: accent.withValues(alpha: isDark ? 0.12 : 0.07),
          border: Border.all(color: chipBorder),
          borderRadius: AppSpacing.roundedPill,
          minHeight: AppSpacing.minTouchTarget,
          semanticsLabel: 'Add properties',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onTap: () => FrontmatterEditorSheet.show(
            context,
            rawContent: rawContent,
            paletteId: paletteId,
            onContentChanged: onContentChanged,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TackIcon(TackIcons.settings, size: 13, color: accent),
              const SizedBox(width: 5),
              Text(
                '+ Properties',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(
                  color: accent,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final chips = <Widget>[];
    for (final entry in parsed.properties.entries) {
      final k = entry.key;
      final v = entry.value;

      if (k == 'status') {
        chips.add(
          _PropertyPill(
            iconWidget: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            label: v,
            backgroundColor: chipFill,
            borderColor: chipBorder,
            textColor: accent,
            onTap: () => _cycleOrPickStatus(context, v),
          ),
        );
      } else if (k == 'priority') {
        chips.add(
          _PropertyPill(
            icon: TackIcons.flag,
            label: v,
            backgroundColor: chipFill,
            borderColor: chipBorder,
            textColor: accent,
            onTap: () => _cyclePriority(v),
          ),
        );
      } else if (k == 'target_date' || k == 'due') {
        chips.add(
          _PropertyPill(
            icon: TackIcons.calendar,
            label: v,
            backgroundColor: chipFill,
            borderColor: chipBorder,
            textColor: accent,
            onTap: () => _pickTargetDate(context, v),
          ),
        );
      } else if (v.toLowerCase() == 'true' || v.toLowerCase() == 'false') {
        final checked = v.toLowerCase() == 'true';
        chips.add(
          _PropertyPill(
            icon: checked ? TackIcons.checkCircle : TackIcons.taskOpen,
            label: k.replaceAll('_', ' '),
            backgroundColor: chipFill,
            borderColor: chipBorder,
            textColor: accent,
            onTap: () {
              HapticFeedback.selectionClick();
              onContentChanged(
                FrontmatterService.upsertProperty(
                  rawContent,
                  k,
                  checked ? 'false' : 'true',
                ),
              );
            },
          ),
        );
      } else {
        chips.add(
          _PropertyPill(
            label: '${k.replaceAll('_', ' ')}: $v',
            backgroundColor: chipFill,
            borderColor: chipBorder,
            textColor: accent,
            onTap: () => FrontmatterEditorSheet.show(
              context,
              rawContent: rawContent,
              paletteId: paletteId,
              onContentChanged: onContentChanged,
            ),
          ),
        );
      }
    }

    chips.add(
      _PropertyPill(
        icon: TackIcons.edit,
        label: 'Edit',
        subtle: true,
        backgroundColor: accent.withValues(alpha: isDark ? 0.10 : 0.06),
        borderColor: chipBorder,
        textColor: accent,
        onTap: () => FrontmatterEditorSheet.show(
          context,
          rawContent: rawContent,
          paletteId: paletteId,
          onContentChanged: onContentChanged,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(spacing: 6, runSpacing: 6, children: chips),
    );
  }
}

class _PropertyPill extends StatelessWidget {
  final dynamic icon;
  final Widget? iconWidget;
  final String label;
  final bool subtle;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _PropertyPill({
    this.icon,
    this.iconWidget,
    required this.label,
    this.subtle = false,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fg = textColor ?? (subtle ? tokens.textTertiary : tokens.textPrimary);
    return TactileInkTarget(
      color: backgroundColor ?? tokens.surfacePrimary.withValues(alpha: 0.9),
      border: Border.all(color: borderColor ?? tokens.borderSubtle),
      borderRadius: AppSpacing.roundedPill,
      minHeight: AppSpacing.minTouchTarget,
      semanticsLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconWidget != null) ...[
            iconWidget!,
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            TackIcon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(color: fg, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive sheet for adding, editing, or deleting YAML frontmatter properties.
class FrontmatterEditorSheet extends StatefulWidget {
  final String rawContent;
  final String paletteId;
  final ValueChanged<String> onContentChanged;

  const FrontmatterEditorSheet({
    super.key,
    required this.rawContent,
    required this.paletteId,
    required this.onContentChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required String rawContent,
    required String paletteId,
    required ValueChanged<String> onContentChanged,
  }) {
    return AppBottomSheet.show<void>(
      context: context,
      builder: (_) => FrontmatterEditorSheet(
        rawContent: rawContent,
        paletteId: paletteId,
        onContentChanged: onContentChanged,
      ),
    );
  }

  @override
  State<FrontmatterEditorSheet> createState() => _FrontmatterEditorSheetState();
}

class _FrontmatterEditorSheetState extends State<FrontmatterEditorSheet> {
  late Map<String, String> _props;
  late String _body;
  final TextEditingController _customKeyCtrl = TextEditingController();
  final TextEditingController _customValCtrl = TextEditingController();
  String? _customFieldError;

  @override
  void initState() {
    super.initState();
    final parsed = FrontmatterService.parse(widget.rawContent);
    _props = Map<String, String>.from(parsed.properties);
    _body = parsed.bodyWithoutFrontmatter;
  }

  @override
  void dispose() {
    _customKeyCtrl.dispose();
    _customValCtrl.dispose();
    super.dispose();
  }

  void _commit() {
    widget.onContentChanged(FrontmatterService.serialize(_props, _body));
  }

  void _setProp(String key, String? val) {
    setState(() {
      if (val == null || val.trim().isEmpty) {
        _props.remove(key);
      } else {
        _props[key] = val.trim();
      }
    });
    _commit();
  }

  void _addCustomField() {
    final key = _customKeyCtrl.text.trim();
    final val = _customValCtrl.text.trim();
    if (key.isEmpty || val.isEmpty) {
      setState(() {
        _customFieldError = key.isEmpty && val.isEmpty
            ? 'Enter both a property key and value.'
            : (key.isEmpty
                  ? 'Enter a property key (e.g. aliases).'
                  : 'Enter a value for "$key".');
      });
      return;
    }
    setState(() => _customFieldError = null);
    _setProp(key, val);
    _customKeyCtrl.clear();
    _customValCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(widget.paletteId);
    final accent = palette.resolveAccentColor(isDark);

    return Padding(
      padding: AppSpacing.modalSheetPadding,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TackIcon(TackIcons.settings, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note Properties (YAML)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSm(
                          color: tokens.textPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Saved as portable --- YAML --- metadata at the top of your note.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_props.isNotEmpty)
                  SizedBox(
                    height: AppSpacing.minTouchTarget,
                    child: TextButton(
                      onPressed: () {
                        final backup = Map<String, String>.from(_props);
                        setState(() => _props.clear());
                        _commit();
                        TackToast.show(
                          context,
                          message: 'Cleared ${backup.length} properties',
                          actionLabel: 'Undo',
                          onAction: () {
                            if (!mounted) return;
                            setState(() => _props = backup);
                            _commit();
                          },
                        );
                      },
                      child: const Text('Clear all'),
                    ),
                  ),
                IconButton(
                  tooltip: 'Done',
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.minTouchTarget,
                    minHeight: AppSpacing.minTouchTarget,
                  ),
                  icon: const TackIcon(TackIcons.close, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'STATUS',
              style: AppTypography.caption(
                color: tokens.textSecondary,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FrontmatterService.statusPresets.map((preset) {
                final selected =
                    _props['status']?.toLowerCase() == preset.toLowerCase();
                return TactileFilterPill(
                  label: preset,
                  isSelected: selected,
                  selectedColor: palette.resolveChipFill(isDark),
                  unselectedColor: tokens.canvasSunken,
                  selectedFg: accent,
                  unselectedFg: tokens.textPrimary,
                  selectedBorderColor: accent,
                  unselectedBorderColor: tokens.borderSubtle,
                  onTap: () => _setProp('status', selected ? null : preset),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'PRIORITY',
              style: AppTypography.caption(
                color: tokens.textSecondary,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FrontmatterService.priorityPresets.map((preset) {
                final selected =
                    _props['priority']?.toLowerCase() == preset.toLowerCase();
                return TactileFilterPill(
                  label: preset,
                  isSelected: selected,
                  selectedColor: palette.resolveChipFill(isDark),
                  unselectedColor: tokens.canvasSunken,
                  selectedFg: accent,
                  unselectedFg: tokens.textPrimary,
                  selectedBorderColor: accent,
                  unselectedBorderColor: tokens.borderSubtle,
                  onTap: () => _setProp('priority', selected ? null : preset),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: SizedBox(
                    height: AppSpacing.minTouchTarget,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final minDate = DateTime(2020);
                        final maxDate = DateTime(2035);
                        final existing = _props['target_date'] != null
                            ? DateTime.tryParse(_props['target_date']!)
                            : null;
                        final initial = FrontmatterPropertiesBar._clampDate(
                          existing ?? DateTime.now(),
                          minDate,
                          maxDate,
                        );
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: minDate,
                          lastDate: maxDate,
                        );
                        if (picked != null) {
                          final formatted =
                              '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          _setProp('target_date', formatted);
                        }
                      },
                      icon: const TackIcon(TackIcons.calendar, size: 16),
                      label: Text(
                        _props['target_date'] ?? 'Set Target Date',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                if (_props.containsKey('target_date')) ...[
                  const SizedBox(width: AppSpacing.s2),
                  IconButton(
                    tooltip: 'Clear target date',
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.minTouchTarget,
                      minHeight: AppSpacing.minTouchTarget,
                    ),
                    icon: const TackIcon(TackIcons.close, size: 16),
                    onPressed: () => _setProp('target_date', null),
                  ),
                ],
              ],
            ),
            if (_props.entries.any(
              (e) => !{'status', 'priority', 'target_date'}.contains(e.key),
            )) ...[
              const SizedBox(height: 12),
              Text(
                'CUSTOM FIELDS',
                style: AppTypography.caption(
                  color: tokens.textSecondary,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ..._props.entries
                  .where(
                    (e) =>
                        !{'status', 'priority', 'target_date'}.contains(e.key),
                  )
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${e.key}: ${e.value}',
                              style: AppTypography.bodySm(
                                color: tokens.textPrimary,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove ${e.key}',
                            constraints: const BoxConstraints(
                              minWidth: AppSpacing.minTouchTarget,
                              minHeight: AppSpacing.minTouchTarget,
                            ),
                            icon: const TackIcon(TackIcons.close, size: 16),
                            onPressed: () => _setProp(e.key, null),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _customKeyCtrl,
                    onChanged: (_) {
                      if (_customFieldError != null) {
                        setState(() => _customFieldError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Key (e.g. aliases)',
                      isDense: true,
                      filled: true,
                      fillColor: tokens.canvasSunken,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: tokens.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: tokens.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkFocusBorder
                              : AppColors.lightFocusBorder,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _customValCtrl,
                    onChanged: (_) {
                      if (_customFieldError != null) {
                        setState(() => _customFieldError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Value',
                      isDense: true,
                      filled: true,
                      fillColor: tokens.canvasSunken,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: tokens.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: tokens.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkFocusBorder
                              : AppColors.lightFocusBorder,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _addCustomField(),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Add custom property',
                  child: TactileInkTarget(
                    color: palette.resolveChipFill(isDark),
                    border: Border.all(
                      color: palette.resolveChipBorder(isDark),
                    ),
                    borderRadius: AppSpacing.roundedSm,
                    width: AppSpacing.minTouchTarget,
                    height: AppSpacing.minTouchTarget,
                    semanticsLabel: 'Add custom property',
                    onTap: _addCustomField,
                    child: TackIcon(TackIcons.plus, size: 18, color: accent),
                  ),
                ),
              ],
            ),
            if (_customFieldError != null) ...[
              const SizedBox(height: 6),
              Text(
                _customFieldError!,
                style: AppTypography.caption(color: tokens.stateDanger),
              ),
            ],
            const SizedBox(height: AppSpacing.s3),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.minTouchTarget,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

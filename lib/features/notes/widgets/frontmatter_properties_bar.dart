import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../services/frontmatter_service.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';

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

  Color _statusColor(String status, bool isDark) {
    final s = status.trim().toLowerCase();
    if (s.contains('approv') || s.contains('done') || s.contains('ship')) {
      return isDark ? AppColors.pastelLimeLight : const Color(0xFF4D7C0F);
    }
    if (s.contains('review') || s.contains('progress') || s.contains('wip')) {
      return isDark ? AppColors.pastelAmberLight : const Color(0xFFB45309);
    }
    if (s.contains('block') || s.contains('urgent') || s.contains('drop')) {
      return isDark ? AppColors.pastelCoralLight : const Color(0xFFB91C1C);
    }
    return isDark ? AppColors.pastelCyanLight : const Color(0xFF0E7490);
  }

  void _cycleOrPickStatus(BuildContext context, String? currentStatus) {
    HapticFeedback.selectionClick();
    final presets = FrontmatterService.statusPresets;
    final idx = currentStatus == null
        ? -1
        : presets.indexWhere((p) => p.toLowerCase() == currentStatus.toLowerCase());
    final next = presets[(idx + 1) % presets.length];
    onContentChanged(FrontmatterService.upsertProperty(rawContent, 'status', next));
  }

  void _cyclePriority(String? currentPriority) {
    HapticFeedback.selectionClick();
    final presets = FrontmatterService.priorityPresets;
    final idx = currentPriority == null
        ? -1
        : presets.indexWhere((p) => p.toLowerCase() == currentPriority.toLowerCase());
    final next = presets[(idx + 1) % presets.length];
    onContentChanged(FrontmatterService.upsertProperty(rawContent, 'priority', next));
  }

  Future<void> _pickTargetDate(BuildContext context, String? current) async {
    HapticFeedback.lightImpact();
    DateTime initial = DateTime.now();
    if (current != null) {
      final parsed = DateTime.tryParse(current);
      if (parsed != null) initial = parsed;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parsed = FrontmatterService.parse(rawContent);

    if (!parsed.hasProperties) {
      if (!isEditingMode) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: InkWell(
          onTap: () => FrontmatterEditorSheet.show(
            context,
            rawContent: rawContent,
            paletteId: paletteId,
            onContentChanged: onContentChanged,
          ),
          borderRadius: AppSpacing.roundedPill,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceAlt.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: AppSpacing.roundedPill,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.slidersHorizontal,
                  size: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  '+ Properties',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final chips = <Widget>[];
    for (final entry in parsed.properties.entries) {
      final k = entry.key;
      final v = entry.value;

      if (k == 'status') {
        final c = _statusColor(v, isDark);
        chips.add(
          _PropertyPill(
            iconWidget: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            label: v,
            backgroundColor: c.withValues(alpha: isDark ? 0.18 : 0.12),
            borderColor: c.withValues(alpha: 0.45),
            textColor: c,
            onTap: () => _cycleOrPickStatus(context, v),
          ),
        );
      } else if (k == 'priority') {
        chips.add(
          _PropertyPill(
            icon: LucideIcons.flag,
            label: v,
            isDark: isDark,
            onTap: () => _cyclePriority(v),
          ),
        );
      } else if (k == 'target_date' || k == 'due') {
        chips.add(
          _PropertyPill(
            icon: TackIcons.calendar,
            label: v,
            isDark: isDark,
            onTap: () => _pickTargetDate(context, v),
          ),
        );
      } else if (v.toLowerCase() == 'true' || v.toLowerCase() == 'false') {
        final checked = v.toLowerCase() == 'true';
        chips.add(
          _PropertyPill(
            icon: checked ? TackIcons.checkCircle : LucideIcons.circle,
            label: k.replaceAll('_', ' '),
            isDark: isDark,
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
            isDark: isDark,
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
        icon: LucideIcons.slidersHorizontal,
        label: 'Edit',
        isDark: isDark,
        subtle: true,
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
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips,
      ),
    );
  }
}

class _PropertyPill extends StatelessWidget {
  final dynamic icon;
  final Widget? iconWidget;
  final String label;
  final bool isDark;
  final bool subtle;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _PropertyPill({
    this.icon,
    this.iconWidget,
    required this.label,
    this.isDark = false,
    this.subtle = false,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = textColor ??
        (subtle
            ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary));
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedPill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: backgroundColor ??
              (isDark ? AppColors.darkSurfaceAlt : Colors.white.withValues(alpha: 0.9)),
          borderRadius: AppSpacing.roundedPill,
          border: Border.all(
            color: borderColor ??
                (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null) ...[
              iconWidget!,
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              TackIcon(icon, size: 12, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: fg,
              ),
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppColors.getPaletteById(widget.paletteId);
    final accent = palette.resolveAccentColor(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.slidersHorizontal, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note Properties (YAML)',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  if (_props.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => _props.clear());
                        _commit();
                      },
                      child: const Text('Clear all'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'STATUS',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: FrontmatterService.statusPresets.map((preset) {
                  final selected =
                      _props['status']?.toLowerCase() == preset.toLowerCase();
                  return ChoiceChip(
                    label: Text(preset),
                    selected: selected,
                    onSelected: (v) => _setProp('status', v ? preset : null),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'PRIORITY',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: FrontmatterService.priorityPresets.map((preset) {
                  final selected =
                      _props['priority']?.toLowerCase() == preset.toLowerCase();
                  return ChoiceChip(
                    label: Text(preset),
                    selected: selected,
                    onSelected: (v) => _setProp('priority', v ? preset : null),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          final formatted =
                              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          _setProp('target_date', formatted);
                        }
                      },
                      icon: const Icon(LucideIcons.calendar, size: 15),
                      label: Text(
                        _props['target_date'] ?? 'Set Target Date',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (_props.containsKey('target_date')) ...[
                    const SizedBox(width: AppSpacing.s2),
                    IconButton(
                      icon: const TackIcon(TackIcons.close, size: 16),
                      onPressed: () => _setProp('target_date', null),
                    ),
                  ],
                ],
              ),
              if (_props.entries
                  .any((e) => !{'status', 'priority', 'target_date'}.contains(e.key))) ...[
                const SizedBox(height: 12),
                Text(
                  'CUSTOM FIELDS',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 6),
                ..._props.entries
                    .where((e) => !{'status', 'priority', 'target_date'}.contains(e.key))
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${e.key}: ${e.value}',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const TackIcon(TackIcons.close, size: 15),
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
                      decoration: InputDecoration(
                        hintText: 'Key (e.g. aliases)',
                        isDense: true,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurfaceAlt
                            : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? AppColors.darkFocusBorder : AppColors.lightFocusBorder, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _customValCtrl,
                      decoration: InputDecoration(
                        hintText: 'Value',
                        isDense: true,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurfaceAlt
                            : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? AppColors.darkFocusBorder : AppColors.lightFocusBorder, width: 1.5),
                        ),
                      ),
                      onSubmitted: (_) {
                        if (_customKeyCtrl.text.trim().isNotEmpty &&
                            _customValCtrl.text.trim().isNotEmpty) {
                          _setProp(_customKeyCtrl.text, _customValCtrl.text);
                          _customKeyCtrl.clear();
                          _customValCtrl.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: () {
                      if (_customKeyCtrl.text.trim().isNotEmpty &&
                          _customValCtrl.text.trim().isNotEmpty) {
                        _setProp(_customKeyCtrl.text, _customValCtrl.text);
                        _customKeyCtrl.clear();
                        _customValCtrl.clear();
                      }
                    },
                    icon: const TackIcon(TackIcons.plus, size: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }
}


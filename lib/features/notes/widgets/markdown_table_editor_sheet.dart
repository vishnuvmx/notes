import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tack_icons.dart';
import '../services/markdown_table_service.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';

/// Touch-first Visual Markdown Table Editor Sheet.
///
/// Allows direct cell editing, adding/removing rows and columns, cycling column
/// alignment (`left`, `center`, `right`), and saving cleanly back to GFM pipe syntax.
class MarkdownTableEditorSheet extends StatefulWidget {
  final EditableMarkdownTable initialTable;
  final String? paletteId;
  final ValueChanged<EditableMarkdownTable> onSave;

  const MarkdownTableEditorSheet({
    super.key,
    required this.initialTable,
    this.paletteId,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required EditableMarkdownTable initialTable,
    String? paletteId,
    required ValueChanged<EditableMarkdownTable> onSave,
  }) {
    return AppBottomSheet.show<void>(
      context: context,
      maxHeightFactor: 0.90,
      builder: (_) => MarkdownTableEditorSheet(
        initialTable: initialTable,
        paletteId: paletteId,
        onSave: onSave,
      ),
    );
  }

  @override
  State<MarkdownTableEditorSheet> createState() =>
      _MarkdownTableEditorSheetState();
}

class _MarkdownTableEditorSheetState extends State<MarkdownTableEditorSheet> {
  late List<TextEditingController> _headerCtrls;
  late List<TableColumnAlign> _alignments;
  late List<List<TextEditingController>> _rowCtrls;
  late final String _initialSnapshot;

  @override
  void initState() {
    super.initState();
    _headerCtrls = widget.initialTable.headers
        .map((h) => TextEditingController(text: MarkdownTableService.stripInlineMarkdown(h)))
        .toList();
    _alignments = List<TableColumnAlign>.from(widget.initialTable.alignments);
    _rowCtrls = widget.initialTable.rows
        .map(
          (row) => List<TextEditingController>.generate(
            _headerCtrls.length,
            (c) => TextEditingController(
              text: c < row.length ? MarkdownTableService.stripInlineMarkdown(row[c]) : '',
            ),
          ),
        )
        .toList();
    if (_rowCtrls.isEmpty) {
      _rowCtrls.add(
        List.generate(_headerCtrls.length, (_) => TextEditingController()),
      );
    }
    _initialSnapshot = _serializeState();
  }

  String _serializeState() {
    final h = _headerCtrls.map((c) => c.text).join('\x1f');
    final a = _alignments.map((e) => e.name).join(',');
    final r = _rowCtrls
        .map((row) => row.map((c) => c.text).join('\x1f'))
        .join('\x1e');
    return '$h|$a|$r';
  }

  bool get _hasChanges => _serializeState() != _initialSnapshot;

  Future<void> _handleClose() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }
    final tokens = context.tokens;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: tokens.surfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: Text(
          'Discard table edits?',
          style: AppTypography.titleSm(color: tokens.textPrimary),
        ),
        content: Text(
          'You have unsaved changes in this table.',
          style: AppTypography.bodySm(color: tokens.textSecondary),
        ),
        actions: [
          SizedBox(
            height: AppSpacing.minTouchTarget,
            child: TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(false),
              child: const Text('Keep editing'),
            ),
          ),
          SizedBox(
            height: AppSpacing.minTouchTarget,
            child: TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Discard'),
            ),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    for (final c in _headerCtrls) {
      c.dispose();
    }
    for (final row in _rowCtrls) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _addRow() {
    HapticFeedback.lightImpact();
    setState(() {
      _rowCtrls.add(
        List.generate(_headerCtrls.length, (_) => TextEditingController()),
      );
    });
  }

  void _removeRow(int rowIdx) {
    if (_rowCtrls.length <= 1) return;
    HapticFeedback.selectionClick();
    setState(() {
      final removed = _rowCtrls.removeAt(rowIdx);
      for (final c in removed) {
        c.dispose();
      }
    });
  }

  void _addColumn() {
    HapticFeedback.lightImpact();
    setState(() {
      final colNum = _headerCtrls.length + 1;
      _headerCtrls.add(TextEditingController(text: 'Col $colNum'));
      _alignments.add(TableColumnAlign.left);
      for (final row in _rowCtrls) {
        row.add(TextEditingController());
      }
    });
  }

  void _removeColumn(int colIdx) {
    if (_headerCtrls.length <= 1) return;
    HapticFeedback.selectionClick();
    setState(() {
      _headerCtrls.removeAt(colIdx).dispose();
      _alignments.removeAt(colIdx);
      for (final row in _rowCtrls) {
        row.removeAt(colIdx).dispose();
      }
    });
  }

  void _cycleAlign(int colIdx) {
    HapticFeedback.selectionClick();
    setState(() {
      _alignments[colIdx] = _alignments[colIdx].next();
    });
  }

  TackSvgIcon _alignIcon(TableColumnAlign align) {
    switch (align) {
      case TableColumnAlign.left:
        return TackIcons.alignLeft;
      case TableColumnAlign.center:
        return TackIcons.alignCenter;
      case TableColumnAlign.right:
        return TackIcons.alignRight;
    }
  }

  EditableMarkdownTable _buildTableSnapshot() {
    return EditableMarkdownTable(
      headers: _headerCtrls.map((c) => c.text).toList(),
      alignments: List<TableColumnAlign>.from(_alignments),
      rows: _rowCtrls
          .map((row) => row.map((c) => c.text).toList())
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(widget.paletteId);
    final accent = palette.resolveAccentColor(isDark);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleClose();
      },
      child: Padding(
        padding: AppSpacing.modalSheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TackIcon(TackIcons.table, size: 19, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visual Table Editor',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSm(
                          color: tokens.textPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Tap the alignment icon on a header to cycle left, center, or right.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.minTouchTarget,
                    minHeight: AppSpacing.minTouchTarget,
                  ),
                  icon: const TackIcon(TackIcons.close, size: 18),
                  onPressed: _handleClose,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s1,
              children: [
                SizedBox(
                  height: AppSpacing.minTouchTarget,
                  child: OutlinedButton.icon(
                    onPressed: _addColumn,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedSm,
                      ),
                    ),
                    icon: const TackIcon(TackIcons.plus, size: 15),
                    label: const Text('Add column'),
                  ),
                ),
                SizedBox(
                  height: AppSpacing.minTouchTarget,
                  child: OutlinedButton.icon(
                    onPressed: _addRow,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedSm,
                      ),
                    ),
                    icon: const TackIcon(TackIcons.plus, size: 15),
                    label: const Text('Add row'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 330),
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            const SizedBox(width: AppSpacing.minTouchTarget),
                            ...List.generate(_headerCtrls.length, (colIdx) {
                              return Container(
                                width: 184,
                                margin: const EdgeInsets.only(right: 8, bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                                  borderRadius: AppSpacing.roundedSm,
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: AppSpacing.minTouchTarget,
                                            minHeight: AppSpacing.minTouchTarget,
                                          ),
                                          icon: TackIcon(
                                            _alignIcon(_alignments[colIdx]),
                                            size: 16,
                                            color: accent,
                                          ),
                                          tooltip: 'Align: ${_alignments[colIdx].name}',
                                          onPressed: () => _cycleAlign(colIdx),
                                        ),
                                        const Spacer(),
                                        if (_headerCtrls.length > 1)
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: AppSpacing.minTouchTarget,
                                              minHeight: AppSpacing.minTouchTarget,
                                            ),
                                            icon: const TackIcon(
                                              TackIcons.close,
                                              size: 15,
                                            ),
                                            tooltip: 'Delete Column',
                                            onPressed: () => _removeColumn(colIdx),
                                          ),
                                      ],
                                    ),
                                    TextField(
                                      controller: _headerCtrls[colIdx],
                                      minLines: 1,
                                      maxLines: 3,
                                      keyboardType: TextInputType.multiline,
                                      style: AppTypography.label(
                                        color: tokens.textPrimary,
                                        weight: FontWeight.w700,
                                      ),
                                      decoration: AppInputDecorations.bareWithHint(
                                        'Header',
                                        hintStyle: AppTypography.label(
                                          color: tokens.textSecondary,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                        // Data Rows
                        ...List.generate(_rowCtrls.length, (rowIdx) {
                          return Row(
                            children: [
                              SizedBox(
                                width: AppSpacing.minTouchTarget,
                                height: AppSpacing.minTouchTarget,
                                child: _rowCtrls.length > 1
                                    ? IconButton(
                                        tooltip: 'Delete Row ${rowIdx + 1}',
                                        constraints: const BoxConstraints(
                                          minWidth: AppSpacing.minTouchTarget,
                                          minHeight: AppSpacing.minTouchTarget,
                                        ),
                                        padding: EdgeInsets.zero,
                                        icon: const TackIcon(
                                          TackIcons.trash,
                                          size: 15,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () => _removeRow(rowIdx),
                                      )
                                    : Center(
                                        child: Text(
                                          '${rowIdx + 1}',
                                          style: AppTypography.caption(
                                            color: tokens.textSecondary,
                                          ),
                                        ),
                                      ),
                              ),
                              ...List.generate(_headerCtrls.length, (colIdx) {
                                return Container(
                                  width: 184,
                                  margin: const EdgeInsets.only(right: 8, bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tokens.canvasSunken,
                                    borderRadius: AppSpacing.roundedSm,
                                    border: Border.all(
                                      color: tokens.borderSubtle,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _rowCtrls[rowIdx][colIdx],
                                    minLines: 1,
                                    maxLines: 4,
                                    keyboardType: TextInputType.multiline,
                                    textAlign: _alignments[colIdx] ==
                                            TableColumnAlign.center
                                        ? TextAlign.center
                                        : (_alignments[colIdx] ==
                                                TableColumnAlign.right
                                            ? TextAlign.right
                                            : TextAlign.left),
                                    style: AppTypography.bodySm(
                                      color: tokens.textPrimary,
                                    ),
                                    decoration: AppInputDecorations.bareWithHint(
                                      'Cell...',
                                      hintStyle: AppTypography.bodySm(
                                        color: tokens.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            Row(
              children: [
                SizedBox(
                  height: AppSpacing.minTouchTarget,
                  child: TextButton(
                    onPressed: _handleClose,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: SizedBox(
                    height: AppSpacing.minTouchTarget,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final updated = _buildTableSnapshot();
                        Navigator.of(context).pop();
                        widget.onSave(updated);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? tokens.textPrimary : AppColors.primaryDark,
                        foregroundColor: isDark ? tokens.surfacePrimary : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedSm,
                        ),
                      ),
                      icon: const TackIcon(TackIcons.check, size: 16),
                      label: Text(
                        'Apply Table Changes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(
                          color: isDark ? tokens.surfacePrimary : Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
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
}

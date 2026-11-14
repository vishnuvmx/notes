import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
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
    final palette = AppColors.getPaletteById(widget.paletteId);
    final accent = palette.resolveAccentColor(isDark);

    return Padding(
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
                child: Text(
                  'Visual Table Editor',
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
              TextButton.icon(
                onPressed: _addColumn,
                icon: const TackIcon(TackIcons.plus, size: 14),
                label: const Text('Column'),
              ),
              TextButton.icon(
                onPressed: _addRow,
                icon: const TackIcon(TackIcons.plus, size: 14),
                label: const Text('Row'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
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
                        const SizedBox(width: 34),
                        ...List.generate(_headerCtrls.length, (colIdx) {
                          return Container(
                            width: 176,
                            margin: const EdgeInsets.only(right: 6, bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        icon: TackIcon(
                                          _alignIcon(_alignments[colIdx]),
                                          size: 15,
                                          color: accent,
                                        ),
                                        tooltip: 'Cycle Alignment',
                                        onPressed: () => _cycleAlign(colIdx),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_headerCtrls.length > 1)
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          icon: const TackIcon(
                                            TackIcons.close,
                                            size: 14,
                                          ),
                                          tooltip: 'Delete Column',
                                          onPressed: () => _removeColumn(colIdx),
                                        ),
                                      ),
                                  ],
                                ),
                                TextField(
                                  controller: _headerCtrls[colIdx],
                                  minLines: 1,
                                  maxLines: 3,
                                  keyboardType: TextInputType.multiline,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  decoration: AppInputDecorations.bareWithHint(
                                    'Header',
                                    hintStyle: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
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
                            width: 34,
                            child: _rowCtrls.length > 1
                                ? IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    icon: const TackIcon(
                                      TackIcons.trash,
                                      size: 14,
                                      color: AppColors.error,
                                    ),
                                    onPressed: () => _removeRow(rowIdx),
                                  )
                                : Center(
                                    child: Text(
                                      '${rowIdx + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted,
                                      ),
                                    ),
                                  ),
                          ),
                          ...List.generate(_headerCtrls.length, (colIdx) {
                            return Container(
                              width: 176,
                              margin: const EdgeInsets.only(right: 6, bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceAlt
                                    : const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
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
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                decoration: AppInputDecorations.bareWithHint(
                                  'Cell...',
                                  hintStyle: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
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
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              final updated = _buildTableSnapshot();
              Navigator.of(context).pop();
              widget.onSave(updated);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : AppColors.primaryDark,
              foregroundColor: isDark ? AppColors.primaryDark : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const TackIcon(TackIcons.check, size: 16),
            label: Text(
              'Apply Table Changes',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

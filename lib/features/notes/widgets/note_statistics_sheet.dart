import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';

/// Clean Modal Bottom Sheet presenting note reading metrics, word counts, and task progress.
class NoteStatisticsSheet extends StatelessWidget {
  final String content;

  const NoteStatisticsSheet({super.key, required this.content});

  /// Displays the NoteStatisticsSheet modally.
  static Future<void> show(BuildContext context, {required String content}) {
    return AppBottomSheet.show(
      context: context,
      builder: (ctx) => NoteStatisticsSheet(content: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final words = content.trim().isEmpty
        ? 0
        : content.trim().split(RegExp(r'\s+')).length;
    final chars = content.length;
    final charsNoSpaces = content.replaceAll(RegExp(r'\s'), '').length;
    final paragraphs = content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .length;
    final readTime = words == 0 ? 0 : ((words / 180).ceil()).clamp(1, 60);

    final totalChecklists = RegExp(r'\[[ xX]\]').allMatches(content).length;
    final completedChecklists = RegExp(r'\[[xX]\]').allMatches(content).length;

    return SingleChildScrollView(
      padding: AppSpacing.modalSheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Note Statistics',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSm(
                    fontSize: 18,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const TackIcon(TackIcons.close, size: 18),
                tooltip: 'Close',
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.minTouchTarget,
                  minHeight: AppSpacing.minTouchTarget,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackSingle = constraints.maxWidth < 290;
              final cards = <Widget>[
                _buildStatCard('Words', '$words', isDark),
                _buildStatCard('Characters', '$chars', isDark),
                _buildStatCard('Chars (no spaces)', '$charsNoSpaces', isDark),
                _buildStatCard('Paragraphs', '$paragraphs', isDark),
                _buildStatCard('Reading Time', '$readTime min read', isDark),
                if (totalChecklists > 0)
                  _buildStatCard(
                    'Tasks',
                    '$completedChecklists/$totalChecklists done',
                    isDark,
                  ),
              ];
              if (stackSingle) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      cards[i],
                    ],
                  ],
                );
              }
              final rows = <Widget>[];
              for (int i = 0; i < cards.length; i += 2) {
                if (i > 0) rows.add(const SizedBox(height: AppSpacing.sm));
                rows.add(
                  Row(
                    children: [
                      Expanded(child: cards[i]),
                      if (i + 1 < cards.length) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: cards[i + 1]),
                      ],
                    ],
                  ),
                );
              }
              return Column(children: rows);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption(
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleSm(
              fontSize: 15,
              weight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

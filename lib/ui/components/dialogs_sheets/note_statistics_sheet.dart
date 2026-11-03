import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import 'app_bottom_sheet.dart';

/// Clean Modal Bottom Sheet presenting note reading metrics, word counts, and task progress.
class NoteStatisticsSheet extends StatelessWidget {
  final String content;

  const NoteStatisticsSheet({
    super.key,
    required this.content,
  });

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

    final words = content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;
    final chars = content.length;
    final charsNoSpaces = content.replaceAll(RegExp(r'\s'), '').length;
    final paragraphs = content.split('\n').where((l) => l.trim().isNotEmpty).length;
    final readTime = ((words / 180).ceil()).clamp(1, 60);

    final totalChecklists = RegExp(r'\[[ xX]\]').allMatches(content).length;
    final completedChecklists = RegExp(r'\[[xX]\]').allMatches(content).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Note Statistics',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              IconButton(
                icon: const TackIcon(TackIcons.close, size: 18),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _buildStatCard('Words', '$words', isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildStatCard('Characters', '$chars', isDark),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _buildStatCard('Chars (no spaces)', '$charsNoSpaces', isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildStatCard('Paragraphs', '$paragraphs', isDark),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _buildStatCard('Reading Time', '$readTime min read', isDark),
                if (totalChecklists > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _buildStatCard('Tasks', '$completedChecklists/$totalChecklists done', isDark),
                ],
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildStatCard(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

enum SmartActionType {
  tidy,
  checklist,
  summarize,
  titleTags,
}

/// Clean, tactile bottom sheet for triggering Tack Smart Actions.
/// Follows Tack's native stationery design language with zero AI slop.
class SmartActionsSheet extends StatelessWidget {
  const SmartActionsSheet({super.key});

  static Future<SmartActionType?> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<SmartActionType>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SmartActionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      (
        type: SmartActionType.tidy,
        title: 'Tidy & Polish',
        subtitle: 'Fix formatting, typos & flow',
        icon: TackIcons.pencil,
        color: AppColors.pastelPeachLight,
        darkColor: AppColors.pastelPeachDark,
      ),
      (
        type: SmartActionType.checklist,
        title: 'Extract Checklist',
        subtitle: 'Turn tasks into interactive checkboxes',
        icon: TackIcons.checkCircle,
        color: AppColors.pastelAmberLight,
        darkColor: AppColors.pastelAmberDark,
      ),
      (
        type: SmartActionType.summarize,
        title: '3 Key Takeaways',
        subtitle: 'Add concise summary bullets at top',
        icon: TackIcons.listView,
        color: AppColors.pastelCyanLight,
        darkColor: AppColors.pastelCyanDark,
      ),
      (
        type: SmartActionType.titleTags,
        title: 'Suggest Title & Tags',
        subtitle: 'Auto-name and categorize note',
        icon: TackIcons.tag,
        color: AppColors.pastelLimeLight,
        darkColor: AppColors.pastelLimeDark,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : const Color(0xFF191A23).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFF191A23).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sheet Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: isDark ? 0.25 : 0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Center(
                  child: TackIcon(TackIcons.bolt, size: 17, color: AppColors.accentAmber),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Smart Actions',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action items list in a single grouped tactile container
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  _buildActionTile(
                    context: context,
                    action: actions[i],
                    isDark: isDark,
                  ),
                  if (i < actions.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 52,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required ({
      SmartActionType type,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      Color darkColor,
    }) action,
    required bool isDark,
  }) {
    final badgeColor = isDark ? action.darkColor : action.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop(action.type);
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: isDark ? 0.35 : 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: TackIcon(
                    action.icon,
                    size: 17,
                    color: isDark ? action.color : action.darkColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      action.subtitle,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TackIcon(
                TackIcons.chevronDown,
                size: 14,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

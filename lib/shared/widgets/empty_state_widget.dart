import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/tack_icons.dart';

/// Playful, soft empty state illustration with cute HeroIcons.
class EmptyStateWidget extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showMascot;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.showMascot = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showMascot)
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE05D5D).withValues(alpha: isDark ? 0.25 : 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      color: isDark ? AppColors.darkSurfaceAlt : AppColors.pastelPeachSoft,
                      child: Center(
                        child: TackIcon(
                          icon,
                          size: 40,
                          color: isDark ? AppColors.pastelPeachLight : AppColors.accentOrange,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceAlt : AppColors.pastelPeachSoft,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: TackIcon(
                    icon,
                    size: 38,
                    color: isDark ? AppColors.pastelPeachLight : AppColors.accentOrange,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const TackIcon(TackIcons.plus, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.lightSurface : AppColors.primaryDark,
                  foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

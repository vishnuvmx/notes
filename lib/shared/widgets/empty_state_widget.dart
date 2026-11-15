import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tack_icons.dart';

/// Playful, soft empty state illustration with HeroIcons / optional mascot.
class EmptyStateWidget extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final dynamic actionIcon;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool showMascot;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.showMascot = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
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
                        color: tokens.accentPin.withValues(
                          alpha: tokens.isDark ? 0.25 : 0.18,
                        ),
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
                        color: tokens.canvasSunken,
                        child: Center(
                          child: TackIcon(
                            icon,
                            size: 40,
                            color: tokens.accentPin,
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
                    color: tokens.canvasSunken,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: TackIcon(
                      icon,
                      size: 36,
                      color: tokens.accentPin,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.s5),
              Text(
                title,
                style: AppTypography.title(color: tokens.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                subtitle,
                style: AppTypography.bodySm(color: tokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.s5),
                if (actionIcon != null)
                  ElevatedButton.icon(
                    onPressed: onAction,
                    icon: TackIcon(
                      actionIcon,
                      size: 18,
                      color: tokens.actionPrimaryFg,
                    ),
                    label: Text(actionLabel!),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, AppSpacing.minTouchTarget),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s5,
                      ),
                      backgroundColor: tokens.actionPrimary,
                      foregroundColor: tokens.actionPrimaryFg,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedPill,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, AppSpacing.minTouchTarget),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s5,
                      ),
                      backgroundColor: tokens.actionPrimary,
                      foregroundColor: tokens.actionPrimaryFg,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedPill,
                      ),
                    ),
                    child: Text(actionLabel!),
                  ),
              ],
              if (secondaryActionLabel != null &&
                  onSecondaryAction != null) ...[
                const SizedBox(height: AppSpacing.s2),
                TextButton(
                  onPressed: onSecondaryAction,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, AppSpacing.minTouchTarget),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s4,
                    ),
                    foregroundColor: tokens.textSecondary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedPill,
                    ),
                  ),
                  child: Text(secondaryActionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

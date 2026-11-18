import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tack_icons.dart';
import 'tactile_ink_target.dart';

/// Soft Monochrome Header App Bar for Tack's 4 main views (`Today`, `Library`, `Boards`, `Search`).
/// Styled after `docs/design/11-reference-ui-style.md` (Screenshot 2 & 3):
/// - Bold title + optional count pill on the left
/// - Optional italic DM Sans tagline below the title (e.g. "Let's make progress today!")
/// - Soft white squircle icon buttons on the right with diffused elevation
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final String? tagline;
  final Widget? trailingAction;
  final VoidCallback onOpenProfileSettings;
  final bool primary;

  const AppHeaderBar({
    super.key,
    required this.title,
    this.subtitle,
    this.tagline,
    this.trailingAction,
    required this.onOpenProfileSettings,
    this.primary = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        tagline != null && tagline!.isNotEmpty ? 78 : AppSpacing.appBarHeight,
      );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasTagline = tagline != null && tagline!.isNotEmpty;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final barHeight = hasTagline
        ? (78 * textScale.clamp(1.0, 1.35))
        : (AppSpacing.appBarHeight * textScale.clamp(1.0, 1.25));

    return AppBar(
      primary: primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: tokens.canvasPrimary,
      automaticallyImplyLeading: false,
      toolbarHeight: barHeight,
      titleSpacing: AppSpacing.s5,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLg(color: tokens.textPrimary),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.s2),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.surfacePrimary,
                      borderRadius: AppSpacing.roundedPill,
                      boxShadow: AppSpacing.elev1(tokens.isDark),
                    ),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(
                        color: tokens.textSecondary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (hasTagline) ...[
            const SizedBox(height: 1),
            Text(
              tagline!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.serifItalic(
                color: tokens.textSecondary,
                fontSize: 15.5,
              ),
            ),
          ],
        ],
      ),
      actions: [
        ?trailingAction,
        Tooltip(
          message: 'Profile & Settings',
          child: TactileInkTarget(
            key: const ValueKey('header_you_button'),
            semanticsLabel: 'Profile & Settings',
            width: 38,
            height: 38,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
            color: tokens.surfacePrimary,
            boxShadow: AppSpacing.elev1(tokens.isDark),
            triggerHaptics: true,
            onTap: onOpenProfileSettings,
            child: TackIcon(
              TackIcons.user,
              size: 18,
              color: tokens.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
      ],
    );
  }
}

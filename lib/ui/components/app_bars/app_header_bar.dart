import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// Soft Monochrome Header App Bar for Tack's 4 main views (`Today`, `Library`, `Boards`, `Search`).
/// Styled after `docs/design/11-reference-ui-style.md` (Screenshot 2 & 3):
/// - Bold title + optional count pill on the left
/// - Optional editorial italic serif tagline below the title (e.g. "Let's make progress today!")
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

    return AppBar(
      primary: primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: tokens.canvasPrimary,
      automaticallyImplyLeading: false,
      toolbarHeight: hasTagline ? 78 : AppSpacing.appBarHeight,
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
                Container(
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
                    style: AppTypography.caption(
                      color: tokens.textSecondary,
                      weight: FontWeight.w600,
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
        Semantics(
          button: true,
          label: 'Profile & Settings',
          child: IconButton(
            key: const ValueKey('header_you_button'),
            onPressed: () {
              HapticFeedback.selectionClick();
              onOpenProfileSettings();
            },
            tooltip: 'Profile & Settings',
            style: IconButton.styleFrom(
              minimumSize: const Size(
                AppSpacing.minTouchTarget,
                AppSpacing.minTouchTarget,
              ),
              padding: EdgeInsets.zero,
            ),
            icon: Container(
              width: 38,
              height: 38,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: tokens.surfacePrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppSpacing.elev1(tokens.isDark),
              ),
              child: Center(
                child: TackIcon(
                  TackIcons.user,
                  size: 18,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
      ],
    );
  }
}

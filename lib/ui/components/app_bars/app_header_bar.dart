import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// Top header app bar for Tack's 4 main views (`Today`, `Library`, `Boards`, `Search`).
/// Adheres to `05-information-architecture.md` §2.1 & `07-design-system.md` §7:
/// - 56dp height on `canvas/primary`
/// - Screen title (`title-lg`) on the left
/// - At most 2 actions (`48x48dp`) on the right, including the **You** sheet trigger
/// - Retires the static "Welcome back 👋" greeting, drawer mascot, and header theme toggle
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? trailingAction;
  final VoidCallback onOpenYouSheet;
  final bool primary;

  const AppHeaderBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingAction,
    required this.onOpenYouSheet,
    this.primary = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AppBar(
      primary: primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: tokens.canvasPrimary,
      automaticallyImplyLeading: false,
      toolbarHeight: AppSpacing.appBarHeight,
      titleSpacing: AppSpacing.s5,
      title: Row(
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
            const SizedBox(width: AppSpacing.s3),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: tokens.canvasSunken,
                borderRadius: AppSpacing.roundedPill,
                border: Border.all(color: tokens.borderSubtle, width: 1),
              ),
              child: Text(
                subtitle!,
                style: AppTypography.caption(
                  color: tokens.textSecondary,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        ?trailingAction,
        Semantics(
          button: true,
          label: 'You — Settings, Backup, and Trash',
          child: IconButton(
            key: const ValueKey('header_you_button'),
            onPressed: () {
              HapticFeedback.selectionClick();
              onOpenYouSheet();
            },
            tooltip: 'You & Settings',
            style: IconButton.styleFrom(
              minimumSize: const Size(
                AppSpacing.minTouchTarget,
                AppSpacing.minTouchTarget,
              ),
              padding: EdgeInsets.zero,
            ),
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tokens.surfacePrimary,
                shape: BoxShape.circle,
                border: Border.all(color: tokens.borderSubtle, width: 1),
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
        const SizedBox(width: AppSpacing.s2),
      ],
    );
  }
}

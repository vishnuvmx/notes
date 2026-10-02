import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/theme_provider.dart';
import '../../../state/workspace_provider.dart';

/// Top header app bar for Tack home screen matching reference mockup.
/// Features avatar, "Hey there, friend", search, and theme toggle.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onToggleSearch;
  final bool isSearching;
  final VoidCallback onQuickCreate;
  final String userName;

  const AppHeaderBar({
    super.key,
    required this.onOpenDrawer,
    required this.onToggleSearch,
    required this.isSearching,
    required this.onQuickCreate,
    this.userName = 'friend',
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProv = context.watch<ThemeProvider>();
    final workspace = context.watch<WorkspaceProvider>();

    final iconColor = isDark ? Colors.white : const Color(0xFF191A23);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFF191A23);

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.lg,
      title: isSearching
          ? Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF1F3F7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E6EC),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  TackIcon(
                    TackIcons.search,
                    size: 18,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search notes, stickies, whiteboards...',
                        hintStyle: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13.5,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => context.read<WorkspaceProvider>().setSearchQuery(val),
                    ),
                  ),
                  if (workspace.searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        context.read<WorkspaceProvider>().setSearchQuery('');
                      },
                      child: TackIcon(
                        TackIcons.close,
                        size: 16,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                ],
              ),
            )
          : Row(
              children: [
                // Cute Tack Mascot Avatar button (opens drawer)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onOpenDrawer();
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: borderColor.withValues(alpha: 0.12),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'icon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => TackIcon(
                          TackIcons.user,
                          size: 20,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Playful greeting
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Hey there, ',
                      style: AppTypography.welcomeGreetingStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: userName,
                          style: AppTypography.welcomeUsernameStyle(
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
      actions: [
        if (isSearching)
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onToggleSearch();
            },
            icon: TackIcon(
              TackIcons.close,
              size: 20,
              color: iconColor,
            ),
            tooltip: 'Close Search',
            style: IconButton.styleFrom(
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
          )
        else ...[
          // Search Button
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onToggleSearch();
            },
            icon: TackIcon(
              TackIcons.search,
              size: 20,
              color: iconColor,
            ),
            tooltip: 'Search Notes',
            style: IconButton.styleFrom(
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
          ),

          // Quick Theme Toggle
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              themeProv.toggleTheme(context);
            },
            icon: TackIcon(
              isDark ? TackIcons.sun : TackIcons.moon,
              size: 20,
              color: isDark ? AppColors.pastelAmberLight : iconColor,
              style: isDark ? HeroIconStyle.solid : HeroIconStyle.outline,
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            style: IconButton.styleFrom(
              minimumSize: const Size(38, 38),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}


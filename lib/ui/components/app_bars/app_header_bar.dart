import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/theme_provider.dart';
import '../../../state/workspace_provider.dart';
import '../inputs/app_search_field.dart';

/// Top header app bar for Tack home screen matching reference mockup.
/// Features avatar, greeting, search, and theme toggle.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onToggleSearch;
  final bool isSearching;
  final VoidCallback? onQuickCreate;
  final String userName;
  final bool primary;

  const AppHeaderBar({
    super.key,
    required this.onOpenDrawer,
    required this.onToggleSearch,
    required this.isSearching,
    this.onQuickCreate,
    this.userName = 'friend',
    this.primary = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProv = context.watch<ThemeProvider>();
    final workspace = context.watch<WorkspaceProvider>();

    final iconColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return AppBar(
      primary: primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.lg,
      title: isSearching
          ? AppSearchField(
              autofocus: true,
              hintText: 'Search notes, stickies, whiteboards...',
              onChanged: (val) => context.read<WorkspaceProvider>().setSearchQuery(val),
              onClear: () => context.read<WorkspaceProvider>().setSearchQuery(''),
            )
          : Row(
              children: [
                // Tack Mascot Avatar button (opens drawer) with 48x48dp touch target
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onOpenDrawer();
                  },
                  tooltip: 'Open Menu',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                  ),
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE05D5D).withValues(alpha: isDark ? 0.35 : 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
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
                              TackIcons.note,
                              size: 20,
                              color: isDark ? AppColors.pastelPeachLight : AppColors.accentOrange,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Greeting text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Welcome back ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.welcomeGreetingStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                          const Text('👋', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Workspace',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
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
              minimumSize: const Size(48, 48),
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
              minimumSize: const Size(48, 48),
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
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

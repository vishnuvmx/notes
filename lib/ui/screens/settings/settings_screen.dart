import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/theme_provider.dart';

/// Settings & Preferences screen for Tack with cute HeroIcons.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProv = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // App Brand Header Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              boxShadow: isDark ? AppSpacing.softShadowDark : AppSpacing.softShadowLight,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'icon.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const TackIcon(TackIcons.pin, size: 40),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tack',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tactile notes, sticky pastels & whiteboard flowchart canvas.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Appearance Section
          Text(
            'APPEARANCE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('System Default'),
                  leading: const TackIcon(TackIcons.settings, size: 22),
                  trailing: themeProv.themeMode == ThemeMode.system
                      ? const TackIcon(TackIcons.check, size: 18, color: AppColors.accentAmber, style: HeroIconStyle.solid)
                      : null,
                  onTap: () => themeProv.setThemeMode(ThemeMode.system),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Light Mode'),
                  leading: const TackIcon(TackIcons.sun, size: 22),
                  trailing: themeProv.themeMode == ThemeMode.light
                      ? const TackIcon(TackIcons.check, size: 18, color: AppColors.accentAmber, style: HeroIconStyle.solid)
                      : null,
                  onTap: () => themeProv.setThemeMode(ThemeMode.light),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Dark Mode'),
                  leading: const TackIcon(TackIcons.moon, size: 22),
                  trailing: themeProv.themeMode == ThemeMode.dark
                      ? const TackIcon(TackIcons.check, size: 18, color: AppColors.accentAmber, style: HeroIconStyle.solid)
                      : null,
                  onTap: () => themeProv.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Typography & Design Info
          Text(
            'DESIGN SYSTEM & ICONS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Icon Pack', 'HeroIcons (Cute Rounded Aesthetics)'),
                const SizedBox(height: 8),
                _buildInfoRow('Font Family', 'DM Sans (-2% letter spacing)'),
                const SizedBox(height: 8),
                _buildInfoRow('Color Tokens', '8 Curated Sticky Pastels + Dark Surfacing'),
                const SizedBox(height: 8),
                _buildInfoRow('Architecture', 'Clean OOP Domain & Repository Pattern'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

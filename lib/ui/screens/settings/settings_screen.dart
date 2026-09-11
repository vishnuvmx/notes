import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/theme_provider.dart';
import '../../../state/workspace_provider.dart';

/// Settings & Preferences screen for Tack with cute HeroIcons.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportBackup(BuildContext context) async {
    final workspace = context.read<WorkspaceProvider>();
    final jsonStr = workspace.exportWorkspaceJson();

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${tempDir.path}/tack_backup_$timestamp.json');
      await file.writeAsString(jsonStr);

      await SharePlus.instance.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Tack Workspace Backup',
      );
    } catch (e) {
      // Fallback to text share if file system write fails
      await SharePlus.instance.share(
        jsonStr,
        subject: 'Tack Workspace Backup',
      );
    }
  }

  Future<void> _showRestoreDialog(BuildContext context) async {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.roundedLg,
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              title: Row(
                children: [
                  const TackIcon(TackIcons.importData, size: 24, color: AppColors.accentAmber),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Restore Workspace',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Paste JSON backup data below to restore your notes, whiteboards, and stickies.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      icon: const TackIcon(TackIcons.clipboard, size: 18),
                      label: const Text('Paste from Clipboard'),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null && data!.text!.trim().isNotEmpty) {
                          setDialogState(() {
                            controller.text = data.text!.trim();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: controller,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: '{\n  "app": "Tack",\n  "items": [...]\n}',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.roundedMd,
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentAmber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                  child: const Text('Restore', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final text = controller.text.trim();
      if (text.isEmpty) return;

      try {
        final count = await context.read<WorkspaceProvider>().importWorkspaceJson(text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully restored $count items into workspace.'),
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.roundedMd,
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restore failed: Invalid backup format.'),
              backgroundColor: AppColors.pastelCoralLight,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProv = context.watch<ThemeProvider>();
    final workspace = context.watch<WorkspaceProvider>();

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
                ClipOval(
                  child: Image.asset(
                    'icon.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
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

          // Workspace Overview Stats
          Text(
            'WORKSPACE OVERVIEW',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: _buildStatBadge(
                  context,
                  label: 'Notes',
                  count: workspace.totalActiveNotesCount,
                  color: AppColors.pastelPeachLight,
                  icon: TackIcons.notes,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatBadge(
                  context,
                  label: 'Stickies',
                  count: workspace.totalStickiesCount,
                  color: AppColors.pastelAmberLight,
                  icon: TackIcons.sticky,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatBadge(
                  context,
                  label: 'Boards',
                  count: workspace.totalWhiteboardsCount,
                  color: AppColors.pastelCyanLight,
                  icon: TackIcons.whiteboard,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatBadge(
                  context,
                  label: 'Clips',
                  count: workspace.totalClipsCount,
                  color: AppColors.pastelLimeLight,
                  icon: TackIcons.clipboard,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Data & Backup Section
          Text(
            'DATA & BACKUP',
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
                  title: const Text('Export Workspace Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Export all items into a JSON backup bundle to keep or transfer.'),
                  leading: const TackIcon(TackIcons.exportData, size: 22, color: AppColors.accentAmber),
                  trailing: const TackIcon(TackIcons.share, size: 18),
                  onTap: () => _exportBackup(context),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Restore from Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Import or restore items from a JSON backup or clipboard.'),
                  leading: const TackIcon(TackIcons.importData, size: 22, color: AppColors.pastelCyanLight),
                  trailing: const TackIcon(TackIcons.chevronDown, size: 18),
                  onTap: () => _showRestoreDialog(context),
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
                const Divider(),
                ListTile(
                  title: const Text('System Default'),
                  leading: const TackIcon(TackIcons.settings, size: 22),
                  trailing: themeProv.themeMode == ThemeMode.system
                      ? const TackIcon(TackIcons.check, size: 18, color: AppColors.accentAmber, style: HeroIconStyle.solid)
                      : null,
                  onTap: () => themeProv.setThemeMode(ThemeMode.system),
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

  Widget _buildStatBadge(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required HeroIcons icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.25),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.4 : 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          TackIcon(icon, size: 18, color: isDark ? Colors.white : AppColors.lightTextPrimary),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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


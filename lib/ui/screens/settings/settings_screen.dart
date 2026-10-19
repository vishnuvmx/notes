import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/theme_provider.dart';
import '../../../state/workspace_provider.dart';
import '../../components/feedback/tack_toast.dart';
import 'about_tack_screen.dart';

/// Clean, tactile Settings screen for Tack.
/// Features theme control, workspace preferences, offline storage health,
/// robust export/restore backups, and deep-dive About Tack session.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportBackup(BuildContext context) async {
    final workspace = context.read<WorkspaceProvider>();
    final jsonStr = workspace.exportWorkspaceJson();

    try {
      final tempDir = await getTemporaryDirectory();
      final docsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

      // Save to docs directory for local redundancy
      final localBackup = File('${docsDir.path}/tack_backup_$timestamp.json');
      await localBackup.writeAsString(jsonStr);

      // Save to temp dir for sharing
      final file = File('${tempDir.path}/tack_backup_$timestamp.json');
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        TackToast.show(
          context,
          message: 'Exported ${workspace.rawItems.length} items to backup',
          icon: TackIcons.checkCircle,
          iconColor: AppColors.success,
          bottomMargin: 88,
        );
      }

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Tack Workspace Backup ($timestamp)',
      );
    } catch (_) {
      // Fallback to text share
      // ignore: deprecated_member_use
      await Share.share(
        jsonStr,
        subject: 'Tack Workspace Backup',
      );
    }
  }

  Future<void> _showRestoreDialog(BuildContext context) async {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        String? validationMessage;
        bool isValid = false;

        void validateInput(String text, void Function(void Function()) setDialogState) {
          final trimmed = text.trim();
          if (trimmed.isEmpty) {
            setDialogState(() {
              validationMessage = null;
              isValid = false;
            });
            return;
          }

          try {
            final dynamic decoded = jsonDecode(trimmed);
            int count = 0;
            if (decoded is Map<String, dynamic> && decoded.containsKey('items')) {
              count = (decoded['items'] as List<dynamic>).length;
            } else if (decoded is List<dynamic>) {
              count = decoded.length;
            }

            setDialogState(() {
              if (count > 0) {
                validationMessage = '✓ Valid Tack backup: $count items found';
                isValid = true;
              } else {
                validationMessage = '⚠ Backup contains 0 items';
                isValid = false;
              }
            });
          } catch (_) {
            setDialogState(() {
              validationMessage = '⚠ Invalid JSON format';
              isValid = false;
            });
          }
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              title: const Text(
                'Restore Backup',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Paste or import a previously exported Tack JSON backup to restore your workspace.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const TackIcon(TackIcons.clipboard, size: 16),
                      label: const Text(
                        'Paste from Clipboard',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        final text = data?.text?.trim() ?? '';
                        if (text.isNotEmpty) {
                          controller.text = text;
                          validateInput(text, setDialogState);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      onChanged: (val) => validateInput(val, setDialogState),
                      decoration: InputDecoration(
                        hintText: 'Paste backup JSON content here...',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    if (validationMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        validationMessage!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isValid ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
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
                    backgroundColor: isValid ? AppColors.primaryDark : AppColors.lightTextMuted,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: isValid ? () => Navigator.of(dialogCtx).pop(true) : null,
                  child: const Text('Restore', style: TextStyle(fontWeight: FontWeight.w600)),
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
          TackToast.show(
            context,
            message: 'Successfully restored $count items',
            icon: TackIcons.checkCircle,
            iconColor: AppColors.success,
            bottomMargin: 88,
          );
        }
      } catch (_) {
        if (context.mounted) {
          TackToast.show(
            context,
            message: 'Failed to restore: Invalid backup structure',
            icon: TackIcons.trash,
            iconColor: AppColors.error,
            bottomMargin: 88,
          );
        }
      }
    }
  }

  Future<void> _confirmEmptyTrash(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        title: const Text('Empty Trash?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: const Text(
          'All items in trash will be permanently deleted. This cannot be undone.',
          style: TextStyle(fontSize: 14, height: 1.4),
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
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      HapticFeedback.mediumImpact();
      await context.read<WorkspaceProvider>().emptyTrash();
      if (context.mounted) {
        TackToast.show(
          context,
          message: 'Trash emptied',
          icon: TackIcons.trash,
          iconColor: AppColors.success,
          bottomMargin: 88,
        );
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const TackIcon(TackIcons.back, size: 22),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          tooltip: 'Back',
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        children: [
          // Theme Section
          _buildSectionTitle('Theme & Appearance', isDark),
          const SizedBox(height: 6),
          _buildThemeSelector(context, themeProv, isDark),
          const SizedBox(height: 20),

          // Workspace Overview & Local Storage Health
          _buildSectionTitle('Workspace & Storage Health', isDark),
          const SizedBox(height: 6),
          _buildStorageOverviewCard(workspace, isDark),
          const SizedBox(height: 20),

          // Workspace Preferences (Replaces Status Bar & Quick Settings)
          _buildSectionTitle('Workspace Preferences', isDark),
          const SizedBox(height: 6),
          _buildCardGroup(
            isDark: isDark,
            children: [
              _buildSwitchTile(
                title: 'Home View Layout',
                subtitle: workspace.viewMode == HomeViewMode.stickyGrid ? 'Tactile Grid Cards' : 'Spiral Notebook List',
                icon: workspace.viewMode == HomeViewMode.stickyGrid ? TackIcons.gridView : TackIcons.listView,
                value: workspace.viewMode == HomeViewMode.stickyGrid,
                isDark: isDark,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  workspace.setViewMode(val ? HomeViewMode.stickyGrid : HomeViewMode.notebook);
                },
              ),
              _buildDivider(isDark),
              _buildStaticInfoTile(
                icon: TackIcons.bolt,
                title: 'Tactile Haptic Feedback',
                subtitle: 'Hardware haptic vibrations on cards, gestures, and long-press menus',
                badgeText: 'Active',
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildStaticInfoTile(
                icon: TackIcons.lock,
                title: 'Offline-First Privacy',
                subtitle: 'Local on-device JSON storage without remote servers.',
                badgeText: 'Local',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Data Management Section (Export & Restore Backup)
          _buildSectionTitle('Data & Backup', isDark),
          const SizedBox(height: 6),
          _buildCardGroup(
            isDark: isDark,
            children: [
              _buildTile(
                icon: TackIcons.exportData,
                title: 'Export Backup',
                subtitle: 'Save or share workspace JSON file',
                onTap: () => _exportBackup(context),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildTile(
                icon: TackIcons.importData,
                title: 'Restore Backup',
                subtitle: 'Import notes, stickies, and boards',
                onTap: () => _showRestoreDialog(context),
                isDark: isDark,
              ),
              if (workspace.trashItems.isNotEmpty) ...[
                _buildDivider(isDark),
                _buildTile(
                  icon: TackIcons.trash,
                  title: 'Empty Trash',
                  subtitle: '${workspace.trashItems.length} items to permanently delete',
                  isDestructive: true,
                  onTap: () => _confirmEmptyTrash(context),
                  isDark: isDark,
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // About Section
          _buildSectionTitle('About Tack', isDark),
          const SizedBox(height: 6),
          _buildCardGroup(
            isDark: isDark,
            children: [
              _buildTile(
                icon: TackIcons.notes,
                title: 'About Tack',
                subtitle: 'Tech stack journey & open-source libraries',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutTackScreen()),
                  );
                },
                isDark: isDark,
              ),
              _buildDivider(isDark),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      'Tack for Android',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFEFF1F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildStorageOverviewCard(WorkspaceProvider workspace, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'On-Device Storage',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${workspace.rawItems.length} total items',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatPill(
                label: 'Notes',
                count: workspace.totalActiveNotesCount,
                color: AppColors.pastelCyanLight,
                isDark: isDark,
              ),
              _buildStatPill(
                label: 'Stickies',
                count: workspace.totalStickiesCount,
                color: AppColors.pastelAmberLight,
                isDark: isDark,
              ),
              _buildStatPill(
                label: 'Boards',
                count: workspace.totalWhiteboardsCount,
                color: AppColors.pastelLimeLight,
                isDark: isDark,
              ),
              _buildStatPill(
                label: 'Clips',
                count: workspace.totalClipsCount,
                color: AppColors.pastelLavenderLight,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.4 : 0.45),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeProvider themeProv, bool isDark) {
    final modes = [
      (ThemeMode.light, 'Light', TackIcons.sun),
      (ThemeMode.dark, 'Dark', TackIcons.moon),
      (ThemeMode.system, 'System', TackIcons.settings),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: modes.map((entry) {
          final isSelected = themeProv.themeMode == entry.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                themeProv.setThemeMode(entry.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.darkSurface : AppColors.lightSurfaceAlt)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TackIcon(
                      entry.$3,
                      size: 15,
                      color: isSelected
                          ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.$2,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardGroup({required List<Widget> children, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          TackIcon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.accentCyan,
          ),
        ],
      ),
    );
  }

  Widget _buildStaticInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          TackIcon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFEFF1F5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.pastelCyanLight : AppColors.pastelCyanDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              TackIcon(
                icon,
                size: 18,
                color: isDestructive
                    ? AppColors.error
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: isDestructive
                            ? AppColors.error
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
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

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 48,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}

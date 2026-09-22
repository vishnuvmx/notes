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
import '../../../domain/services/pinned_notification_service.dart';

/// Clean, tactile Settings screen for Tack.
/// Minimal stationery design language with zero bloat or marketing fluff.
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

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Tack Workspace Backup',
      );
    } catch (_) {
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
                        if (data?.text != null && data!.text!.trim().isNotEmpty) {
                          setDialogState(() {
                            controller.text = data.text!.trim();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Paste backup JSON content...',
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
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restored $count items'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid backup JSON'),
              behavior: SnackBarBehavior.floating,
            ),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          _buildSectionTitle('Theme', isDark),
          const SizedBox(height: 6),
          _buildThemeSelector(context, themeProv, isDark),
          const SizedBox(height: 20),

          // Android System Integration Section
          _buildSectionTitle('System & Android', isDark),
          const SizedBox(height: 6),
          _buildCardGroup(
            isDark: isDark,
            children: [
              _QuickCaptureSettingsTile(isDark: isDark),
              _buildDivider(isDark),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    TackIcon(
                      TackIcons.tag,
                      size: 18,
                      color: isDark ? AppColors.pastelCyanLight : AppColors.pastelCyanDark,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Settings Tile',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add "Quick Note" in Android notification panel for 1-tap capture anywhere',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Data Management Section
          _buildSectionTitle('Data & Workspace', isDark),
          const SizedBox(height: 6),
          _buildCardGroup(
            isDark: isDark,
            children: [
              _buildTile(
                icon: TackIcons.exportData,
                title: 'Export Backup',
                subtitle: 'Save JSON file',
                onTap: () => _exportBackup(context),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildTile(
                icon: TackIcons.importData,
                title: 'Restore Backup',
                subtitle: 'Import notes and boards',
                onTap: () => _showRestoreDialog(context),
                isDark: isDark,
              ),
              if (workspace.trashItems.isNotEmpty) ...[
                _buildDivider(isDark),
                _buildTile(
                  icon: TackIcons.trash,
                  title: 'Empty Trash',
                  subtitle: '${workspace.trashItems.length} items',
                  isDestructive: true,
                  onTap: () => _confirmEmptyTrash(context),
                  isDark: isDark,
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // About Section
          _buildSectionTitle('About', isDark),
          const SizedBox(height: 6),
          _buildCardGroup(
            isDark: isDark,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Text(
                      'Tack',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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

class _QuickCaptureSettingsTile extends StatefulWidget {
  final bool isDark;
  const _QuickCaptureSettingsTile({required this.isDark});

  @override
  State<_QuickCaptureSettingsTile> createState() => _QuickCaptureSettingsTileState();
}

class _QuickCaptureSettingsTileState extends State<_QuickCaptureSettingsTile> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    PinnedNotificationService.isQuickCaptureEnabled().then((val) {
      if (mounted) setState(() => _enabled = val);
    });
  }

  void _onToggle(bool val) async {
    HapticFeedback.lightImpact();
    setState(() => _enabled = val);
    await PinnedNotificationService.setQuickCaptureEnabled(val);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          TackIcon(
            TackIcons.notification,
            size: 18,
            color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Bar Quick Capture',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Persistent 1-tap note capture in notification drawer',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _enabled,
            onChanged: _onToggle,
            activeTrackColor: AppColors.accentCyan,
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/theme_provider.dart';
import '../../../state/workspace_provider.dart';

/// Clean, tactile Settings & Preferences screen matching Tack's design language.
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
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              title: const Row(
                children: [
                  TackIcon(TackIcons.importData, size: 20, color: AppColors.accentAmber),
                  SizedBox(width: 8),
                  Text(
                    'Restore Workspace',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                ],
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const TackIcon(TackIcons.clipboard, size: 16),
                      label: const Text(
                        'Paste from Clipboard',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
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
                      style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Paste backup JSON here...',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          fontSize: 11.5,
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentAmber, width: 1.5),
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
                    backgroundColor: AppColors.accentAmber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
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
              content: Text('Successfully restored $count items.'),
              backgroundColor: isDark ? const Color(0xFF14151B) : const Color(0xFF191A23),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFF2C2E3B)),
              ),
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Restore failed: Invalid backup JSON.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        title: const Text('Empty Trash?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: const Text(
          'All items in trash will be permanently removed.',
          style: TextStyle(fontSize: 13),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Empty', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      HapticFeedback.mediumImpact();
      await context.read<WorkspaceProvider>().emptyTrash();
    }
  }

  Future<void> _showServerConfigDialog(BuildContext context) async {
    final currentUrl = await ApiConfig.getBaseUrl();
    final defaultUrl = ApiConfig.defaultBaseUrl;
    final controller = TextEditingController(text: currentUrl);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        String? testStatus;
        bool isTesting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              title: const Row(
                children: [
                  TackIcon(TackIcons.bolt, size: 20, color: AppColors.accentAmber),
                  SizedBox(width: 8),
                  Text('AI Server Connection', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                ],
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Default: $defaultUrl\nUse localhost for emulator, local Wi-Fi IP (192.168.x.x:3000) for phone, or production cloud URL.',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: defaultUrl,
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onPressed: isTesting
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isTesting = true;
                                    testStatus = 'Testing...';
                                  });
                                  final ok = await ApiConfig.checkServerHealth(controller.text.trim());
                                  setDialogState(() {
                                    isTesting = false;
                                    testStatus = ok ? 'Connected successfully!' : 'Connection failed';
                                  });
                                },
                          child: Text(
                            isTesting ? 'Testing...' : 'Test Connection',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            controller.text = defaultUrl;
                          },
                          child: const Text('Reset', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    if (testStatus != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        testStatus!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: testStatus!.contains('success') ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentAmber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await ApiConfig.setBaseUrl(controller.text.trim());
                    if (context.mounted) Navigator.of(dialogCtx).pop();
                  },
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProv = context.watch<ThemeProvider>();
    final workspace = context.watch<WorkspaceProvider>();

    return Scaffold(
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
          // App Brand Header Card
          _buildBrandHeader(context, isDark),
          const SizedBox(height: 22),

          // Appearance Section
          _buildSectionLabel('APPEARANCE', isDark),
          const SizedBox(height: 8),
          _buildThemeSegmentedControl(context, themeProv, isDark),
          const SizedBox(height: 22),

          // Workspace Overview Stats
          _buildSectionLabel('WORKSPACE OVERVIEW', isDark),
          const SizedBox(height: 8),
          _buildWorkspaceStats(context, workspace, isDark),
          const SizedBox(height: 22),

          // Data & Storage Section
          _buildSectionLabel('DATA & STORAGE', isDark),
          const SizedBox(height: 8),
          _buildDataSection(context, workspace, isDark),
          const SizedBox(height: 32),

          // Clean subtle footer
          Center(
            child: Text(
              'Tack • Made with tactile care',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF191A23).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                child: const Center(
                  child: TackIcon(TackIcons.pin, size: 22, color: AppColors.accentAmber),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Tack',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentAmber.withValues(alpha: isDark ? 0.2 : 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'v1.0',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentAmber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Tactile workspace • Local & offline-first',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.5,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSegmentedControl(BuildContext context, ThemeProvider themeProv, bool isDark) {
    final modes = [
      (ThemeMode.light, 'Light', TackIcons.sun),
      (ThemeMode.system, 'System', TackIcons.settings),
      (ThemeMode.dark, 'Dark', TackIcons.moon),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
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
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.darkSurfaceAlt : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : const Color(0xFF191A23).withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                    : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TackIcon(
                      entry.$3,
                      size: 16,
                      color: isSelected
                          ? AppColors.accentAmber
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.$2,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

  Widget _buildWorkspaceStats(BuildContext context, WorkspaceProvider workspace, bool isDark) {
    final stats = [
      ('Notes', workspace.totalActiveNotesCount, AppColors.pastelPeachLight, AppColors.pastelPeachDark, TackIcons.notes),
      ('Stickies', workspace.totalStickiesCount, AppColors.pastelAmberLight, AppColors.pastelAmberDark, TackIcons.sticky),
      ('Boards', workspace.totalWhiteboardsCount, AppColors.pastelCyanLight, AppColors.pastelCyanDark, TackIcons.whiteboard),
      ('Clips', workspace.totalClipsCount, AppColors.pastelLimeLight, AppColors.pastelLimeDark, TackIcons.clipboard),
    ];

    return Row(
      children: stats.map((stat) {
        final accent = isDark ? stat.$4 : stat.$3;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : const Color(0xFF191A23).withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.35 : 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: TackIcon(stat.$5, size: 14, color: isDark ? stat.$3 : stat.$4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${stat.$2}',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  stat.$1,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDataSection(BuildContext context, WorkspaceProvider workspace, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF191A23).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsActionTile(
            context,
            icon: TackIcons.exportData,
            iconColor: AppColors.accentAmber,
            title: 'Export Backup',
            subtitle: 'Save JSON bundle',
            trailing: TackIcons.share,
            onTap: () => _exportBackup(context),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 52,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          _buildSettingsActionTile(
            context,
            icon: TackIcons.importData,
            iconColor: AppColors.pastelCyanLight,
            title: 'Restore Backup',
            subtitle: 'Import JSON or clipboard',
            trailing: TackIcons.chevronDown,
            onTap: () => _showRestoreDialog(context),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 52,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          _buildSettingsActionTile(
            context,
            icon: TackIcons.bolt,
            iconColor: AppColors.accentAmber,
            title: 'AI Server Connection',
            subtitle: 'Configure local or cloud URL',
            trailing: TackIcons.settings,
            onTap: () => _showServerConfigDialog(context),
          ),
          if (workspace.trashItems.isNotEmpty) ...[
            Divider(
              height: 1,
              thickness: 1,
              indent: 52,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            _buildSettingsActionTile(
              context,
              icon: TackIcons.trash,
              iconColor: AppColors.error,
              title: 'Empty Trash',
              subtitle: '${workspace.trashItems.length} items in trash',
              trailing: TackIcons.close,
              isDestructive: true,
              onTap: () => _confirmEmptyTrash(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required IconData trailing,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: TackIcon(icon, size: 18, color: iconColor),
                ),
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
                    const SizedBox(height: 2),
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
                trailing,
                size: 16,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

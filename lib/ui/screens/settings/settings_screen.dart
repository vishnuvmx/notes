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
import 'about_tack_screen.dart';
import 'release_notes_tab.dart';

/// Clean, editorial Settings & Backup screen (`05-information-architecture.md` §6).
///
/// Features:
/// - **Appearance**: Theme selector (`System` · `Light` · `Dark`)
/// - **Daily Desk**: Real interactive switch for **Carry forward unfinished tasks**
/// - **Storage & Backup**: Accurate counts of all items (including Trash), Export JSON, Restore JSON
/// - **About & Release Notes**
class SettingsScreen extends StatefulWidget {
  final int initialTabIndex;

  const SettingsScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportBackup(BuildContext context) async {
    final workspace = context.read<WorkspaceProvider>();
    final jsonStr = workspace.exportWorkspaceJson();
    final totalExported = workspace.allActiveItems.length +
        workspace.trashItems.length +
        workspace.archivedItems.length;

    try {
      final tempDir = await getTemporaryDirectory();
      final docsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

      final localBackup = File('${docsDir.path}/tack_backup_$timestamp.json');
      await localBackup.writeAsString(jsonStr);

      final file = File('${tempDir.path}/tack_backup_$timestamp.json');
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('Exported $totalExported items to backup'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Tack Workspace Backup ($timestamp)',
        ),
      );
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(
          text: jsonStr,
          subject: 'Tack Workspace Backup',
        ),
      );
    }
  }

  Future<void> _showRestoreDialog(BuildContext context) async {
    final controller = TextEditingController();
    final tokens = context.tokens;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) {
          String? validationMessage;
          bool isValid = false;

          void validateInput(
            String text,
            void Function(void Function()) setDialogState,
          ) {
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
              if (decoded is Map<String, dynamic> &&
                  decoded.containsKey('items')) {
                count = (decoded['items'] as List<dynamic>).length;
              } else if (decoded is List<dynamic>) {
                count = decoded.length;
              }

              setDialogState(() {
                if (count > 0) {
                  validationMessage = 'Valid Tack backup: $count items found';
                  isValid = true;
                } else {
                  validationMessage = 'Backup contains 0 items';
                  isValid = false;
                }
              });
            } catch (_) {
              setDialogState(() {
                validationMessage = 'Invalid JSON format';
                isValid = false;
              });
            }
          }

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Restore Backup'),
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Paste a previously exported Tack JSON backup to merge and restore your workspace.',
                        style: AppTypography.bodySm(
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      OutlinedButton.icon(
                        icon: TackIcon(
                          TackIcons.clipboard,
                          size: 16,
                          color: tokens.textPrimary,
                        ),
                        label: const Text('Paste from Clipboard'),
                        onPressed: () async {
                          final data =
                              await Clipboard.getData(Clipboard.kTextPlain);
                          final text = data?.text?.trim() ?? '';
                          if (text.isNotEmpty) {
                            controller.text = text;
                            validateInput(text, setDialogState);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      TextField(
                        controller: controller,
                        maxLines: 4,
                        style: AppTypography.mono(color: tokens.textPrimary),
                        onChanged: (val) => validateInput(val, setDialogState),
                        decoration: const InputDecoration(
                          hintText: 'Paste backup JSON content here…',
                        ),
                      ),
                      if (validationMessage != null) ...[
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          validationMessage!,
                          style: AppTypography.caption(
                            color: isValid ? tokens.success : tokens.danger,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isValid
                        ? () => Navigator.of(dialogCtx).pop(true)
                        : null,
                    child: const Text('Restore'),
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
          final count =
              await context.read<WorkspaceProvider>().importWorkspaceJson(text);
          if (context.mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(
                content: Text('Restored $count items'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text('Failed to restore: invalid backup format'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final themeProv = context.watch<ThemeProvider>();
    final workspace = context.watch<WorkspaceProvider>();

    return Scaffold(
      backgroundColor: tokens.canvasPrimary,
      appBar: AppBar(
        backgroundColor: tokens.canvasPrimary,
        leading: IconButton(
          icon: TackIcon(TackIcons.back, size: 20, color: tokens.textPrimary),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop();
          },
          tooltip: 'Back',
        ),
        title: Text(
          'Settings & Backup',
          style: AppTypography.title(color: tokens.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.s5,
              AppSpacing.s1,
              AppSpacing.s5,
              AppSpacing.s2,
            ),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: tokens.canvasSunken,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: tokens.borderSubtle, width: 1),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (_) => HapticFeedback.selectionClick(),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: tokens.surfacePrimary,
                borderRadius: BorderRadius.circular(6),
                boxShadow: AppSpacing.elev1(tokens.isDark),
              ),
              labelColor: tokens.textPrimary,
              unselectedLabelColor: tokens.textTertiary,
              labelStyle: AppTypography.label(
                color: tokens.textPrimary,
                weight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTypography.label(
                color: tokens.textTertiary,
                weight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Preferences'),
                Tab(text: "What's New"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPreferencesTab(context, themeProv, workspace, tokens),
                const ReleaseNotesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab(
    BuildContext context,
    ThemeProvider themeProv,
    WorkspaceProvider workspace,
    TackTokens tokens,
  ) {
    final totalActive = workspace.allActiveItems.length;
    final trashCount = workspace.trashItems.length;
    final totalItems = totalActive + trashCount + workspace.archivedItems.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s3,
        AppSpacing.s5,
        AppSpacing.s9,
      ),
      children: [
        // 1. Appearance
        _SectionLabel(text: 'Appearance'),
        const SizedBox(height: AppSpacing.s2),
        _ThemeSegmentedControl(themeProv: themeProv),

        const SizedBox(height: AppSpacing.s6),

        // 2. Daily Desk Behavior
        _SectionLabel(text: 'Today & Daily Note'),
        const SizedBox(height: AppSpacing.s2),
        Container(
          decoration: BoxDecoration(
            color: tokens.surfacePrimary,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: SwitchListTile(
            title: Text(
              'Carry forward unfinished tasks',
              style: AppTypography.body(
                color: tokens.textPrimary,
                weight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Automatically copy unchecked `- [ ]` tasks from your previous Daily Note into today’s note.',
              style: AppTypography.bodySm(color: tokens.textSecondary),
            ),
            value: workspace.carryForwardTasksEnabled,
            activeThumbColor: tokens.surfacePrimary,
            activeTrackColor: tokens.actionPrimary,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              workspace.setCarryForwardTasksEnabled(val);
            },
          ),
        ),

        const SizedBox(height: AppSpacing.s6),

        // 3. Storage & Backup
        _SectionLabel(text: 'Local Storage & Backup'),
        const SizedBox(height: AppSpacing.s2),
        Container(
          decoration: BoxDecoration(
            color: tokens.surfacePrimary,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tokens.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    Expanded(
                      child: Text(
                        'On-device JSON store',
                        style: AppTypography.titleSm(color: tokens.textPrimary),
                      ),
                    ),
                    Text(
                      '$totalItems total items ($trashCount in Trash)',
                      style: AppTypography.caption(color: tokens.textTertiary),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.borderSubtle),
              ListTile(
                leading: TackIcon(
                  TackIcons.exportData,
                  size: 20,
                  color: tokens.textPrimary,
                ),
                title: Text(
                  'Export Workspace Backup',
                  style: AppTypography.body(
                    color: tokens.textPrimary,
                    weight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Save or share a complete JSON backup of all notes, boards, and trash',
                  style: AppTypography.caption(color: tokens.textSecondary),
                ),
                onTap: () => _exportBackup(context),
              ),
              Divider(height: 1, color: tokens.borderSubtle),
              ListTile(
                leading: TackIcon(
                  TackIcons.importData,
                  size: 20,
                  color: tokens.textPrimary,
                ),
                title: Text(
                  'Restore from Backup',
                  style: AppTypography.body(
                    color: tokens.textPrimary,
                    weight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Merge items from an exported Tack JSON file',
                  style: AppTypography.caption(color: tokens.textSecondary),
                ),
                onTap: () => _showRestoreDialog(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.s6),

        // 4. About
        _SectionLabel(text: 'About'),
        const SizedBox(height: AppSpacing.s2),
        Container(
          decoration: BoxDecoration(
            color: tokens.surfacePrimary,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Column(
            children: [
              ListTile(
                leading: TackIcon(
                  TackIcons.notes,
                  size: 20,
                  color: tokens.textPrimary,
                ),
                title: Text(
                  'About Tack',
                  style: AppTypography.body(
                    color: tokens.textPrimary,
                    weight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Paper & Pin design system & open-source libraries',
                  style: AppTypography.caption(color: tokens.textSecondary),
                ),
                trailing: TackIcon(
                  TackIcons.chevronRight,
                  size: 16,
                  color: tokens.textTertiary,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutTackScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      text,
      style: AppTypography.label(
        color: tokens.textSecondary,
        weight: FontWeight.w600,
      ),
    );
  }
}

class _ThemeSegmentedControl extends StatelessWidget {
  final ThemeProvider themeProv;

  const _ThemeSegmentedControl({required this.themeProv});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final modes = [
      (ThemeMode.system, 'System', TackIcons.settings),
      (ThemeMode.light, 'Light', TackIcons.sun),
      (ThemeMode.dark, 'Dark', TackIcons.moon),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.canvasSunken,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Row(
        children: modes.map((entry) {
          final isSelected = themeProv.themeMode == entry.$1;
          return Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                themeProv.setThemeMode(entry.$1);
              },
              borderRadius: BorderRadius.circular(6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: AnimatedContainer(
                  duration: AppSpacing.durationFast,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tokens.surfacePrimary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isSelected
                        ? AppSpacing.elev1(tokens.isDark)
                        : AppSpacing.elev0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TackIcon(
                        entry.$3,
                        size: 16,
                        color: isSelected
                            ? tokens.textPrimary
                            : tokens.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.$2,
                        style: AppTypography.label(
                          color: isSelected
                              ? tokens.textPrimary
                              : tokens.textTertiary,
                          weight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

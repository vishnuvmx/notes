import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/theme_provider.dart';
import '../../../state/workspace_provider.dart';
import '../folders/folder_view_screen.dart';
import 'about_tack_screen.dart';
import 'release_notes_tab.dart';

/// Clean, editorial Profile & Settings screen (`05-information-architecture.md` §6).
///
/// Features:
/// - **Profile & Workspace Hero**: Avatar, customizable name, status, and 4 stat pills
/// - **Trash**: Direct navigation with active item count badge
/// - **Appearance**: Soft Monochrome theme selector (`System` · `Light` · `Dark`)
/// - **Daily Desk**: Real interactive switch for **Carry forward unfinished tasks**
/// - **Storage & Backup**: Accurate counts of all items (including Trash), Export JSON, Restore JSON
/// - **About & Release Notes**
class ProfileSettingsScreen extends StatefulWidget {
  final int initialTabIndex;

  const ProfileSettingsScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

/// Backwards compatibility alias for existing routes and callers.
typedef SettingsScreen = ProfileSettingsScreen;

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _userName = 'Karthik';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _tabController.addListener(_onTabChanged);
    _loadProfileName();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('user_profile_name');
      if (saved != null && saved.trim().isNotEmpty && mounted) {
        setState(() => _userName = saved.trim());
      }
    } catch (_) {}
  }

  Future<void> _editProfileName() async {
    final controller = TextEditingController(text: _userName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        final tokens = dialogCtx.tokens;
        return AlertDialog(
          backgroundColor: tokens.surfacePrimary,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
          title: Text(
            'Edit Profile Name',
            style: AppTypography.titleSm(color: tokens.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: AppTypography.body(color: tokens.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your name…',
              hintStyle: AppTypography.body(color: tokens.textTertiary),
              filled: true,
              fillColor: tokens.canvasSunken,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.roundedSm,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.label(color: tokens.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.actionPrimary,
                foregroundColor: tokens.actionPrimaryFg,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppSpacing.roundedPill,
                ),
              ),
              onPressed: () {
                final trimmed = controller.text.trim();
                Navigator.of(dialogCtx).pop(trimmed.isEmpty ? 'Karthik' : trimmed);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (newName != null && newName != _userName && mounted) {
      setState(() => _userName = newName);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile_name', newName);
      } catch (_) {}
    }
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
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
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
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: TackIcon(TackIcons.back, size: 20, color: tokens.textPrimary),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop();
          },
          tooltip: 'Back',
        ),
        title: Text(
          'Profile & Settings',
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
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: tokens.canvasSunken,
              borderRadius: AppSpacing.roundedPill,
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (_) => HapticFeedback.selectionClick(),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              splashBorderRadius: AppSpacing.roundedPill,
              indicator: BoxDecoration(
                color: tokens.actionPrimary,
                borderRadius: AppSpacing.roundedPill,
              ),
              labelColor: tokens.actionPrimaryFg,
              unselectedLabelColor: tokens.textSecondary,
              labelStyle: AppTypography.label(
                color: tokens.actionPrimaryFg,
                weight: FontWeight.w700,
              ),
              unselectedLabelStyle: AppTypography.label(
                color: tokens.textSecondary,
                weight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Profile & Settings'),
                Tab(text: "What's New"),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tabController.index,
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
    final noteCount = workspace.libraryNotes.length;
    final boardCount = workspace.boardItems.length;
    final taskCount = workspace.openTasks.length;
    final trashCount = workspace.trashItems.length;
    final totalActive = workspace.allActiveItems.length;
    final totalItems = totalActive + trashCount + workspace.archivedItems.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s3,
        AppSpacing.s5,
        AppSpacing.s9,
      ),
      children: [
        // 1. Profile & Workspace Hero Card (DailyLoop & Regent style)
        Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: BoxDecoration(
            color: tokens.surfacePrimary,
            borderRadius: AppSpacing.roundedMd,
            boxShadow: AppSpacing.elev1(tokens.isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: tokens.actionPrimary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'K',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: tokens.actionPrimaryFg,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: tokens.accentPin,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: tokens.surfacePrimary,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.title(
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _editProfileName,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: tokens.canvasSunken,
                                  shape: BoxShape.circle,
                                ),
                                child: TackIcon(
                                  TackIcons.editSvg,
                                  size: 13,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Local & offline-first • Paper & Pin',
                          style: AppTypography.caption(
                            color: tokens.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              Row(
                children: [
                  Expanded(
                    child: _StatMetricPill(
                      label: 'Notes',
                      count: '$noteCount',
                      tokens: tokens,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: _StatMetricPill(
                      label: 'Boards',
                      count: '$boardCount',
                      tokens: tokens,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: _StatMetricPill(
                      label: 'Tasks',
                      count: '$taskCount',
                      tokens: tokens,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: _StatMetricPill(
                      label: 'Trash',
                      count: '$trashCount',
                      tokens: tokens,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.s4),

        // 2. Trash Navigation Tile
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: tokens.surfacePrimary,
            borderRadius: AppSpacing.roundedMd,
            boxShadow: AppSpacing.elev1(tokens.isDark),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.accentPin.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: TackIcon(
                  TackIcons.trash,
                  size: 18,
                  color: tokens.accentPin,
                ),
              ),
            ),
            title: Text(
              'Trash & Deleted Items',
              style: AppTypography.body(
                color: tokens.textPrimary,
                weight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Restore or permanently delete items',
              style: AppTypography.caption(color: tokens.textSecondary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trashCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: tokens.accentPin.withValues(alpha: 0.15),
                      borderRadius: AppSpacing.roundedPill,
                    ),
                    child: Text(
                      '$trashCount',
                      style: AppTypography.caption(
                        color: tokens.accentPin,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                TackIcon(
                  TackIcons.chevronRight,
                  size: 16,
                  color: tokens.textTertiary,
                ),
              ],
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FolderViewScreen(
                    folderType: FolderType.trash,
                  ),
                ),
              );
            },
          ),
        ),
      ),

        const SizedBox(height: AppSpacing.s6),

        // 3. Appearance
        _SectionLabel(text: 'Appearance'),
        const SizedBox(height: AppSpacing.s2),
        _ThemeSegmentedControl(themeProv: themeProv),

        const SizedBox(height: AppSpacing.s6),

        // 4. Daily Desk Behavior
        _SectionLabel(text: 'Today & Daily Note'),
        const SizedBox(height: AppSpacing.s2),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: tokens.surfacePrimary,
            borderRadius: AppSpacing.roundedMd,
            boxShadow: AppSpacing.elev1(tokens.isDark),
          ),
          child: Material(
            color: Colors.transparent,
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
      ),

        const SizedBox(height: AppSpacing.s6),

        // 5. Storage & Backup
        _SectionLabel(text: 'Local Storage & Backup'),
        const SizedBox(height: AppSpacing.s2),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: tokens.surfacePrimary,
            borderRadius: AppSpacing.roundedMd,
            boxShadow: AppSpacing.elev1(tokens.isDark),
          ),
          child: Material(
            color: Colors.transparent,
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
      ),

        const SizedBox(height: AppSpacing.s6),

        // 6. About
        _SectionLabel(text: 'About'),
        const SizedBox(height: AppSpacing.s2),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: tokens.surfacePrimary,
            borderRadius: AppSpacing.roundedMd,
            boxShadow: AppSpacing.elev1(tokens.isDark),
          ),
          child: Material(
            color: Colors.transparent,
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
                  'Soft Monochrome design system & open-source libraries',
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
      ),
      ],
    );
  }
}

class _StatMetricPill extends StatelessWidget {
  final String label;
  final String count;
  final TackTokens tokens;

  const _StatMetricPill({
    required this.label,
    required this.count,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: tokens.canvasSunken,
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Column(
        children: [
          Text(
            count,
            style: AppTypography.titleSm(color: tokens.textPrimary),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption(color: tokens.textTertiary),
          ),
        ],
      ),
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
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: tokens.canvasSunken,
        borderRadius: AppSpacing.roundedPill,
      ),
      child: Row(
        children: modes.map((entry) {
          final isSelected = themeProv.themeMode == entry.$1;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  themeProv.setThemeMode(entry.$1);
                },
                borderRadius: AppSpacing.roundedPill,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: AnimatedContainer(
                    duration: AppSpacing.durationFast,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tokens.actionPrimary
                          : Colors.transparent,
                      borderRadius: AppSpacing.roundedPill,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TackIcon(
                          entry.$3,
                          size: 15,
                          color: isSelected
                              ? tokens.actionPrimaryFg
                              : tokens.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.$2,
                          style: AppTypography.label(
                            color: isSelected
                                ? tokens.actionPrimaryFg
                                : tokens.textSecondary,
                            weight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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

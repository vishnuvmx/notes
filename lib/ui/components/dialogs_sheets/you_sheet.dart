import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/workspace_provider.dart';
import '../../screens/folders/folder_view_screen.dart';
import '../../screens/settings/profile_settings_screen.dart';
import 'app_bottom_sheet.dart';

/// The **You** / Profile Settings entry point (`05-information-architecture.md` §2.1 & §6).
///
/// Navigates directly to the dedicated [ProfileSettingsScreen].
class YouSheet extends StatelessWidget {
  const YouSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.selectionClick();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileSettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final workspace = context.watch<WorkspaceProvider>();

    final noteCount = workspace.libraryNotes.length;
    final boardCount = workspace.boardItems.length;
    final taskCount = workspace.openTasks.length;
    final trashCount = workspace.trashItems.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s2,
        AppSpacing.s5,
        AppSpacing.s5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.canvasSunken,
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: tokens.borderSubtle, width: 1),
                ),
                child: Center(
                  child: TackPinBadge(color: tokens.accentPin, size: 12),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tack Workspace',
                      style: AppTypography.titleSm(color: tokens.textPrimary),
                    ),
                    Text(
                      'Local & offline-first',
                      style: AppTypography.caption(color: tokens.textTertiary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  minimumSize: const Size(
                    AppSpacing.minTouchTarget,
                    AppSpacing.minTouchTarget,
                  ),
                ),
                icon: TackIcon(
                  TackIcons.close,
                  size: 18,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s4),

          // Workspace stat pills
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  value: '$noteCount',
                  label: noteCount == 1 ? 'Note' : 'Notes',
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: _StatPill(
                  value: '$boardCount',
                  label: boardCount == 1 ? 'Board' : 'Boards',
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: _StatPill(
                  value: '$taskCount',
                  label: taskCount == 1 ? 'Open task' : 'Open tasks',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.s4),
          Divider(height: 1, color: tokens.borderSubtle),
          const SizedBox(height: AppSpacing.s2),

          // Navigation rows
          _YouNavRow(
            icon: TackIcons.trash,
            label: 'Trash',
            trailingBadge: trashCount > 0 ? '$trashCount' : null,
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(
                MaterialPageRoute(
                  builder: (_) => const FolderViewScreen(
                    folderType: FolderType.trash,
                  ),
                ),
              );
            },
          ),
          _YouNavRow(
            icon: TackIcons.settings,
            label: 'Settings & Backup',
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          _YouNavRow(
            icon: TackIcons.sparkles,
            label: 'About Tack',
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              _showAboutModal(nav.context);
            },
          ),
        ],
      ),
    );
  }

  static void _showAboutModal(BuildContext context) {
    AppBottomSheet.show<void>(
      context: context,
      builder: (ctx) {
        final tokens = ctx.tokens;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s3,
            AppSpacing.s5,
            AppSpacing.s6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TackPinBadge(color: tokens.accentPin, size: 12),
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    'Tack · Soft Monochrome Edition',
                    style: AppTypography.title(color: tokens.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Version 2.5.0 · Local-first Markdown notes & visual boards for Android.',
                style: AppTypography.bodySm(color: tokens.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                '• Today desk with Week Strip, Daily Note, Inbox triage, and Open Tasks\n'
                '• Bidirectional [[Wiki-links]], backlinks, and Spec Cards on Boards\n'
                '• Soft Monochrome & Coral design system with full offline storage',
                style: AppTypography.bodySm(color: tokens.textPrimary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;

  const _StatPill({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: tokens.canvasSunken,
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.title(color: tokens.textPrimary),
          ),
          const SizedBox(height: 2),
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

class _YouNavRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String? trailingBadge;
  final VoidCallback onTap;

  const _YouNavRow({
    required this.icon,
    required this.label,
    this.trailingBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: AppSpacing.roundedSm,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.minTouchTarget,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
          child: Row(
            children: [
              TackIcon(icon, size: 20, color: tokens.textPrimary),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body(
                    color: tokens.textPrimary,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailingBadge != null) ...[
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
                    trailingBadge!,
                    style: AppTypography.caption(
                      color: tokens.textSecondary,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
              ],
              TackIcon(
                TackIcons.chevronRight,
                size: 16,
                color: tokens.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

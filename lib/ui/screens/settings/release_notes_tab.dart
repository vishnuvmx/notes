import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

enum _ReleaseCategory {
  all('All'),
  connected('Connected Specs'),
  editor('Rich Editor'),
  knowledge('Daily & Graph'),
  ux('Soft Monochrome UI');

  final String label;
  const _ReleaseCategory(this.label);
}

class _ReleaseEntry {
  final String title;
  final String summary;
  final String badge;
  final String? syntaxHint;
  final IconData icon;
  final String paletteId;
  final _ReleaseCategory category;

  const _ReleaseEntry({
    required this.title,
    required this.summary,
    required this.badge,
    required this.icon,
    required this.paletteId,
    required this.category,
    this.syntaxHint,
  });
}

/// Interactive Release Notes tab inside Settings showcasing all major v2.0.0
/// Connected Specs, Rich Markdown, Knowledge Graph, and Soft Monochrome UI updates.
class ReleaseNotesTab extends StatefulWidget {
  const ReleaseNotesTab({super.key});

  @override
  State<ReleaseNotesTab> createState() => _ReleaseNotesTabState();
}

class _ReleaseNotesTabState extends State<ReleaseNotesTab> {
  _ReleaseCategory _selectedCategory = _ReleaseCategory.all;

  static const List<_ReleaseEntry> _v2Entries = [
    // Connected Specs & Slash Blocks
    _ReleaseEntry(
      title: 'Bi-Directional Wiki-Links & Backlinks',
      badge: 'Knowledge Links',
      syntaxHint: '[[Note#Heading|Alias]]',
      icon: LucideIcons.link2,
      paletteId: 'cyan',
      category: _ReleaseCategory.connected,
      summary:
          'Link any note, section heading, or YAML alias inline with live autocomplete. '
          'Every note includes a collapsible Backlinks & Unlinked Mentions panel with 1-tap link conversion.',
    ),
    _ReleaseEntry(
      title: 'Canvas Spec Cards & Live Board Embeds',
      badge: 'Visual Specs',
      syntaxHint: '![[Board#nodeId]]',
      icon: LucideIcons.workflow,
      paletteId: 'peach',
      category: _ReleaseCategory.connected,
      summary:
          'Pin live Markdown specs directly onto visual flowcharts with real-time task progress counters, '
          'or embed interactive mini vector board previews straight inside your notes.',
    ),
    _ReleaseEntry(
      title: 'Slash (/) Command Palette & "Turn Into"',
      badge: 'Block Engine',
      syntaxHint: '/toggle  •  /table  •  /toc',
      icon: LucideIcons.terminal,
      paletteId: 'lavender',
      category: _ReleaseCategory.editor,
      summary:
          'Type / at the start of any line for instant block insertion, or transform existing lines '
          'non-destructively between Headings, To-Dos, Toggles, Callouts, and Lists—plus Move Line Up/Down.',
    ),

    // Structured Specs, Folding & Touch Tables
    _ReleaseEntry(
      title: 'Toggle Blocks & Heading Section Folding',
      badge: 'Reader & Specs',
      syntaxHint: '>▸ Toggle Title',
      icon: LucideIcons.chevronsDownUp,
      paletteId: 'amber',
      category: _ReleaseCategory.editor,
      summary:
          'Collapse long briefs and study notes with interactive <details> or >▸ toggle blocks, '
          'and fold entire # H1–H4 sections in Reader Mode with line-count summary chips.',
    ),
    _ReleaseEntry(
      title: 'Document Outline Drawer & Inline [TOC]',
      badge: 'Navigation',
      syntaxHint: '[TOC]',
      icon: LucideIcons.listTree,
      paletteId: 'cyan',
      category: _ReleaseCategory.editor,
      summary:
          'Jump to any heading from the auto-detected Document Outline sheet in the editor top bar, '
          'or drop [TOC] anywhere in a note for an auto-generated Table of Contents card.',
    ),
    _ReleaseEntry(
      title: 'YAML Frontmatter Properties Bar',
      badge: 'Local .md',
      syntaxHint: 'status  •  priority  •  aliases',
      icon: LucideIcons.slidersHorizontal,
      paletteId: 'rose',
      category: _ReleaseCategory.connected,
      summary:
          'Structured tactile chips for status, priority, target_date, aliases, and custom keys—stored '
          'as 100% portable YAML frontmatter with zero lock-in.',
    ),
    _ReleaseEntry(
      title: 'Touch-First Visual Markdown Table Editor',
      badge: 'Mobile Editor',
      syntaxHint: '1-Tap Edit Table',
      icon: LucideIcons.table,
      paletteId: 'lime',
      category: _ReleaseCategory.editor,
      summary:
          'Tap "Edit Table" on any rendered Markdown table to add/remove rows and columns, cycle '
          'left/center/right alignment, and edit cells comfortably without typing pipe characters.',
    ),

    // Daily Habit Loop, Hierarchy & Graph
    _ReleaseEntry(
      title: "Templates Gallery & 1-Tap Today's Note",
      badge: 'Daily Desk',
      syntaxHint: '{{date}}  •  Carry-Forward',
      icon: LucideIcons.sun,
      paletteId: 'amber',
      category: _ReleaseCategory.knowledge,
      summary:
          'Launch Product Specs, Design Rulebooks, ADRs, Meeting, or Cornell templates—or save your own. '
          "Today's Note automatically carries forward unfinished [ ] tasks from your previous daily note.",
    ),
    _ReleaseEntry(
      title: 'Custom Folders, Sub-Notes & Breadcrumbs',
      badge: 'Hierarchy',
      syntaxHint: 'Folder › Parent › Sub-note',
      icon: LucideIcons.folderTree,
      paletteId: 'lavender',
      category: _ReleaseCategory.knowledge,
      summary:
          'Organize notes into custom folders, nest child sub-notes with tappable ancestor breadcrumbs, '
          'and personalize pages with custom emoji icons.',
    ),
    _ReleaseEntry(
      title: '2D Knowledge Graph & Section Transclusion',
      badge: 'Knowledge Map',
      syntaxHint: 'Global & 1-Hop Local Graph',
      icon: LucideIcons.network,
      paletteId: 'cyan',
      category: _ReleaseCategory.knowledge,
      summary:
          'Explore an interactive force-directed map of your notes, boards, sub-notes, and #tags in Global '
          'or 1-Hop Local mode, plus rich multi-line ![[Note#Section]] transclusions.',
    ),

    // Soft Monochrome Redesign
    _ReleaseEntry(
      title: 'Soft Monochrome UI, Floating Nav & Today Triage',
      badge: 'Redesign',
      syntaxHint: 'Today  •  Library  •  Boards  •  Search',
      icon: LucideIcons.zap,
      paletteId: 'coral',
      category: _ReleaseCategory.ux,
      summary:
          'Calm Soft Monochrome canvas with floating pill navigation, detached (+) Capture button, '
          'week strip, segmented task/inbox triage, and responsive grid cards with tinted preview blocks.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final filtered = _selectedCategory == _ReleaseCategory.all
        ? _v2Entries
        : _v2Entries.where((e) => e.category == _selectedCategory).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s3,
        AppSpacing.s5,
        AppSpacing.s9,
      ),
      children: [
        // 1. Hero Release Card (v2.0.0)
        _buildHeroReleaseBanner(tokens),
        const SizedBox(height: AppSpacing.s4),

        // 2. Interactive Category Filter Pills (Soft Monochrome Segmented Pills)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _ReleaseCategory.values.map((cat) {
              final selected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s2),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat);
                    },
                    borderRadius: AppSpacing.roundedPill,
                    child: AnimatedContainer(
                      duration: AppSpacing.durationFast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s4,
                        vertical: AppSpacing.s2,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? tokens.actionPrimary : tokens.surfacePrimary,
                        borderRadius: AppSpacing.roundedPill,
                        border: selected
                            ? null
                            : Border.all(color: tokens.borderSubtle, width: 1),
                      ),
                      child: Text(
                        cat.label,
                        style: AppTypography.label(
                          color: selected
                              ? tokens.actionPrimaryFg
                              : tokens.textSecondary,
                          weight: selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),

        // 3. Major Feature Cards
        ...filtered.map((entry) => _buildReleaseCard(entry, tokens)),

        const SizedBox(height: AppSpacing.s3),

        // 4. Previous Milestone Card (v1.0.0)
        _buildPreviousVersionCard(tokens),
      ],
    );
  }

  Widget _buildHeroReleaseBanner(TackTokens tokens) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: BoxDecoration(
        color: tokens.surfacePrimary,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.elev1(tokens.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tokens.actionPrimary,
                  borderRadius: AppSpacing.roundedPill,
                ),
                child: Text(
                  'v2.0.0  •  MAJOR UPDATE',
                  style: AppTypography.caption(
                    color: tokens.actionPrimaryFg,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tokens.canvasSunken,
                  borderRadius: AppSpacing.roundedPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TackIcon(
                      TackIcons.lock,
                      size: 12,
                      color: tokens.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '100% Local-First',
                      style: AppTypography.caption(
                        color: tokens.textSecondary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Soft Monochrome Desk, Connected Specs & Knowledge Graph',
            style: AppTypography.title(color: tokens.textPrimary),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Designed for tactile Android speed—bringing your daily note, inbox triage, structured specs, and infinite boards together offline without accounts or cloud lock-in.',
            style: AppTypography.bodySm(color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s4),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              _buildMetricChip('Soft Monochrome UI', 'coral', tokens),
              _buildMetricChip('2-Way Board ↔ Spec Sync', 'peach', tokens),
              _buildMetricChip('1-Tap Daily & Inbox', 'amber', tokens),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String text, String paletteId, TackTokens tokens) {
    final palette = AppColors.getPaletteById(paletteId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.resolveSoftBackground(tokens.isDark),
        borderRadius: AppSpacing.roundedPill,
      ),
      child: Text(
        text,
        style: AppTypography.caption(
          color: palette.resolveAccentColor(tokens.isDark),
          weight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildReleaseCard(_ReleaseEntry entry, TackTokens tokens) {
    final palette = AppColors.getPaletteById(entry.paletteId);
    final accent = palette.resolveAccentColor(tokens.isDark);
    final softBg = palette.resolveSoftBackground(tokens.isDark);

    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: tokens.surfacePrimary,
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppSpacing.elev1(tokens.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: AppSpacing.roundedPill,
                ),
                child: Text(
                  entry.badge,
                  style: AppTypography.caption(
                    color: accent,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              if (entry.syntaxHint != null) ...[
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Text(
                    entry.syntaxHint!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTypography.mono(
                      fontSize: 11.5,
                      color: tokens.textTertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: softBg,
              borderRadius: AppSpacing.roundedSm,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 3.5,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: AppSpacing.roundedPill,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(entry.icon, size: 16, color: accent),
                            const SizedBox(width: AppSpacing.s2),
                            Expanded(
                              child: Text(
                                entry.title,
                                style: AppTypography.titleSm(
                                  color: tokens.textPrimary,
                                  fontSize: 15.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.summary,
                          style: AppTypography.bodySm(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousVersionCard(TackTokens tokens) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: tokens.surfacePrimary,
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppSpacing.elev1(tokens.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.canvasSunken,
                  borderRadius: AppSpacing.roundedPill,
                ),
                child: Text(
                  'v1.0.0',
                  style: AppTypography.caption(
                    color: tokens.textSecondary,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                'Initial Tactile Workspace Foundation',
                style: AppTypography.titleSm(
                  color: tokens.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '8 curated object palettes, infinite flowchart whiteboard canvas, inline Mermaid diagram renderer, smart capture deduplication, and offline JSON/PDF/PNG export.',
            style: AppTypography.bodySm(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

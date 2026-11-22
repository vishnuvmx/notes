import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/tactile_ink_target.dart';
import '../../../shared/widgets/z_order_column.dart';

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
  final String? syntaxHint;
  final String paletteId;
  final _ReleaseCategory category;

  const _ReleaseEntry({
    required this.title,
    required this.summary,
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
      syntaxHint: '[[Note#Heading|Alias]]',
      paletteId: 'cyan',
      category: _ReleaseCategory.connected,
      summary:
          'Link any note or section heading inline with live autocomplete. '
          'Every note includes a collapsible Backlinks & Unlinked Mentions panel with 1-tap link conversion.',
    ),
    _ReleaseEntry(
      title: 'Canvas Spec Cards & Live Board Embeds',
      syntaxHint: '![[Board#nodeId]]',
      paletteId: 'peach',
      category: _ReleaseCategory.connected,
      summary:
          'Pin live Markdown specs directly onto visual flowcharts with real-time task progress counters, '
          'or embed interactive mini vector board previews straight inside your notes.',
    ),
    _ReleaseEntry(
      title: 'Slash (/) Command Palette & "Turn Into"',
      syntaxHint: '/toggle  •  /table  •  /toc',
      paletteId: 'lavender',
      category: _ReleaseCategory.editor,
      summary:
          'Type / at the start of any line for instant block insertion, or transform existing lines '
          'non-destructively between Headings, To-Dos, Toggles, Callouts, and Lists—plus Move Line Up/Down.',
    ),

    // Structured Specs, Folding & Touch Tables
    _ReleaseEntry(
      title: 'Toggle Blocks & Heading Section Folding',
      syntaxHint: '>▸ Toggle Title',
      paletteId: 'amber',
      category: _ReleaseCategory.editor,
      summary:
          'Collapse long briefs and study notes with interactive <details> or >▸ toggle blocks, '
          'and fold entire # H1–H4 sections in Reader Mode with line-count summary chips.',
    ),
    _ReleaseEntry(
      title: 'Document Outline Drawer & Inline [TOC]',
      syntaxHint: '[TOC]',
      paletteId: 'cyan',
      category: _ReleaseCategory.editor,
      summary:
          'Jump to any heading from the auto-detected Document Outline sheet in the editor top bar, '
          'or drop [TOC] anywhere in a note for an auto-generated Table of Contents card.',
    ),
    _ReleaseEntry(
      title: 'Touch-First Visual Markdown Table Editor',
      syntaxHint: '1-Tap Edit Table',
      paletteId: 'lime',
      category: _ReleaseCategory.editor,
      summary:
          'Tap "Edit Table" on any rendered Markdown table to add/remove rows and columns, cycle '
          'left/center/right alignment, and edit cells comfortably without typing pipe characters.',
    ),

    // Daily Habit Loop, Hierarchy & Graph
    _ReleaseEntry(
      title: "1-Tap Today's Daily Note & Task Carry-Forward",
      syntaxHint: 'Daily Note  •  Carry-Forward',
      paletteId: 'amber',
      category: _ReleaseCategory.knowledge,
      summary:
          "Start Today's Note in one tap from the Today desk—unfinished [ ] tasks from your previous "
          'daily note carry forward automatically.',
    ),
    _ReleaseEntry(
      title: 'Custom Folders, Sub-Notes & Breadcrumbs',
      syntaxHint: 'Folder › Parent › Sub-note',
      paletteId: 'lavender',
      category: _ReleaseCategory.knowledge,
      summary:
          'Organize notes into custom folders, nest child sub-notes with tappable ancestor breadcrumbs, '
          'and personalize pages with custom emoji icons.',
    ),
    _ReleaseEntry(
      title: '2D Knowledge Graph & Section Transclusion',
      syntaxHint: 'Global & 1-Hop Local Graph',
      paletteId: 'cyan',
      category: _ReleaseCategory.knowledge,
      summary:
          'Explore an interactive force-directed map of your notes, boards, sub-notes, and #tags in Global '
          'or 1-Hop Local mode, plus rich multi-line ![[Note#Section]] transclusions.',
    ),

    // Soft Monochrome Redesign
    _ReleaseEntry(
      title: 'Soft Monochrome UI, Floating Nav & Today Triage',
      syntaxHint: 'Today  •  Library  •  Boards  •  Search',
      paletteId: 'coral',
      category: _ReleaseCategory.ux,
      summary:
          'Calm Soft Monochrome canvas with floating pill navigation, detached (+) Capture button, '
          'segmented task triage, and responsive grid cards.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final filtered = _selectedCategory == _ReleaseCategory.all
        ? _v2Entries
        : _v2Entries.where((e) => e.category == _selectedCategory).toList();
    final gutter = AppSpacing.screenGutter(MediaQuery.sizeOf(context).width);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.readMaxWidth),
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.s3,
              gutter,
              AppSpacing.s5 + bottomInset,
            ),
            children: [
              ZOrderColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Clean Editorial Release Header (no badge spam)
                  _buildHeroReleaseBanner(tokens),
                  const SizedBox(height: AppSpacing.s4),

                  // 2. Category Filter Pills
                  SingleChildScrollView(
                    clipBehavior: Clip.hardEdge,
                    physics: const ClampingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _ReleaseCategory.values.map((cat) {
                        final selected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.s2),
                          child: TactileFilterPill(
                            label: cat.label,
                            semanticsLabel: '${cat.label} category filter',
                            isSelected: selected,
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),

                  // 3. Clean Hairline-Divided Changelog List
                  _buildChangelogSurface(filtered, tokens),

                  const SizedBox(height: AppSpacing.s4),

                  // 4. Previous Milestone Footnote (v1.0.0)
                  _buildPreviousVersionCard(tokens),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroReleaseBanner(TackTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'v2.0.0',
                style: AppTypography.mono(
                  fontSize: 12,
                  weight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
                child: Text(
                  '·',
                  style: AppTypography.caption(color: tokens.textTertiary),
                ),
              ),
              Text(
                'Local-First Workspace',
                style: AppTypography.caption(
                  color: tokens.textSecondary,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Connected Specs, Daily Desk & Knowledge Graph',
            style: AppTypography.titleLg(
              color: tokens.textPrimary,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Daily note carry-forward, inbox triage, structured specs, and infinite boards—100% offline with zero accounts or lock-in.',
            style: AppTypography.bodySm(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChangelogSurface(
    List<_ReleaseEntry> entries,
    TackTokens tokens,
  ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: tokens.surfacePrimary,
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          smoothness: AppSpacing.defaultSmoothing,
          side: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppSpacing.s4,
                endIndent: AppSpacing.s4,
                color: tokens.borderSubtle,
              ),
            _buildReleaseRow(entries[i], tokens),
          ],
        ],
      ),
    );
  }

  Widget _buildReleaseRow(_ReleaseEntry entry, TackTokens tokens) {
    final headingColor = AppColors.getPaletteById(entry.paletteId)
        .resolveAccentColor(tokens.isDark);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.title,
            style: AppTypography.titleSm(
              color: headingColor,
              fontSize: 16.5,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.summary,
            style: AppTypography.bodySm(color: tokens.textSecondary),
          ),
          if (entry.syntaxHint != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              entry.syntaxHint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.mono(
                fontSize: 11.5,
                color: tokens.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviousVersionCard(TackTokens tokens) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: ShapeDecoration(
        color: tokens.surfacePrimary,
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          smoothness: AppSpacing.defaultSmoothing,
          side: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'v1.0.0',
                style: AppTypography.mono(
                  fontSize: 12,
                  weight: FontWeight.w600,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  'Initial Workspace Foundation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSm(
                    color: tokens.textPrimary,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '8 curated palettes, infinite flowchart whiteboard canvas, inline Mermaid diagrams, smart capture deduplication, and offline JSON/PDF/PNG export.',
            style: AppTypography.bodySm(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

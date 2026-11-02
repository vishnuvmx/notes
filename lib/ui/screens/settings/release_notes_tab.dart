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
  ux('UX Polish');

  final String label;
  const _ReleaseCategory(this.label);
}

class _ReleaseEntry {
  final String title;
  final String summary;
  final String badge;
  final String? syntaxHint;
  final IconData icon;
  final Color accentColor;
  final _ReleaseCategory category;

  const _ReleaseEntry({
    required this.title,
    required this.summary,
    required this.badge,
    required this.icon,
    required this.accentColor,
    required this.category,
    this.syntaxHint,
  });
}

/// Interactive Release Notes tab inside Settings showcasing all major v2.0.0
/// Connected Specs, Rich Markdown, Knowledge Graph, and UX Simplification updates.
class ReleaseNotesTab extends StatefulWidget {
  const ReleaseNotesTab({super.key});

  @override
  State<ReleaseNotesTab> createState() => _ReleaseNotesTabState();
}

class _ReleaseNotesTabState extends State<ReleaseNotesTab> {
  _ReleaseCategory _selectedCategory = _ReleaseCategory.all;

  static const List<_ReleaseEntry> _v2Entries = [
    // Phase 1 — Connected Specs & Slash Blocks
    _ReleaseEntry(
      title: 'Bi-Directional Wiki-Links & Backlinks',
      badge: 'Obsidian',
      syntaxHint: '[[Note#Heading|Alias]]',
      icon: LucideIcons.link2,
      accentColor: AppColors.pastelCyanLight,
      category: _ReleaseCategory.connected,
      summary:
          'Link any note, section heading, or YAML alias inline with live autocomplete. '
          'Every note now includes a collapsible Backlinks & Unlinked Mentions panel with 1-tap link conversion.',
    ),
    _ReleaseEntry(
      title: 'Canvas Spec Cards & Live Board Embeds',
      badge: 'Figma Specs',
      syntaxHint: '![[Whiteboard#nodeId]]',
      icon: LucideIcons.workflow,
      accentColor: AppColors.pastelPeachLight,
      category: _ReleaseCategory.connected,
      summary:
          'Pin live Markdown specs directly onto Whiteboard flowcharts with real-time task progress counters, '
          'or embed interactive mini vector whiteboard previews straight inside your notes.',
    ),
    _ReleaseEntry(
      title: 'Slash (/) Command Palette & "Turn Into"',
      badge: 'Notion',
      syntaxHint: '/toggle  •  /table  •  /toc',
      icon: LucideIcons.terminal,
      accentColor: AppColors.pastelLavenderLight,
      category: _ReleaseCategory.editor,
      summary:
          'Type / at the start of any line for instant block insertion, or transform existing lines '
          'non-destructively between Headings, To-Dos, Toggles, Callouts, and Lists—plus Move Line Up/Down.',
    ),

    // Phase 2 — Structured Specs, Folding & Touch Tables
    _ReleaseEntry(
      title: 'Toggle Blocks & Heading Section Folding',
      badge: 'Reader & Specs',
      syntaxHint: '>▸ Toggle Title',
      icon: LucideIcons.chevronsDownUp,
      accentColor: AppColors.pastelAmberLight,
      category: _ReleaseCategory.editor,
      summary:
          'Collapse long PRDs and study notes with interactive <details> or >▸ toggle blocks, '
          'and fold entire # H1–H4 sections in Reader Mode with line-count summary chips.',
    ),
    _ReleaseEntry(
      title: 'Document Outline Drawer & Inline [TOC]',
      badge: 'Navigation',
      syntaxHint: '[TOC]',
      icon: LucideIcons.listTree,
      accentColor: AppColors.pastelCyanLight,
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
      accentColor: AppColors.pastelRoseLight,
      category: _ReleaseCategory.connected,
      summary:
          'Structured tactile chips for status, priority, target_date, aliases, and custom keys—stored '
          'as 100% portable YAML frontmatter with zero database lock-in.',
    ),
    _ReleaseEntry(
      title: 'Touch-First Visual Markdown Table Editor',
      badge: 'Mobile Editor',
      syntaxHint: '1-Tap Edit Table',
      icon: LucideIcons.table,
      accentColor: AppColors.pastelLimeLight,
      category: _ReleaseCategory.editor,
      summary:
          'Tap "Edit Table" on any rendered Markdown table to add/remove rows and columns, cycle '
          'left/center/right alignment, and edit cells comfortably without typing pipe characters.',
    ),

    // Phase 3 — Daily Habit Loop, Hierarchy & Graph
    _ReleaseEntry(
      title: "Templates Gallery & 1-Tap Today's Note",
      badge: 'Daily Habit',
      syntaxHint: '{{date}}  •  Carry-Forward',
      icon: LucideIcons.sun,
      accentColor: AppColors.pastelAmberLight,
      category: _ReleaseCategory.knowledge,
      summary:
          'Launch Product Specs (PRD), Design Rulebooks, ADRs, Meeting, or Cornell templates—or save your own. '
          "Today's Note automatically carries forward unfinished [ ] tasks from your previous daily note.",
    ),
    _ReleaseEntry(
      title: 'Custom Folders, Sub-Notes & Breadcrumbs',
      badge: 'Hierarchy',
      syntaxHint: 'Folder › Parent › Sub-note',
      icon: LucideIcons.folderTree,
      accentColor: AppColors.pastelLavenderLight,
      category: _ReleaseCategory.knowledge,
      summary:
          'Organize notes into custom folders, nest child sub-notes with tappable ancestor breadcrumbs, '
          'and personalize pages with custom emoji icons.',
    ),
    _ReleaseEntry(
      title: '2D Knowledge Graph & Section Transclusion',
      badge: 'Knowledge',
      syntaxHint: 'Global & 1-Hop Local Graph',
      icon: LucideIcons.network,
      accentColor: AppColors.pastelCyanLight,
      category: _ReleaseCategory.knowledge,
      summary:
          'Explore an interactive force-directed map of your notes, boards, sub-notes, and #tags in Global '
          'or 1-Hop Local mode, plus rich multi-line ![[Note#Section]] transclusions.',
    ),

    // Ergonomic UX Simplifications
    _ReleaseEntry(
      title: 'Zero-Friction Instant Capture & 1-Swipe Exit',
      badge: 'UX Polish',
      syntaxHint: '⚡ Quick Note  •  Grid ↔ List',
      icon: LucideIcons.zap,
      accentColor: AppColors.pastelLimeLight,
      category: _ReleaseCategory.ux,
      summary:
          'Added 1-tap Quick Note creation (skipping upfront form prompts), 1-swipe Back exit from the editor '
          'with instant auto-save, and a 1-tap Sticky Grid ↔ Numbered Notebook List switcher on Home.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _selectedCategory == _ReleaseCategory.all
        ? _v2Entries
        : _v2Entries.where((e) => e.category == _selectedCategory).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 10, AppSpacing.lg, 44),
      children: [
        // 1. Hero Release Card (v2.0.0)
        _buildHeroReleaseBanner(isDark),
        const SizedBox(height: 14),

        // 2. Interactive Category Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _ReleaseCategory.values.map((cat) {
              final selected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.pastelLimeLight
                          : (isDark ? AppColors.darkCard : Colors.white),
                      borderRadius: AppSpacing.roundedPill,
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF191A23)
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: 1.3,
                      ),
                    ),
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12.5,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: -0.2,
                        color: selected
                            ? const Color(0xFF191A23)
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // 3. Major Feature Cards
        ...filtered.map((entry) => _buildReleaseCard(entry, isDark)),

        const SizedBox(height: 12),

        // 4. Previous Milestone Card (v1.0.0)
        _buildPreviousVersionCard(isDark),
      ],
    );
  }

  Widget _buildHeroReleaseBanner(bool isDark) {
    final borderColor = isDark
        ? AppColors.pastelLimeLight.withValues(alpha: 0.4)
        : const Color(0xFF191A23);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF191A23).withValues(alpha: 0.08),
                  blurRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pastelLimeLight,
                  borderRadius: AppSpacing.roundedPill,
                  border: Border.all(color: const Color(0xFF191A23), width: 1.1),
                ),
                child: Text(
                  'v2.0.0  •  MAJOR UPDATE',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: const Color(0xFF191A23),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TackIcon(TackIcons.lock, size: 13, color: AppColors.accentCyan),
                  const SizedBox(width: 4),
                  Text(
                    '100% Local-First',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.pastelCyanLight : AppColors.pastelCyanDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Connected Specs, Knowledge Graph & Zero-Friction UX',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.22,
              color: isDark ? Colors.white : const Color(0xFF191A23),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Inspired by the best of Figma Specs, Obsidian, and Notion—reimagined for tactile Android speed without accounts, cloud lock-in, or databases.',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              height: 1.42,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMetricChip('10 New Core Features', AppColors.pastelCyanLight, isDark),
              _buildMetricChip('2-Way Board ↔ Spec Sync', AppColors.pastelPeachLight, isDark),
              _buildMetricChip('1-Tap Daily & Capture', AppColors.pastelAmberLight, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 0.9),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: isDark ? Colors.white : const Color(0xFF191A23),
        ),
      ),
    );
  }

  Widget _buildReleaseCard(_ReleaseEntry entry, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: entry.accentColor.withValues(alpha: isDark ? 0.2 : 0.25),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: entry.accentColor.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    entry.icon,
                    size: 18,
                    color: isDark ? entry.accentColor : const Color(0xFF191A23),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceAlt
                                : const Color(0xFFEFF1F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entry.badge,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        if (entry.syntaxHint != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              entry.syntaxHint!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.8,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? entry.accentColor
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            entry.summary,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.8,
              height: 1.44,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousVersionCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceAlt.withValues(alpha: 0.6)
            : const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Initial Tactile Workspace Foundation',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '8 curated sticky pastel palettes, infinite flowchart whiteboard canvas, inline Mermaid diagram renderer, smart clipboard deduplication, and offline JSON/PDF/PNG export.',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.2,
              height: 1.4,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}


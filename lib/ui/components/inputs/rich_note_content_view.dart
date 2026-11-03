import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'code_syntax_highlighter.dart';
import 'mermaid/mermaid_diagram_card.dart';
import 'whiteboard_embed_card.dart';
import '../dialogs_sheets/document_outline_sheet.dart';
import '../dialogs_sheets/markdown_table_editor_sheet.dart';
import '../../../core/utils/url_launcher_helper.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/whiteboard_item.dart';
import '../../../domain/services/frontmatter_service.dart';
import '../../../domain/services/markdown_table_service.dart';
import '../../../domain/services/wiki_link_service.dart';

/// Rich Interactive Content View for Tack Notes.
/// Renders Headings (H1-H6 with section folding), Collapsible Toggle Blocks,
/// Inline `[TOC]` Outline, Blockquotes/Callouts, Interactive Checklists,
/// Bullet & Numbered Lists, Interactive GFM Tables, Fenced Code Blocks,
/// Wiki-Links, Whiteboard/Note Embeds, Clickable Links, Images, and Dividers.
class RichNoteContentView extends StatefulWidget {
  final String content;
  final ValueChanged<String>? onContentChanged;
  final ValueChanged<int>? onLineTap;
  final ValueChanged<int>? onHeadingJump;
  final bool isInteractive;
  final String? paletteId;
  final Iterable<BaseWorkspaceItem> workspaceItems;
  final ValueChanged<ParsedWikiLink>? onWikiLinkTap;
  final int transclusionDepth;

  const RichNoteContentView({
    super.key,
    required this.content,
    this.onContentChanged,
    this.onLineTap,
    this.onHeadingJump,
    this.isInteractive = true,
    this.paletteId,
    this.workspaceItems = const [],
    this.onWikiLinkTap,
    this.transclusionDepth = 0,
  });

  @override
  State<RichNoteContentView> createState() => _RichNoteContentViewState();
}

class _RichNoteContentViewState extends State<RichNoteContentView> {
  final Set<int> _foldedHeadingLines = <int>{};
  final Map<int, bool> _toggleOpenState = <int, bool>{};

  String get content => widget.content;
  ValueChanged<String>? get onContentChanged => widget.onContentChanged;
  ValueChanged<int>? get onLineTap => widget.onLineTap;
  bool get isInteractive => widget.isInteractive;
  String? get paletteId => widget.paletteId;
  Iterable<BaseWorkspaceItem> get workspaceItems => widget.workspaceItems;
  ValueChanged<ParsedWikiLink>? get onWikiLinkTap => widget.onWikiLinkTap;

  TackColorPalette get palette => AppColors.getPaletteById(paletteId);

  Widget _wrapLineTap(Widget child, int lineIndex) {
    if (onLineTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => onLineTap?.call(lineIndex),
      child: child,
    );
  }

  void _toggleCheckbox(int lineIndex) {
    if (onContentChanged == null) return;
    HapticFeedback.lightImpact();

    final lines = content.split('\n');
    if (lineIndex >= 0 && lineIndex < lines.length) {
      final line = lines[lineIndex];
      if (line.contains('[ ]')) {
        lines[lineIndex] = line.replaceFirst('[ ]', '[x]');
      } else if (line.contains('[x]')) {
        lines[lineIndex] = line.replaceFirst('[x]', '[ ]');
      } else if (line.contains('[X]')) {
        lines[lineIndex] = line.replaceFirst('[X]', '[ ]');
      }
      onContentChanged!(lines.join('\n'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final parsedFrontmatter = FrontmatterService.parse(content);
    if (parsedFrontmatter.bodyWithoutFrontmatter.trim().isEmpty &&
        !parsedFrontmatter.hasProperties) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Text(
            'No content yet. Switch to edit mode to write...',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ),
      );
    }

    final lines = content.split('\n');
    final widgets = <Widget>[];

    int i = parsedFrontmatter.contentStartLineIndex;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // 0a. Inline Table of Contents: [TOC] or [[_TOC_]]
      if (trimmed.toUpperCase() == '[TOC]' || trimmed.toUpperCase() == '[[_TOC_]]') {
        widgets.add(
          InlineTocCard(
            content: content,
            paletteId: paletteId,
            onJumpToLine: widget.onHeadingJump ?? onLineTap,
          ),
        );
        i++;
        continue;
      }

      // 0b. HTML <details> / <summary> Toggle Block (Notion / GitHub / Obsidian portable)
      if (RegExp(r'^<details(\s+open)?\s*>', caseSensitive: false).hasMatch(trimmed)) {
        final defaultOpen = RegExp(r'^<details\s+open', caseSensitive: false).hasMatch(trimmed);
        String summaryTitle = 'Toggle details';
        final bodyLines = <String>[];
        int j = i + 1;
        while (j < lines.length &&
            !RegExp(r'^</details\s*>', caseSensitive: false).hasMatch(lines[j].trim())) {
          final lTrim = lines[j].trim();
          final sumMatch = RegExp(
            r'^<summary>(.*?)</summary>$',
            caseSensitive: false,
          ).firstMatch(lTrim);
          if (sumMatch != null) {
            summaryTitle = sumMatch.group(1)!.trim();
          } else {
            bodyLines.add(lines[j]);
          }
          j++;
        }
        widgets.add(
          _buildToggleBlockWidget(
            context: context,
            lineIndex: i,
            title: summaryTitle,
            bodyMarkdown: bodyLines.join('\n').trim(),
            defaultOpen: defaultOpen,
            isDark: isDark,
            theme: theme,
          ),
        );
        i = (j < lines.length) ? j + 1 : j;
        continue;
      }

      // 1. Fenced code block: ```lang ... ```
      if (trimmed.startsWith('```')) {
        final lang = trimmed.substring(3).trim();
        final codeLines = <String>[];
        int j = i + 1;
        while (j < lines.length && !lines[j].trim().startsWith('```')) {
          codeLines.add(lines[j]);
          j++;
        }
        final code = codeLines.join('\n');
        final normalizedLang = lang.toLowerCase();
        final trimmedCode = code.trim().toLowerCase();
        final isMermaid = normalizedLang == 'mermaid' ||
            normalizedLang == 'chart' ||
            normalizedLang == 'graph' ||
            normalizedLang == 'flowchart' ||
            normalizedLang == 'pie' ||
            normalizedLang == 'timeline' ||
            normalizedLang == 'sequence' ||
            (normalizedLang.isEmpty &&
                (trimmedCode.startsWith('graph') ||
                    trimmedCode.startsWith('flowchart') ||
                    trimmedCode.startsWith('pie') ||
                    trimmedCode.startsWith('timeline') ||
                    trimmedCode.startsWith('sequencediagram')));

        if (isMermaid) {
          widgets.add(
            MermaidDiagramCard(
              rawCode: code,
              paletteId: paletteId,
            ),
          );
        } else {
          widgets.add(_wrapLineTap(_buildFencedCodeBlock(context, lang, code, isDark, theme), i));
        }
        i = (j < lines.length) ? j + 1 : j;
        continue;
      }

      // 2. Table: line has '|' and next line is a separator line (e.g. |---|---|)
      if (line.contains('|') && (i + 1 < lines.length)) {
        final nextTrimmed = lines[i + 1].trim();
        if (nextTrimmed.contains('|') &&
            RegExp(r'^\|?(\s*:?-+:?\s*\|)+\s*:?-+:?\s*\|?$').hasMatch(nextTrimmed)) {
          final tableLines = <String>[line, lines[i + 1]];
          int j = i + 2;
          while (j < lines.length && lines[j].trim().isNotEmpty && lines[j].contains('|')) {
            tableLines.add(lines[j]);
            j++;
          }
          widgets.add(_wrapLineTap(_buildTable(context, tableLines, i, j, isDark, theme), i));
          i = j;
          continue;
        }
      }

      // 2b. Standalone Workspace Embed: ![[Whiteboard]] or ![[Note#Section]]
      final embedLineMatch = RegExp(r'^\s*(!\[\[[^\[\]\n]+\]\])\s*$').firstMatch(line);
      if (embedLineMatch != null) {
        final parsedEmbed = WikiLinkService.parseToken(embedLineMatch.group(1)!);
        if (parsedEmbed != null) {
          final resolved = WikiLinkService.resolveTarget(parsedEmbed.target, workspaceItems);
          widgets.add(
            WorkspaceEmbedCard(
              link: parsedEmbed,
              resolvedItem: resolved,
              onTap: () => onWikiLinkTap?.call(parsedEmbed),
            ),
          );
          i++;
          continue;
        }
      }

      // 3. Standalone Image: ![alt](url)
      final imgMatch = RegExp(r'^\s*!\[(.*?)\]\((.*?)\)\s*$').firstMatch(line);
      if (imgMatch != null) {
        final alt = imgMatch.group(1) ?? '';
        final url = imgMatch.group(2) ?? '';
        widgets.add(_wrapLineTap(_buildImageBlock(context, alt, url, isDark), i));
        i++;
        continue;
      }

      // 4. Horizontal Rule: ---, ***, ___ (at least 3 characters)
      if (RegExp(r'^\s*(-{3,}|\*{3,}|_{3,})\s*$').hasMatch(line)) {
        widgets.add(_wrapLineTap(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              thickness: 1.2,
              color: palette.resolveTableBorder(isDark),
            ),
          ),
          i,
        ));
        i++;
        continue;
      }

      // 5. Blockquotes, Toggle Shorthands (>▸ Title), and Alerts (> [!NOTE], etc.)
      if (trimmed.startsWith('>')) {
        final quoteLines = <String>[line];
        int j = i + 1;
        while (j < lines.length && lines[j].trim().startsWith('>')) {
          quoteLines.add(lines[j]);
          j++;
        }
        final firstStripped = quoteLines.first.trim().replaceFirst(RegExp(r'^>+\s*'), '');
        if (firstStripped.startsWith('▸')) {
          final toggleTitle = firstStripped.substring(1).trim();
          final innerLines = quoteLines
              .skip(1)
              .map((l) => l.trim().replaceFirst(RegExp(r'^>+\s?'), ''))
              .toList();
          widgets.add(
            _buildToggleBlockWidget(
              context: context,
              lineIndex: i,
              title: toggleTitle.isEmpty ? 'Toggle section' : toggleTitle,
              bodyMarkdown: innerLines.join('\n').trim(),
              defaultOpen: false,
              isDark: isDark,
              theme: theme,
            ),
          );
        } else {
          widgets.add(_wrapLineTap(_buildBlockquoteOrAlert(context, quoteLines, isDark, theme), i));
        }
        i = j;
        continue;
      }

      // 5b. Foldable Headings (# H1 to #### H4) in Reader Mode
      final topHeadingMatch = RegExp(r'^(#{1,4})\s+(.*)$').firstMatch(trimmed);
      if (topHeadingMatch != null && isInteractive) {
        final hLevel = topHeadingMatch.group(1)!.length;
        int sectionEnd = i + 1;
        bool inFence = false;
        while (sectionEnd < lines.length) {
          final st = lines[sectionEnd].trim();
          if (st.startsWith('```')) {
            inFence = !inFence;
            sectionEnd++;
            continue;
          }
          if (!inFence) {
            final nextH = RegExp(r'^(#{1,6})\s+').firstMatch(st);
            if (nextH != null && nextH.group(1)!.length <= hLevel) {
              break;
            }
          }
          sectionEnd++;
        }
        final hasFoldableBody = sectionEnd > i + 1 &&
            lines.sublist(i + 1, sectionEnd).any((l) => l.trim().isNotEmpty);
        final isFolded = _foldedHeadingLines.contains(i);

        widgets.add(
          _buildFoldableHeadingRow(
            context: context,
            line: line,
            lineIndex: i,
            isDark: isDark,
            hasFoldableBody: hasFoldableBody,
            isFolded: isFolded,
            foldedLineCount: sectionEnd - i - 1,
          ),
        );

        if (isFolded && hasFoldableBody) {
          i = sectionEnd;
        } else {
          i++;
        }
        continue;
      }

      // 6. Line-based elements (Headings, Checklists, Lists, Paragraphs)
      widgets.add(_wrapLineTap(_buildLineWidget(context, line, i, isDark), i));
      i++;
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  Widget _buildFoldableHeadingRow({
    required BuildContext context,
    required String line,
    required int lineIndex,
    required bool isDark,
    required bool hasFoldableBody,
    required bool isFolded,
    required int foldedLineCount,
  }) {
    final headingChild = _wrapLineTap(
      _buildLineWidget(context, line, lineIndex, isDark),
      lineIndex,
    );
    if (!hasFoldableBody) return headingChild;

    final accent = palette.resolveAccentColor(isDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isFolded) {
                    _foldedHeadingLines.remove(lineIndex);
                  } else {
                    _foldedHeadingLines.add(lineIndex);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 6, top: 6, bottom: 4),
                child: AnimatedRotation(
                  turns: isFolded ? -0.25 : 0.0,
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: isFolded
                        ? accent
                        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ),
                ),
              ),
            ),
            Expanded(child: headingChild),
            if (isFolded)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _foldedHeadingLines.remove(lineIndex));
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.11),
                    borderRadius: AppSpacing.roundedPill,
                  ),
                  child: Text(
                    '••• $foldedLineCount lines',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleBlockWidget({
    required BuildContext context,
    required int lineIndex,
    required String title,
    required String bodyMarkdown,
    required bool defaultOpen,
    required bool isDark,
    required ThemeData theme,
  }) {
    final isOpen = _toggleOpenState[lineIndex] ?? defaultOpen;
    final accent = palette.resolveAccentColor(isDark);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceAlt.withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOpen
              ? accent.withValues(alpha: 0.45)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _toggleOpenState[lineIndex] = !isOpen);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isOpen ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRichTextSpans(
                      title,
                      isDark,
                      theme,
                      context: context,
                      baseStyle: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen && bodyMarkdown.isNotEmpty && widget.transclusionDepth < 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 12, 12),
              child: RichNoteContentView(
                content: bodyMarkdown,
                paletteId: paletteId,
                isInteractive: false,
                workspaceItems: workspaceItems,
                onWikiLinkTap: onWikiLinkTap,
                transclusionDepth: widget.transclusionDepth + 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLineWidget(BuildContext context, String line, int lineIndex, bool isDark) {
    final theme = Theme.of(context);
    final trimmed = line.trim();

    if (trimmed.isEmpty) {
      return const SizedBox(height: 10);
    }

    // Headings H1 to H6 (# to ######)
    final headingMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
    if (headingMatch != null) {
      final level = headingMatch.group(1)!.length;
      final text = headingMatch.group(2)!;
      TextStyle? style;
      EdgeInsets padding;
      switch (level) {
        case 1:
          style = theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          );
          padding = const EdgeInsets.only(top: 14, bottom: 6);
          break;
        case 2:
          style = theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          );
          padding = const EdgeInsets.only(top: 12, bottom: 4);
          break;
        case 3:
          style = theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          );
          padding = const EdgeInsets.only(top: 10, bottom: 4);
          break;
        case 4:
          style = theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          );
          padding = const EdgeInsets.only(top: 8, bottom: 3);
          break;
        case 5:
          style = theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          );
          padding = const EdgeInsets.only(top: 6, bottom: 2);
          break;
        case 6:
        default:
          style = theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          );
          padding = const EdgeInsets.only(top: 6, bottom: 2);
          break;
      }
      return Padding(
        padding: padding,
        child: _buildRichTextSpans(
          text,
          isDark,
          theme,
          baseStyle: style,
          context: context,
        ),
      );
    }

    // Interactive Checklist item ([ ] or [x] or [X]) with indentation support
    final isUnchecked = line.contains('[ ]');
    final isChecked = line.contains('[x]') || line.contains('[X]');

    if (isUnchecked || isChecked) {
      final leadingSpaces = line.indexOf(RegExp(r'\[|\S'));
      final indent = (leadingSpaces > 0 ? (leadingSpaces / 2).floor() : 0).clamp(0, 5);
      final taskText = line
          .replaceAll(RegExp(r'^\s*[-*+]?\s*\[[ xX]\]\s*'), '')
          .replaceAll(RegExp(r'\[[ xX]\]'), '')
          .trim();

      return Padding(
        padding: EdgeInsets.only(top: 3, bottom: 3, left: indent * 16.0),
        child: InkWell(
          onTap: isInteractive ? () => _toggleCheckbox(lineIndex) : null,
          borderRadius: AppSpacing.roundedSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppSpacing.fastAnim,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isChecked
                        ? palette.resolveBulletColor(isDark)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isChecked
                          ? palette.resolveBulletColor(isDark)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: 1.8,
                    ),
                  ),
                  child: isChecked
                      ? const Center(
                          child: TackIcon(
                            TackIcons.check,
                            size: 14,
                            color: Colors.white,
                            style: HeroIconStyle.solid,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildRichTextSpans(
                    taskText,
                    isDark,
                    theme,
                    context: context,
                    baseStyle: theme.textTheme.bodyLarge?.copyWith(
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked
                          ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      fontWeight: isChecked ? FontWeight.w400 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Blockquote (> Quote text or >> Nested Quote)
    if (trimmed.startsWith('>')) {
      return _buildBlockquoteOrAlert(context, [line], isDark, theme);
    }

    // Numbered item (e.g. 1. item) with indentation
    final numMatch = RegExp(r'^(\s*)(\d+\.)\s*(.*)$').firstMatch(line);
    if (numMatch != null) {
      final leadingSpaces = numMatch.group(1)?.length ?? 0;
      final indent = (leadingSpaces / 2).floor().clamp(0, 5);
      final numPrefix = numMatch.group(2) ?? '';
      final body = numMatch.group(3) ?? '';

      return Padding(
        padding: EdgeInsets.only(top: 3, bottom: 3, left: indent * 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                numPrefix,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.resolveNumberPrefix(isDark),
                ),
              ),
            ),
            Expanded(child: _buildRichTextSpans(body, isDark, theme, context: context)),
          ],
        ),
      );
    }

    // Bullet item (- item, • item, * item, + item) with multi-level indentation
    final bulletMatch = RegExp(r'^(\s*)([-•*+])\s*(.*)$').firstMatch(line);
    if (bulletMatch != null) {
      final leadingSpaces = bulletMatch.group(1)?.length ?? 0;
      final indent = (leadingSpaces / 2).floor().clamp(0, 5);
      final body = bulletMatch.group(3) ?? '';

      Widget bulletWidget;
      final bulletColor = palette.resolveBulletColor(isDark);
      if (indent % 3 == 1) {
        bulletWidget = Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: bulletColor, width: 1.5),
          ),
        );
      } else if (indent % 3 == 2) {
        bulletWidget = Container(
          width: 5,
          height: 5,
          color: bulletColor,
        );
      } else {
        bulletWidget = Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: bulletColor,
            shape: BoxShape.circle,
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.only(top: 3, bottom: 3, left: indent * 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 8),
              child: bulletWidget,
            ),
            Expanded(child: _buildRichTextSpans(body, isDark, theme, context: context)),
          ],
        ),
      );
    }

    // Regular paragraph
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _buildRichTextSpans(line, isDark, theme, context: context),
    );
  }

  Widget _buildBlockquoteOrAlert(
    BuildContext context,
    List<String> quoteLines,
    bool isDark,
    ThemeData theme,
  ) {
    if (quoteLines.isEmpty) return const SizedBox.shrink();

    final firstLine = quoteLines.first.trim();
    final strippedFirst = firstLine.replaceFirst(RegExp(r'^>+\s*'), '');

    final alertMatch = RegExp(r'^\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\](?:\s+(.*))?$', caseSensitive: false)
        .firstMatch(strippedFirst);

    if (alertMatch != null) {
      final alertType = alertMatch.group(1)!.toUpperCase();
      final titleOverride = alertMatch.group(2)?.trim();

      final bodyLines = <String>[];
      for (int k = 1; k < quoteLines.length; k++) {
        final l = quoteLines[k].trim();
        bodyLines.add(l.replaceFirst(RegExp(r'^>+\s*'), ''));
      }
      final bodyText = bodyLines.join('\n').trim();

      Color alertColor;
      IconData alertIcon;
      switch (alertType) {
        case 'TIP':
          alertColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
          alertIcon = LucideIcons.lightbulb;
          break;
        case 'IMPORTANT':
          alertColor = isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
          alertIcon = LucideIcons.star;
          break;
        case 'WARNING':
          alertColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
          alertIcon = LucideIcons.alertTriangle;
          break;
        case 'CAUTION':
          alertColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
          alertIcon = LucideIcons.shieldAlert;
          break;
        case 'NOTE':
        default:
          alertColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
          alertIcon = LucideIcons.info;
          break;
      }

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: alertColor.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: alertColor.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: alertColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(alertIcon, size: 15, color: alertColor),
                          const SizedBox(width: 6),
                          Text(
                            titleOverride != null && titleOverride.isNotEmpty ? titleOverride : alertType,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: alertColor,
                            ),
                          ),
                        ],
                      ),
                      if (bodyText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildRichTextSpans(
                          bodyText,
                          isDark,
                          theme,
                          context: context,
                          baseStyle: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Standard multi-line blockquote
    final quoteTexts = <String>[];
    int minDepth = 99;
    for (final raw in quoteLines) {
      final t = raw.trim();
      int depth = 0;
      while (depth < t.length && t[depth] == '>') {
        depth++;
      }
      if (depth < minDepth && depth > 0) minDepth = depth;
      quoteTexts.add(t.substring(depth).trim());
    }
    final combinedQuote = quoteTexts.join('\n');

    return Container(
      margin: EdgeInsets.only(top: 6, bottom: 6, left: (minDepth > 0 ? (minDepth - 1) * 12.0 : 0.0)),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.resolveQuoteBg(isDark),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: palette.resolveQuoteBar(isDark), width: 3.5),
        ),
      ),
      child: _buildRichTextSpans(
        combinedQuote,
        isDark,
        theme,
        context: context,
        baseStyle: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          height: 1.45,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
    );
  }

  Widget _buildFencedCodeBlock(
    BuildContext context,
    String lang,
    String code,
    bool isDark,
    ThemeData theme,
  ) {
    final langLabel = lang.trim().toUpperCase();
    final lines = code.split('\n');
    final lineCount = lines.isEmpty ? 1 : lines.length;
    final gutterText = List.generate(lineCount, (i) => '${i + 1}').join('\n');

    final codeTextStyle = GoogleFonts.jetBrainsMono(
      fontSize: 12.5,
      height: 1.52,
      letterSpacing: -0.1,
      color: isDark ? const Color(0xFFABB2BF) : const Color(0xFF2E3440),
    );

    final gutterTextStyle = GoogleFonts.jetBrainsMono(
      fontSize: 12.5,
      height: 1.52,
      letterSpacing: -0.1,
      color: isDark ? const Color(0xFF5C6370) : const Color(0xFF9CA3AF),
      fontWeight: FontWeight.w500,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181A20) : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D37) : const Color(0xFFE2E6ED),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Prettier / IDE Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2129) : const Color(0xFFECF0F6),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF2A2D37) : const Color(0xFFE2E6ED),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Window dots
                Row(
                  children: [
                    _buildMacDot(const Color(0xFFFF5F56)),
                    const SizedBox(width: 5.5),
                    _buildMacDot(const Color(0xFFFFBD2E)),
                    const SizedBox(width: 5.5),
                    _buildMacDot(const Color(0xFF27C93F)),
                  ],
                ),
                const SizedBox(width: 12),
                // Language badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF282C37) : const Color(0xFFDEE3EC),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    langLabel.isEmpty ? 'CODE' : langLabel,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: palette.resolveCodeAccent(isDark),
                    ),
                  ),
                ),
                const Spacer(),
                // Copy button
                _CopyCodeButton(code: code, isDark: isDark),
              ],
            ),
          ),
          // Code Area with Sticky Gutter
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line Numbers Gutter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF15171C) : const Color(0xFFF1F3F6),
                  border: Border(
                    right: BorderSide(
                      color: isDark ? const Color(0xFF252833) : const Color(0xFFE5E9F0),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  gutterText,
                  textAlign: TextAlign.right,
                  style: gutterTextStyle,
                ),
              ),
              // Code Content
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: SelectableText.rich(
                    TextSpan(
                      children: CodeSyntaxHighlighter.highlight(
                        code,
                        isDark: isDark,
                        baseStyle: codeTextStyle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    List<String> lines,
    int startLineIndex,
    int endLineExclusive,
    bool isDark,
    ThemeData theme,
  ) {
    if (lines.length < 2) return const SizedBox.shrink();

    List<String> parseCells(String line) {
      var raw = line.trim();
      if (raw.startsWith('|')) raw = raw.substring(1);
      if (raw.endsWith('|')) raw = raw.substring(0, raw.length - 1);
      return raw.split('|').map((c) => c.trim()).toList();
    }

    final headers = parseCells(lines[0]);
    final separatorCells = parseCells(lines[1]);
    final alignments = <TextAlign>[];
    for (final s in separatorCells) {
      final trimmed = s.trim();
      if (trimmed.startsWith(':') && trimmed.endsWith(':')) {
        alignments.add(TextAlign.center);
      } else if (trimmed.endsWith(':')) {
        alignments.add(TextAlign.right);
      } else {
        alignments.add(TextAlign.left);
      }
    }

    final rows = <List<String>>[];
    for (int i = 2; i < lines.length; i++) {
      rows.add(parseCells(lines[i]));
    }

    final borderColor = palette.resolveTableBorder(isDark);
    final headerBg = palette.resolveTableHeaderBg(isDark);
    final canVisualEdit = isInteractive && onContentChanged != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canVisualEdit)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: headerBg.withValues(alpha: 0.65),
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.table,
                    size: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${rows.length} rows • ${headers.length} cols',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final parsedTable = MarkdownTableService.parseTableLines(lines);
                      if (parsedTable == null) return;
                      HapticFeedback.lightImpact();
                      MarkdownTableEditorSheet.show(
                        context,
                        initialTable: parsedTable,
                        paletteId: paletteId,
                        onSave: (updatedTable) {
                          final updatedDoc = MarkdownTableService.replaceTableInDocument(
                            rawDocument: content,
                            startLine: startLineIndex,
                            endLineExclusive: endLineExclusive,
                            updatedTable: updatedTable,
                          );
                          onContentChanged?.call(updatedDoc);
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: AppSpacing.roundedPill,
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.pencil,
                            size: 10.5,
                            color: palette.resolveAccentColor(isDark),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Edit Table',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder(
                horizontalInside: BorderSide(color: borderColor, width: 0.8),
                verticalInside: BorderSide(color: borderColor, width: 0.8),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: headerBg),
                  children: List.generate(headers.length, (colIdx) {
                    final align = colIdx < alignments.length ? alignments[colIdx] : TextAlign.left;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Align(
                        alignment: align == TextAlign.center
                            ? Alignment.center
                            : (align == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
                        child: _buildRichTextSpans(
                          headers[colIdx],
                          isDark,
                          theme,
                          context: context,
                          baseStyle: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                ...rows.map((row) {
                  return TableRow(
                    children: List.generate(headers.length, (colIdx) {
                      final text = colIdx < row.length ? row[colIdx] : '';
                      final align = colIdx < alignments.length ? alignments[colIdx] : TextAlign.left;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Align(
                          alignment: align == TextAlign.center
                              ? Alignment.center
                              : (align == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
                          child: _buildRichTextSpans(text, isDark, theme, context: context),
                        ),
                      );
                    }),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBlock(BuildContext context, String alt, String url, bool isDark) {
    final cleanUrl = url.trim().replaceFirst(RegExp(r'^file://'), '');
    Widget imgWidget;
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      imgWidget = Image.network(
        cleanUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildImageError(alt, isDark),
      );
    } else if (!kIsWeb) {
      final file = File(cleanUrl);
      if (file.existsSync()) {
        imgWidget = Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildImageError(alt, isDark),
        );
      } else {
        imgWidget = _buildImageError(alt, isDark);
      }
    } else {
      imgWidget = _buildImageError(alt, isDark);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _openImageLightbox(context, cleanUrl, alt);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2F38) : const Color(0xFFE2E6EE),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : const Color(0x0A191A23),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360, minWidth: 100),
                    child: imgWidget,
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (alt.trim().isNotEmpty && alt != 'Image') ...[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                alt.trim(),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageError(String alt, bool isDark) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 24,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
          const SizedBox(width: 8),
          Text(
            alt.isNotEmpty ? alt : 'Image could not be loaded',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichTextSpans(
    String text,
    bool isDark,
    ThemeData theme, {
    TextStyle? baseStyle,
    BuildContext? context,
  }) {
    final spans = <InlineSpan>[];
    final defaultStyle = baseStyle ??
        theme.textTheme.bodyLarge?.copyWith(
          height: 1.5,
          fontSize: 15,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontFamily: AppTypography.fontFamily,
        );

    final pattern = RegExp(
      r'(`[^`\n]+`)'
      r'|(!?\[\[[^\[\]\n]+\]\])'
      r'|(!\[[^\]\n]*\]\([^)\n]+\))'
      r'|(\[[^\]\n]+\]\([^)\n]+\))'
      r'|(https?:\/\/[^\s<]+[^<.,:;"\)\]\s])'
      r'|(==.*?==)'
      r'|(\*\*.*?\*\*)'
      r'|(__.*?__)'
      r'|(\*.*?\*)'
      r'|(_.*?_)'
      r'|(~~.*?~~)'
      r'|(<u>.*?</u>)'
      r'|(#[a-zA-Z0-9_-]+)',
      dotAll: false,
    );

    int lastIndex = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: defaultStyle,
        ));
      }

      final matched = match.group(0)!;
      if (matched.startsWith('`') && matched.endsWith('`') && matched.length >= 2) {
        final codeText = matched.substring(1, matched.length - 1);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: palette.resolveInlineCodeBg(isDark),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: palette.resolveTableBorder(isDark),
                  width: 0.8,
                ),
              ),
              child: Text(
                codeText,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: (defaultStyle?.fontSize ?? 15) * 0.88,
                  fontWeight: FontWeight.w600,
                  color: palette.resolveInlineCodeText(isDark),
                ),
              ),
            ),
          ),
        );
      } else if ((matched.startsWith('[[') || matched.startsWith('![[')) &&
          matched.endsWith(']]')) {
        final parsedLink = WikiLinkService.parseToken(matched);
        if (parsedLink != null) {
          final targetItem = WikiLinkService.resolveTarget(parsedLink.target, workspaceItems);
          final isBoard = targetItem is WhiteboardCanvasItem;
          final exists = targetItem != null;
          final linkPalette = exists ? AppColors.getPaletteById(targetItem.paletteId) : palette;
          final linkAccent = linkPalette.resolveAccentColor(isDark);

          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Material(
                  color: exists
                      ? linkAccent.withValues(alpha: isDark ? 0.18 : 0.12)
                      : (isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF1F3F7)),
                  borderRadius: BorderRadius.circular(7),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onWikiLinkTap?.call(parsedLink);
                    },
                    borderRadius: BorderRadius.circular(7),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: exists
                              ? linkAccent.withValues(alpha: 0.45)
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TackIcon(
                            !exists
                                ? TackIcons.plus
                                : (isBoard ? TackIcons.whiteboardSvg : TackIcons.notesSvg),
                            size: 11.5,
                            color: exists ? linkAccent : AppColors.accentAmber,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              parsedLink.displayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: (defaultStyle?.fontSize ?? 15) * 0.86,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: exists
                                    ? linkAccent
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          spans.add(TextSpan(text: matched, style: defaultStyle));
        }
      } else if (matched.startsWith('![') && matched.contains('](') && matched.endsWith(')')) {
        final midIndex = matched.indexOf('](');
        final alt = matched.substring(2, midIndex);
        final url = matched.substring(midIndex + 2, matched.length - 1).trim();
        final cleanUrl = url.replaceFirst(RegExp(r'^file://'), '');
        final isNet = cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://');

        Widget inlineImg;
        if (isNet) {
          inlineImg = Image.network(
            cleanUrl,
            height: 28,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_rounded, size: 20),
          );
        } else if (!kIsWeb) {
          final file = File(cleanUrl);
          if (file.existsSync()) {
            inlineImg = Image.file(file, height: 28, fit: BoxFit.cover);
          } else {
            inlineImg = const Icon(Icons.broken_image_rounded, size: 20);
          }
        } else {
          inlineImg = const Icon(Icons.broken_image_rounded, size: 20);
        }

        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () {
                if (context != null) {
                  _openImageLightbox(context, cleanUrl, alt);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: inlineImg,
                ),
              ),
            ),
          ),
        );
      } else if (matched.startsWith('[') && matched.contains('](') && matched.endsWith(')')) {
        final midIndex = matched.indexOf('](');
        final label = matched.substring(1, midIndex);
        final url = matched.substring(midIndex + 2, matched.length - 1);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: InkWell(
              onTap: () {
                if (context != null) {
                  UrlLauncherHelper.openUrl(context, url);
                }
              },
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: url));
                HapticFeedback.lightImpact();
                if (context != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link copied: $url'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: palette.resolveAccentColor(isDark),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: palette.resolveAccentColor(isDark),
                        fontSize: defaultStyle?.fontSize,
                      ),
                    ),
                    const SizedBox(width: 3),
                    TackIcon(
                      TackIcons.link,
                      size: 11,
                      color: palette.resolveAccentColor(isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else if (matched.startsWith('http://') || matched.startsWith('https://')) {
        final url = matched;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: InkWell(
              onTap: () {
                if (context != null) {
                  UrlLauncherHelper.openUrl(context, url);
                }
              },
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: url));
                HapticFeedback.lightImpact();
                if (context != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link copied: $url'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      url,
                      style: TextStyle(
                        color: palette.resolveAccentColor(isDark),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: palette.resolveAccentColor(isDark),
                        fontSize: defaultStyle?.fontSize,
                      ),
                    ),
                    const SizedBox(width: 3),
                    TackIcon(
                      TackIcons.link,
                      size: 11,
                      color: palette.resolveAccentColor(isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else if (matched.startsWith('==') && matched.endsWith('==') && matched.length >= 4) {
        final innerText = matched.substring(2, matched.length - 2);
        final colonIdx = innerText.indexOf(':');
        String displayText = innerText;
        Color highlightBg;
        if (colonIdx > 0 && colonIdx < 15) {
          final prefix = innerText.substring(0, colonIdx).toLowerCase();
          final known = AppColors.presetPalettes.any((p) => p.id == prefix);
          if (known) {
            displayText = innerText.substring(colonIdx + 1);
            highlightBg = AppColors.getHighlightColor(prefix, isDark: isDark);
          } else {
            highlightBg = AppColors.getHighlightColor(paletteId, isDark: isDark);
          }
        } else {
          highlightBg = AppColors.getHighlightColor(paletteId, isDark: isDark);
        }

        spans.add(TextSpan(
          text: displayText,
          style: defaultStyle?.copyWith(
            backgroundColor: highlightBg,
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (matched.startsWith('**') && matched.endsWith('**') && matched.length >= 4) {
        spans.add(TextSpan(
          text: matched.substring(2, matched.length - 2),
          style: defaultStyle?.copyWith(fontWeight: FontWeight.w800),
        ));
      } else if (matched.startsWith('__') && matched.endsWith('__') && matched.length >= 4) {
        spans.add(TextSpan(
          text: matched.substring(2, matched.length - 2),
          style: defaultStyle?.copyWith(decoration: TextDecoration.underline),
        ));
      } else if (matched.startsWith('<u>') && matched.endsWith('</u>') && matched.length >= 7) {
        spans.add(TextSpan(
          text: matched.substring(3, matched.length - 4),
          style: defaultStyle?.copyWith(decoration: TextDecoration.underline),
        ));
      } else if (matched.startsWith('*') && matched.endsWith('*') && matched.length >= 2) {
        spans.add(TextSpan(
          text: matched.substring(1, matched.length - 1),
          style: defaultStyle?.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (matched.startsWith('_') && matched.endsWith('_') && matched.length >= 2) {
        spans.add(TextSpan(
          text: matched.substring(1, matched.length - 1),
          style: defaultStyle?.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (matched.startsWith('~~') && matched.endsWith('~~') && matched.length >= 4) {
        spans.add(TextSpan(
          text: matched.substring(2, matched.length - 2),
          style: defaultStyle?.copyWith(decoration: TextDecoration.lineThrough),
        ));
      } else if (matched.startsWith('#') && matched.length > 1) {
        final hexColor = AppColors.tryParseHexColor(matched);
        if (hexColor != null) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: hexColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: hexColor.withValues(alpha: 0.8),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: hexColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      matched,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF18191F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.resolveSoftBackground(isDark),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: palette.resolveTableBorder(isDark),
                    width: 1,
                  ),
                ),
                child: Text(
                  matched,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.resolveAccentColor(isDark),
                  ),
                ),
              ),
            ),
          );
        }
      } else {
        spans.add(TextSpan(text: matched, style: defaultStyle));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: defaultStyle,
      ));
    }

    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: spans,
      ),
    );
  }
}

class _CopyCodeButton extends StatefulWidget {
  final String code;
  final bool isDark;

  const _CopyCodeButton({
    required this.code,
    required this.isDark,
  });

  @override
  State<_CopyCodeButton> createState() => _CopyCodeButtonState();
}

class _CopyCodeButtonState extends State<_CopyCodeButton> {
  bool _copied = false;

  void _onCopy() {
    Clipboard.setData(ClipboardData(text: widget.code));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isDark ? const Color(0xFFABB2BF) : const Color(0xFF5C6370);
    final activeFg = widget.isDark ? const Color(0xFF98C379) : const Color(0xFF439446);

    return InkWell(
      onTap: _onCopy,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TackIcon(
              _copied ? TackIcons.check : TackIcons.copy,
              size: 13,
              color: _copied ? activeFg : fg,
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? 'Copied!' : 'Copy',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _copied ? activeFg : fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openImageLightbox(BuildContext context, String url, String alt) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      pageBuilder: (ctx, _, _) => _ImageLightboxViewer(url: url, alt: alt),
    ),
  );
}

class _ImageLightboxViewer extends StatelessWidget {
  final String url;
  final String alt;

  const _ImageLightboxViewer({required this.url, required this.alt});

  @override
  Widget build(BuildContext context) {
    final cleanUrl = url.trim().replaceFirst(RegExp(r'^file://'), '');
    final isNetwork = cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://');

    Widget imageWidget;
    if (isNetwork) {
      imageWidget = Image.network(
        cleanUrl,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          );
        },
        errorBuilder: (_, _, _) => const Icon(
          Icons.broken_image_rounded,
          size: 48,
          color: Colors.white54,
        ),
      );
    } else if (!kIsWeb) {
      final file = File(cleanUrl);
      if (file.existsSync()) {
        imageWidget = Image.file(file, fit: BoxFit.contain);
      } else {
        imageWidget = const Icon(
          Icons.broken_image_rounded,
          size: 48,
          color: Colors.white54,
        );
      }
    } else {
      imageWidget = const Icon(
        Icons.broken_image_rounded,
        size: 48,
        color: Colors.white54,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Interactive Pinch & Zoom Image Area
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.5,
                boundaryMargin: const EdgeInsets.all(60),
                child: imageWidget,
              ),
            ),

            // Top action bar
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                      shape: const CircleBorder(),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  if (alt.isNotEmpty && alt != 'Image')
                    Expanded(
                      child: Text(
                        alt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (isNetwork)
                    IconButton(
                      icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white, size: 22),
                      tooltip: 'Open in browser',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () => UrlLauncherHelper.openUrl(context, cleanUrl),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


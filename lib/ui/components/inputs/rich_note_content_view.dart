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
import '../dialogs_sheets/app_bottom_sheet.dart';
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
  _FootnoteCollection _footnoteCollection = const _FootnoteCollection.empty();

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
    final inheritedFootnotes = _FootnoteScope.maybeOf(context);
    final footnoteCollection = _extractFootnotes(
      lines,
      parsedFrontmatter.contentStartLineIndex,
      inherited: inheritedFootnotes,
    );
    _footnoteCollection = footnoteCollection;

    final widgets = <Widget>[];

    int i = parsedFrontmatter.contentStartLineIndex;
    while (i < lines.length) {
      if (footnoteCollection.definitionLineIndices.contains(i)) {
        i++;
        continue;
      }

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

      // 0b. HTML <details> / <summary> Toggle Block (portable Markdown/HTML)
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
            normalizedLang == 'sequencediagram' ||
            normalizedLang == 'erdiagram' ||
            normalizedLang == 'er' ||
            normalizedLang == 'gantt' ||
            normalizedLang == 'mindmap' ||
            (normalizedLang.isEmpty &&
                (trimmedCode.startsWith('graph') ||
                    trimmedCode.startsWith('flowchart') ||
                    trimmedCode.startsWith('pie') ||
                    trimmedCode.startsWith('timeline') ||
                    trimmedCode.startsWith('sequencediagram') ||
                    trimmedCode.startsWith('erdiagram') ||
                    trimmedCode.startsWith('gantt') ||
                    trimmedCode.startsWith('mindmap')));

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

      // 5c. Definition Lists (Term line followed by `: Definition` lines)
      if (!_isNonDefinitionTermLine(trimmed)) {
        final firstDefStart = _findDefinitionStartLine(lines, i);
        if (firstDefStart != -1) {
          final parsedDefs = _consumeDefinitionList(lines, i);
          widgets.add(
            _wrapLineTap(
              _buildDefinitionListWidget(context, parsedDefs.groups, isDark, theme),
              i,
            ),
          );
          i = parsedDefs.nextIndex;
          continue;
        }
      }

      // 6. Line-based elements (Headings, Checklists, Lists, Paragraphs)
      widgets.add(_wrapLineTap(_buildLineWidget(context, line, i, isDark), i));
      i++;
    }

    if (footnoteCollection.localDefinitions.isNotEmpty) {
      widgets.add(_buildFootnotesSection(context, footnoteCollection, isDark, theme));
    }

    return _FootnoteScope(
      collection: footnoteCollection,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,
        ),
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
                        language: lang,
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
                    child: Icon(
                      TackIcons.maximize,
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
            TackIcons.imageOff,
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

  // ─── Inline Recursive Parser + Sup/Sub + Footnotes ────────────────────────────

  static final RegExp _footnoteRefRegex = RegExp(r'\[\^([^\[\]\s\n]+)\](?!:)');
  static final RegExp _wikiTokenRegex = RegExp(r'!?\[\[[^\[\]\n]+\]\]');
  static final RegExp _inlineImgRegex = RegExp(r'!\[[^\]\n]*\]\([^)\n]+\)');
  static final RegExp _bareUrlRegex =
      RegExp(r'https?:\/\/[^\s<]+[^<.,:;"\)\]\s]');
  static final RegExp _inlineHtmlTagRegex = RegExp(
    r'<(sup|sub|u)>(.*?)<\/\1>',
    caseSensitive: false,
  );
  static final RegExp _hashTokenRegex = RegExp(r'#[a-zA-Z0-9_-]+');
  static final RegExp _wordCharRegex = RegExp(r'[A-Za-z0-9_]');
  static final RegExp _footnoteDefRegex = RegExp(r'^\s*\[\^([^\[\]\s\n]+)\]:(.*)$');
  static final RegExp _defLineRegex = RegExp(r'^\s{0,3}:\s+(.+)$');

  Widget _buildRichTextSpans(
    String text,
    bool isDark,
    ThemeData theme, {
    TextStyle? baseStyle,
    BuildContext? context,
  }) {
    final defaultStyle = baseStyle ??
        theme.textTheme.bodyLarge?.copyWith(
          height: 1.5,
          fontSize: 15,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontFamily: AppTypography.fontFamily,
        );

    final spans = _parseInlineSpans(
      text,
      isDark,
      theme,
      defaultStyle,
      context: context,
      depth: 0,
    );

    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: spans,
      ),
    );
  }

  List<InlineSpan> _parseInlineSpans(
    String text,
    bool isDark,
    ThemeData theme,
    TextStyle? currentStyle, {
    BuildContext? context,
    int depth = 0,
  }) {
    if (text.isEmpty) return const [];
    if (depth >= 8) {
      return [TextSpan(text: text, style: currentStyle)];
    }

    final spans = <InlineSpan>[];
    final buffer = StringBuffer();

    void flushBuffer() {
      if (buffer.isNotEmpty) {
        spans.add(TextSpan(text: buffer.toString(), style: currentStyle));
        buffer.clear();
      }
    }

    int i = 0;
    while (i < text.length) {
      final codeUnit = text.codeUnitAt(i);

      // 1. Inline code: `code` (atomic leaf, inherits emphasis/decoration from enclosing spans)
      if (codeUnit == 96) {
        final closeIdx = text.indexOf('`', i + 1);
        if (closeIdx > i + 1 && !text.substring(i + 1, closeIdx).contains('\n')) {
          flushBuffer();
          final codeText = text.substring(i + 1, closeIdx);
          spans.add(
            _buildInlineCodeSpan(codeText, isDark, currentStyle),
          );
          i = closeIdx + 1;
          continue;
        }
      }

      // 2. Wiki-links / embeds: [[Target]] or ![[Target]]
      if (text.startsWith('[[', i) || text.startsWith('![[', i)) {
        final wikiMatch = _wikiTokenRegex.matchAsPrefix(text, i);
        if (wikiMatch != null) {
          final matched = wikiMatch.group(0)!;
          final parsedLink = WikiLinkService.parseToken(matched);
          if (parsedLink != null) {
            flushBuffer();
            spans.add(_buildWikiLinkSpan(parsedLink, isDark, currentStyle));
            i = wikiMatch.end;
            continue;
          }
        }
      }

      // 3. Inline image: ![alt](url)
      if (text.startsWith('![', i)) {
        final imgMatch = _inlineImgRegex.matchAsPrefix(text, i);
        if (imgMatch != null) {
          flushBuffer();
          spans.add(
            _buildInlineImageSpan(
              imgMatch.group(0)!,
              isDark,
              context: context,
            ),
          );
          i = imgMatch.end;
          continue;
        }
      }

      // 4. Footnote reference badge: [^id]
      if (text.startsWith('[^', i)) {
        final fnMatch = _footnoteRefRegex.matchAsPrefix(text, i);
        if (fnMatch != null &&
            (fnMatch.end >= text.length || text.codeUnitAt(fnMatch.end) != 40)) {
          final id = fnMatch.group(1)!;
          final entry = _footnoteCollection.byId[id];
          if (entry != null) {
            flushBuffer();
            spans.add(
              _buildFootnoteBadgeSpan(
                entry,
                isDark,
                theme,
                currentStyle,
                context: context,
              ),
            );
            i = fnMatch.end;
            continue;
          }
        }
      }

      // 5. Markdown link: [label](url) (supports formatted label inside!)
      if (codeUnit == 91) {
        final link = _tryMatchMarkdownLink(text, i);
        if (link != null) {
          flushBuffer();
          spans.add(
            _buildMarkdownLinkSpan(
              link.label,
              link.url,
              isDark,
              theme,
              currentStyle,
              context: context,
              depth: depth + 1,
            ),
          );
          i = link.endIndex;
          continue;
        }
      }

      // 6. Bare URL: https://...
      if (text.startsWith('http://', i) || text.startsWith('https://', i)) {
        final urlMatch = _bareUrlRegex.matchAsPrefix(text, i);
        if (urlMatch != null) {
          flushBuffer();
          spans.add(
            _buildBareUrlSpan(
              urlMatch.group(0)!,
              isDark,
              currentStyle,
              context: context,
            ),
          );
          i = urlMatch.end;
          continue;
        }
      }

      // 7. HTML inline tags: <sup>...</sup>, <sub>...</sub>, <u>...</u>
      if (codeUnit == 60) {
        final tagMatch = _inlineHtmlTagRegex.matchAsPrefix(text, i);
        if (tagMatch != null) {
          final tag = tagMatch.group(1)!.toLowerCase();
          final inner = tagMatch.group(2)!;
          if (inner.isNotEmpty) {
            flushBuffer();
            if (tag == 'u') {
              final nextStyle = _mergeTextStyle(
                currentStyle,
                addDecoration: TextDecoration.underline,
              );
              spans.addAll(
                _parseInlineSpans(
                  inner,
                  isDark,
                  theme,
                  nextStyle,
                  context: context,
                  depth: depth + 1,
                ),
              );
            } else {
              spans.add(
                _buildScriptSpan(
                  inner,
                  isSuperscript: tag == 'sup',
                  isDark: isDark,
                  theme: theme,
                  currentStyle: currentStyle,
                  context: context,
                  depth: depth + 1,
                ),
              );
            }
            i = tagMatch.end;
            continue;
          }
        }
      }

      // 8. Custom Highlight: ==...== or ==palette:text==
      if (text.startsWith('==', i) && !_isWhitespace(text, i + 2)) {
        final endIdx = _findClosingMarker(text, i + 2, '==');
        if (endIdx > i + 2) {
          flushBuffer();
          final innerText = text.substring(i + 2, endIdx);
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

          final nextStyle = _mergeTextStyle(
            currentStyle,
            fontWeight: currentStyle?.fontWeight ?? FontWeight.w600,
            backgroundColor: highlightBg,
          );
          spans.addAll(
            _parseInlineSpans(
              displayText,
              isDark,
              theme,
              nextStyle,
              context: context,
              depth: depth + 1,
            ),
          );
          i = endIdx + 2;
          continue;
        }
      }

      // 9a. Bold + Italic: ***...***
      if (text.startsWith('***', i) && !_isWhitespace(text, i + 3)) {
        final endIdx = _findClosingMarker(text, i + 3, '***');
        if (endIdx > i + 3) {
          flushBuffer();
          final nextStyle = _mergeTextStyle(
            currentStyle,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
          );
          spans.addAll(
            _parseInlineSpans(
              text.substring(i + 3, endIdx),
              isDark,
              theme,
              nextStyle,
              context: context,
              depth: depth + 1,
            ),
          );
          i = endIdx + 3;
          continue;
        }
      }

      // 9b. Underline + Italic: ___...___
      if (text.startsWith('___', i) &&
          _canOpenUnderscore(text, i) &&
          !_isWhitespace(text, i + 3)) {
        final endIdx = _findClosingMarker(
          text,
          i + 3,
          '___',
          requireUnderscoreBoundary: true,
        );
        if (endIdx > i + 3) {
          flushBuffer();
          final nextStyle = _mergeTextStyle(
            currentStyle,
            fontStyle: FontStyle.italic,
            addDecoration: TextDecoration.underline,
          );
          spans.addAll(
            _parseInlineSpans(
              text.substring(i + 3, endIdx),
              isDark,
              theme,
              nextStyle,
              context: context,
              depth: depth + 1,
            ),
          );
          i = endIdx + 3;
          continue;
        }
      }

      // 9c. Bold: **...**
      if (text.startsWith('**', i) &&
          !text.startsWith('***', i) &&
          !_isWhitespace(text, i + 2)) {
        final endIdx = _findClosingMarker(
          text,
          i + 2,
          '**',
          allowNestedSingleStar: true,
        );
        if (endIdx > i + 2) {
          flushBuffer();
          final nextStyle = _mergeTextStyle(
            currentStyle,
            fontWeight: FontWeight.w800,
          );
          spans.addAll(
            _parseInlineSpans(
              text.substring(i + 2, endIdx),
              isDark,
              theme,
              nextStyle,
              context: context,
              depth: depth + 1,
            ),
          );
          i = endIdx + 2;
          continue;
        }
      }

      // 9d. Underline: __...__
      if (text.startsWith('__', i) &&
          !text.startsWith('___', i) &&
          _canOpenUnderscore(text, i) &&
          !_isWhitespace(text, i + 2)) {
        final endIdx = _findClosingMarker(
          text,
          i + 2,
          '__',
          requireUnderscoreBoundary: true,
        );
        if (endIdx > i + 2) {
          flushBuffer();
          final nextStyle = _mergeTextStyle(
            currentStyle,
            addDecoration: TextDecoration.underline,
          );
          spans.addAll(
            _parseInlineSpans(
              text.substring(i + 2, endIdx),
              isDark,
              theme,
              nextStyle,
              context: context,
              depth: depth + 1,
            ),
          );
          i = endIdx + 2;
          continue;
        }
      }

      // 9e. Strikethrough: ~~...~~ (MUST precede single ~subscript~!)
      if (text.startsWith('~~', i) && !_isWhitespace(text, i + 2)) {
        final endIdx = _findClosingMarker(text, i + 2, '~~');
        if (endIdx > i + 2) {
          flushBuffer();
          final nextStyle = _mergeTextStyle(
            currentStyle,
            addDecoration: TextDecoration.lineThrough,
          );
          spans.addAll(
            _parseInlineSpans(
              text.substring(i + 2, endIdx),
              isDark,
              theme,
              nextStyle,
              context: context,
              depth: depth + 1,
            ),
          );
          i = endIdx + 2;
          continue;
        }
      }

      // 9f. Italic: *...* (also allows ***bold** italic* when *** failed to close as ***)
      if (codeUnit == 42 &&
          (!text.startsWith('**', i) || text.startsWith('***', i)) &&
          !_isWhitespace(text, i + 1)) {
        final endIdx = _findClosingMarker(
          text,
          i + 1,
          '*',
          allowNestedMarker: '**',
        );
        if (endIdx > i + 1) {
          flushBuffer();
          final nextStyle = _mergeTextStyle(
            currentStyle,
            fontStyle: FontStyle.italic,
          );
          spans.addAll(
            _parseInlineSpans(
              text.substring(i + 1, endIdx),
              isDark,
              theme,
              nextStyle,
              context: context,
              depth: depth + 1,
            ),
          );
          i = endIdx + 1;
          continue;
        }
      }

      // 9g. Italic: _..._ (with intraword snake_case guard)
      if (codeUnit == 95 &&
          (!text.startsWith('__', i) || text.startsWith('___', i)) &&
          _canOpenUnderscore(text, i) &&
          !_isWhitespace(text, i + 1)) {
        final endIdx = _findClosingMarker(
          text,
          i + 1,
          '_',
          requireUnderscoreBoundary: true,
          allowNestedMarker: '__',
        );
        if (endIdx > i + 1) {
          flushBuffer();
          final nextStyle = _mergeTextStyle(
            currentStyle,
            fontStyle: FontStyle.italic,
          );
          spans.addAll(
            _parseInlineSpans(
              text.substring(i + 1, endIdx),
              isDark,
              theme,
              nextStyle,
              context: context,
              depth: depth + 1,
            ),
          );
          i = endIdx + 1;
          continue;
        }
      }

      // 10a. Superscript: ^sup^ (guards against unlinked [^ or spaces inside)
      if (codeUnit == 94 &&
          (i == 0 || text.codeUnitAt(i - 1) != 91) &&
          !_isWhitespace(text, i + 1)) {
        final endIdx = _findClosingMarker(text, i + 1, '^');
        if (endIdx > i + 1) {
          flushBuffer();
          spans.add(
            _buildScriptSpan(
              text.substring(i + 1, endIdx),
              isSuperscript: true,
              isDark: isDark,
              theme: theme,
              currentStyle: currentStyle,
              context: context,
              depth: depth + 1,
            ),
          );
          i = endIdx + 1;
          continue;
        }
      }

      // 10b. Subscript: ~sub~ (distinct from ~~strike~~)
      if (codeUnit == 126 &&
          !text.startsWith('~~', i) &&
          (i == 0 || text.codeUnitAt(i - 1) != 126) &&
          !_isWhitespace(text, i + 1)) {
        final endIdx = _findClosingMarker(text, i + 1, '~');
        if (endIdx > i + 1) {
          flushBuffer();
          spans.add(
            _buildScriptSpan(
              text.substring(i + 1, endIdx),
              isSuperscript: false,
              isDark: isDark,
              theme: theme,
              currentStyle: currentStyle,
              context: context,
              depth: depth + 1,
            ),
          );
          i = endIdx + 1;
          continue;
        }
      }

      // 11. Hashtags and #RRGGBB color swatch pills
      if (codeUnit == 35 && i + 1 < text.length) {
        final hashMatch = _hashTokenRegex.matchAsPrefix(text, i);
        if (hashMatch != null) {
          flushBuffer();
          spans.add(_buildHashTokenSpan(hashMatch.group(0)!, isDark));
          i = hashMatch.end;
          continue;
        }
      }

      buffer.writeCharCode(codeUnit);
      i++;
    }

    flushBuffer();
    return spans;
  }

  TextStyle? _mergeTextStyle(
    TextStyle? base, {
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? addDecoration,
    Color? backgroundColor,
  }) {
    if (base == null) {
      return TextStyle(
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        decoration: addDecoration,
        backgroundColor: backgroundColor,
      );
    }

    TextDecoration? mergedDecoration = base.decoration;
    if (addDecoration != null && addDecoration != TextDecoration.none) {
      final list = <TextDecoration>[
        if (mergedDecoration != null && mergedDecoration != TextDecoration.none)
          mergedDecoration,
        addDecoration,
      ];
      mergedDecoration =
          list.length == 1 ? list.first : TextDecoration.combine(list);
    }

    return base.copyWith(
      fontWeight: fontWeight ?? base.fontWeight,
      fontStyle: fontStyle ?? base.fontStyle,
      decoration: mergedDecoration,
      backgroundColor: backgroundColor ?? base.backgroundColor,
    );
  }

  bool _isWhitespace(String text, int index) {
    if (index < 0 || index >= text.length) return true;
    final ch = text.codeUnitAt(index);
    return ch == 32 || ch == 9 || ch == 10 || ch == 13;
  }

  bool _isWordChar(String ch) => _wordCharRegex.hasMatch(ch);

  bool _canOpenUnderscore(String text, int index) {
    if (index > 0 && _isWordChar(text[index - 1])) return false;
    return true;
  }

  ({String label, String url, int endIndex})? _tryMatchMarkdownLink(
    String text,
    int startIndex,
  ) {
    int k = startIndex + 1;
    while (k < text.length) {
      final ch = text.codeUnitAt(k);
      if (ch == 10 || ch == 13) return null;
      if (ch == 96) {
        final closeTick = text.indexOf('`', k + 1);
        if (closeTick != -1 && !text.substring(k + 1, closeTick).contains('\n')) {
          k = closeTick + 1;
          continue;
        }
      }
      if (ch == 93) {
        // ']' must be directly followed by '(' and non-empty label
        if (k > startIndex + 1 && text.startsWith('](', k)) {
          final urlStart = k + 2;
          final urlEnd = text.indexOf(')', urlStart);
          if (urlEnd > urlStart &&
              !text.substring(urlStart, urlEnd).contains('\n')) {
            return (
              label: text.substring(startIndex + 1, k),
              url: text.substring(urlStart, urlEnd),
              endIndex: urlEnd + 1,
            );
          }
        }
        return null;
      }
      k++;
    }
    return null;
  }

  int _findClosingMarker(
    String text,
    int start,
    String marker, {
    bool allowNestedSingleStar = false,
    bool requireUnderscoreBoundary = false,
    String? allowNestedMarker,
  }) {
    final len = marker.length;
    bool openSingleStar = false;
    int j = start;
    while (j <= text.length - len) {
      final ch = text.codeUnitAt(j);
      if (ch == 10 || ch == 13) return -1;

      // Never match closing marker inside inline `code`
      if (ch == 96) {
        final closeTick = text.indexOf('`', j + 1);
        if (closeTick != -1 && !text.substring(j + 1, closeTick).contains('\n')) {
          j = closeTick + 1;
          continue;
        }
      }

      // Skip inner balanced marker (e.g. **bold** inside *italic*)
      if (allowNestedMarker != null && text.startsWith(allowNestedMarker, j)) {
        final nl = allowNestedMarker.length;
        final isTripleEdge =
            (allowNestedMarker == '**' && text.startsWith('***', j)) ||
            (allowNestedMarker == '__' && text.startsWith('___', j));
        if (!isTripleEdge) {
          final innerClose = text.indexOf(allowNestedMarker, j + nl);
          if (innerClose != -1 && !text.substring(j + nl, innerClose).contains('\n')) {
            j = innerClose + nl;
            continue;
          }
        }
      }

      // Track inner *italic* inside **bold** so **bold *italic*** closes cleanly
      if (allowNestedSingleStar && ch == 42 && !text.startsWith('**', j)) {
        final canOpen = !_isWhitespace(text, j + 1);
        final canClose = j > start && !_isWhitespace(text, j - 1);
        if (!openSingleStar && canOpen) {
          openSingleStar = true;
        } else if (openSingleStar && canClose) {
          openSingleStar = false;
        }
        j++;
        continue;
      }

      if (text.startsWith(marker, j) && j > start && !_isWhitespace(text, j - 1)) {
        if (allowNestedSingleStar &&
            marker == '**' &&
            openSingleStar &&
            text.startsWith('***', j)) {
          // Consume the first '*' to close inner *italic*, letting j+1 close '**'
          openSingleStar = false;
          j++;
          continue;
        }
        if (marker == '~' &&
            j + 1 < text.length &&
            text.codeUnitAt(j + 1) == 126) {
          j++;
          continue;
        }
        if (requireUnderscoreBoundary &&
            j + len < text.length &&
            _isWordChar(text[j + len])) {
          j++;
          continue;
        }
        return j;
      }

      j++;
    }
    return -1;
  }

  WidgetSpan _buildInlineCodeSpan(
    String codeText,
    bool isDark,
    TextStyle? currentStyle,
  ) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: palette.resolveInlineCodeBg(isDark),
          borderRadius: AppSpacing.roundedXs,
        ),
        child: Text(
          codeText,
          style: GoogleFonts.jetBrainsMono(
            fontSize: (currentStyle?.fontSize ?? 15) * 0.88,
            fontWeight: currentStyle?.fontWeight == FontWeight.w800
                ? FontWeight.w800
                : FontWeight.w600,
            fontStyle: currentStyle?.fontStyle ?? FontStyle.normal,
            decoration: currentStyle?.decoration,
            color: palette.resolveInlineCodeText(isDark),
          ),
        ),
      ),
    );
  }

  WidgetSpan _buildScriptSpan(
    String inner, {
    required bool isSuperscript,
    required bool isDark,
    required ThemeData theme,
    required TextStyle? currentStyle,
    required BuildContext? context,
    required int depth,
  }) {
    final baseFontSize = currentStyle?.fontSize ?? 15;
    final scriptStyle = (currentStyle ?? const TextStyle()).copyWith(
      fontSize: baseFontSize * 0.72,
      height: 1.0,
    );

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Transform.translate(
        offset: Offset(
          0,
          isSuperscript ? -(baseFontSize * 0.34) : (baseFontSize * 0.20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.5),
          child: RichText(
            textScaler: TextScaler.noScaling,
            text: TextSpan(
              style: scriptStyle,
              children: _parseInlineSpans(
                inner,
                isDark,
                theme,
                scriptStyle,
                context: context,
                depth: depth,
              ),
            ),
          ),
        ),
      ),
    );
  }

  WidgetSpan _buildFootnoteBadgeSpan(
    _FootnoteEntry entry,
    bool isDark,
    ThemeData theme,
    TextStyle? currentStyle, {
    required BuildContext? context,
  }) {
    final baseFontSize = currentStyle?.fontSize ?? 15;
    final accent = palette.resolveAccentColor(isDark);

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Transform.translate(
        offset: Offset(0, -(baseFontSize * 0.28)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: context == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _showFootnoteSheet(context, entry, isDark, theme);
                    },
              customBorder: AppSpacing.smoothBorder(AppSpacing.roundedXs),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: AppSpacing.smoothDecoration(
                  color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
                  borderRadius: AppSpacing.roundedXs,
                  side: BorderSide(
                    color: accent.withValues(alpha: 0.48),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${entry.number}',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: (baseFontSize * 0.68).clamp(9.5, 13.0),
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: accent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  WidgetSpan _buildWikiLinkSpan(
    ParsedWikiLink parsedLink,
    bool isDark,
    TextStyle? currentStyle,
  ) {
    final targetItem =
        WikiLinkService.resolveTarget(parsedLink.target, workspaceItems);
    final isBoard = targetItem is WhiteboardCanvasItem;
    final exists = targetItem != null;
    final linkPalette =
        exists ? AppColors.getPaletteById(targetItem.paletteId) : palette;
    final linkAccent = linkPalette.resolveAccentColor(isDark);

    return WidgetSpan(
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: exists
                    ? null
                    : Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        width: 0.8,
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
                        fontSize: (currentStyle?.fontSize ?? 15) * 0.86,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: exists
                            ? linkAccent
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  WidgetSpan _buildInlineImageSpan(
    String matched,
    bool isDark, {
    required BuildContext? context,
  }) {
    final midIndex = matched.indexOf('](');
    final alt = matched.substring(2, midIndex);
    final url = matched.substring(midIndex + 2, matched.length - 1).trim();
    final cleanUrl = url.replaceFirst(RegExp(r'^file://'), '');
    final isNet =
        cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://');

    Widget inlineImg;
    if (isNet) {
      inlineImg = Image.network(
        cleanUrl,
        height: 28,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Icon(TackIcons.imageOff, size: 20),
      );
    } else if (!kIsWeb) {
      final file = File(cleanUrl);
      if (file.existsSync()) {
        inlineImg = Image.file(file, height: 28, fit: BoxFit.cover);
      } else {
        inlineImg = Icon(TackIcons.imageOff, size: 20);
      }
    } else {
      inlineImg = Icon(TackIcons.imageOff, size: 20);
    }

    return WidgetSpan(
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
    );
  }

  WidgetSpan _buildMarkdownLinkSpan(
    String label,
    String url,
    bool isDark,
    ThemeData theme,
    TextStyle? currentStyle, {
    required BuildContext? context,
    required int depth,
  }) {
    final accent = palette.resolveAccentColor(isDark);
    final linkLabelStyle = _mergeTextStyle(
      currentStyle,
      fontWeight: currentStyle?.fontWeight == FontWeight.w800
          ? FontWeight.w800
          : FontWeight.w600,
      addDecoration: TextDecoration.underline,
    )?.copyWith(
      color: accent,
      decorationColor: accent,
    );

    return WidgetSpan(
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
              RichText(
                textScaler: TextScaler.noScaling,
                text: TextSpan(
                  style: linkLabelStyle,
                  children: _parseInlineSpans(
                    label,
                    isDark,
                    theme,
                    linkLabelStyle,
                    context: context,
                    depth: depth,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              TackIcon(
                TackIcons.link,
                size: 11,
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  WidgetSpan _buildBareUrlSpan(
    String url,
    bool isDark,
    TextStyle? currentStyle, {
    required BuildContext? context,
  }) {
    final accent = palette.resolveAccentColor(isDark);
    return WidgetSpan(
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
                  color: accent,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: accent,
                  fontSize: currentStyle?.fontSize,
                ),
              ),
              const SizedBox(width: 3),
              TackIcon(
                TackIcons.link,
                size: 11,
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  WidgetSpan _buildHashTokenSpan(String matched, bool isDark) {
    final hexColor = AppColors.tryParseHexColor(matched);
    if (hexColor != null) {
      return WidgetSpan(
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
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.25),
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
      );
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: palette.resolveAccentColor(isDark).withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: AppSpacing.roundedXs,
        ),
        child: Text(
          matched,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: palette.resolveAccentColor(isDark),
          ),
        ),
      ),
    );
  }

  // ─── Footnotes & Definition List Helpers ───────────────────────────────────

  _FootnoteCollection _extractFootnotes(
    List<String> lines,
    int startIndex, {
    _FootnoteCollection? inherited,
  }) {
    final rawDefs = <String, ({String body, int lineIndex})>{};
    final defLineIndices = <int>{};

    bool inFence = false;
    int idx = startIndex;
    while (idx < lines.length) {
      final line = lines[idx];
      final trimmed = line.trim();
      if (trimmed.startsWith('```')) {
        inFence = !inFence;
        idx++;
        continue;
      }
      if (!inFence) {
        final defMatch = _footnoteDefRegex.firstMatch(line);
        if (defMatch != null) {
          final id = defMatch.group(1)!;
          final buffer = <String>[];
          final firstBody = defMatch.group(2)!.trim();
          if (firstBody.isNotEmpty) buffer.add(firstBody);
          defLineIndices.add(idx);

          int k = idx + 1;
          while (k < lines.length) {
            final next = lines[k];
            final nextTrim = next.trim();
            if (nextTrim.startsWith('```') || _footnoteDefRegex.hasMatch(next)) {
              break;
            }
            if (next.startsWith('  ') || next.startsWith('\t')) {
              if (nextTrim.isNotEmpty) buffer.add(nextTrim);
              defLineIndices.add(k);
              k++;
              continue;
            }
            if (nextTrim.isEmpty &&
                k + 1 < lines.length &&
                (lines[k + 1].startsWith('  ') || lines[k + 1].startsWith('\t'))) {
              defLineIndices.add(k);
              k++;
              continue;
            }
            break;
          }

          rawDefs[id] = (
            body: buffer.isEmpty ? '(No details provided)' : buffer.join(' '),
            lineIndex: idx,
          );
          idx = k;
          continue;
        }
      }
      idx++;
    }

    if (rawDefs.isEmpty && inherited == null) {
      return const _FootnoteCollection.empty();
    }

    // Order footnotes by first appearance in body, then unreferenced definitions.
    final byId = <String, _FootnoteEntry>{};
    final localOrdered = <_FootnoteEntry>[];

    if (inherited != null) {
      byId.addAll(inherited.byId);
    }

    int nextNumber = 1;
    if (inherited != null && inherited.byId.isNotEmpty) {
      for (final entry in inherited.byId.values) {
        if (entry.number >= nextNumber) {
          nextNumber = entry.number + 1;
        }
      }
    }

    // Assign local numbering cleanly in top-level docs (1..N) or extending inherited.
    final orderedIds = <String>[];
    bool refInFence = false;
    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().startsWith('```')) {
        refInFence = !refInFence;
        continue;
      }
      if (refInFence || defLineIndices.contains(i)) continue;

      for (final m in _footnoteRefRegex.allMatches(line)) {
        final id = m.group(1)!;
        if (rawDefs.containsKey(id) && !orderedIds.contains(id)) {
          orderedIds.add(id);
        }
      }
    }
    for (final id in rawDefs.keys) {
      if (!orderedIds.contains(id)) {
        orderedIds.add(id);
      }
    }

    int localCounter = inherited == null ? 1 : nextNumber;
    for (final id in orderedIds) {
      final def = rawDefs[id]!;
      final entry = _FootnoteEntry(
        id: id,
        number: localCounter++,
        body: def.body,
        definitionLine: def.lineIndex,
      );
      byId[id] = entry;
      localOrdered.add(entry);
    }

    return _FootnoteCollection(
      byId: byId,
      localDefinitions: localOrdered,
      definitionLineIndices: defLineIndices,
    );
  }

  bool _isNonDefinitionTermLine(String trimmed) {
    if (trimmed.isEmpty) return true;
    if (trimmed.startsWith('#') ||
        trimmed.startsWith('```') ||
        trimmed.startsWith('>') ||
        trimmed.startsWith(':') ||
        trimmed.startsWith('![') ||
        trimmed.startsWith('![[') ||
        trimmed.startsWith('<')) {
      return true;
    }
    final upper = trimmed.toUpperCase();
    if (upper == '[TOC]' || upper == '[[_TOC_]]') return true;
    if (_footnoteDefRegex.hasMatch(trimmed)) return true;
    if (RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(trimmed)) return true;
    if (RegExp(r'^[-*+]\s+').hasMatch(trimmed)) return true;
    if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) return true;
    return false;
  }

  int _findDefinitionStartLine(List<String> lines, int termIndex) {
    if (termIndex + 1 >= lines.length) return -1;
    if (_defLineRegex.hasMatch(lines[termIndex + 1])) return termIndex + 1;
    if (lines[termIndex + 1].trim().isEmpty &&
        termIndex + 2 < lines.length &&
        _defLineRegex.hasMatch(lines[termIndex + 2])) {
      return termIndex + 2;
    }
    return -1;
  }

  _ParsedDefinitionList _consumeDefinitionList(List<String> lines, int start) {
    final groups = <_DefinitionGroup>[];
    int pos = start;

    while (pos < lines.length) {
      final termTrimmed = lines[pos].trim();
      if (_isNonDefinitionTermLine(termTrimmed)) break;

      final defStart = _findDefinitionStartLine(lines, pos);
      if (defStart == -1) break;

      final defs = <String>[];
      int cur = defStart;
      while (cur < lines.length) {
        final m = _defLineRegex.firstMatch(lines[cur]);
        if (m == null) break;

        final parts = <String>[m.group(1)!.trim()];
        int cont = cur + 1;
        while (cont < lines.length) {
          final l = lines[cont];
          final lt = l.trim();
          if (lt.startsWith('```') || _defLineRegex.hasMatch(l)) break;
          if ((l.startsWith('  ') || l.startsWith('\t')) && lt.isNotEmpty) {
            parts.add(lt);
            cont++;
            continue;
          }
          break;
        }
        defs.add(parts.join(' '));
        cur = cont;

        // Skip single blank line between definitions belonging to the same term.
        if (cur < lines.length &&
            lines[cur].trim().isEmpty &&
            cur + 1 < lines.length &&
            _defLineRegex.hasMatch(lines[cur + 1])) {
          cur++;
        }
      }

      groups.add(_DefinitionGroup(term: termTrimmed, definitions: defs));
      pos = cur;

      // Consume a separating blank line if another term + definition follows.
      if (pos < lines.length &&
          lines[pos].trim().isEmpty &&
          pos + 1 < lines.length &&
          !_isNonDefinitionTermLine(lines[pos + 1].trim()) &&
          _findDefinitionStartLine(lines, pos + 1) != -1) {
        pos++;
      } else {
        break;
      }
    }

    return _ParsedDefinitionList(groups: groups, nextIndex: pos);
  }

  Widget _buildDefinitionListWidget(
    BuildContext context,
    List<_DefinitionGroup> groups,
    bool isDark,
    ThemeData theme,
  ) {
    final accent = palette.resolveAccentColor(isDark);
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = palette.resolveTableBorder(isDark);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSpacing.smoothDecoration(
        color: surface,
        borderRadius: AppSpacing.roundedMd,
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int g = 0; g < groups.length; g++) ...[
            if (g > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(height: 1, thickness: 1, color: borderColor),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: _buildRichTextSpans(
                    groups[g].term,
                    isDark,
                    theme,
                    context: context,
                    baseStyle: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      letterSpacing: -0.25,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (int d = 0; d < groups[g].definitions.length; d++)
              Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  bottom: d < groups[g].definitions.length - 1 ? 6 : 0,
                ),
                child: Container(
                  padding: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: accent.withValues(alpha: 0.45),
                        width: 2.2,
                      ),
                    ),
                  ),
                  child: _buildRichTextSpans(
                    groups[g].definitions[d],
                    isDark,
                    theme,
                    context: context,
                    baseStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.48,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFootnotesSection(
    BuildContext context,
    _FootnoteCollection collection,
    bool isDark,
    ThemeData theme,
  ) {
    final accent = palette.resolveAccentColor(isDark);
    final surface = isDark ? AppColors.darkSunken : AppColors.lightSunken;
    final borderColor = palette.resolveTableBorder(isDark);
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppSpacing.smoothDecoration(
          color: surface,
          borderRadius: AppSpacing.roundedMd,
          side: BorderSide(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TackIcon(TackIcons.link, size: 13, color: accent),
                const SizedBox(width: 6),
                Text(
                  'FOOTNOTES',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (int idx = 0; idx < collection.localDefinitions.length; idx++) ...[
              if (idx > 0) const SizedBox(height: 8),
              _wrapLineTap(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2, right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: AppSpacing.smoothDecoration(
                        color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius: AppSpacing.roundedXs,
                        side: BorderSide(
                          color: accent.withValues(alpha: 0.45),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${collection.localDefinitions[idx].number}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildRichTextSpans(
                        collection.localDefinitions[idx].body,
                        isDark,
                        theme,
                        context: context,
                        baseStyle: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13.5,
                          height: 1.48,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontFamily: AppTypography.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
                collection.localDefinitions[idx].definitionLine,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFootnoteSheet(
    BuildContext context,
    _FootnoteEntry entry,
    bool isDark,
    ThemeData theme,
  ) {
    final accent = palette.resolveAccentColor(isDark);
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    AppBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: AppSpacing.smoothDecoration(
                    color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
                    borderRadius: AppSpacing.roundedXs,
                    side: BorderSide(
                      color: accent.withValues(alpha: 0.48),
                      width: 0.9,
                    ),
                  ),
                  child: Text(
                    'Footnote ${entry.number}',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '[^${entry.id}]',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRichTextSpans(
              entry.body,
              isDark,
              theme,
              context: sheetContext,
              baseStyle: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 15,
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
          ],
        ),
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
        errorBuilder: (_, _, _) => Icon(
          TackIcons.imageOff,
          size: 48,
          color: Colors.white54,
        ),
      );
    } else if (!kIsWeb) {
      final file = File(cleanUrl);
      if (file.existsSync()) {
        imageWidget = Image.file(file, fit: BoxFit.contain);
      } else {
        imageWidget = Icon(
          TackIcons.imageOff,
          size: 48,
          color: Colors.white54,
        );
      }
    } else {
      imageWidget = Icon(
        TackIcons.imageOff,
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
                    icon: Icon(TackIcons.close, color: Colors.white, size: 24),
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
                      icon: Icon(TackIcons.externalLink, color: Colors.white, size: 22),
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

class _FootnoteEntry {
  final String id;
  final int number;
  final String body;
  final int definitionLine;

  const _FootnoteEntry({
    required this.id,
    required this.number,
    required this.body,
    required this.definitionLine,
  });
}

class _FootnoteCollection {
  final Map<String, _FootnoteEntry> byId;
  final List<_FootnoteEntry> localDefinitions;
  final Set<int> definitionLineIndices;

  const _FootnoteCollection({
    required this.byId,
    required this.localDefinitions,
    required this.definitionLineIndices,
  });

  const _FootnoteCollection.empty()
      : byId = const {},
        localDefinitions = const [],
        definitionLineIndices = const {};
}

class _FootnoteScope extends InheritedWidget {
  final _FootnoteCollection collection;

  const _FootnoteScope({
    required this.collection,
    required super.child,
  });

  static _FootnoteCollection? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FootnoteScope>()?.collection;

  @override
  bool updateShouldNotify(_FootnoteScope oldWidget) =>
      collection != oldWidget.collection;
}

class _DefinitionGroup {
  final String term;
  final List<String> definitions;

  const _DefinitionGroup({
    required this.term,
    required this.definitions,
  });
}

class _ParsedDefinitionList {
  final List<_DefinitionGroup> groups;
  final int nextIndex;

  const _ParsedDefinitionList({
    required this.groups,
    required this.nextIndex,
  });
}


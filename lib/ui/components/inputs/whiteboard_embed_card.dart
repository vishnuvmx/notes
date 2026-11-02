import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/whiteboard_item.dart';
import '../../../domain/services/frontmatter_service.dart';
import '../../../domain/services/wiki_link_service.dart';

/// Live interactive embed card for `![[Whiteboard]]`, `![[Whiteboard#nodeId]]`,
/// and `![[Note#Heading]]` inside RichNoteContentView.
class WorkspaceEmbedCard extends StatelessWidget {
  final ParsedWikiLink link;
  final BaseWorkspaceItem? resolvedItem;
  final VoidCallback onTap;

  const WorkspaceEmbedCard({
    super.key,
    required this.link,
    required this.resolvedItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = resolvedItem;

    if (item == null) {
      return _buildUnresolvedCard(context, isDark);
    }

    if (item is WhiteboardCanvasItem) {
      return _buildWhiteboardCard(context, item, isDark);
    }

    return _buildNoteTransclusionCard(context, item, isDark);
  }

  Widget _buildUnresolvedCard(BuildContext context, bool isDark) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentAmber.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: TackIcon(TackIcons.plus, size: 18, color: AppColors.accentAmber),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create "${link.target}"',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Tap to create & link this note',
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
        ),
      ),
    );
  }

  Widget _buildWhiteboardCard(
    BuildContext context,
    WhiteboardCanvasItem board,
    bool isDark,
  ) {
    final palette = AppColors.getPaletteById(board.paletteId);
    final accent = palette.resolveAccentColor(isDark);

    CanvasNode? focusedNode;
    if (link.anchor != null && link.anchor!.isNotEmpty) {
      final needle = link.anchor!.toLowerCase();
      focusedNode = board.nodes.cast<CanvasNode?>().firstWhere(
            (n) =>
                n != null &&
                (n.id.toLowerCase() == needle || n.text.toLowerCase().contains(needle)),
            orElse: () => null,
          );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? palette.lightColor.withValues(alpha: 0.35) : const Color(0xFF191A23),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF191A23).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? palette.darkColor.withValues(alpha: 0.35)
                      : palette.softBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    TackIcon(TackIcons.whiteboardSvg, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link.alias ?? board.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark ? Colors.white : const Color(0xFF191A23),
                            ),
                          ),
                          Text(
                            focusedNode != null
                                ? 'Focused node: "${focusedNode.text}"  •  ${board.nodes.length} nodes'
                                : '${board.nodes.length} nodes  •  ${board.edges.length} connections',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: AppSpacing.roundedPill,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        'Open Board →',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Live Mini Vector Canvas Preview
              SizedBox(
                height: 156,
                child: CustomPaint(
                  painter: _MiniWhiteboardPreviewPainter(
                    board: board,
                    focusedNodeId: focusedNode?.id,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTransclusionCard(
    BuildContext context,
    BaseWorkspaceItem noteItem,
    bool isDark,
  ) {
    final palette = AppColors.getPaletteById(noteItem.paletteId);
    final accent = palette.resolveAccentColor(isDark);
    final rawBody =
        FrontmatterService.parse(WikiLinkService.contentOfItem(noteItem))
            .bodyWithoutFrontmatter;
    final excerpt = WikiLinkService.extractSectionMarkdown(
      rawBody,
      anchor: link.anchor,
      maxLines: 9,
    );
    final lines = excerpt
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(8)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? palette.darkColor.withValues(alpha: 0.22)
            : palette.softBackground.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? palette.lightColor.withValues(alpha: 0.35)
              : palette.resolveTableBorder(false),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4.5, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (noteItem.iconEmoji != null && noteItem.iconEmoji!.isNotEmpty) ...[
                              Text(noteItem.iconEmoji!, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                            ] else ...[
                              TackIcon(TackIcons.notesSvg, size: 15, color: accent),
                              const SizedBox(width: 7),
                            ],
                            Expanded(
                              child: Text(
                                link.anchor != null
                                    ? '${noteItem.title}  ›  #${link.anchor}'
                                    : (link.alias ?? noteItem.title),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: isDark ? Colors.white : const Color(0xFF191A23),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: AppSpacing.roundedPill,
                              ),
                              child: Text(
                                link.anchor != null ? 'Section ↗' : 'Embed ↗',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (lines.isNotEmpty) ...[
                          const SizedBox(height: 9),
                          ...lines.map((rawLine) => _buildTranscludedLine(rawLine, isDark, accent)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranscludedLine(String rawLine, bool isDark, Color accent) {
    final trimmed = rawLine.trim();
    final primary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Heading line
    final headingMatch = RegExp(r'^(#{1,4})\s+(.+)$').firstMatch(trimmed);
    if (headingMatch != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 3, bottom: 2),
        child: Text(
          headingMatch.group(2)!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.25,
            color: primary,
          ),
        ),
      );
    }

    // Checklist line
    final taskMatch = RegExp(r'^(?:[-*]\s+)?\[([ xX])\]\s+(.+)$').firstMatch(trimmed);
    if (taskMatch != null) {
      final done = taskMatch.group(1)!.toLowerCase() == 'x';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              done ? '✓ ' : '○ ',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: done ? AppColors.success : accent,
              ),
            ),
            Expanded(
              child: Text(
                taskMatch.group(2)!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12.6,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? secondary.withValues(alpha: 0.7) : secondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Bullet line
    final bulletMatch = RegExp(r'^[-*]\s+(.+)$').firstMatch(trimmed);
    if (bulletMatch != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '•  ',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            Expanded(
              child: Text(
                bulletMatch.group(1)!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12.6,
                  height: 1.38,
                  color: secondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Plain / quote line
    final cleanText = trimmed.startsWith('>') ? trimmed.substring(1).trim() : trimmed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Text(
        cleanText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12.8,
          fontStyle: trimmed.startsWith('>') ? FontStyle.italic : FontStyle.normal,
          height: 1.38,
          color: secondary,
        ),
      ),
    );
  }
}

class _MiniWhiteboardPreviewPainter extends CustomPainter {
  final WhiteboardCanvasItem board;
  final String? focusedNodeId;
  final bool isDark;

  _MiniWhiteboardPreviewPainter({
    required this.board,
    required this.focusedNodeId,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle dot grid background
    final dotPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.06);
    const gridStep = 18.0;
    for (double x = 12; x < size.width; x += gridStep) {
      for (double y = 12; y < size.height; y += gridStep) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }

    if (board.nodes.isEmpty) return;

    double minX = board.nodes.first.x;
    double maxX = board.nodes.first.x + board.nodes.first.width;
    double minY = board.nodes.first.y;
    double maxY = board.nodes.first.y + board.nodes.first.height;

    for (final n in board.nodes) {
      minX = math.min(minX, n.x);
      maxX = math.max(maxX, n.x + n.width);
      minY = math.min(minY, n.y);
      maxY = math.max(maxY, n.y + n.height);
    }

    final contentW = math.max(maxX - minX, 120.0);
    final contentH = math.max(maxY - minY, 80.0);
    const pad = 18.0;

    final scaleX = (size.width - pad * 2) / contentW;
    final scaleY = (size.height - pad * 2) / contentH;
    final scale = math.min(scaleX, scaleY).clamp(0.08, 1.15);

    final offsetX = (size.width - contentW * scale) / 2 - minX * scale;
    final offsetY = (size.height - contentH * scale) / 2 - minY * scale;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    final nodeMap = {for (final n in board.nodes) n.id: n};

    // Draw edges
    final edgePaint = Paint()
      ..color = isDark ? const Color(0xFF6B7280) : const Color(0xFF64748B)
      ..strokeWidth = (1.8 / scale).clamp(1.2, 4.0)
      ..style = PaintingStyle.stroke;

    for (final edge in board.edges) {
      final from = nodeMap[edge.fromNodeId];
      final to = nodeMap[edge.toNodeId];
      if (from == null || to == null) continue;
      canvas.drawLine(from.center, to.center, edgePaint);
    }

    // Draw nodes
    for (final node in board.nodes) {
      final palette = AppColors.getPaletteById(node.paletteId);
      final isFocused = node.id == focusedNodeId;
      final rect = Rect.fromLTWH(node.x, node.y, node.width, node.height);

      final fillPaint = Paint()
        ..color = isDark ? palette.darkColor.withValues(alpha: 0.85) : palette.softBackground
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = isFocused ? AppColors.accentOrange : palette.lightColor
        ..strokeWidth = isFocused ? (3.0 / scale).clamp(2.0, 6.0) : (1.5 / scale).clamp(1.0, 3.0)
        ..style = PaintingStyle.stroke;

      final radius = node.shapeType == CanvasNodeType.startEnd
          ? Radius.circular(node.height / 2)
          : const Radius.circular(8);
      final rrect = RRect.fromRectAndRadius(rect, radius);
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, strokePaint);

      if (node.text.isNotEmpty) {
        final firstLine = node.text.split('\n').first;
        final tp = TextPainter(
          text: TextSpan(
            text: firstLine,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF191A23),
            ),
          ),
          maxLines: 1,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: math.max(node.width - 14, 20));

        tp.paint(
          canvas,
          Offset(
            node.x + (node.width - tp.width) / 2,
            node.y + (node.height - tp.height) / 2,
          ),
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniWhiteboardPreviewPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.focusedNodeId != focusedNodeId ||
        oldDelegate.isDark != isDark;
  }
}


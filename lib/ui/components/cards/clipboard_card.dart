import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/clipboard_item.dart';
import '../feedback/tack_toast.dart';

/// Tactile, modern Clipboard Card following the Tack Android-First Design System.
/// Features curated pastel accents, DM Sans typography, tactile paper-snippet container,
/// interactive copy pill with micro-animation, and long-press menu trigger.
class ClipboardCard extends StatefulWidget {
  final ClipboardItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ClipboardCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<ClipboardCard> createState() => _ClipboardCardState();
}

class _ClipboardCardState extends State<ClipboardCard> {
  bool _isPressed = false;
  bool _justCopied = false;
  Timer? _copiedResetTimer;

  @override
  void dispose() {
    _copiedResetTimer?.cancel();
    super.dispose();
  }

  void _handleCopy() {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: widget.item.clipText));

    setState(() {
      _justCopied = true;
    });

    _copiedResetTimer?.cancel();
    _copiedResetTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _justCopied = false;
        });
      }
    });

    TackToast.show(
      context,
      message: 'Copied to clipboard',
      icon: TackIcons.checkCircle,
      iconColor: AppColors.success,
      bottomMargin: 88,
    );
  }

  bool _isUrl(String text) {
    final trimmed = text.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = AppColors.getPaletteById(widget.item.paletteId);
    final accentColor = palette.resolveAccentColor(isDark);

    final rawTitle = widget.item.title.trim();
    final hasCustomTitle = rawTitle.isNotEmpty && rawTitle != 'Clipboard';
    final isLink = _isUrl(widget.item.clipText);

    // Calculate metadata
    final charCount = widget.item.clipText.length;
    final lineCount = widget.item.clipText.split('\n').length;
    final metaText = '$charCount chars  •  $lineCount ${lineCount == 1 ? 'line' : 'lines'}';

    return AnimatedScale(
      scale: _isPressed ? 0.975 : 1.0,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.item.isPinned
                ? palette.lightColor.withValues(alpha: isDark ? 0.5 : 0.65)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: widget.item.isPinned ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: _isPressed ? 0.2 : 0.35)
                  : const Color(0xFF191A23).withValues(alpha: _isPressed ? 0.02 : 0.05),
              blurRadius: _isPressed ? 8 : 16,
              offset: Offset(0, _isPressed ? 2 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTapDown: (_) {
              HapticFeedback.selectionClick();
              setState(() => _isPressed = true);
            },
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              setState(() => _isPressed = false);
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            onLongPress: widget.onLongPress != null
                ? () {
                    setState(() => _isPressed = false);
                    HapticFeedback.mediumImpact();
                    widget.onLongPress!();
                  }
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Metadata Bar: Source Pill, Pin badge, Star, and Date
                  Row(
                    children: [
                      // Source App / Type Badge (Flexible with ellipsis for long source names)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: palette.lightColor.withValues(alpha: isDark ? 0.16 : 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: palette.lightColor.withValues(alpha: isDark ? 0.35 : 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TackIcon(
                                isLink ? TackIcons.link : TackIcons.clipboard,
                                size: 11.5,
                                color: accentColor,
                              ),
                              const SizedBox(width: 4.5),
                              Flexible(
                                child: Text(
                                  widget.item.sourceApp.isNotEmpty
                                      ? widget.item.sourceApp
                                      : (isLink ? 'Link' : 'Clipboard'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (widget.item.isPinned) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.accentAmber.withValues(alpha: isDark ? 0.2 : 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const TackIcon(
                                TackIcons.pin,
                                size: 11,
                                color: AppColors.accentAmber,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Pinned',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: AppColors.accentAmber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (widget.item.isFavorite) ...[
                        const SizedBox(width: 6),
                        const TackIcon(
                          TackIcons.star,
                          size: 13,
                          color: AppColors.accentAmber,
                        ),
                      ],

                      const SizedBox(width: 8),

                      // Timestamp
                      Text(
                        DateFormatter.formatTimestamp(widget.item.updatedAt),
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),

                  // Optional Custom Title
                  if (hasCustomTitle) ...[
                    const SizedBox(height: 9),
                    Text(
                      rawTitle,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 9),

                  // Tactile Paper-Clipping Snippet Box
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE8EAEF),
                          width: 1.0,
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 3.5,
                              color: palette.lightColor,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Text(
                                  widget.item.clipText.isEmpty ? '(Empty text snippet)' : widget.item.clipText,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 13,
                                    height: 1.45,
                                    letterSpacing: -0.2,
                                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF232530),
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Bottom Action Row: Character Count & Ergonomic Copy Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Metadata info
                      Expanded(
                        child: Text(
                          metaText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tactile Copy Pill Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleCopy,
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _justCopied
                                  ? AppColors.success.withValues(alpha: isDark ? 0.22 : 0.15)
                                  : palette.lightColor.withValues(alpha: isDark ? 0.20 : 0.14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _justCopied
                                    ? AppColors.success.withValues(alpha: 0.6)
                                    : palette.lightColor.withValues(alpha: isDark ? 0.45 : 0.55),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TackIcon(
                                  _justCopied ? TackIcons.check : TackIcons.copy,
                                  size: 13,
                                  color: _justCopied ? AppColors.success : accentColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _justCopied ? 'Copied!' : 'Copy',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    color: _justCopied ? AppColors.success : accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

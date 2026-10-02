import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/clipboard_item.dart';
import '../feedback/tack_toast.dart';

/// Clean Clipboard Card matching reference aesthetics.
/// Features iOS-style press depression, haptics, and instant copy action.
class ClipboardCard extends StatefulWidget {
  final ClipboardItem item;
  final VoidCallback onTap;

  const ClipboardCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<ClipboardCard> createState() => _ClipboardCardState();
}

class _ClipboardCardState extends State<ClipboardCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: _isPressed ? 0.975 : 1.0,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : const Color(0xFF191A23).withValues(alpha: _isPressed ? 0.02 : 0.04),
              blurRadius: _isPressed ? 8 : 16,
              offset: Offset(0, _isPressed ? 2 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTapDown: (_) {
              HapticFeedback.selectionClick();
              setState(() => _isPressed = true);
            },
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              setState(() => _isPressed = false);
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Title + Copy Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: TackIcon(
                          TackIcons.copy,
                          size: 18,
                          color: isDark ? AppColors.pastelCyanLight : AppColors.pastelCyanDark,
                        ),
                        tooltip: 'Copy',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceAlt
                              : AppColors.lightSurfaceAlt,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Clipboard.setData(ClipboardData(text: widget.item.clipText));
                          TackToast.show(
                            context,
                            message: 'Copied to clipboard',
                            icon: TackIcons.checkCircle,
                            iconColor: AppColors.success,
                            bottomMargin: 88,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Clean Snippet Text Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.item.clipText,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        height: 1.4,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Timestamp
                  Text(
                    DateFormatter.formatTimestamp(widget.item.updatedAt),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tack_icons.dart';
import '../../core/utils/date_formatter.dart';
import '../models/base_item.dart';
import '../../features/notes/models/text_note.dart';
import 'tack_card_open_container.dart';
import 'tactile_ink_target.dart';

/// Uniform Soft Monochrome Note Grid Card.
///
/// Shares identical square-ish geometry (`AppSpacing.cardAspectRatio`) with
/// `BoardGridCard` so Notes, Boards, and mixed Pinned grids stay evenly spaced:
/// - Top header: single-line title, pin badge (if favorited), and `...` peek action
/// - Subtitle: calm date (`Mar 10, 2025`)
/// - Lower area: clean open blank space with optional subtle bottom-left tag pill
///   (no body text snippet or embedded image clutter).
///
/// When [openBuilder] is provided, tapping the card (or invoking peek open)
/// runs a Container Transform ([TackCardOpenContainer]) smoothly expanding the
/// card into the detail route and collapsing back into it on Back.
class NeoNoteCard extends StatefulWidget {
  final BaseWorkspaceItem item;
  final VoidCallback? onTap;
  final WidgetBuilder? openBuilder;
  final VoidCallback? onLongPress;
  final void Function(VoidCallback openDetail)? onPeek;
  final bool isGrid;
  final bool showContentPreview;

  const NeoNoteCard({
    super.key,
    required this.item,
    this.onTap,
    this.openBuilder,
    this.onLongPress,
    this.onPeek,
    this.isGrid = true,
    this.showContentPreview = false,
  }) : assert(onTap != null || openBuilder != null);

  @override
  State<NeoNoteCard> createState() => _NeoNoteCardState();
}

class _NeoNoteCardState extends State<NeoNoteCard> {
  bool _isPressed = false;

  Widget _buildInnerSurface({
    required TackTokens tokens,
    required String displayTitle,
    required String? customTag,
    required Color softTint,
    required Color accentColor,
    required ShapeBorder cardShape,
    required VoidCallback handleTap,
  }) {
    final VoidCallback? peekHandler = widget.onPeek != null
        ? () => widget.onPeek!(handleTap)
        : widget.onLongPress;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: cardShape,
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          setState(() => _isPressed = true);
        },
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          setState(() => _isPressed = false);
          HapticFeedback.lightImpact();
          handleTap();
        },
        onLongPress: peekHandler != null
            ? () {
                setState(() => _isPressed = false);
                HapticFeedback.mediumImpact();
                peekHandler();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s3,
            AppSpacing.s3,
            AppSpacing.s5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Row: Title + optional Pin + More (...)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s2),
                      child: Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSm(
                          color: tokens.textPrimary,
                          fontSize: 15.5,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (widget.item.isFavorite) ...[
                    const SizedBox(width: AppSpacing.s2),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s2),
                      child: TackPinBadge(color: tokens.accentPin, size: 10),
                    ),
                  ],
                  if (peekHandler != null) ...[
                    Tooltip(
                      message: 'Item options',
                      child: TactileInkTarget(
                        semanticsLabel: 'Item options',
                        useCircleShape: true,
                        width: 28,
                        height: 28,
                        triggerHaptics: true,
                        onTap: peekHandler,
                        child: TackIcon(
                          TackIcons.more,
                          size: 16,
                          color: tokens.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: AppSpacing.s1),

              // 2. Calm Date Subtitle
              Text(
                DateFormatter.formatCardDate(widget.item.updatedAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(
                  color: tokens.textTertiary,
                  weight: FontWeight.w500,
                ),
              ),

              // 3. Clean Blank Gap Space (optional subtle tag tucked at bottom-left)
              Expanded(
                child: customTag != null
                    ? Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s3,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: softTint,
                            borderRadius: AppSpacing.roundedPill,
                          ),
                          child: Text(
                            customTag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption(
                              color: accentColor,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.expand(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(widget.item.paletteId);
    final accentColor = palette.resolveAccentColor(tokens.isDark);
    final softTint = palette.resolveSoftBackground(tokens.isDark);

    final displayTitle =
        (widget.item.iconEmoji != null && widget.item.iconEmoji!.isNotEmpty)
            ? '${widget.item.iconEmoji} ${widget.item.title}'
            : (widget.item.title.trim().isEmpty ? 'Untitled' : widget.item.title);

    final String? customTag = (widget.item is TextNote &&
            (widget.item as TextNote).tags.isNotEmpty)
        ? '#${(widget.item as TextNote).tags.first}'
        : (widget.item.folderName != null &&
                widget.item.folderName!.isNotEmpty &&
                widget.item.folderName != 'All Notes'
            ? widget.item.folderName!
            : null);

    final cardShape = SmoothRectangleBorder(
      borderRadius: AppSpacing.roundedMd,
      smoothness: AppSpacing.defaultSmoothing,
      side: BorderSide(
        color: _isPressed
            ? tokens.borderStrong
            : tokens.borderSubtle.withValues(alpha: 0.7),
        width: 1,
      ),
    );

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: AppSpacing.durationFast,
      curve: AppSpacing.curveStandard,
      child: AspectRatio(
        aspectRatio: AppSpacing.cardAspectRatio,
        child: widget.openBuilder != null
            ? TackCardOpenContainer(
                openBuilder: widget.openBuilder!,
                closedShape: cardShape,
                closedBuilder: (_, openContainer) => _buildInnerSurface(
                  tokens: tokens,
                  displayTitle: displayTitle,
                  customTag: customTag,
                  softTint: softTint,
                  accentColor: accentColor,
                  cardShape: cardShape,
                  handleTap: openContainer,
                ),
              )
            : Container(
                decoration: ShapeDecoration(
                  color: tokens.surfacePrimary,
                  shadows: AppSpacing.elev1(tokens.isDark),
                  shape: cardShape,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildInnerSurface(
                  tokens: tokens,
                  displayTitle: displayTitle,
                  customTag: customTag,
                  softTint: softTint,
                  accentColor: accentColor,
                  cardShape: cardShape,
                  handleTap: widget.onTap!,
                ),
              ),
      ),
    );
  }
}

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/tack_icons.dart';

/// Apple Liquid Glass Floating Bottom Navigation Bar + Detached Circular (+) Orb.
///
/// Features:
/// - Real translucent `BackdropFilter` glass refraction (`TileMode.clamp`, 120Hz safe)
/// - Specular curved-glass rim light + outer contrast hairline so the dock stays
///   sharply separated from both pure-white cards and deep-carbon backgrounds
/// - 120Hz spring-driven optical glass lens supporting both tap and finger-scrubbing
/// - Matching detached circular Liquid Glass `( + )` capture orb
class SmartBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;
  final int inboxCount;

  const SmartBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
    this.inboxCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gutter = AppSpacing.screenGutter(screenWidth);

    final navItems = [
      (icon: TackIcons.today, label: 'Today', index: 0, badge: inboxCount),
      (icon: TackIcons.library, label: 'Library', index: 1, badge: 0),
      (icon: TackIcons.boards, label: 'Boards', index: 3, badge: 0),
      (icon: TackIcons.search, label: 'Search', index: 4, badge: 0),
    ];

    final matchedSlot = navItems.indexWhere(
      (item) => item.index == currentIndex,
    );
    final selectedSlot = matchedSlot >= 0 ? matchedSlot : 0;
    final hasValidSelection = matchedSlot >= 0;

    return RepaintBoundary(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.s2,
            gutter,
            AppSpacing.s3,
          ),
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                // 1. Liquid Glass Floating Pill Dock
                Expanded(
                  child: _LiquidGlassDock(
                    items: navItems,
                    selectedSlot: selectedSlot,
                    hasValidSelection: hasValidSelection,
                    currentIndex: currentIndex,
                    tokens: tokens,
                    onSelectIndex: onTap,
                  ),
                ),

                const SizedBox(width: AppSpacing.s3),

                // 2. Detached Circular Liquid Glass (+) Capture Orb
                _LiquidGlassCaptureOrb(tokens: tokens, onTap: onFabTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef _NavSlotData = ({dynamic icon, String label, int index, int badge});

class _LiquidGlassDock extends StatefulWidget {
  final List<_NavSlotData> items;
  final int selectedSlot;
  final bool hasValidSelection;
  final int currentIndex;
  final TackTokens tokens;
  final ValueChanged<int> onSelectIndex;

  const _LiquidGlassDock({
    required this.items,
    required this.selectedSlot,
    required this.hasValidSelection,
    required this.currentIndex,
    required this.tokens,
    required this.onSelectIndex,
  });

  @override
  State<_LiquidGlassDock> createState() => _LiquidGlassDockState();
}

class _LiquidGlassDockState extends State<_LiquidGlassDock>
    with SingleTickerProviderStateMixin {
  /// Snappy, fluid Apple-style liquid spring (slight silky settle, zero slop).
  static const SpringDescription _lensSpring = SpringDescription(
    mass: 1.0,
    stiffness: 460.0,
    damping: 38.0,
  );

  late final AnimationController _lensController;
  late int _currentSlot;
  bool _isDragging = false;
  int? _lastDragSlot;

  @override
  void initState() {
    super.initState();
    _currentSlot = widget.selectedSlot.clamp(0, widget.items.length - 1);
    _lensController = AnimationController.unbounded(
      vsync: this,
      value: _currentSlot.toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant _LiquidGlassDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSlot = widget.selectedSlot.clamp(0, widget.items.length - 1);
    if (nextSlot != _currentSlot && !_isDragging) {
      _currentSlot = nextSlot;
      _springToSlot(nextSlot);
    }
  }

  void _springToSlot(int slot) {
    final target = slot.toDouble();
    final current = _lensController.value;
    if ((current - target).abs() < 0.0005 &&
        _lensController.velocity.abs() < 0.01) {
      _lensController.value = target;
      return;
    }
    _lensController.animateWith(
      SpringSimulation(
        _lensSpring,
        current,
        target,
        _lensController.velocity.clamp(-14.0, 14.0),
        tolerance: const Tolerance(distance: 0.0005, velocity: 0.005),
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details, double trackInnerWidth) {
    if (trackInnerWidth <= 0) return;
    final slotWidth = trackInnerWidth / widget.items.length;
    final maxSlot = (widget.items.length - 1).toDouble();
    final nextVal = ((details.localPosition.dx - 5.0) / slotWidth - 0.5).clamp(
      0.0,
      maxSlot,
    );
    _lensController.value = nextVal;

    final nearest = nextVal.round().clamp(0, widget.items.length - 1);
    if (nearest != _lastDragSlot) {
      _lastDragSlot = nearest;
      HapticFeedback.selectionClick();
      if (nearest != _currentSlot) {
        _currentSlot = nearest;
        widget.onSelectIndex(widget.items[nearest].index);
      }
    }
  }

  void _handleDragEnd() {
    if (!_isDragging) return;
    final target = _lensController.value.round().clamp(
      0,
      widget.items.length - 1,
    );
    setState(() => _isDragging = false);
    _lastDragSlot = null;
    if (target != _currentSlot) {
      _currentSlot = target;
      widget.onSelectIndex(widget.items[target].index);
    }
    _springToSlot(target);
  }

  @override
  void dispose() {
    _lensController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    const dockHeight = 60.0;
    const dockPadding = 5.0;

    return Container(
      height: dockHeight,
      decoration: BoxDecoration(
        borderRadius: AppSpacing.roundedPill,
        boxShadow: [
          BoxShadow(
            color: tokens.glassShadowAmbient,
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: tokens.glassShadowContact,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.roundedPill,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 24,
            sigmaY: 24,
            tileMode: ui.TileMode.clamp,
          ),
          child: CustomPaint(
            foregroundPainter: _LiquidGlassRimPainter(
              rimBright: tokens.glassRimBright,
              rimMid: tokens.glassRimMid,
              rimBottom: tokens.glassRimBottom,
              outerHairline: tokens.glassOuterHairline,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppSpacing.roundedPill,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [tokens.glassDockTop, tokens.glassDockBottom],
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final innerWidth = (constraints.maxWidth - dockPadding * 2)
                      .clamp(0.0, double.infinity);
                  final slotWidth = innerWidth / widget.items.length;

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (d) {
                      setState(() => _isDragging = true);
                      _lastDragSlot = _currentSlot;
                      _handleDragUpdate(
                        DragUpdateDetails(
                          globalPosition: d.globalPosition,
                          localPosition: d.localPosition,
                        ),
                        innerWidth,
                      );
                    },
                    onHorizontalDragUpdate: (d) =>
                        _handleDragUpdate(d, innerWidth),
                    onHorizontalDragEnd: (_) => _handleDragEnd(),
                    onHorizontalDragCancel: _handleDragEnd,
                    child: Padding(
                      padding: const EdgeInsets.all(dockPadding),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Gliding Liquid Glass Optical Lens
                          if (widget.hasValidSelection)
                            AnimatedBuilder(
                              animation: _lensController,
                              builder: (_, _) {
                                final pos = _lensController.value;
                                final vel = _lensController.velocity.abs();
                                final motionFactor = _isDragging
                                    ? 1.0
                                    : (vel / 10.0).clamp(0.0, 1.0);
                                final stretchX = 1.0 + 0.045 * motionFactor;
                                final swellY = 1.0 + 0.055 * motionFactor;
                                final dx = pos * slotWidth;

                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Transform.translate(
                                    offset: Offset(dx, 0),
                                    child: SizedBox(
                                      width: slotWidth,
                                      height: double.infinity,
                                      child: Transform.scale(
                                        scaleX: stretchX,
                                        scaleY: swellY,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                AppSpacing.roundedPill,
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                tokens.glassLensTop,
                                                tokens.glassLensBottom,
                                              ],
                                            ),
                                            border: Border.all(
                                              color: tokens.glassLensRim,
                                              width: tokens.isDark ? 0.9 : 1.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    tokens.glassShadowContact,
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                          // Foreground 4-slot crisp icons
                          Row(
                            children: [
                              for (final item in widget.items)
                                Expanded(
                                  child: _buildNavItem(context, item, tokens),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    _NavSlotData item,
    TackTokens tokens,
  ) {
    final isSelected = widget.currentIndex == item.index;
    final fgColor = isSelected
        ? tokens.textPrimary
        : (tokens.isDark
              ? tokens.textSecondary
              : tokens.textPrimary.withValues(alpha: 0.58));

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      value: item.badge > 0 ? '${item.badge} items' : null,
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onSelectIndex(item.index);
      },
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: Material(
          type: MaterialType.transparency,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('nav_item_${item.index}'),
            customBorder: const StadiumBorder(),
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onSelectIndex(item.index);
            },
            child: Center(
              child: AnimatedScale(
                scale: isSelected ? 1.06 : 0.96,
                duration: AppSpacing.durationFast,
                curve: AppSpacing.silky120Hz,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TackIcon(
                      item.icon,
                      size: 22,
                      color: fgColor,
                      style: isSelected
                          ? HeroIconStyle.solid
                          : HeroIconStyle.outline,
                    ),
                    if (item.badge > 0)
                      Positioned(
                        top: -2,
                        right: -4,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: tokens.accentPin,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? tokens.glassLensTop
                                  : tokens.glassDockTop,
                              width: 1.2,
                            ),
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
  }
}

/// Detached circular Liquid Glass `( + )` capture orb with tactile spring press.
class _LiquidGlassCaptureOrb extends StatefulWidget {
  final TackTokens tokens;
  final VoidCallback onTap;

  const _LiquidGlassCaptureOrb({required this.tokens, required this.onTap});

  @override
  State<_LiquidGlassCaptureOrb> createState() => _LiquidGlassCaptureOrbState();
}

class _LiquidGlassCaptureOrbState extends State<_LiquidGlassCaptureOrb> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return Tooltip(
      message: 'Capture thought, note, or board',
      child: Semantics(
        button: true,
        label: 'Capture thought, note, or board',
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: AppSpacing.silky120Hz,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tokens.glassShadowAmbient,
                  blurRadius: 22,
                  spreadRadius: -2,
                  offset: const Offset(0, 9),
                ),
                BoxShadow(
                  color: tokens.glassShadowContact,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: 16,
                  sigmaY: 16,
                  tileMode: ui.TileMode.clamp,
                ),
                child: CustomPaint(
                  foregroundPainter: _LiquidGlassRimPainter(
                    rimBright: tokens.glassFabRim,
                    rimMid: tokens.glassFabRim.withValues(alpha: 0.18),
                    rimBottom: tokens.glassFabRim.withValues(alpha: 0.28),
                    outerHairline: tokens.glassOuterHairline,
                    isCircle: true,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [tokens.glassFabTop, tokens.glassFabBottom],
                      ),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: const ValueKey('nav_capture_fab'),
                        customBorder: const CircleBorder(),
                        splashFactory: NoSplash.splashFactory,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onHighlightChanged: (v) {
                          if (_pressed != v) setState(() => _pressed = v);
                        },
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onTap();
                        },
                        child: Center(
                          child: TackIcon(
                            TackIcons.plus,
                            size: 24,
                            color: tokens.actionPrimaryFg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the signature Apple Liquid Glass curved specular rim + outer contrast
/// hairline so the frosted surface pops crisply off any light or dark canvas.
class _LiquidGlassRimPainter extends CustomPainter {
  final Color rimBright;
  final Color rimMid;
  final Color rimBottom;
  final Color outerHairline;
  final bool isCircle;

  const _LiquidGlassRimPainter({
    required this.rimBright,
    required this.rimMid,
    required this.rimBottom,
    required this.outerHairline,
    this.isCircle = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(
      isCircle ? size.height / 2 : size.height / 2,
    );

    // 1. Crisp outer contrast hairline (prevents glass from washing into white/dark bg)
    final outerRRect = RRect.fromRectAndRadius(rect.deflate(0.4), radius);
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = outerHairline;
    canvas.drawRRect(outerRRect, outerPaint);

    // 2. Specular refractive inner rim light (bright top-left catchlight -> soft bounce)
    final rimRRect = RRect.fromRectAndRadius(rect.deflate(1.1), radius);
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width * 0.35, size.height),
        [rimBright, rimMid, rimBottom],
        const [0.0, 0.52, 1.0],
      );
    canvas.drawRRect(rimRRect, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassRimPainter oldDelegate) =>
      oldDelegate.rimBright != rimBright ||
      oldDelegate.rimMid != rimMid ||
      oldDelegate.rimBottom != rimBottom ||
      oldDelegate.outerHairline != outerHairline ||
      oldDelegate.isCircle != isCircle;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../widgets/onboarding_slide_stage.dart';

/// Four-slide first-run onboarding experience for Tack.
///
/// Features custom artwork generated from `docs/design/onboarding-references/`
/// alongside `floating_cloud_meadows.jpg`, tight DM Sans hierarchy, Back-step
/// navigation on slides 2-4, and a single clear completion path (`Start Writing`).
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  final bool isReplay;

  const OnboardingScreen({
    super.key,
    required this.onCompleted,
    this.isReplay = false,
  });

  static const String cloudMeadowsAsset =
      'assets/images/onboarding/floating_cloud_meadows.jpg';

  static const List<OnboardingSlideData> slides = [
    OnboardingSlideData(
      imageAsset: 'assets/images/onboarding/slide1_tactile_grid.jpg',
      title: 'Notes & stickies,\nwith a tactile twist',
      bodySpans: [
        (text: 'Jot ', highlight: false),
        (text: 'markdown notes', highlight: true),
        (text: ', pin colorful ', highlight: false),
        (text: 'sticky cards', highlight: true),
        (text: ', and track daily tasks in one clean grid.', highlight: false),
      ],
    ),
    OnboardingSlideData(
      imageAsset: cloudMeadowsAsset,
      title: 'All your ideas,\nweightlessly organized',
      showFloatingTileDock: true,
      bodySpans: [
        (text: 'Bring ', highlight: false),
        (text: 'Notes', highlight: true),
        (text: ', ', highlight: false),
        (text: 'Stickies', highlight: true),
        (text: ', visual ', highlight: false),
        (text: 'Whiteboards', highlight: true),
        (text: ', and saved clips together without clutter.', highlight: false),
      ],
    ),
    OnboardingSlideData(
      imageAsset: 'assets/images/onboarding/slide3_connected_ideas.jpg',
      title: '#Tags and\n[[WikiLinks]]',
      bodySpans: [
        (text: 'Connect thoughts with ', highlight: false),
        (text: '[[WikiLinks]]', highlight: true),
        (text: ' and ', highlight: false),
        (text: '#tags', highlight: true),
        (text: ' and explore links in your ', highlight: false),
        (text: 'Knowledge Graph', highlight: true),
        (text: '.', highlight: false),
      ],
    ),
    OnboardingSlideData(
      imageAsset: 'assets/images/onboarding/slide4_local_sanctuary.jpg',
      title: 'Everything in\nyour control',
      bodySpans: [
        (text: 'All notes stay saved ', highlight: false),
        (text: 'locally on device', highlight: true),
        (text: '—with offline ', highlight: false),
        (text: 'JSON & Markdown', highlight: true),
        (text: ' export anytime.', highlight: false),
      ],
    ),
  ];

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _precached = false;

  bool get _isLastSlide => _currentPage >= OnboardingScreen.slides.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final slide in OnboardingScreen.slides) {
        precacheImage(AssetImage(slide.imageAsset), context);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleNextOrFinish() {
    HapticFeedback.lightImpact();
    if (!_isLastSlide) {
      _goToPage(_currentPage + 1);
      return;
    }
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final screenSize = MediaQuery.sizeOf(context);
    final gutter = AppSpacing.screenGutter(screenSize.width);

    return PopScope(
      canPop: _currentPage == 0 && widget.isReplay,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentPage > 0) {
          _goToPage(_currentPage - 1);
        }
      },
      child: Scaffold(
        backgroundColor: tokens.surfacePrimary,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.s2,
                  gutter,
                  AppSpacing.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Minimal Brand Header + Skip (omitted on final slide to avoid redundant exit)
                    SizedBox(
                      height: AppSpacing.minTouchTarget,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: AppSpacing.roundedXs,
                            child: Image.asset(
                              'icon.png',
                              width: 24,
                              height: 24,
                              cacheWidth: 96,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s2),
                          Text(
                            'Tack',
                            style: AppTypography.titleSm(
                              color: tokens.textPrimary,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            reverseDuration: const Duration(milliseconds: 110),
                            transitionBuilder:
                                TackAnimatedTransition.switcherTransition,
                            child: !_isLastSlide
                                ? TextButton(
                                    key: const ValueKey('onboarding_skip'),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      widget.onCompleted();
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: tokens.textSecondary,
                                      minimumSize: const Size(
                                        AppSpacing.minTouchTarget,
                                        AppSpacing.minTouchTarget,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.s3,
                                      ),
                                    ),
                                    child: Text(
                                      'Skip',
                                      style: AppTypography.label(
                                        color: tokens.textSecondary,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('onboarding_no_skip'),
                                    height: AppSpacing.minTouchTarget,
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s2),

                    // 2. Swipeable Slide Pages (Hero Stage + Editorial Copy)
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: OnboardingScreen.slides.length,
                        onPageChanged: (idx) {
                          setState(() => _currentPage = idx);
                        },
                        itemBuilder: (context, index) {
                          final slide = OnboardingScreen.slides[index];
                          return _OnboardingSlidePage(slide: slide);
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s4),

                    // 3. Bottom Navigation Dock (Expanding Pill Indicator + Ink CTA)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (
                              int i = 0;
                              i < OnboardingScreen.slides.length;
                              i++
                            )
                              _PagerDot(
                                index: i,
                                isActive: i == _currentPage,
                                tokens: tokens,
                                onTap: () => _goToPage(i),
                              ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Flexible(
                          child: ElevatedButton(
                            key: const ValueKey('onboarding_primary_cta'),
                            onPressed: _handleNextOrFinish,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tokens.actionPrimary,
                              foregroundColor: tokens.actionPrimaryFg,
                              elevation: 0,
                              minimumSize: const Size(
                                112,
                                AppSpacing.minTouchTarget,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s5,
                                vertical: AppSpacing.s3,
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppSpacing.roundedPill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _isLastSlide ? 'Start Writing' : 'Next',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.label(
                                      color: tokens.actionPrimaryFg,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (!_isLastSlide) ...[
                                  const SizedBox(width: AppSpacing.s2),
                                  TackIcon(
                                    TackIcons.arrowRight,
                                    size: 16,
                                    color: tokens.actionPrimaryFg,
                                  ),
                                ],
                              ],
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
      ),
    );
  }
}

class _OnboardingSlidePage extends StatelessWidget {
  final OnboardingSlideData slide;

  const _OnboardingSlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1.0);
        final compactHeight =
            constraints.maxHeight < 460 ||
            constraints.maxWidth < 350 ||
            scale > 1.15;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: OnboardingSlideStage(slide: slide)),
            SizedBox(height: compactHeight ? AppSpacing.s4 : AppSpacing.s6),
            Text(
              slide.title,
              style: AppTypography.titleLg(
                color: tokens.textPrimary,
                fontSize: compactHeight ? 24 : 28,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text.rich(
              TextSpan(
                style: compactHeight
                    ? AppTypography.bodySm(color: tokens.textSecondary)
                    : AppTypography.body(color: tokens.textSecondary),
                children: [
                  for (final span in slide.bodySpans)
                    TextSpan(
                      text: span.text,
                      style: span.highlight
                          ? (compactHeight
                                ? AppTypography.bodySm(
                                    color: tokens.textPrimary,
                                    weight: FontWeight.w600,
                                  )
                                : AppTypography.body(
                                    color: tokens.textPrimary,
                                    weight: FontWeight.w600,
                                  ))
                          : null,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PagerDot extends StatelessWidget {
  final int index;
  final bool isActive;
  final TackTokens tokens;
  final VoidCallback onTap;

  const _PagerDot({
    required this.index,
    required this.isActive,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Semantics(
      button: true,
      selected: isActive,
      label: 'Go to slide ${index + 1}',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: screenWidth >= 380 ? AppSpacing.minTouchTarget : 32,
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isActive ? 24 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? tokens.actionPrimary : tokens.borderStrong,
                  borderRadius: AppSpacing.roundedPill,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

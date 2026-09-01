import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';


/// Delightful, tactile animated splash & loading screen for Tack.
/// Features floating bouncy pastel sticky shapes, breathing brand icon,
/// smooth animated typography, and seamless transition to the Home dashboard.
class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _pulseController;

  // Staggered animations
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _taglineFadeAnimation;
  late final Animation<double> _cardsBounceAnimation;
  late final Animation<double> _dotsProgressAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.1, 0.55, curve: Curves.easeIn),
    );

    _cardsBounceAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.25, 0.70, curve: Curves.elasticOut),
    );

    _taglineFadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.50, 0.85, curve: Curves.easeOutCubic),
    );

    _dotsProgressAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.60, 0.95, curve: Curves.easeInOut),
    );

    _mainController.forward();

    // Navigate to Home screen after animation completes
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 650),
            pageBuilder: (_, animation, _) => widget.nextScreen,
            transitionsBuilder: (_, animation, _, child) {

              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.04),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient soft glowing gradients
          Positioned(
            top: size.height * 0.15,
            left: size.width * 0.1,
            child: _buildAmbientBlob(
              color: AppColors.pastelPeachLight.withValues(alpha: isDark ? 0.08 : 0.25),
              size: 220,
            ),
          ),
          Positioned(
            bottom: size.height * 0.2,
            right: size.width * 0.08,
            child: _buildAmbientBlob(
              color: AppColors.pastelLavenderLight.withValues(alpha: isDark ? 0.08 : 0.25),
              size: 260,
            ),
          ),
          Positioned(
            top: size.height * 0.45,
            right: size.width * 0.12,
            child: _buildAmbientBlob(
              color: AppColors.pastelCyanLight.withValues(alpha: isDark ? 0.06 : 0.2),
              size: 180,
            ),
          ),

          // Floating background playful pastel cards
          AnimatedBuilder(
            animation: _cardsBounceAnimation,
            builder: (context, child) {
              final t = _cardsBounceAnimation.value;
              return Stack(
                children: [
                  // Top Left Amber Sticky
                  Positioned(
                    top: size.height * 0.22 - (1 - t) * 40,
                    left: 36,
                    child: Transform.rotate(
                      angle: -0.18 * t,
                      child: Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: _buildFloatingStickyTile(
                          color: AppColors.pastelAmberLight,
                          width: 58,
                          height: 58,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),

                  // Top Right Coral Sticky
                  Positioned(
                    top: size.height * 0.26 - (1 - t) * 50,
                    right: 42,
                    child: Transform.rotate(
                      angle: 0.15 * t,
                      child: Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: _buildFloatingStickyTile(
                          color: AppColors.pastelCoralLight,
                          width: 64,
                          height: 64,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),

                  // Bottom Left Cyan Sticky
                  Positioned(
                    bottom: size.height * 0.28 + (1 - t) * 40,
                    left: 48,
                    child: Transform.rotate(
                      angle: 0.12 * t,
                      child: Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: _buildFloatingStickyTile(
                          color: AppColors.pastelCyanLight,
                          width: 52,
                          height: 52,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),

                  // Bottom Right Lime Sticky
                  Positioned(
                    bottom: size.height * 0.24 + (1 - t) * 40,
                    right: 38,
                    child: Transform.rotate(
                      angle: -0.14 * t,
                      child: Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: _buildFloatingStickyTile(
                          color: AppColors.pastelLimeLight,
                          width: 60,
                          height: 60,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Central Hero Branding Animation
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated App Icon Container
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulse = 1.0 + (_pulseController.value * 0.04);
                        return Transform.scale(
                          scale: pulse,
                          child: Container(
                            width: 108,
                            height: 108,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? Colors.black : AppColors.pastelPeachLight)
                                      .withValues(alpha: isDark ? 0.6 : 0.4),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // App Brand Name "Tack"
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(_scaleAnimation),
                    child: Text(
                      'Tack',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontFamily: AppTypography.fontFamily,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle Tagline
                FadeTransition(
                  opacity: _taglineFadeAnimation,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontFamily: AppTypography.fontFamily,
                        letterSpacing: -0.3,
                      ),
                      children: [
                        const TextSpan(text: 'Everything '),
                        TextSpan(
                          text: 'worth',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.pastelAmberLight : AppColors.accentAmber,
                          ),
                        ),
                        const TextSpan(text: ' remembering.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Cute Animated Pastel Loading Dots
                FadeTransition(
                  opacity: _dotsProgressAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final delay = (index * 0.25);
                          final wave = ((_pulseController.value + delay) % 1.0);
                          final dotScale = 0.7 + (wave * 0.6);
                          final colors = [
                            AppColors.pastelPeachLight,
                            AppColors.pastelAmberLight,
                            AppColors.pastelCyanLight,
                            AppColors.pastelLavenderLight,
                          ];

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8 * dotScale,
                            height: 8 * dotScale,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientBlob({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingStickyTile({
    required Color color,
    required double width,
    required double height,
    required bool isDark,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.35 : 0.85),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }
}

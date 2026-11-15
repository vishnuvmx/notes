import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// Central theme builder for Tack — Direction A ("Paper & Pin") Light & Dark themes.
/// Registers `TackTokens` ThemeExtension on both themes.
class AppTheme {
  AppTheme._();

  // ================= Light Theme ("Paper & Pin") =================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      platform: TargetPlatform.android,
      splashFactory: InkRipple.splashFactory,
      extensions: const <ThemeExtension<dynamic>>[
        TackTokens.light,
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _TackFadePageTransitionsBuilder(),
          TargetPlatform.iOS: _TackFadePageTransitionsBuilder(),
          TargetPlatform.linux: _TackFadePageTransitionsBuilder(),
          TargetPlatform.macOS: _TackFadePageTransitionsBuilder(),
          TargetPlatform.windows: _TackFadePageTransitionsBuilder(),
        },
      ),
      brightness: Brightness.light,
      primaryColor: AppColors.lightActionPrimary,
      scaffoldBackgroundColor: AppColors.lightCanvas,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightActionPrimary,
        onPrimary: AppColors.lightCanvas,
        secondary: AppColors.lightAccentPin,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        surfaceContainerHighest: AppColors.lightSunken,
        outline: AppColors.lightBorderStrong,
        outlineVariant: AppColors.lightBorderSubtle,
        error: AppColors.lightStateDanger,
        onError: Colors.white,
      ),
      textTheme: AppTypography.lightTextTheme,
      fontFamily: AppTypography.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightCanvas,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        toolbarHeight: AppSpacing.appBarHeight,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTypography.title(color: AppColors.lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: const SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          smoothness: 0.60,
          side: BorderSide(color: AppColors.lightBorderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightActionPrimary,
          foregroundColor: AppColors.lightCanvas,
          elevation: 0,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: const SmoothRectangleBorder(
            borderRadius: AppSpacing.roundedSm,
            smoothness: 0.60,
          ),
          textStyle: AppTypography.label(color: AppColors.lightCanvas, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          side: const BorderSide(color: AppColors.lightBorderStrong, width: 1.0),
          shape: const SmoothRectangleBorder(
            borderRadius: AppSpacing.roundedSm,
            smoothness: 0.60,
          ),
          textStyle: AppTypography.label(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          shape: const SmoothRectangleBorder(
            borderRadius: AppSpacing.roundedSm,
            smoothness: 0.60,
          ),
          textStyle: AppTypography.label(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        border: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: BorderSide(color: AppColors.lightBorderStrong, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: BorderSide(color: AppColors.lightBorderStrong, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: BorderSide(color: AppColors.lightActionPrimary, width: 2.0),
        ),
        hintStyle: AppTypography.body(color: AppColors.lightTextTertiary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorderSubtle,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedModal,
          smoothness: 0.60,
          side: BorderSide(color: AppColors.lightBorderSubtle, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedModal,
          smoothness: 0.60,
        ),
        showDragHandle: false,
        dragHandleColor: AppColors.lightBorderStrong,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightSurface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        position: PopupMenuPosition.under,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: BorderSide(color: AppColors.lightBorderSubtle, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.lightActionPrimary,
        contentTextStyle: AppTypography.bodySm(color: AppColors.lightCanvas),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedSm,
          side: BorderSide.none,
        ),
        elevation: 4,
        actionTextColor: AppColors.pastelAmberLight,
      ),
    );
  }

  // ================= Dark Theme (Warm Charcoal) =================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      platform: TargetPlatform.android,
      splashFactory: InkRipple.splashFactory,
      extensions: const <ThemeExtension<dynamic>>[
        TackTokens.dark,
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _TackFadePageTransitionsBuilder(),
          TargetPlatform.iOS: _TackFadePageTransitionsBuilder(),
          TargetPlatform.linux: _TackFadePageTransitionsBuilder(),
          TargetPlatform.macOS: _TackFadePageTransitionsBuilder(),
          TargetPlatform.windows: _TackFadePageTransitionsBuilder(),
        },
      ),
      brightness: Brightness.dark,
      primaryColor: AppColors.darkActionPrimary,
      scaffoldBackgroundColor: AppColors.darkCanvas,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkActionPrimary,
        onPrimary: AppColors.darkCanvas,
        secondary: AppColors.darkAccentPin,
        onSecondary: AppColors.darkCanvas,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSunken,
        outline: AppColors.darkBorderStrong,
        outlineVariant: AppColors.darkBorderSubtle,
        error: AppColors.darkStateDanger,
        onError: AppColors.darkCanvas,
      ),
      textTheme: AppTypography.darkTextTheme,
      fontFamily: AppTypography.fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkCanvas,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        toolbarHeight: AppSpacing.appBarHeight,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: AppTypography.title(color: AppColors.darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: const SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          smoothness: 0.60,
          side: BorderSide(color: AppColors.darkBorderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkActionPrimary,
          foregroundColor: AppColors.darkCanvas,
          elevation: 0,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: const SmoothRectangleBorder(
            borderRadius: AppSpacing.roundedSm,
            smoothness: 0.60,
          ),
          textStyle: AppTypography.label(color: AppColors.darkCanvas, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          side: const BorderSide(color: AppColors.darkBorderStrong, width: 1.0),
          shape: const SmoothRectangleBorder(
            borderRadius: AppSpacing.roundedSm,
            smoothness: 0.60,
          ),
          textStyle: AppTypography.label(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          shape: const SmoothRectangleBorder(
            borderRadius: AppSpacing.roundedSm,
            smoothness: 0.60,
          ),
          textStyle: AppTypography.label(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        border: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: BorderSide(color: AppColors.darkBorderStrong, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: BorderSide(color: AppColors.darkBorderStrong, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.roundedSm,
          borderSide: BorderSide(color: AppColors.darkActionPrimary, width: 2.0),
        ),
        hintStyle: AppTypography.body(color: AppColors.darkTextTertiary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorderSubtle,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedModal,
          smoothness: 0.60,
          side: BorderSide(color: AppColors.darkBorderSubtle, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedModal,
          smoothness: 0.60,
        ),
        showDragHandle: false,
        dragHandleColor: AppColors.darkBorderStrong,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        surfaceTintColor: Colors.transparent,
        position: PopupMenuPosition.under,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: BorderSide(color: AppColors.darkBorderSubtle, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkActionPrimary,
        contentTextStyle: AppTypography.bodySm(color: AppColors.darkCanvas),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedSm,
          side: BorderSide.none,
        ),
        elevation: 4,
        actionTextColor: AppColors.darkAccentPin,
      ),
    );
  }
}

/// Clean fade + subtle vertical settle page transition with zero scale
/// bounding-box artifacts and zero Cupertino parallax shadow shimmer.
class _TackFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _TackFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return TackAnimatedTransition(
      animation: animation,
      slideBegin: const Offset(0, 0.02),
      child: child,
    );
  }
}

/// Composited fade and optional slide/scale transition that manages and
/// disposes its [CurvedAnimation] listeners properly and uses responsive exit
/// curves so route pops, dialogs, and previews never stall at high opacity.
class TackAnimatedTransition extends StatefulWidget {
  const TackAnimatedTransition({
    super.key,
    required this.animation,
    required this.child,
    this.fadeCurve = Curves.easeOutCubic,
    this.fadeReverseCurve = const Interval(
      0.28,
      1.0,
      curve: Curves.easeInCubic,
    ),
    this.motionCurve = Curves.easeOutCubic,
    this.motionReverseCurve = const Interval(
      0.28,
      1.0,
      curve: Curves.easeInCubic,
    ),
    this.slideBegin,
    this.scaleBegin,
  });

  final Animation<double> animation;
  final Widget child;
  final Curve fadeCurve;
  final Curve fadeReverseCurve;
  final Curve motionCurve;
  final Curve motionReverseCurve;
  final Offset? slideBegin;
  final double? scaleBegin;

  /// Shared [AnimatedSwitcher] transition builder that isolates the fading
  /// subtree in a [RepaintBoundary] so complex children do not re-rasterize
  /// every cross-fade frame.
  static Widget switcherTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: RepaintBoundary(child: child),
    );
  }

  @override
  State<TackAnimatedTransition> createState() => _TackAnimatedTransitionState();
}

class _TackAnimatedTransitionState extends State<TackAnimatedTransition> {
  late CurvedAnimation _fadeAnimation;
  CurvedAnimation? _motionAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void didUpdateWidget(covariant TackAnimatedTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    final configChanged = oldWidget.animation != widget.animation ||
        oldWidget.fadeCurve != widget.fadeCurve ||
        oldWidget.fadeReverseCurve != widget.fadeReverseCurve ||
        oldWidget.motionCurve != widget.motionCurve ||
        oldWidget.motionReverseCurve != widget.motionReverseCurve ||
        oldWidget.slideBegin != widget.slideBegin ||
        oldWidget.scaleBegin != widget.scaleBegin;
    if (configChanged) {
      _disposeAnimations();
      _initAnimations();
    }
  }

  void _initAnimations() {
    _fadeAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: widget.fadeCurve,
      reverseCurve: widget.fadeReverseCurve,
    );

    final hasMotion = widget.slideBegin != null || widget.scaleBegin != null;
    if (!hasMotion) {
      _motionAnimation = null;
      _slideAnimation = null;
      _scaleAnimation = null;
      return;
    }

    final useSeparateMotion = widget.motionCurve != widget.fadeCurve ||
        widget.motionReverseCurve != widget.fadeReverseCurve;
    final motionBase = useSeparateMotion
        ? (_motionAnimation = CurvedAnimation(
            parent: widget.animation,
            curve: widget.motionCurve,
            reverseCurve: widget.motionReverseCurve,
          ))
        : _fadeAnimation;

    _slideAnimation = widget.slideBegin == null
        ? null
        : Tween<Offset>(
            begin: widget.slideBegin,
            end: Offset.zero,
          ).animate(motionBase);

    _scaleAnimation = widget.scaleBegin == null
        ? null
        : Tween<double>(
            begin: widget.scaleBegin,
            end: 1.0,
          ).animate(motionBase);
  }

  void _disposeAnimations() {
    _fadeAnimation.dispose();
    _motionAnimation?.dispose();
    _motionAnimation = null;
  }

  @override
  void dispose() {
    _disposeAnimations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep RepaintBoundary directly around child so FadeTransition alpha-blends
    // the cached layer, and apply transform motion outside FadeTransition.
    Widget current = FadeTransition(
      opacity: _fadeAnimation,
      child: RepaintBoundary(child: widget.child),
    );
    if (_slideAnimation != null) {
      current = SlideTransition(
        position: _slideAnimation!,
        child: current,
      );
    }
    if (_scaleAnimation != null) {
      current = ScaleTransition(
        scale: _scaleAnimation!,
        child: current,
      );
    }
    return current;
  }
}

/// Clean input decoration presets that prevent global InputDecorationTheme leaking
/// inner borders or filled colors into custom-styled search fields, table cells, or inline inputs.
class AppInputDecorations {
  AppInputDecorations._();

  static const InputDecoration bare = InputDecoration(
    isDense: true,
    filled: false,
    fillColor: Colors.transparent,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    contentPadding: EdgeInsets.zero,
  );

  static InputDecoration bareWithHint(String hint, {TextStyle? hintStyle}) {
    return bare.copyWith(
      hintText: hint,
      hintStyle: hintStyle,
    );
  }
}

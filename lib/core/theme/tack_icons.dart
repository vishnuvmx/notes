import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'app_colors.dart';

enum HeroIconStyle { outline, solid }

/// Descriptor for Tack's custom 64x64 SVG icon packs in
/// `icons/white-icons/` and `icons/dark-icons/`.
///
/// - Single-color SVGs (`isSingleColor: true`) can be safely color-tinted via
///   `BlendMode.srcIn` when an explicit/semantic color is provided.
/// - Two-tone / multi-color SVGs (`isSingleColor: false`) preserve their
///   built-in dual-tone shading and switch between `white-icons/` and
///   `dark-icons/` based on surface brightness or foreground luminance.
class TackSvgIcon {
  final String name;
  final bool isSingleColor;
  final double opticalScale;

  const TackSvgIcon(
    this.name, {
    this.isSingleColor = false,
    this.opticalScale = 1.20,
  });
}

/// Central Iconography for Tack powered by custom light/dark SVG packs and
/// Lucide fallback icons for shapes without a custom SVG.
///
/// Always render icons through `TackIcon(...)` rather than `Icon(...)`.
class TackIcons {
  TackIcons._();

  // Primary SVG icons
  static const TackSvgIcon homeSvg = TackSvgIcon('home');
  static const TackSvgIcon notesSvg = TackSvgIcon('notes');
  static const TackSvgIcon whiteboardSvg = TackSvgIcon('whiteboard');
  static const TackSvgIcon clipboardSvg = TackSvgIcon('clipboard');
  static const TackSvgIcon plusSvg = TackSvgIcon('plus', isSingleColor: true);
  static const TackSvgIcon selectSvg = TackSvgIcon('select');
  static const TackSvgIcon handSvg = TackSvgIcon('hand', isSingleColor: true);
  static const TackSvgIcon connectorSvg = TackSvgIcon('connector');
  static const TackSvgIcon textSvg = TackSvgIcon('text', isSingleColor: true);
  static const TackSvgIcon imageSvg = TackSvgIcon('image');
  static const TackSvgIcon drawSvg = TackSvgIcon('draw');
  static const TackSvgIcon editSvg = TackSvgIcon('edit');
  static const TackSvgIcon eyeSvg = TackSvgIcon('eye', isSingleColor: true);
  static const TackSvgIcon undoSvg = TackSvgIcon('undo', isSingleColor: true);
  static const TackSvgIcon redoSvg = TackSvgIcon('redo', isSingleColor: true);
  static const TackSvgIcon searchSvg = TackSvgIcon('search', isSingleColor: true);
  static const TackSvgIcon copySvg = TackSvgIcon('copy');
  static const TackSvgIcon pasteSvg = TackSvgIcon('paste');

  // Navigation & Primary Tabs
  static const TackSvgIcon today = TackSvgIcon('today');
  static const TackSvgIcon library = TackSvgIcon('library');
  static const TackSvgIcon inbox = TackSvgIcon('inbox');
  static const TackSvgIcon boards = TackSvgIcon('boards');
  static const TackSvgIcon home = TackSvgIcon('home');
  static const TackSvgIcon notes = TackSvgIcon('notes');
  static const TackSvgIcon sticky = TackSvgIcon('sticky_notes');
  static const TackSvgIcon whiteboard = TackSvgIcon('whiteboard');
  static const TackSvgIcon clipboard = TackSvgIcon('clipboard');
  static const TackSvgIcon plus = TackSvgIcon('plus', isSingleColor: true);

  // App Bar & Common Actions
  static const TackSvgIcon menu = TackSvgIcon('menu', isSingleColor: true);
  static const TackSvgIcon search = TackSvgIcon('search', isSingleColor: true);
  static const TackSvgIcon close = TackSvgIcon('close', isSingleColor: true);
  static const TackSvgIcon check = TackSvgIcon('check', isSingleColor: true);
  static const TackSvgIcon checkCircle =
      TackSvgIcon('check_circle', isSingleColor: true);
  static const TackSvgIcon back = TackSvgIcon('back');
  static const TackSvgIcon more = TackSvgIcon('more', isSingleColor: true);
  static const TackSvgIcon share = TackSvgIcon('share', isSingleColor: true);
  static const TackSvgIcon copy = TackSvgIcon('copy');
  static const TackSvgIcon paste = TackSvgIcon('paste');
  static const TackSvgIcon exportData =
      TackSvgIcon('export', isSingleColor: true);
  static const TackSvgIcon importData =
      TackSvgIcon('import', isSingleColor: true);
  static const TackSvgIcon undo = TackSvgIcon('undo', isSingleColor: true);
  static const TackSvgIcon redo = TackSvgIcon('redo', isSingleColor: true);
  static const TackSvgIcon palette = TackSvgIcon('palette');
  static const TackSvgIcon clock = TackSvgIcon('clock', isSingleColor: true);
  static const TackSvgIcon sort = TackSvgIcon('sort');
  static const TackSvgIcon saving = TackSvgIcon('loading');
  static const IconData command = LucideIcons.command;

  // Todo / Tasks
  static const TackSvgIcon task = TackSvgIcon('task', isSingleColor: true);
  static const TackSvgIcon taskOpen =
      TackSvgIcon('task_open', isSingleColor: true);
  static const TackSvgIcon todayTasks = TackSvgIcon('today_tasks');

  // Folders & Views
  static const TackSvgIcon folder = TackSvgIcon('folder');
  static const TackSvgIcon folderPlus = TackSvgIcon('folder_plus');
  static const TackSvgIcon folderTree = TackSvgIcon('folder_tree');
  static const TackSvgIcon graph = TackSvgIcon('graph');
  static const TackSvgIcon gridView = TackSvgIcon('grid_view');
  static const TackSvgIcon listView = TackSvgIcon('list_view');

  // Secondary / Drawer / Settings
  static const TackSvgIcon star = TackSvgIcon('star', isSingleColor: true);
  static const TackSvgIcon archive = TackSvgIcon('archive');
  static const TackSvgIcon trash = TackSvgIcon('delete', isSingleColor: true);
  static const TackSvgIcon settings =
      TackSvgIcon('settings', isSingleColor: true);
  static const IconData sun = LucideIcons.sun;
  static const IconData moon = LucideIcons.moon;
  static const TackSvgIcon user = TackSvgIcon('user', isSingleColor: true);
  static const TackSvgIcon notification = TackSvgIcon('notification');

  // Editor & Formatting
  static const TackSvgIcon chevronDown =
      TackSvgIcon('chevron_down', isSingleColor: true);
  static const TackSvgIcon chevronUp =
      TackSvgIcon('chevron_up', isSingleColor: true);
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const TackSvgIcon chevronRight =
      TackSvgIcon('chevron_right', isSingleColor: true);
  static const TackSvgIcon edit = TackSvgIcon('edit');
  static const TackSvgIcon reader = TackSvgIcon('eye', isSingleColor: true);
  static const TackSvgIcon tag = TackSvgIcon('tag', isSingleColor: true);
  static const TackSvgIcon eye = TackSvgIcon('eye', isSingleColor: true);
  static const TackSvgIcon eyeOff = TackSvgIcon('eye_off');
  static const IconData imageOff = LucideIcons.imageOff;
  static const IconData externalLink = LucideIcons.externalLink;
  static const TackSvgIcon play = TackSvgIcon('play', isSingleColor: true);
  static const TackSvgIcon bold =
      TackSvgIcon('bold', isSingleColor: true, opticalScale: 1.28);
  static const TackSvgIcon italic =
      TackSvgIcon('italic', isSingleColor: true, opticalScale: 1.28);
  static const TackSvgIcon underline = TackSvgIcon('underline');
  static const TackSvgIcon strikethrough = TackSvgIcon('strikethrough');
  static const TackSvgIcon code = TackSvgIcon('code', isSingleColor: true);
  static const TackSvgIcon quote = TackSvgIcon('quote', isSingleColor: true);
  static const TackSvgIcon bulletList = TackSvgIcon('bullet_list');
  static const TackSvgIcon numberedList = TackSvgIcon('numbered_list');
  static const TackSvgIcon heading1 = TackSvgIcon('heading_1');
  static const TackSvgIcon heading2 = TackSvgIcon('heading_2');
  static const TackSvgIcon heading3 = TackSvgIcon('heading_3');
  static const TackSvgIcon table = TackSvgIcon('table');
  static const TackSvgIcon alignLeft =
      TackSvgIcon('align_left', isSingleColor: true);
  static const TackSvgIcon alignCenter =
      TackSvgIcon('align_center', isSingleColor: true);
  static const TackSvgIcon alignRight =
      TackSvgIcon('align_right', isSingleColor: true);

  // Whiteboard & Canvas Tools
  static const IconData square = LucideIcons.square;
  static const IconData diamond = LucideIcons.diamond;
  static const TackSvgIcon flow = TackSvgIcon('flow');
  static const TackSvgIcon cursor =
      TackSvgIcon('cursor', isSingleColor: true, opticalScale: 1.12);
  static const TackSvgIcon hand = TackSvgIcon('hand', isSingleColor: true);
  static const TackSvgIcon move = TackSvgIcon('move', isSingleColor: true);
  static const TackSvgIcon photo = TackSvgIcon('image');
  static const TackSvgIcon camera = TackSvgIcon('camera');
  static const TackSvgIcon minus = TackSvgIcon('minus', isSingleColor: true);
  static const TackSvgIcon pencil = TackSvgIcon('draw');
  static const TackSvgIcon link = TackSvgIcon('link');
  static const TackSvgIcon pin = TackSvgIcon('pin');
  static const TackSvgIcon stickyNote = TackSvgIcon('sticky_note');
  static const TackSvgIcon map = TackSvgIcon('map');
  static const IconData scan = LucideIcons.scan;
  static const TackSvgIcon maximize =
      TackSvgIcon('expand', isSingleColor: true);
  static const TackSvgIcon collapse = TackSvgIcon('collapse');
  static const IconData arrowLeftRight = LucideIcons.arrowLeftRight;
  static const IconData bolt = LucideIcons.zap;
  static const TackSvgIcon sparkles = TackSvgIcon('sparkles');
  static const IconData briefcase = LucideIcons.briefcase;
  static const TackSvgIcon calendar = TackSvgIcon('calendar');
  static const TackSvgIcon lock = TackSvgIcon('lock', opticalScale: 1.06);

  // Status & Feedback
  static const TackSvgIcon info = TackSvgIcon('info', isSingleColor: true);
  static const TackSvgIcon warning = TackSvgIcon('warning', isSingleColor: true);
  static const TackSvgIcon error = TackSvgIcon('error', isSingleColor: true);
  static const TackSvgIcon success = TackSvgIcon('success', isSingleColor: true);
  static const TackSvgIcon flag =
      TackSvgIcon('flag', isSingleColor: true, opticalScale: 1.08);
  static const TackSvgIcon refresh =
      TackSvgIcon('refresh', isSingleColor: true, opticalScale: 1.0);
  static const TackSvgIcon save = TackSvgIcon('save');
  static const TackSvgIcon shield = TackSvgIcon('shield');
  static const TackSvgIcon lightbulb = TackSvgIcon('lightbulb');
  static const TackSvgIcon workflow = TackSvgIcon('workflow');
  static const TackSvgIcon layers = TackSvgIcon('layers');
  static const TackSvgIcon arrowUp = TackSvgIcon('arrow_up');
  static const TackSvgIcon arrowDown = TackSvgIcon('arrow_down');
  static const TackSvgIcon arrowLeft = TackSvgIcon('arrow_left');
  static const TackSvgIcon arrowRight = TackSvgIcon('arrow_right');

  // Additional custom SVG icons from dark-icons / white-icons packs
  static const TackSvgIcon add = TackSvgIcon('add', isSingleColor: true);
  static const TackSvgIcon alert = TackSvgIcon('alert', isSingleColor: true);
  static const TackSvgIcon crop = TackSvgIcon('crop', isSingleColor: true);
  static const TackSvgIcon expandNavigation =
      TackSvgIcon('expand_navigation', isSingleColor: true);
  static const TackSvgIcon grid = TackSvgIcon('grid');
  static const TackSvgIcon imageTool = TackSvgIcon('image_tool');
  static const TackSvgIcon nestedList = TackSvgIcon('nested_list');
  static const TackSvgIcon paragraph =
      TackSvgIcon('paragraph', isSingleColor: true);
  static const TackSvgIcon smile = TackSvgIcon('smile', isSingleColor: true);
  static const TackSvgIcon textTool =
      TackSvgIcon('text_tool', isSingleColor: true);
  static const TackSvgIcon visibility =
      TackSvgIcon('visibility', isSingleColor: true);
}

/// Unified icon widget supporting custom SVG packs (`TackSvgIcon`), legacy
/// asset paths (`String`), and Lucide `IconData` fallbacks.
class TackIcon extends StatelessWidget {
  final dynamic icon;
  final double size;
  final Color? color;
  final dynamic style;

  const TackIcon(
    this.icon, {
    super.key,
    this.size = 22.0,
    this.color,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeIconColor = IconTheme.of(context).color;
    final effectiveColor =
        color ??
        themeIconColor ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    if (icon is TackSvgIcon) {
      final svgIcon = icon as TackSvgIcon;
      final Widget svgWidget;
      if (svgIcon.isSingleColor) {
        final useTint = color != null || themeIconColor != null;
        final folder = useTint
            ? 'dark-icons'
            : (isDark ? 'white-icons' : 'dark-icons');
        svgWidget = SvgPicture.asset(
          'icons/$folder/${svgIcon.name}.svg',
          width: size,
          height: size,
          colorFilter: useTint
              ? ColorFilter.mode(effectiveColor, BlendMode.srcIn)
              : null,
        );
      } else {
        // Multi-color / two-tone SVGs must not receive a BlendMode.srcIn color
        // filter, as it flattens their palette accents. Only explicit light
        // (> 0.65 luminance) or dark (< 0.12 luminance) ink overrides force
        // white-icons vs dark-icons; mid-tone accent colors follow theme mode.
        final targetColor = color ?? themeIconColor;
        final bool useWhiteVariant;
        if (targetColor != null) {
          final lum = targetColor.computeLuminance();
          useWhiteVariant = lum > 0.65 ? true : (lum < 0.12 ? false : isDark);
        } else {
          useWhiteVariant = isDark;
        }
        final folder = useWhiteVariant ? 'white-icons' : 'dark-icons';
        svgWidget = SvgPicture.asset(
          'icons/$folder/${svgIcon.name}.svg',
          width: size,
          height: size,
        );
      }

      // Normalize the 64x64 SVG viewBox transparent margin while keeping a
      // strict `size x size` layout footprint so icons fill their slots cleanly
      // without overflowing tight containers or shifting surrounding layouts.
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: svgIcon.opticalScale == 1.0
              ? svgWidget
              : Transform.scale(
                  scale: svgIcon.opticalScale,
                  child: svgWidget,
                ),
        ),
      );
    }

    if (icon is String) {
      final effectiveSvgSize = size * 1.5;
      return SvgPicture.asset(
        icon as String,
        width: effectiveSvgSize,
        height: effectiveSvgSize,
        colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      );
    }

    if (icon is IconData) {
      return Icon(
        icon as IconData,
        size: size,
        color: effectiveColor,
      );
    }

    return SizedBox(width: size, height: size);
  }
}

/// Custom tactile Pin Badge matching Tack's visual language.
class TackPinBadge extends StatelessWidget {
  final Color? color;
  final double size;
  final bool showIcon;

  const TackPinBadge({
    super.key,
    this.color,
    this.size = 14.0,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor =
        color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightAccentPin);

    if (!showIcon) {
      return Container(
        width: size * 0.65,
        height: size * 0.65,
        decoration: BoxDecoration(
          color: resolvedColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
      );
    }

    return TackIcon(
      TackIcons.pin,
      size: size,
      color: resolvedColor,
    );
  }
}
